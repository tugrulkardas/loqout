import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';

import 'blocklist_service.dart';

/// Own package name — never treat TapFocus as a blocked foreground app.
const String kTapFocusPackageName = 'com.tugrul.tapfocus.tapfocus_project';

const String kPrefsBlockedAppsKey = 'tapfocus_blocked_apps';
const String kPrefsSessionActiveKey = 'tapfocus_session_active';
const String kPrefsInterventionCountKey = 'tapfocus_intervention_count';

/// Native [TapFocusApplication] listens for these keys and brings TapFocus
/// forward / shows a SYSTEM_ALERT_WINDOW block overlay. Mock NFC is unrelated.
const String kPrefsInterveneRequestKey = 'tapfocus_intervene_request';
const String kPrefsIntervenePkgKey = 'tapfocus_intervene_pkg';

const int _eventMoveToForeground = 1;
const int _eventActivityResumed = 23;

/// iOS background fetch hook (main-isolate rules differ on iOS).
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

/// Background isolate entry — **isolate-safe only**.
///
/// Do NOT call:
/// - `FlutterBackgroundService()` (main-isolate API)
/// - `DartPluginRegistrant.ensureInitialized()` (re-registers the Android
///   plugin and throws "only be used in the main isolate")
/// - UI widgets / dialogs / Mood Matrix state
///
/// Share `blocked_apps` via SharedPreferences; talk to UI via [service.invoke].
@pragma('vm:entry-point')
void onWatchdogStart(ServiceInstance service) async {
  // Binding only — never DartPluginRegistrant on this root isolate.
  WidgetsFlutterBinding.ensureInitialized();

  // Promote to FGS immediately (Android 14 / HyperOS RemoteServiceException).
  if (service is AndroidServiceInstance) {
    try {
      await service.setAsForegroundService();
    } catch (e) {
      debugPrint('TapFocus watchdog: setAsForegroundService failed: $e');
    }

    service.on('setAsForeground').listen((_) async {
      try {
        await service.setAsForegroundService();
      } catch (_) {}
    });
    service.on('setAsBackground').listen((_) async {
      try {
        await service.setAsBackgroundService();
      } catch (_) {}
    });
  }

  List<String> blockedApps = await _loadPersistedBlockedApps();
  DateTime? lastInterventionAt;
  String? lastIntervenedPackage;

  service.on('stopService').listen((_) async {
    try {
      await _persistSessionState(active: false, blockedApps: const []);
    } catch (_) {}
    service.stopSelf();
  });

  service.on('setAppList').listen((event) async {
    try {
      final raw = event?['apps'];
      if (raw is! List) return;
      blockedApps = raw
          .whereType<String>()
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty && p != kTapFocusPackageName)
          .toList(growable: false);
      await _persistSessionState(active: true, blockedApps: blockedApps);
      debugPrint(
        'TapFocus watchdog: block list updated (${blockedApps.length})',
      );
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: 'LoqOut focus active',
          content: '${blockedApps.length} apps locked.',
        );
      }
    } catch (e) {
      debugPrint('TapFocus watchdog: setAppList error: $e');
    }
  });

  Timer.periodic(const Duration(seconds: 1), (_) async {
    try {
      if (service is! AndroidServiceInstance) {
        service.invoke('update');
        return;
      }

      if (blockedApps.isEmpty) {
        blockedApps = await _loadPersistedBlockedApps();
      }

      bool hasUsage = false;
      try {
        hasUsage = await UsageStats.checkUsagePermission() ?? false;
      } catch (e) {
        debugPrint('TapFocus watchdog: usage permission check failed: $e');
      }

      if (!hasUsage) {
        await service.setForegroundNotificationInfo(
          title: 'LoqOut: permission missing',
          content: 'Usage access was revoked. Open LoqOut to fix.',
        );
        service.invoke('update');
        return;
      }

      if (blockedApps.isEmpty) {
        await service.setForegroundNotificationInfo(
          title: 'LoqOut focus active',
          content: 'Waiting for block list…',
        );
        service.invoke('update');
        return;
      }

      final currentApp = await _resolveForegroundPackage();
      final isViolation = currentApp != null &&
          currentApp.isNotEmpty &&
          blockedApps.contains(currentApp) &&
          currentApp != kTapFocusPackageName;

      if (isViolation) {
        debugPrint('TapFocus watchdog: violation $currentApp');
        await service.setForegroundNotificationInfo(
          title: 'LoqOut: blocked',
          content: 'Return to focus — $currentApp is locked.',
        );

        try {
          service.invoke('violation', {'package': currentApp});
        } catch (_) {}

        final now = DateTime.now();
        final shouldIntervene = lastInterventionAt == null ||
            now.difference(lastInterventionAt!) >=
                const Duration(milliseconds: 1500) ||
            lastIntervenedPackage != currentApp;

        if (shouldIntervene) {
          lastInterventionAt = now;
          lastIntervenedPackage = currentApp;
          await _incrementInterventionCount();
          // HyperOS often silently ignores Activity starts from a FGS.
          // Primary: SharedPreferences → TapFocusApplication (overlay + launch).
          // Fallback: service.openApp().
          await _requestNativeIntervention(currentApp);
          try {
            await service.openApp();
          } catch (e) {
            debugPrint('TapFocus watchdog: openApp failed: $e');
          }
        }
      } else {
        await service.setForegroundNotificationInfo(
          title: 'LoqOut focus active',
          content: '${blockedApps.length} apps locked.',
        );
      }
    } catch (e) {
      debugPrint('TapFocus watchdog loop error: $e');
    }

    try {
      service.invoke('update');
    } catch (_) {}
  });
}

