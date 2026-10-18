import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'models/app_models.dart';
import 'models/session_telemetry.dart';
import 'l10n/l10n_ext.dart';
import 'screens/home_shell.dart';
import 'services/background_watchdog.dart';
import 'services/blocklist_service.dart';
import 'services/insights_service.dart';
import 'services/intervention_service.dart';
import 'services/ios_shield_service.dart';
import 'services/launcher_apps_service.dart';
import 'services/permission_service.dart';
import 'services/session_repository.dart';
import 'theme/tapfocus_theme.dart';
import 'widgets/beta_qr_auth_button.dart';
import 'widgets/emergency_override_dialog.dart';
import 'widgets/post_session_mood_prompt.dart';

/// Active focus session surface — no per-session app picker.
///
/// Blocklist comes from [BlocklistService] (persistent Default Blocklist).
/// Kick-off is Mood → NFC on [FocusSetupScreen]; this screen starts the
/// watchdog and handles unlock.
class FocusSessionScreen extends StatefulWidget {
  final String nfcUid;
  final MoodQuadrant startQuadrant;
  final int intensity;
  final int moodX;
  final int moodY;
  final int valence;
  final int energy;

  /// Packages from the persistent Default Blocklist at kick-off time.
  final List<String> blockedPackages;
  final List<String> blockedAppNames;

  /// True when reopening a session that is already enforced.
  /// Skips a second kickoff so the lock screen is shown immediately.
  final bool resumeActiveSession;

  /// Draft captured at process start. Null for a freshly authenticated session.
  final FocusSessionRecord? resumedRecord;

  const FocusSessionScreen({
    super.key,
    required this.nfcUid,
    required this.startQuadrant,
    required this.intensity,
    required this.moodX,
    required this.moodY,
    required this.valence,
    required this.energy,
    required this.blockedPackages,
    required this.blockedAppNames,
    this.resumeActiveSession = false,
    this.resumedRecord,
  });

  factory FocusSessionScreen.resume(FocusSessionRecord record) {
    return FocusSessionScreen(
      nfcUid: record.nfcUid,
      startQuadrant: record.moodQuadrant,
      intensity: record.intensity,
      moodX: record.moodX,
      moodY: record.moodY,
      valence: record.valence,
      energy: record.energy,
      blockedPackages: List<String>.from(record.blockedPackages),
      blockedAppNames: List<String>.from(record.blockedAppNames),
      resumeActiveSession: true,
      resumedRecord: record,
    );
  }

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  final PermissionService _permissions = const PermissionService();
  final SessionRepository _sessions = SessionRepository();
  final BlocklistService _blocklist = BlocklistService();

  bool isSessionActive = false;
  bool _startingSession = false;
  bool _unlocking = false;

  StreamSubscription<Map<String, dynamic>?>? _violationSub;
  String? _lastViolationPackage;
  int _interventionCount = 0;
  FocusSessionRecord? _activeRecord;
  DateTime? _sessionStartedAt;

  late List<String> _blockedPackages;
  late List<String> _blockedAppNames;

