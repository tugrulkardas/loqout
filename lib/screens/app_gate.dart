import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../focus_session_screen.dart';
import '../models/app_models.dart';
import '../models/session_telemetry.dart';
import '../services/ios_shield_service.dart';
import '../services/permission_service.dart';
import '../services/session_repository.dart';
import '../theme/tapfocus_theme.dart';
import '../widgets/product_motto.dart';
import 'home_shell.dart';
import 'permission_onboarding_screen.dart';
import '../l10n/l10n_ext.dart';

/// First-frame-safe bootstrap gate.
///
/// Launches as a lightweight UI shell, waits until the Activity frame is ready,
/// then checks permissions. Never starts background services.
class AppGate extends StatefulWidget {
  const AppGate({
    super.key,
    this.permissionService = const PermissionService(),
  });

  final PermissionService permissionService;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _ready = false;
  bool _permissionsOk = false;
  FocusSessionRecord? _activeSession;

  bool get _requiresAndroidPermissions => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    // Respect Flutter engine lifecycle: no platform permission calls
    // until the first frame has been painted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
  }

  Future<void> _evaluate() async {
    if (!mounted) return;

    var permissionsOk = true;
    if (_requiresAndroidPermissions) {
      try {
        permissionsOk = (await widget.permissionService.checkAll()).allGranted;
      } catch (e, st) {
        debugPrint('AppGate permission evaluation failed: $e\n$st');
        permissionsOk = false;
      }
    }

    FocusSessionRecord? active;
    try {
      final draft = await SessionRepository().loadActiveDraft();
      if (draft != null && draft.endedAt == null) active = draft;
    } catch (e, st) {
      debugPrint('AppGate active session lookup failed: $e\n$st');
    }

    if (active == null && IosShieldService.isSupported) {
      try {
        if (await IosShieldService.instance.isSessionActive()) {
          active = FocusSessionRecord(
            id: 'sess_ios_restore',
            nfcUid: 'ios:restore',
            moodQuadrant: MoodQuadrant.yellow,
            valence: 1,
            energy: 1,
            intensity: 1,
            moodX: 5,
            moodY: 4,
            blockedPackages: const ['ios.familycontrols.applications'],
            blockedAppNames: const [],
            startedAt: DateTime.now(),
          );
        }
      } catch (e, st) {
        debugPrint('AppGate iOS shield lookup failed: $e\n$st');
      }
    }

    if (!mounted) return;
    setState(() {
      _activeSession = active;
      _permissionsOk = permissionsOk;
      _ready = true;
    });
  }

  void _onPermissionsComplete() {
    if (!mounted) return;
    setState(() => _permissionsOk = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      final c = context.colors;
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  context.l10n.gateStarting,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: ProductMotto(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_permissionsOk) {
      return PermissionOnboardingScreen(
        permissionService: widget.permissionService,
        onComplete: _onPermissionsComplete,
      );
    }

    if (_activeSession != null) {
      return FocusSessionScreen.resume(_activeSession!);
    }

    return const HomeShell();
  }
}