Future<void> _persistSessionState({
  required bool active,
  required List<String> blockedApps,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefsSessionActiveKey, active);
    await prefs.setStringList(
      kPrefsBlockedAppsKey,
      List<String>.from(blockedApps),
    );
  } catch (e) {
    debugPrint('TapFocus watchdog: persist failed: $e');
  }
}

Future<List<String>> _loadPersistedBlockedApps() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool(kPrefsSessionActiveKey) ?? false;
    if (!active) return [];

    // Prefer the active-session list written at kick-off.
    final sessionList = List<String>.from(
      prefs.getStringList(kPrefsBlockedAppsKey) ?? const [],
    );
    if (sessionList.isNotEmpty) return sessionList;

    // Fallback: durable Default Blocklist (isolate-safe, no UI deps).
    return List<String>.from(
      prefs.getStringList(BlocklistService.packagesKey) ?? const [],
    );
  } catch (_) {
    return [];
  }
}

Future<void> _incrementInterventionCount() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(kPrefsInterventionCountKey) ?? 0) + 1;
    await prefs.setInt(kPrefsInterventionCountKey, next);
  } catch (_) {}
}

/// Writes markers that [TapFocusApplication] observes to reclaim the foreground.
///
/// Uses both SharedPreferences and a cache marker file so HyperOS cannot
/// silently swallow the reclaim (Activity starts from FGS alone often fail).
Future<void> _requestNativeIntervention(String blockedPackage) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefsIntervenePkgKey, blockedPackage);
    // Unique timestamp so the SharedPreferences listener always fires.
    await prefs.setInt(
      kPrefsInterveneRequestKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  } catch (e) {
    debugPrint('TapFocus watchdog: prefs intervene request failed: $e');
  }

  try {
    // FileObserver in TapFocusApplication — works without MethodChannel on
    // the background engine. Try both common cache roots (multi-user vs legacy).
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final payload = '$blockedPackage|$stamp';
    final candidates = <String>[
      '/data/user/0/$kTapFocusPackageName/cache/tapfocus_intervene',
      '/data/data/$kTapFocusPackageName/cache/tapfocus_intervene',
    ];
    for (final path in candidates) {
      try {
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsString(payload, flush: true);
        debugPrint('TapFocus watchdog: file intervene → $path');
      } catch (e) {
        debugPrint('TapFocus watchdog: file intervene miss ($path): $e');
      }
    }
  } catch (e) {
    debugPrint('TapFocus watchdog: file intervene request failed: $e');
  }
}

Future<String?> _resolveForegroundPackage() async {
  final end = DateTime.now();
  final start = end.subtract(const Duration(seconds: 5));

  try {
    final events = await UsageStats.queryEvents(start, end);
    for (final event in events.reversed) {
      final type = int.tryParse(event.eventType ?? '');
      final pkg = event.packageName ?? '';
      if (pkg.isEmpty) continue;
      if (type == _eventMoveToForeground || type == _eventActivityResumed) {
        return pkg;
      }
    }
  } catch (e) {
    debugPrint('TapFocus watchdog: queryEvents failed: $e');
  }

  try {
    final stats = await UsageStats.queryUsageStats(start, end);
    stats.sort(
      (a, b) => (int.tryParse(b.lastTimeUsed ?? '0') ?? 0)
          .compareTo(int.tryParse(a.lastTimeUsed ?? '0') ?? 0),
    );
    if (stats.isNotEmpty) return stats.first.packageName;
  } catch (e) {
    debugPrint('TapFocus watchdog: queryUsageStats failed: $e');
  }

  return null;
}