  @override
  void initState() {
    super.initState();
    _blockedPackages = List<String>.from(widget.blockedPackages);
    _blockedAppNames = List<String>.from(widget.blockedAppNames);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForViolations();
      if (widget.resumeActiveSession) {
        _resumeLockedSession();
      } else {
        _startFocusSession();
      }
    });
  }

  @override
  void dispose() {
    _violationSub?.cancel();
    super.dispose();
  }

  void _listenForViolations() {
    // flutter_background_service is Android/iOS only.
    if (useDesktopMockLauncherApps) return;

    final service = FlutterBackgroundService();
    _violationSub = service.on('violation').listen((event) async {
      if (!isSessionActive) return;
      final pkg = event?['package'] as String?;
      final count = await _sessions.readInterventionCount();
      if (mounted) {
        setState(() {
          if (pkg != null && pkg.isNotEmpty) _lastViolationPackage = pkg;
          _interventionCount = count;
        });
      }
      await InterventionService.bringToForeground(blockedPackage: pkg);
    });
  }

  Future<bool> _ensureOverlayPermission() async {
    final guard = await checkOverlayGuard();
    if (guard.canDrawOverlays) return true;

    final granted = await _permissions.hasSystemAlertWindowPermission();
    if (granted) return true;

    if (mounted) _showOverlayPermissionDialog();
    return false;
  }

  Future<bool> _ensureNotificationPermission() async {
    final granted = await _permissions.hasNotificationPermission();
    if (granted) return true;

    final requested = await _permissions.requestNotificationPermission();
    if (requested) return true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification permission is required for the focus watchdog.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return false;
  }

  void _showOverlayPermissionDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Overlay Permission Required'),
        content: const Text(
          "To bring LoqOut forward when a blocked app opens, allow "
          "'Display over other apps'.\n\n"
          "On Xiaomi / HyperOS also enable "
          "'Display pop-up windows while running in the background' "
          "for LoqOut in App settings → Other permissions.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _permissions.requestSystemAlertWindowPermission();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Family Controls shield. Called only after the user reached this screen
  /// via NFC or QR. Does not start at app launch.
  Future<bool> _armIosShield() async {
    final summary = await IosShieldService.instance.summary();
    if (!summary.hasTargets) {
      if (!mounted) return false;
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.iosShieldSelectOne)),
      );
      Navigator.of(context).pop();
      return false;
    }

    if (!mounted) return false;
    final l10n = context.l10n;
    try {
      final armed = await IosShieldService.instance.startShield();
      if (!mounted) return false;
      _blockedPackages = List<String>.from(armed.markerPackages);
      _blockedAppNames = [
        if (armed.applicationCount > 0) l10n.iosShieldApps(armed.applicationCount),
        if (armed.categoryCount > 0)
          l10n.iosShieldCategories(armed.categoryCount),
        if (armed.webDomainCount > 0) l10n.iosShieldSites(armed.webDomainCount),
      ];
      return true;
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.sessionStartFailed(e.message ?? e.code)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Restores the lock screen after the UI process was recreated mid-session.
  Future<void> _resumeLockedSession() async {
    if (_startingSession || isSessionActive) return;
    setState(() => _startingSession = true);
    try {
      final draft = await _sessions.loadActiveDraft();
      final record = (draft != null && draft.endedAt == null)
          ? draft
          : widget.resumedRecord;
      if (record == null) {
        if (mounted) setState(() => _startingSession = false);
        return;
      }

      if (record.blockedPackages.isNotEmpty) {
        _blockedPackages = List<String>.from(record.blockedPackages);
        _blockedAppNames = List<String>.from(record.blockedAppNames);
      }

      if (IosShieldService.isSupported) {
        await IosShieldService.instance.restoreShield();
      } else if (!useDesktopMockLauncherApps) {
        final running = await FlutterBackgroundService().isRunning();
        if (!running) {
          final started = await startWatchdogService(
            blockedApps: _blockedPackages,
            resetInterventionCount: false,
          );
          if (!started) {
            debugPrint('Could not reattach focus watchdog while resuming');
          }
        }
      }

      final count = await _sessions.readInterventionCount();
      if (!mounted) return;
      setState(() {
        isSessionActive = true;
        _startingSession = false;
        _activeRecord = record;
        _sessionStartedAt = record.startedAt;
        _interventionCount = count;
      });
    } catch (e) {
      debugPrint('Resume locked session failed: $e');
      if (mounted) setState(() => _startingSession = false);
    }
  }

  /// Explicit user-initiated start — loads Default Blocklist if needed.
  Future<void> _startFocusSession() async {
    if (_startingSession || isSessionActive) return;
    setState(() => _startingSession = true);

    try {
      if (IosShieldService.isSupported) {
        final ready = await _armIosShield();
        if (!ready) return;
      } else {
        if (_blockedPackages.isEmpty) {
          final stored = await _blocklist.load();
          _blockedPackages = List<String>.from(stored.packages);
          _blockedAppNames = List<String>.from(stored.names);
        }

        if (_blockedPackages.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your Default Blocklist is empty. Edit it on the Focus screen.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pop();
          }
          return;
        }

        final snapshot = await _permissions.checkAll();
        if (!snapshot.usageStats) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usage Access is required before locking.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final hasOverlay = await _ensureOverlayPermission();
        if (!hasOverlay) return;

        final hasNotifications = await _ensureNotificationPermission();
        if (!hasNotifications) return;

        await ensureWatchdogNotificationChannel();

        var started = false;
        if (useDesktopMockLauncherApps) {
          // Desktop / web: UI-only session so PO can test Emergency Unlock.
          started = true;
          debugPrint('Desktop mock session — skipping Android watchdog start');
        } else {
          started =
              await startWatchdogService(blockedApps: _blockedPackages);
        }

        if (!started) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Could not start the focus watchdog. '
                  'Check notification permission and try again.',
                ),
                backgroundColor: TapFocusColors.of(context).danger,
              ),
            );
          }
          return;
        }
      }

      final startedAt = DateTime.now();
      final record = FocusSessionRecord(
        id: 'sess_${startedAt.millisecondsSinceEpoch}',
        nfcUid: widget.nfcUid,
        moodQuadrant: widget.startQuadrant,
        valence: widget.valence,
        energy: widget.energy,
        intensity: widget.intensity,
        moodX: widget.moodX,
        moodY: widget.moodY,
        blockedPackages: List<String>.from(_blockedPackages),
        blockedAppNames: List<String>.from(_blockedAppNames),
        startedAt: startedAt,
        interventionCount: 0,
      );
      await _sessions.resetInterventionCount();
      await _sessions.saveActiveDraft(record);

      if (!mounted) return;
      setState(() {
        isSessionActive = true;
        _lastViolationPackage = null;
        _interventionCount = 0;
        _activeRecord = record;
        _sessionStartedAt = startedAt;
      });
    } catch (e) {
      debugPrint('Start focus session failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.sessionStartFailed('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _startingSession = false);
    }
  }

  String _authChannelLabel(AppLocalizations l10n, String uid) {
    if (uid.startsWith('qr:')) return l10n.sessionAuthBetaQr;
    if (uid.startsWith('mock:')) return l10n.sessionAuthMockNfc;
    return l10n.sessionAuthNfc;
  }

  Future<void> _unlockSession({bool viaEmergencyOverride = false}) async {
    if (_unlocking || !isSessionActive) return;
    setState(() => _unlocking = true);
    try {
      final interventions = await _sessions.readInterventionCount();
      final endedAt = DateTime.now();
      final startedAt = _sessionStartedAt ?? endedAt;
      final durationMinutes = (() {
        final seconds = endedAt.difference(startedAt).inSeconds;
        if (seconds <= 0) return 0;
        return (seconds / 60).ceil().clamp(1, 24 * 60);
      })();

      MoodSelection? postMood;
      if (mounted) {
        postMood = await PostSessionMoodPrompt.show(context);
      }

      final record = _activeRecord ??
          FocusSessionRecord(
            id: 'sess_${startedAt.millisecondsSinceEpoch}',
            nfcUid: widget.nfcUid,
            moodQuadrant: widget.startQuadrant,
            valence: widget.valence,
            energy: widget.energy,
            intensity: widget.intensity,
            moodX: widget.moodX,
            moodY: widget.moodY,
            blockedPackages: List<String>.from(_blockedPackages),
            blockedAppNames: List<String>.from(_blockedAppNames),
            startedAt: startedAt,
          );

      record.interventionCount = interventions;
      record.endedAt = endedAt;
      record.durationMinutes = durationMinutes;
      record.completionStatus = viaEmergencyOverride
          ? SessionCompletionStatus.earlyExit
          : (durationMinutes < 2
              ? SessionCompletionStatus.earlyExit
              : SessionCompletionStatus.completed);

      if (postMood != null) {
        record.postMoodQuadrant = postMood.quadrant;
        record.postValence = postMood.valence;
        record.postEnergy = postMood.energy;
        record.postIntensity = postMood.intensity;
      }

      if (IosShieldService.isSupported) {
        await IosShieldService.instance.stopShield();
      }
      await stopWatchdogService();
      await _sessions.upsert(record);
      await _sessions.clearActiveDraft();
      InsightsService().invalidate();

      if (!mounted) return;
      setState(() => isSessionActive = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unlock failed: $e'),
            backgroundColor: TapFocusColors.of(context).danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  Future<void> _onEmergencyUnlockPressed() async {
    if (_unlocking || !isSessionActive) return;
    final burned = await showEmergencyOverrideDialog(context);
    if (!burned || !mounted) return;
    await _unlockSession(viaEmergencyOverride: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final moodEnglish =
        MoodAxes.getMoodLabel(widget.valence, widget.energy);
    final moodLabel = localizeMoodLabel(l10n, moodEnglish);
    final uidPreview = widget.nfcUid.length >= 12
        ? widget.nfcUid.substring(0, 12)
        : widget.nfcUid;

    return Scaffold(
      backgroundColor: c.voidBlack,
      appBar: AppBar(
        title: Text(isSessionActive ? l10n.focusTitle : l10n.sessionActivating),
        backgroundColor: c.voidBlack,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: !isSessionActive && !_startingSession,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSessionActive
                          ? l10n.sessionLocked
                          : l10n.sessionActivating,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: c.accent,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.sessionMoodLine(moodLabel, widget.intensity),
                      style: TextStyle(
                        fontSize: 15,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.sessionAuthLine(
                        _authChannelLabel(l10n, widget.nfcUid),
                        uidPreview,
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.sessionShieldingApps(_blockedPackages.length)}'
                      '${_blockedAppNames.isNotEmpty ? ': ${_blockedAppNames.take(3).join(', ')}${_blockedAppNames.length > 3 ? '…' : ''}' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textSecondary,
                      ),
                    ),
                    if (isSessionActive && _lastViolationPackage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.sessionBlockedAttempt(_lastViolationPackage!),
                        style: TextStyle(
                          fontSize: 13,
                          color: c.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (_startingSession) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Text(
                  l10n.sessionStartingWatchdog,
                  textAlign: TextAlign.center,
                ),
              ] else if (!isSessionActive) ...[
                Text(
                  l10n.sessionActivateFailed,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _startFocusSession,
                  icon: const Icon(Icons.lock),
                  label: Text(l10n.sessionRetryActivate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accentDeep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                ),
              ] else ...[
                Icon(Icons.lock, size: 64, color: c.textSecondary),
                const SizedBox(height: 12),
                Text(
                  _interventionCount > 0
                      ? '${l10n.sessionAppsLocked(_blockedPackages.length)}'
                          ' · $_interventionCount'
                      : l10n.sessionAppsLocked(_blockedPackages.length),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.sessionUnlockHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary),
                ),
                const SizedBox(height: 28),
                BetaQrAuthButton(
                  enabled: !_unlocking,
                  label: l10n.sessionScanQrUnlock,
                  filled: true,
                  onAuthenticated: () => _unlockSession(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _unlocking ? null : _onEmergencyUnlockPressed,
                  icon: const Icon(Icons.local_fire_department),
                  label: Text(l10n.sessionEmergencyUnlock),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.danger.withValues(alpha: 0.18),
                    foregroundColor: c.warning,
                    disabledBackgroundColor: c.danger.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: c.danger.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                if (_unlocking) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
