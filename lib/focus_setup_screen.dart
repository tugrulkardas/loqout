import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'focus_session_screen.dart';
import 'l10n/l10n_ext.dart';
import 'models/app_models.dart';
import 'models/session_telemetry.dart';
import 'screens/edit_blocklist_screen.dart';
import 'screens/ios_shield_picker_screen.dart';
import 'services/blocklist_service.dart';
import 'services/ios_shield_service.dart';
import 'services/session_repository.dart';
import 'theme/tapfocus_theme.dart';
import 'widgets/beta_qr_auth_button.dart';
import 'widgets/language_menu_button.dart';
import 'widgets/product_motto.dart';

class FocusSetupScreen extends StatefulWidget {
  const FocusSetupScreen({
    super.key,
    this.onToggleTheme,
    this.themeIcon,
    this.themeTooltip,
  });

  final VoidCallback? onToggleTheme;
  final IconData? themeIcon;
  final String? themeTooltip;

  @override
  State<FocusSetupScreen> createState() => _FocusSetupScreenState();
}

class _FocusSetupScreenState extends State<FocusSetupScreen> {
  static const int gridSize = 10;

  int _selectedX = 4;
  int _selectedY = 4;
  bool _busy = false;

  /// Null until first localized default is applied / an update is set.
  String? _scanStatus;

  DefaultBlocklist _blocklist = const DefaultBlocklist(
    packages: [],
    names: [],
  );
  IosShieldSelection _iosShield = const IosShieldSelection();

