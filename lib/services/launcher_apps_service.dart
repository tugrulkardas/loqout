import 'package:device_apps/device_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_models.dart';
import 'background_watchdog.dart';

/// True when the Android package list cannot be read (desktop, web, and iOS).
/// iOS shielding uses Family Controls, not this mock catalog.
bool get useDesktopMockLauncherApps {
  if (kIsWeb) return true;
  return defaultTargetPlatform != TargetPlatform.android;
}

/// Desktop / web stand-ins so Edit Blocklist + session kick-off work without
/// `device_apps` / PackageManager (Sprint 4.1 PO testing path).
List<AppInfo> desktopMockLauncherApps() {
  return [
    AppInfo(
      appName: 'Mockstagram',
      packageName: 'com.tapfocus.mock.instagram',
      foregroundMs: 3 * 60 * 60 * 1000,
    ),
    AppInfo(
      appName: 'MockTok',
      packageName: 'com.tapfocus.mock.tiktok',
      foregroundMs: 2 * 60 * 60 * 1000,
    ),
    AppInfo(
      appName: 'MockTube',
      packageName: 'com.tapfocus.mock.youtube',
      foregroundMs: 90 * 60 * 1000,
    ),
    AppInfo(
      appName: 'MockChat',
      packageName: 'com.tapfocus.mock.chat',
      foregroundMs: 45 * 60 * 1000,
    ),
  ];
}

/// Loads user-launchable apps from the OS — no hardcoded name/icon maps.
///
/// Prefers a native PackageManager `CATEGORY_LAUNCHER` query; falls back to
/// `device_apps` with `onlyAppsWithLaunchIntent: true`.
/// On non-Android, returns [desktopMockLauncherApps] for local UI testing.
class LauncherAppsService {
  static const MethodChannel _channel =
      MethodChannel('com.tugrul.tapfocus/launcher_apps');

  /// Returns launchable apps with OS labels + icons. Excludes TapFocus itself.
  Future<List<AppInfo>> loadLaunchableApps() async {
    if (useDesktopMockLauncherApps) {
      debugPrint('LauncherAppsService: using desktop mock apps');
      return desktopMockLauncherApps();
    }

    try {
      final native = await _loadViaNative();
      if (native.isNotEmpty) return native;
    } catch (e, st) {
      debugPrint('Native launcher query failed, using fallback: $e\n$st');
    }
    return _loadViaDeviceApps();
  }

  Future<List<AppInfo>> _loadViaNative() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('getLauncherApps');
    if (raw == null) return [];

    final apps = <AppInfo>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final packageName = map['packageName'] as String? ?? '';
      final label = (map['label'] as String?)?.trim() ?? '';
      if (packageName.isEmpty || packageName == kTapFocusPackageName) continue;
      if (label.isEmpty) continue;

      Uint8List? icon;
      final iconBytes = map['icon'];
      if (iconBytes is Uint8List) {
        icon = iconBytes;
      } else if (iconBytes is List) {
        icon = Uint8List.fromList(iconBytes.cast<int>());
      }

      apps.add(AppInfo(
        appName: label,
        packageName: packageName,
        icon: icon,
      ));
    }

    apps.sort(
      (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
    );
    return apps;
  }

  Future<List<AppInfo>> _loadViaDeviceApps() async {
    final installed = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );

    final apps = <AppInfo>[];
    for (final app in installed) {
      if (app.packageName == kTapFocusPackageName) continue;
      final name = app.appName.trim();
      if (name.isEmpty) continue;

      Uint8List? icon;
      if (app is ApplicationWithIcon) {
        icon = app.icon;
      }

      apps.add(AppInfo(
        appName: name,
        packageName: app.packageName,
        icon: icon,
      ));
    }

    apps.sort(
      (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
    );
    return apps;
  }
}
