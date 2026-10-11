import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:usage_stats/usage_stats.dart';

/// Snapshot of the Android permissions TapFocus needs for enforcement.
@immutable
class PermissionSnapshot {
  const PermissionSnapshot({
    required this.usageStats,
    required this.systemAlertWindow,
    required this.notifications,
  });

  final bool usageStats;
  final bool systemAlertWindow;
  final bool notifications;

  bool get allGranted =>
      usageStats && systemAlertWindow && notifications;

  List<TapFocusPermission> get missing {
    return [
      if (!usageStats) TapFocusPermission.usageStats,
      if (!systemAlertWindow) TapFocusPermission.systemAlertWindow,
      if (!notifications) TapFocusPermission.notifications,
    ];
  }
}

enum TapFocusPermission {
  usageStats,
  systemAlertWindow,
  notifications,
}

extension TapFocusPermissionMeta on TapFocusPermission {
  String get title {
    switch (this) {
      case TapFocusPermission.usageStats:
        return 'Usage Access';
      case TapFocusPermission.systemAlertWindow:
        return 'Display Over Other Apps';
      case TapFocusPermission.notifications:
        return 'Notifications';
    }
  }

  String get rationale {
    switch (this) {
      case TapFocusPermission.usageStats:
        return 'Lets LoqOut detect when a blocked app comes to the foreground '
            'during a focus session.';
      case TapFocusPermission.systemAlertWindow:
        return 'Lets LoqOut bring the block / mood screen forward when a '
            'banned app is opened.';
      case TapFocusPermission.notifications:
        return 'Required for the foreground watchdog service notification '
            'while a focus session is active.';
    }
  }
}

/// Defensive, lifecycle-safe permission checks.
///
/// Never throws to callers — all platform failures are caught and treated as
/// "not granted" so missing permissions produce UI, not crashes.
class PermissionService {
  const PermissionService();

  /// Check all required permissions. Safe to call after the first frame.
  Future<PermissionSnapshot> checkAll() async {
    final usage = await hasUsageStatsPermission();
    final overlay = await hasSystemAlertWindowPermission();
    final notifications = await hasNotificationPermission();
    return PermissionSnapshot(
      usageStats: usage,
      systemAlertWindow: overlay,
      notifications: notifications,
    );
  }

  Future<bool> hasUsageStatsPermission() async {
    // Desktop / web: mock launcher path — treat as granted for Edit Blocklist.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (e, st) {
      debugPrint('Usage stats permission check failed: $e\n$st');
      return false;
    }
  }

  Future<bool> hasSystemAlertWindowPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      return await ph.Permission.systemAlertWindow.isGranted;
    } catch (e, st) {
      debugPrint('Overlay permission check failed: $e\n$st');
      return false;
    }
  }

  Future<bool> hasNotificationPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      // Pre-Android 13: treated as granted by the OS / plugin.
      final status = await ph.Permission.notification.status;
      return status.isGranted || status.isLimited;
    } catch (e, st) {
      debugPrint('Notification permission check failed: $e\n$st');
      return false;
    }
  }

  /// Opens the system Usage Access settings screen.
  Future<void> requestUsageStatsPermission() async {
    try {
      await UsageStats.grantUsagePermission();
    } catch (e, st) {
      debugPrint('Usage stats permission request failed: $e\n$st');
    }
  }

  /// Requests overlay permission (opens settings on most Android versions).
  Future<bool> requestSystemAlertWindowPermission() async {
    try {
      final status = await ph.Permission.systemAlertWindow.request();
      return status.isGranted;
    } catch (e, st) {
      debugPrint('Overlay permission request failed: $e\n$st');
      return false;
    }
  }

  /// Requests POST_NOTIFICATIONS on Android 13+.
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await ph.Permission.notification.request();
      return status.isGranted || status.isLimited;
    } catch (e, st) {
      debugPrint('Notification permission request failed: $e\n$st');
      return false;
    }
  }

  Future<void> request(TapFocusPermission permission) async {
    switch (permission) {
      case TapFocusPermission.usageStats:
        await requestUsageStatsPermission();
      case TapFocusPermission.systemAlertWindow:
        await requestSystemAlertWindowPermission();
      case TapFocusPermission.notifications:
        await requestNotificationPermission();
    }
  }

  /// Opens app settings as a last-resort fallback.
  Future<bool> openAppSettingsFallback() async {
    try {
      return await ph.openAppSettings();
    } catch (e, st) {
      debugPrint('openAppSettings failed: $e\n$st');
      return false;
    }
  }
}
