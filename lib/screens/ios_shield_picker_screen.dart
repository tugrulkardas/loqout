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

class _IosShieldPickerScreenState extends State<IosShieldPickerScreen> {
  final IosShieldService _shield = IosShieldService.instance;
  final BlocklistService _blocklist = BlocklistService();

  IosShieldSelection _selection = const IosShieldSelection();
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final selection = await _shield.summary();
      if (!mounted) return;
      setState(() => _selection = selection);
    } on PlatformException catch (e) {
      _showError(e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _authorize() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final selection = await _shield.requestAuthorization();
      if (!mounted) return;
      setState(() => _selection = selection);
    } on PlatformException catch (e) {
      _showError(e.message ?? e.code);
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
      _showError(e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final denied = _selection.authorizationStatus == 'denied';
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _selection.hasTargets
                          ? l10n.iosShieldSummary(
                              _selection.applicationCount,
                              _selection.categoryCount,
                              _selection.webDomainCount,
                            )
                          : l10n.focusNoAppsShielded,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (!_selection.isApproved) ...[
                  FilledButton(
                    onPressed: _busy ? null : _authorize,
                    child: Text(l10n.iosShieldAuthorize),
                  ),
                  const SizedBox(height: 12),
                ],
                if (denied) ...[
                  Text(
                    l10n.iosShieldDenied,
                    style: TextStyle(color: c.warning, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: openAppSettings,
                    child: Text(l10n.iosShieldOpenSettings),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: _busy || !_selection.isApproved ? null : _pick,
                  child: Text(l10n.iosShieldOpenPicker),
                ),
              ],
            ),
    );
  }
}
