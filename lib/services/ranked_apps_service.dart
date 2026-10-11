import 'package:flutter/foundation.dart';
import 'package:usage_stats/usage_stats.dart';

import '../models/app_models.dart';
import 'launcher_apps_service.dart';
import 'permission_service.dart';

/// Result of a 7-day usage-ranked launcher query.
class RankedLauncherApps {
  const RankedLauncherApps({
    required this.usedApps,
    required this.unusedApps,
    required this.fetchedAt,
  });

  /// Foreground time > 0 in the last 7 days, sorted descending by usage.
  final List<AppInfo> usedApps;

  /// Zero foreground time in the last 7 days (habit-noise), A–Z.
  final List<AppInfo> unusedApps;

  final DateTime fetchedAt;

  List<AppInfo> get all => [...usedApps, ...unusedApps];

  bool get isEmpty => usedApps.isEmpty && unusedApps.isEmpty;
}

/// Loads launchable apps ranked by last-7-days foreground usage.
///
/// Caches the ranked result in memory for the lifetime of this service
/// instance (one Focus Session setup screen) to avoid repeated I/O.
class RankedAppsService {
  RankedAppsService({
    LauncherAppsService? launcherApps,
    PermissionService? permissions,
  })  : _launcherApps = launcherApps ?? LauncherAppsService(),
        _permissions = permissions ?? const PermissionService();

  final LauncherAppsService _launcherApps;
  final PermissionService _permissions;

  RankedLauncherApps? _cache;
  Future<RankedLauncherApps>? _inFlight;

  RankedLauncherApps? get cached => _cache;

  void invalidateCache() {
    _cache = null;
    _inFlight = null;
  }

  /// Async ranked load. Reuses in-memory cache unless [forceRefresh].
  Future<RankedLauncherApps> loadRankedApps({bool forceRefresh = false}) {
    if (forceRefresh) {
      invalidateCache();
    }
    if (_cache != null) {
      return Future.value(_cache!);
    }
    if (_inFlight != null) {
      return _inFlight!;
    }

    _inFlight = _fetchAndRank().then((result) {
      _cache = result;
      _inFlight = null;
      return result;
    }).catchError((Object e, StackTrace st) {
      _inFlight = null;
      debugPrint('RankedAppsService failed: $e\n$st');
      throw e;
    });

    return _inFlight!;
  }

  Future<RankedLauncherApps> _fetchAndRank() async {
    if (useDesktopMockLauncherApps) {
      final mocks = desktopMockLauncherApps();
      final used = mocks.where((a) => a.foregroundMs > 0).toList()
        ..sort((a, b) => b.foregroundMs.compareTo(a.foregroundMs));
      final unused = mocks.where((a) => a.foregroundMs <= 0).toList();
      return RankedLauncherApps(
        usedApps: used,
        unusedApps: unused,
        fetchedAt: DateTime.now(),
      );
    }

    // Kick off launcher enumeration immediately; usage query in parallel.
    final launchableFuture = _launcherApps.loadLaunchableApps();
    final usageFuture = _loadSevenDayForegroundMs();

    final launchable = await launchableFuture;
    final usageMs = await usageFuture;

    final used = <AppInfo>[];
    final unused = <AppInfo>[];

    for (final app in launchable) {
      final ms = usageMs[app.packageName] ?? 0;
      final ranked = app.copyWithUsage(ms);
      if (ms > 0) {
        used.add(ranked);
      } else {
        unused.add(ranked);
      }
    }

    used.sort((a, b) {
      final byUsage = b.foregroundMs.compareTo(a.foregroundMs);
      if (byUsage != 0) return byUsage;
      return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
    });
    unused.sort(
      (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
    );

    return RankedLauncherApps(
      usedApps: used,
      unusedApps: unused,
      fetchedAt: DateTime.now(),
    );
  }

  /// Aggregated foreground ms per package over a rolling 7-day window.
  Future<Map<String, int>> _loadSevenDayForegroundMs() async {
    final granted = await _permissions.hasUsageStatsPermission();
    if (!granted) return {};

    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    final totals = <String, int>{};

    try {
      // Prefer OS-side aggregation (one entry per package for the window).
      final aggregated =
          await UsageStats.queryAndAggregateUsageStats(start, end);
      for (final entry in aggregated.entries) {
        final pkg = entry.key;
        if (pkg.isEmpty) continue;
        final ms =
            int.tryParse(entry.value.totalTimeInForeground ?? '0') ?? 0;
        if (ms > 0) totals[pkg] = ms;
      }
      if (totals.isNotEmpty) return totals;
    } catch (e) {
      debugPrint('queryAndAggregateUsageStats failed: $e');
    }

    try {
      // Fallback: INTERVAL_BEST buckets — must SUM, not overwrite.
      final stats = await UsageStats.queryUsageStats(start, end);
      for (final u in stats) {
        final pkg = u.packageName ?? '';
        if (pkg.isEmpty) continue;
        final ms = int.tryParse(u.totalTimeInForeground ?? '0') ?? 0;
        if (ms <= 0) continue;
        totals[pkg] = (totals[pkg] ?? 0) + ms;
      }
    } catch (e) {
      debugPrint('queryUsageStats fallback failed: $e');
    }

    return totals;
  }
}

/// Formats foreground ms for list subtitles (e.g. "2h 15m this week").
String formatForegroundUsage(int ms) {
  if (ms <= 0) return 'Unused in last 7 days';
  final totalMinutes = (ms / 60000).round();
  if (totalMinutes < 1) return '<1m this week';
  if (totalMinutes < 60) return '${totalMinutes}m this week';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) return '${hours}h this week';
  return '${hours}h ${minutes}m this week';
}
