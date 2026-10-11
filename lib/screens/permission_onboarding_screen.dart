import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../services/permission_service.dart';
import '../theme/tapfocus_theme.dart';

/// Structured permission onboarding. Never crashes on missing grants —
/// keeps the user in a controlled UI until required OS permissions are set.
class PermissionOnboardingScreen extends StatefulWidget {
  const PermissionOnboardingScreen({
    super.key,
    required this.onComplete,
    this.permissionService = const PermissionService(),
  });

  final VoidCallback onComplete;
  final PermissionService permissionService;

  @override
  State<PermissionOnboardingScreen> createState() =>
      _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen>
    with WidgetsBindingObserver {
  PermissionSnapshot? _snapshot;
  bool _checking = true;

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

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _checking = true);

    final snapshot = await widget.permissionService.checkAll();
    if (!mounted) return;

    setState(() {
      _snapshot = snapshot;
      _checking = false;
    });

    if (snapshot.allGranted) {
      widget.onComplete();
    }
  }

  Future<void> _request(TapFocusPermission permission) async {
    await widget.permissionService.request(permission);
    // Settings-based permissions (usage / overlay) resolve after resume;
    // still refresh immediately for dialog-based grants (notifications).
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    final l10n = context.l10n;
    final snapshot = _snapshot;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                l10n.appTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.permissionsBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: c.textSecondary,
                    ),
              ),
              const SizedBox(height: 28),
              if (_checking || snapshot == null)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      for (final permission in TapFocusPermission.values)
                        _PermissionTile(
                          permission: permission,
                          granted: _isGranted(snapshot, permission),
                          onGrant: () => _request(permission),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _refresh,
                child: Text(l10n.permissionsGrantedRecheck),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await widget.permissionService.openAppSettingsFallback();
                },
                child: Text(l10n.openAppSettings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isGranted(PermissionSnapshot snapshot, TapFocusPermission permission) {
    switch (permission) {
      case TapFocusPermission.usageStats:
        return snapshot.usageStats;
      case TapFocusPermission.systemAlertWindow:
        return snapshot.systemAlertWindow;
      case TapFocusPermission.notifications:
        return snapshot.notifications;
    }
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.permission,
    required this.granted,
    required this.onGrant,
  });

  final TapFocusPermission permission;
  final bool granted;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = granted ? c.accent : c.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: granted ? c.accentDim : c.warningDim,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    granted ? Icons.check_circle : Icons.lock_outline,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      permission.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                  ),
                  Text(
                    granted ? 'Granted' : 'Required',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                permission.rationale,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: c.textSecondary,
                ),
              ),
              if (!granted) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onGrant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(context.l10n.permissionsGrant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
