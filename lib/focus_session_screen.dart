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
import 'services/focus_stats.dart';
import 'services/insights_service.dart';
import 'services/intervention_service.dart';
import 'services/ios_shield_service.dart';
import 'services/launcher_apps_service.dart';
import 'services/permission_service.dart';
import 'services/session_repository.dart';
import 'theme/tapfocus_theme.dart';
import 'widgets/beta_qr_auth_button.dart';
import 'widgets/emergency_override_dialog.dart';
import 'widgets/focus_week_strip.dart';
import 'widgets/hold_to_unlock_button.dart';
import 'widgets/streak_progress_ring.dart';
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
  FocusSessionRecord? _activeRecord;
  DateTime? _sessionStartedAt;
  Timer? _clock;
  FocusStats _stats = const FocusStats.empty();
  Map<String, Uint8List> _lockedIcons = const {};
  String? _insight;
  int? _shieldedApps;
  int? _shieldedCategories;
  int? _shieldedSites;

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
    _clock?.cancel();
    _violationSub?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clock ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && isSessionActive) setState(() {});
    });
  }

  Future<void> _loadLockedContext() async {
    try {
      final sessions = await _sessions.loadAll();
      final stats = FocusStats.fromSessions(sessions);
      final insights = await InsightsService().load();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _insight = _insightLine(insights);
      });
    } catch (e, st) {
      debugPrint('Locked screen stats failed: $e\n$st');
    }
    await _loadAndroidIcons();
  }

  Future<void> _loadAndroidIcons() async {
    if (useDesktopMockLauncherApps || _blockedPackages.isEmpty) return;
    try {
      final apps = await LauncherAppsService().loadLaunchableApps();
      final wanted = _blockedPackages.toSet();
      final icons = <String, Uint8List>{};
      for (final app in apps) {
        final icon = app.icon;
        if (icon == null || !wanted.contains(app.packageName)) continue;
        icons[app.packageName] = icon;
      }
      if (mounted) setState(() => _lockedIcons = icons);
    } catch (e, st) {
      debugPrint('Locked app icons unavailable: $e\n$st');
    }
  }

  String _insightLine(InsightsSnapshot snapshot) {
    final l10n = context.l10n;
    switch (snapshot.moodShiftStory) {
      case MoodShiftStory.improves:
        return l10n.insightsMoodImproves;
      case MoodShiftStory.steadies:
        return l10n.insightsMoodSteadies;
      case MoodShiftStory.declines:
        return l10n.insightsMoodDeclines;
      case null:
        return l10n.lockInsightEmpty;
    }
  }

  void _listenForViolations() {
    // flutter_background_service is Android/iOS only.
    if (useDesktopMockLauncherApps) return;

    final service = FlutterBackgroundService();
    _violationSub = service.on('violation').listen((event) async {
      if (!isSessionActive) return;
      final pkg = event?['package'] as String?;
      if (mounted) {
        setState(() {
          if (pkg != null && pkg.isNotEmpty) _lastViolationPackage = pkg;
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
      _shieldedApps = armed.applicationCount;
      _shieldedCategories = armed.categoryCount;
      _shieldedSites = armed.webDomainCount;
      return true;
    } on PlatformException catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(iosAuthErrorMessage(l10n, e.code)),
            backgroundColor: Colors.red,
          ),
        );
        await IosShieldService.instance.noteAuthFailure(e.code);
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
      _shieldedApps = record.shieldedApplicationCount;
      _shieldedCategories = record.shieldedCategoryCount;
      _shieldedSites = record.shieldedWebDomainCount;

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

      if (!mounted) return;
      setState(() {
        isSessionActive = true;
        _startingSession = false;
        _activeRecord = record;
        _sessionStartedAt = record.startedAt;
      });
      _startClock();
      await _loadLockedContext();
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
        shieldedApplicationCount: _shieldedApps,
        shieldedCategoryCount: _shieldedCategories,
        shieldedWebDomainCount: _shieldedSites,
      );
      await _sessions.resetInterventionCount();
      await _sessions.saveActiveDraft(record);

      if (!mounted) return;
      setState(() {
        isSessionActive = true;
        _lastViolationPackage = null;
        _activeRecord = record;
        _sessionStartedAt = startedAt;
      });
      _startClock();
      await _loadLockedContext();
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
      record.localEndDate = focusLocalDateKey(endedAt);
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

  String _lockedSummary(AppLocalizations l10n) {
    if (_shieldedApps != null ||
        _shieldedCategories != null ||
        _shieldedSites != null) {
      final parts = <String>[
        if ((_shieldedApps ?? 0) > 0) l10n.sessionAppsLocked(_shieldedApps!),
        if ((_shieldedCategories ?? 0) > 0)
          l10n.sessionCategoriesLocked(_shieldedCategories!),
        if ((_shieldedSites ?? 0) > 0)
          l10n.sessionWebsitesLocked(_shieldedSites!),
      ];
      if (parts.isEmpty) return l10n.focusNoAppsShielded;
      return parts.join(' · ');
    }
    return l10n.sessionAppsLocked(_blockedPackages.length);
  }

  int _previewDurationMinutes() {
    final start = _sessionStartedAt;
    if (start == null) return 0;
    final seconds = DateTime.now().difference(start).inSeconds;
    if (seconds <= 0) return 0;
    return (seconds / 60).ceil().clamp(1, 24 * 60);
  }

  String _streakLine(AppLocalizations l10n) {
    final effect = _streakEffect();
    switch (effect) {
      case StreakEndEffect.keepsToday:
        return l10n.lockStreakKeeps;
      case StreakEndEffect.alreadyCounted:
        return l10n.lockStreakAlready;
      case StreakEndEffect.doesNotCountToday:
        return l10n.lockStreakMiss;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    if (isSessionActive) return _lockedScaffold(c, l10n);
    return _activatingScaffold(c, l10n);
  }

  Widget _activatingScaffold(TapFocusColors c, AppLocalizations l10n) {
    final moodEnglish = MoodAxes.getMoodLabel(widget.valence, widget.energy);
    final moodLabel = localizeMoodLabel(l10n, moodEnglish);
    final uidPreview = widget.nfcUid.length >= 12
        ? widget.nfcUid.substring(0, 12)
        : widget.nfcUid;
    return Scaffold(
      backgroundColor: c.voidBlack,
      appBar: AppBar(
        title: Text(l10n.sessionActivating),
        backgroundColor: c.voidBlack,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: !_startingSession,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.sessionMoodLine(moodLabel, widget.intensity),
              style: TextStyle(fontSize: 15, color: c.textPrimary),
            ),
            Text(
              l10n.sessionAuthLine(
                _authChannelLabel(l10n, widget.nfcUid),
                uidPreview,
              ),
              style: TextStyle(fontSize: 15, color: c.textSecondary),
            ),
            const SizedBox(height: 24),
            if (_startingSession) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(l10n.sessionStartingWatchdog, textAlign: TextAlign.center),
            ] else ...[
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
            ],
          ],
        ),
      ),
    );
  }

  StreakRingState _ringState() {
    final start = _sessionStartedAt;
    final elapsedMinutes = start == null
        ? 0.0
        : DateTime.now().difference(start).inSeconds / 60.0;
    return streakRingState(
      todayCompletedMinutes: _stats.todayCompletedMinutes,
      elapsedMinutes: elapsedMinutes < 0 ? 0 : elapsedMinutes,
    );
  }

  Widget _lockedScaffold(TapFocusColors c, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final moodEnglish = MoodAxes.getMoodLabel(widget.valence, widget.energy);
    final moodLabel = localizeMoodLabel(l10n, moodEnglish);
    final elapsed = _sessionStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(_sessionStartedAt!);
    final ring = _ringState();
    final caption = ring.reached
        ? l10n.lockTodayOnStreak
        : l10n.lockMinutesToStreak(ring.minutesRemaining);
    final atRisk = _streakEffect() == StreakEndEffect.doesNotCountToday &&
        _stats.streakDays > 0;
    return Scaffold(
      backgroundColor: c.voidBlack,
      appBar: AppBar(
        title: Text(l10n.focusTitle),
        backgroundColor: c.voidBlack,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final short = constraints.maxHeight < 560;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, short ? 4 : 8, 24, 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StreakProgressRing(
                      progress: ring.fraction,
                      timeLabel: formatFocusClock(elapsed),
                      caption: caption,
                      semanticsLabel: '${l10n.lockThisSession}. '
                          '${formatFocusClock(elapsed)}. $caption',
                      diameter: short ? 132 : 164,
                      reached: ring.reached,
                    ),
                    _weekReadout(c, l10n, theme),
                    _moodCard(c, l10n, theme, moodLabel),
                    _lockedTargets(c, l10n, theme),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _streakNotice(c, l10n, theme, atRisk),
                        const SizedBox(height: 8),
                        HoldToUnlockButton(
                          label: l10n.lockHoldToUnlock,
                          semanticsHint: l10n.lockHoldSemanticsHint,
                          accessibleLabel: l10n.lockUnlockAction,
                          enabled: !_unlocking,
                          onUnlocked: _unlockSession,
                        ),
                        BetaQrAuthButton(
                          enabled: !_unlocking,
                          label: l10n.sessionScanQrUnlock,
                          quiet: true,
                          onAuthenticated: () => _unlockSession(),
                        ),
                        TextButton.icon(
                          onPressed:
                              _unlocking ? null : _onEmergencyUnlockPressed,
                          icon: Icon(
                            Icons.local_fire_department_outlined,
                            size: 18,
                            color: c.textMuted,
                          ),
                          label: Text(l10n.sessionEmergencyUnlock),
                          style: TextButton.styleFrom(
                            foregroundColor: c.textSecondary,
                            visualDensity: VisualDensity.compact,
                            textStyle: theme.textTheme.bodyMedium,
                          ),
                        ),
                        if (_unlocking)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  StreakEndEffect _streakEffect() {
    final elapsed = _previewDurationMinutes();
    return streakEffectOfEnding(
      elapsedMinutes: elapsed,
      todayCompletedMinutes: _stats.todayCompletedMinutes,
      countsAsCompleted: elapsed >= 2,
    );
  }

  Widget _weekReadout(TapFocusColors c, AppLocalizations l10n, ThemeData theme) {
    final fresh = _stats.isFreshRecord;
    final todayIndex = DateTime.now().weekday - DateTime.monday;
    final column = Column(
      children: [
        Semantics(
          label: fresh
              ? l10n.lockStartToday
              : l10n.lockFocusTimeWeek(_stats.weekFocusMinutes),
          child: ExcludeSemantics(
            child: FocusWeekStrip(
              completed: _stats.weekCompleted,
              todayIndex: todayIndex,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (fresh)
          ExcludeSemantics(
            child: Text(
              l10n.lockStartToday,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else ...[
          if (_stats.streakDays > 0)
            Text(
              l10n.lockStreakDays(_stats.streakDays),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            l10n.lockFocusTimeToday(_stats.todayFocusMinutes),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
        ],
      ],
    );
    return column;
  }

  Widget _moodCard(
    TapFocusColors c,
    AppLocalizations l10n,
    ThemeData theme,
    String moodLabel,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        boxShadow: c.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.circle,
                size: 10,
                color: widget.startQuadrant.color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sessionMoodLine(moodLabel, widget.intensity),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _insight ?? l10n.lockInsightEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: c.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockedTargets(TapFocusColors c, AppLocalizations l10n, ThemeData theme) {
    final icons = <Widget>[];
    if (!useDesktopMockLauncherApps) {
      for (final package in _blockedPackages) {
        final bytes = _lockedIcons[package];
        if (bytes == null) continue;
        icons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.memory(
                bytes,
                width: 26,
                height: 26,
                gaplessPlayback: true,
              ),
            ),
          ),
        );
        if (icons.length == 5) break;
      }
    }
    return Column(
      children: [
        if (icons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: icons,
              ),
            ),
          ),
        Text(
          _lockedSummary(l10n),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        ),
        if (_lastViolationPackage != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.sessionBlockedAttempt(_lastViolationPackage!),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: c.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _streakNotice(
    TapFocusColors c,
    AppLocalizations l10n,
    ThemeData theme,
    bool atRisk,
  ) {
    final text = Text(
      _streakLine(l10n),
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: atRisk ? c.warningDeep : c.textMuted,
        fontWeight: atRisk ? FontWeight.w700 : FontWeight.w500,
        height: 1.3,
      ),
    );
    if (!atRisk) return text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.warningDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: text,
      ),
    );
  }
}
