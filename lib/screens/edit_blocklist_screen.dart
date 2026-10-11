import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../models/app_models.dart';
import '../services/blocklist_service.dart';
import '../services/permission_service.dart';
import '../services/ranked_apps_service.dart';
import '../theme/tapfocus_theme.dart';

/// Dedicated editor for the persistent Default Blocklist.
///
/// Updates are written immediately on Save so the next session kick-off
/// (and the watchdog) use the new list — no per-session re-selection.
class EditBlocklistScreen extends StatefulWidget {
  const EditBlocklistScreen({super.key});

  @override
  State<EditBlocklistScreen> createState() => _EditBlocklistScreenState();
}

class _EditBlocklistScreenState extends State<EditBlocklistScreen> {
  final BlocklistService _blocklist = BlocklistService();
  final PermissionService _permissions = const PermissionService();
  late final RankedAppsService _rankedApps = RankedAppsService(
    permissions: _permissions,
  );

  bool _loading = true;
  bool _saving = false;
  bool _usageGranted = false;
  bool _showUnused = false;

  List<AppInfo> _usedApps = [];
  List<AppInfo> _unusedApps = [];
  final Set<String> _selected = {};
  final Map<String, String> _labels = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    final existing = await _blocklist.load();
    _selected
      ..clear()
      ..addAll(existing.packages);
    for (var i = 0; i < existing.packages.length; i++) {
      _labels[existing.packages[i]] = existing.names[i];
    }

    final usage = await _permissions.hasUsageStatsPermission();
    if (!usage) {
      if (mounted) {
        setState(() {
          _usageGranted = false;
          _loading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _usageGranted = true);
    await _loadApps();
  }

  Future<void> _loadApps({bool forceRefresh = false}) async {
    try {
      final ranked =
          await _rankedApps.loadRankedApps(forceRefresh: forceRefresh);
      for (final app in ranked.all) {
        _labels.putIfAbsent(app.packageName, () => app.appName);
      }
      if (!mounted) return;
      setState(() {
        _usedApps = ranked.usedApps;
        _unusedApps = ranked.unusedApps;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.blocklistLoadFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.blocklistSelectOne),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final packages = _selected.toList(growable: false);
      final names = packages.map((p) => _labels[p] ?? p).toList();
      await _blocklist.save(packages: packages, names: names);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.blocklistSaved(packages.length)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.blocklistSaveFailed('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _tile(AppInfo app) {
    final selected = _selected.contains(app.packageName);
    return CheckboxListTile(
      secondary: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: app.icon != null
            ? Image.memory(
                app.icon!,
                width: 40,
                height: 40,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.android, size: 40, color: Colors.grey),
              )
            : const Icon(Icons.android, size: 40, color: Colors.grey),
      ),
      title: Text(
        app.appName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        formatForegroundUsage(app.foregroundMs),
        style: TextStyle(
          fontSize: 12,
          color: app.hasRecentUsage
              ? Colors.grey.shade700
              : Colors.grey.shade500,
        ),
      ),
      value: selected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _selected.add(app.packageName);
            _labels[app.packageName] = app.appName;
          } else {
            _selected.remove(app.packageName);
          }
        });
      },
    );
  }

  Widget _usageBanner() {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.warningDim,
        border: Border.all(
          color: c.warning.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Usage Access Required',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: c.warning,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grant Usage Access so LoqOut can list your apps, then return here.',
            style: TextStyle(color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await _permissions.requestUsageStatsPermission();
            },
            icon: const Icon(Icons.settings),
            label: Text(context.l10n.blocklistOpenUsageSettings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.blocklistTitle),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _loading
                ? null
                : () => _bootstrap().then((_) => _loadApps(forceRefresh: true)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Choose apps to shield by default. Saved once — every '
                    'focus session uses this list automatically.',
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_selected.length} selected',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: !_usageGranted
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [_usageBanner()],
                        )
                      : ListView(
                          children: [
                            if (_usedApps.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  'Top distractors (last 7 days)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              ..._usedApps.map(_tile),
                            ],
                            if (_unusedApps.isNotEmpty) ...[
                              const Divider(),
                              TextButton.icon(
                                onPressed: () => setState(
                                  () => _showUnused = !_showUnused,
                                ),
                                icon: Icon(
                                  _showUnused
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                ),
                                label: Text(
                                  _showUnused
                                      ? 'Hide unused apps'
                                      : 'Show unused apps (${_unusedApps.length})',
                                ),
                              ),
                              if (_showUnused) ..._unusedApps.map(_tile),
                            ],
                            if (_usedApps.isEmpty && _unusedApps.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(l10n.blocklistEmptyApps),
                                ),
                              ),
                          ],
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save),
                      label: Text(
                        _saving ? l10n.blocklistSaving : l10n.blocklistSave,
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