  final _sessions = SessionRepository();
  final _blocklistService = BlocklistService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadBlocklist());
  }

  Future<void> _reloadBlocklist({bool refreshIosShield = false}) async {
    final loaded = await _blocklistService.load();
    var iosShield = _iosShield;
    // AuthorizationCenter aborts the process when the distribution profile
    // lacks Family Controls. Do not touch it during cold start.
    if (refreshIosShield && IosShieldService.isSupported) {
      try {
        iosShield = await IosShieldService.instance.summary();
      } catch (e, st) {
        debugPrint('Family Controls summary failed: $e\n$st');
      }
    }
    if (!mounted) return;
    setState(() {
      _blocklist = loaded;
      _iosShield = iosShield;
    });
  }

  MoodQuadrant _getCurrentQuadrant() {
    return MoodAxes.quadrantFromCell(_selectedX, _selectedY, gridSize: gridSize);
  }

  int _getCurrentIntensity() {
    const double center = 4.5;
    final double dx = (_selectedX - center).abs();
    final double dy = (_selectedY - center).abs();
    final double distance = math.sqrt(math.pow(dx, 2) + math.pow(dy, 2));
    const double maxDistance = 6.36;
    final double normalizedIntensity = distance / maxDistance;
    return (1 + (normalizedIntensity * 4)).round().clamp(1, 5);
  }

  void _updateSelection(Offset localPos, double size) {
    final double step = size / gridSize;
    final int newX = (localPos.dx / step).floor().clamp(0, gridSize - 1);
    final int newY = (localPos.dy / step).floor().clamp(0, gridSize - 1);

    if (newX != _selectedX || newY != _selectedY) {
      setState(() {
        _selectedX = newX;
        _selectedY = newY;
      });
    }
  }

  String? _getUidFromTag(NfcTag tag) {
    final data = tag.data;
    if (data.containsKey('ndef')) {
      final ndef = data['ndef'];
      if (ndef is Map &&
          ndef.containsKey('identifier') &&
          ndef['identifier'] is List) {
        return (ndef['identifier'] as List)
            .map((b) => (b as int).toRadixString(16).padLeft(2, '0'))
            .join(':');
      }
    }

    try {
      if (data.containsKey('mifareclassic')) {
        final mifare = data['mifareclassic'];
        if (mifare is Map &&
            mifare.containsKey('identifier') &&
            mifare['identifier'] is List) {
          return (mifare['identifier'] as List)
              .map((e) => (e as int).toRadixString(16).padLeft(2, '0'))
              .join(':');
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _openEditBlocklist() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IosShieldService.isSupported
            ? const IosShieldPickerScreen()
            : const EditBlocklistScreen(),
      ),
    );
    await _reloadBlocklist(
      refreshIosShield: IosShieldService.isSupported && changed == true,
    );
    if (changed == true && mounted) {
      setState(() {
        _scanStatus = context.l10n.focusBlocklistUpdated;
      });
    }
  }

  bool get _shieldReady => IosShieldService.isSupported
      ? (_iosShield.hasTargets || _blocklist.isNotEmpty)
      : _blocklist.isNotEmpty;

  /// First-time / empty blocklist gate — configure once before kick-off.
  Future<bool> _ensureBlocklistConfigured() async {
    await _reloadBlocklist();
    if (_shieldReady) return true;

    if (!mounted) return false;
    final l10n = context.l10n;
    final goEdit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.focusEditBlocklist),
        content: Text(l10n.focusConfigureBlocklist),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.focusEditBlocklist),
          ),
        ],
      ),
    );

    if (goEdit == true && mounted) {
      await _openEditBlocklist();
    }
    return _shieldReady;
  }

  List<String> _iosShieldNames(AppLocalizations l10n) {
    return [
      if (_iosShield.applicationCount > 0)
        l10n.iosShieldApps(_iosShield.applicationCount),
      if (_iosShield.categoryCount > 0)
        l10n.iosShieldCategories(_iosShield.categoryCount),
      if (_iosShield.webDomainCount > 0)
        l10n.iosShieldSites(_iosShield.webDomainCount),
    ];
  }

  Future<void> _completeAuthentication(String uid) async {
    final ready = await _ensureBlocklistConfigured();
    if (!ready) {
      if (mounted) {
        setState(() {
          _scanStatus = context.l10n.focusConfigureBlocklist;
        });
      }
      return;
    }

    final currentQuadrant = _getCurrentQuadrant();
    final currentIntensity = _getCurrentIntensity();
    final valence = MoodAxes.valenceFromX(_selectedX, gridSize: gridSize);
    final energy = MoodAxes.energyFromY(_selectedY, gridSize: gridSize);

    // Non-blocking checkpoint — matrix persistence must not block the ritual.
    // ignore: unawaited_futures
    _sessions.syncInitialMoodCheckpoint(
      nfcUid: uid,
      quadrant: currentQuadrant.name,
      intensity: currentIntensity,
      x: _selectedX,
      y: _selectedY,
      valence: valence,
      energy: energy,
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FocusSessionScreen(
          nfcUid: uid,
          startQuadrant: currentQuadrant,
          intensity: currentIntensity,
          moodX: _selectedX,
          moodY: _selectedY,
          valence: valence,
          energy: energy,
          blockedPackages: IosShieldService.isSupported
              ? List<String>.from(_iosShield.markerPackages)
              : List<String>.from(_blocklist.packages),
          blockedAppNames: IosShieldService.isSupported
              ? _iosShieldNames(context.l10n)
              : List<String>.from(_blocklist.names),
        ),
      ),
    );
  }

  Future<void> _onBetaQrAuthenticated() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _scanStatus = context.l10n.focusQrAuthenticated;
    });
    try {
      await _completeAuthentication(kTapFocusBetaQrUid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startNfcScanAndSave() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _scanStatus = 'NFC scanner open. Hold your phone to the LoqOut tag…';
    });

    bool isAvailable = false;
    try {
      isAvailable = await NfcManager.instance.isAvailable();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scanStatus = context.l10n.focusNfcCheckFailed('$e');
      });
      return;
    }

    if (!isAvailable) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scanStatus = context.l10n.focusNfcUnavailable;
      });
      return;
    }

    try {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            await NfcManager.instance.stopSession();
          } catch (_) {}

          final uid = _getUidFromTag(tag);
          if (uid == null) {
            if (!mounted) return;
            setState(() {
              _busy = false;
              _scanStatus = 'Could not read NFC tag UID.';
            });
            return;
          }

          await _completeAuthentication(uid);
          if (mounted) setState(() => _busy = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scanStatus = 'NFC session error: $e';
      });
    }
  }

  Widget _buildBlocklistBadge() {
    final c = context.colors;
    final l10n = context.l10n;
    final empty = !_shieldReady;
    final title = IosShieldService.isSupported && _iosShield.hasTargets
        ? l10n.iosShieldSummary(
            _iosShield.applicationCount,
            _iosShield.categoryCount,
            _iosShield.webDomainCount,
          )
        : (empty
            ? l10n.focusNoAppsShielded
            : l10n.focusShieldCount(_blocklist.length));
    final subtitle = empty
        ? l10n.focusConfigureBlocklist
        : (IosShieldService.isSupported
            ? l10n.iosShieldOpenPicker
            : _blocklist.summaryLabels());
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _busy ? null : _openEditBlocklist,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: empty
                  ? c.warning.withValues(alpha: 0.45)
                  : c.accent.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: empty ? c.warningDim : c.accentDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  empty ? Icons.shield_outlined : Icons.shield,
                  color: empty ? c.warning : c.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.focusEditBlocklist,
                onPressed: _busy ? null : _openEditBlocklist,
                icon: Icon(
                  Icons.edit_outlined,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final scanStatus = _scanStatus ?? l10n.focusMoodSelectedHint;
    final currentQuadrant = _getCurrentQuadrant();
    final moodEnglish = MoodAxes.getMoodLabelFromCell(
      _selectedX,
      _selectedY,
      gridSize: gridSize,
    );
    final energyLabel = currentQuadrant == MoodQuadrant.red ||
            currentQuadrant == MoodQuadrant.yellow
        ? l10n.energyHigh
        : l10n.energyLow;
    final valenceLabel = currentQuadrant == MoodQuadrant.yellow ||
            currentQuadrant == MoodQuadrant.green
        ? l10n.valencePleasant
        : l10n.valenceUnpleasant;
    const double meterSize = 300;
    final TextStyle axisLabelStyle = TextStyle(
      fontSize: 12,
      color: c.textMuted,
      fontStyle: FontStyle.italic,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          const LanguageMenuButton(),
          if (widget.onToggleTheme != null)
            IconButton(
              tooltip: widget.themeTooltip ?? l10n.themeSystem,
              onPressed: widget.onToggleTheme,
              icon: Icon(widget.themeIcon ?? Icons.brightness_auto),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.focusHowFeeling,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const ProductMotto(compact: true),
              const SizedBox(height: 10),
              Text(
                l10n.focusAxisGuide,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 15),
              Column(
                children: [
                  Text(l10n.axisHighEnergy, style: axisLabelStyle),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(l10n.axisUnpleasant, style: axisLabelStyle),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: meterSize,
                        height: meterSize,
                        child: GestureDetector(
                          onTapDown: (details) =>
                              _updateSelection(details.localPosition, meterSize),
                          onPanUpdate: (details) =>
                              _updateSelection(details.localPosition, meterSize),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridSize,
                              crossAxisSpacing: 3.0,
                              mainAxisSpacing: 3.0,
                            ),
                            itemCount: gridSize * gridSize,
                            itemBuilder: (context, index) {
                              final x = index % gridSize;
                              final y = index ~/ gridSize;
                              final isHighEnergy = y < 5;
                              final isPleasant = x >= 5;

                              final MoodQuadrant quadrant;
                              if (isHighEnergy) {
                                quadrant = isPleasant
                                    ? MoodQuadrant.yellow
                                    : MoodQuadrant.red;
                              } else {
                                quadrant = isPleasant
                                    ? MoodQuadrant.green
                                    : MoodQuadrant.blue;
                              }

                              final isSelected =
                                  _selectedX == x && _selectedY == y;

                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white
                                      : quadrant.color,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.transparent,
                                    width: isSelected ? 2.5 : 0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RotatedBox(
                        quarterTurns: 1,
                        child: Text(l10n.axisPleasant, style: axisLabelStyle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.axisLowEnergy, style: axisLabelStyle),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: currentQuadrant.color.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentQuadrant.color.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      localizeMoodLabel(l10n, moodEnglish),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: currentQuadrant.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.focusEnergyValencePair(energyLabel, valenceLabel),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildBlocklistBadge(),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _busy ? null : _startNfcScanAndSave,
                icon: const Icon(Icons.nfc),
                label: Text(l10n.focusNfcActivate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentQuadrant.color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              BetaQrAuthButton(
                enabled: !_busy,
                label: l10n.focusScanQrBeta,
                onAuthenticated: _onBetaQrAuthenticated,
              ),
              const SizedBox(height: 30),
              Text(
                scanStatus,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scanStatus.toLowerCase().contains('fail') ||
                          scanStatus.toLowerCase().contains('could not') ||
                          scanStatus.toLowerCase().contains('unavailable') ||
                          scanStatus.toLowerCase().contains('configure')
                      ? c.danger
                      : c.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
