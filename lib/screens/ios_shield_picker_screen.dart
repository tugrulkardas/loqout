import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/l10n_ext.dart';
import '../services/blocklist_service.dart';
import '../services/ios_shield_service.dart';
import '../theme/tapfocus_theme.dart';

/// iOS Default Blocklist. Selection happens in [FamilyActivityPicker];
/// LoqOut only stores the opaque token counts Apple returns.
class IosShieldPickerScreen extends StatefulWidget {
  const IosShieldPickerScreen({super.key});

  @override
  State<IosShieldPickerScreen> createState() => _IosShieldPickerScreenState();
}

class _IosShieldPickerScreenState extends State<IosShieldPickerScreen>
    with WidgetsBindingObserver {
  final IosShieldService _shield = IosShieldService.instance;
  final BlocklistService _blocklist = BlocklistService();

  IosShieldSelection _selection = const IosShieldSelection();
  String _passcode = 'unknown';
  String? _failureCode;
  String? _recordedFailure;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  IosLockAvailability get _availability => iosLockAvailability(
        passcode: _passcode,
        authorizationStatus: _selection.authorizationStatus,
        failureCode: _failureCode,
      );

  Future<void> _refresh({bool userInitiated = false}) async {
    try {
      final passcode = await _shield.devicePasscodeStatus();
      if (!mounted) return;
      if (passcode == 'missing') {
        setState(() {
          _passcode = passcode;
          _failureCode = 'passcodeRequired';
          _selection = const IosShieldSelection();
        });
        await _recordFailure(userInitiated: userInitiated);
        return;
      }
      final selection = await _shield.summary();
      if (!mounted) return;
      setState(() {
        _passcode = passcode;
        _selection = selection;
        _failureCode = selection.authorizationStatus == 'denied' ? 'denied' : null;
      });
      await _recordFailure(userInitiated: userInitiated);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _failureCode = e.code);
      await _recordFailure(userInitiated: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recordFailure({required bool userInitiated}) async {
    final code = iosLockFailureCode(_availability);
    if (code == null) {
      _recordedFailure = null;
      return;
    }
    if (!userInitiated && _recordedFailure == code) return;
    _recordedFailure = code;
    await _shield.noteAuthFailure(code);
  }

  Future<void> _authorize() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final selection = await _shield.requestAuthorization();
      if (!mounted) return;
      setState(() {
        _selection = selection;
        _failureCode = selection.isApproved
            ? null
            : (selection.authorizationStatus == 'denied' ? 'denied' : null);
        _passcode = 'available';
      });
      await _recordFailure(userInitiated: true);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _failureCode = e.code);
      await _recordFailure(userInitiated: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final selection = await _shield.presentActivityPicker();
      if (!mounted) return;
      setState(() => _selection = selection);
      if (selection.cancelled || !selection.hasTargets) {
        if (!selection.cancelled && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.iosShieldSelectOne)),
          );
        }
        return;
      }
      final l10n = context.l10n;
      await _blocklist.save(
        packages: selection.markerPackages,
        names: [
          if (selection.applicationCount > 0)
            l10n.iosShieldApps(selection.applicationCount),
          if (selection.categoryCount > 0)
            l10n.iosShieldCategories(selection.categoryCount),
          if (selection.webDomainCount > 0)
            l10n.iosShieldSites(selection.webDomainCount),
        ],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.iosShieldSaved)),
      );
      Navigator.of(context).pop(true);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _failureCode = e.code);
      await _recordFailure(userInitiated: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final availability = _availability;
    final blocked = availability != IosLockAvailability.ready &&
        availability != IosLockAvailability.needsAuthorization;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.iosShieldTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(
                  l10n.iosShieldBody,
                  style: TextStyle(color: c.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 20),
                if (availability == IosLockAvailability.ready &&
                    _selection.hasTargets)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.iosShieldSummary(
                          _selection.applicationCount,
                          _selection.categoryCount,
                          _selection.webDomainCount,
                        ),
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (blocked) ...[
                  Text(
                    availability == IosLockAvailability.passcodeRequired
                        ? l10n.iosShieldPasscodeTitle
                        : l10n.iosShieldNeedApprovalTitle,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    iosLockMessage(l10n, availability),
                    style: TextStyle(color: c.warning, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  if (availability == IosLockAvailability.passcodeRequired ||
                      availability == IosLockAvailability.denied)
                    OutlinedButton(
                      onPressed: openAppSettings,
                      child: Text(l10n.iosShieldOpenSettings),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : () => _refresh(userInitiated: true),
                    child: Text(l10n.iosShieldTryAgain),
                  ),
                ],
                if (availability == IosLockAvailability.needsAuthorization) ...[
                  FilledButton(
                    onPressed: _busy ? null : _authorize,
                    child: Text(l10n.iosShieldAuthorize),
                  ),
                ],
                if (availability == IosLockAvailability.ready) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _pick,
                    child: Text(l10n.iosShieldOpenPicker),
                  ),
                ],
              ],
            ),
    );
  }
}
