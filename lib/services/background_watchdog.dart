import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'watchdog_entry.dart';

export 'watchdog_entry.dart'
    show
        kTapFocusPackageName,
        onWatchdogStart,
        onIosBackground,
        kPrefsBlockedAppsKey,
        kPrefsSessionActiveKey,
        kPrefsInterventionCountKey;

const MethodChannel _interventionChannel =
    MethodChannel('com.tugrul.tapfocus/intervention');

/// Must match [AndroidConfiguration.notificationChannelId] and the native
/// channel created before startForegroundService.
const String kWatchdogNotificationChannelId = 'tapfocus_watchdog_channel';
const int kWatchdogNotificationId = 888;

/// Creates the FGS notification channel on Android before the service starts.
/// Without this, Android 14 throws CannotPostForegroundServiceNotificationException.
Future<void> ensureWatchdogNotificationChannel() async {
  try {
    await _interventionChannel.invokeMethod<bool>(
      'ensureWatchdogNotificationChannel',
      <String, dynamic>{'channelId': kWatchdogNotificationChannelId},
    );
  } catch (e) {
    debugPrint('ensureWatchdogNotificationChannel failed: $e');
  }
}

/// Main-isolate APIs for configuring / starting / stopping the watchdog.
///
/// Never call these from [onWatchdogStart] — that runs in a background isolate
/// where [FlutterBackgroundService] construction throws.
Future<void> configureWatchdogService() async {
  // Channel MUST exist before native startForeground uses this id.
  await ensureWatchdogNotificationChannel();

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onWatchdogStart,
      isForegroundMode: true,
      autoStart: false,
      autoStartOnBoot: false,
      notificationChannelId: kWatchdogNotificationChannelId,
      initialNotificationTitle: 'LoqOut focus active',
      initialNotificationContent: 'Watchdog protecting your session…',
      foregroundServiceNotificationId: kWatchdogNotificationId,
      foregroundServiceTypes: const [
        AndroidForegroundType.dataSync,
        AndroidForegroundType.specialUse,
      ],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onWatchdogStart,
      onBackground: onIosBackground,
    ),
  );
}

/// Starts the watchdog from the **UI isolate** only.
Future<bool> startWatchdogService({
  required List<String>? blockedApps,
  bool resetInterventionCount = true,
}) async {
  try {
    final filtered = (blockedApps ?? const <String>[])
        .whereType<String>()
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && p != kTapFocusPackageName)
        .toSet()
        .toList(growable: false);

    if (filtered.isEmpty) {
      debugPrint('Refusing to start watchdog: empty blocked app list');
      return false;
    }

    await _persistSessionStateMain(active: true, blockedApps: filtered);
    if (resetInterventionCount) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(kPrefsInterventionCountKey, 0);
      } catch (_) {}
    }

    // Create channel again right before start (idempotent) — HyperOS is strict.
    await ensureWatchdogNotificationChannel();
    await configureWatchdogService();

    final service = FlutterBackgroundService();
    final alreadyRunning = await service.isRunning();
    if (!alreadyRunning) {
      final started = await service.startService();
      if (!started) {
        debugPrint('startService returned false');
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }

    _safeInvokeAppList(service, filtered);
    await Future.delayed(const Duration(milliseconds: 250));
    _safeInvokeAppList(service, filtered);
    return true;
  } on PlatformException catch (e, st) {
    debugPrint('Watchdog PlatformException: ${e.code} ${e.message}\n$st');
    return false;
  } catch (e, st) {
    debugPrint('Failed to start watchdog: $e\n$st');
    return false;
  }
}

void _safeInvokeAppList(FlutterBackgroundService service, List<String> apps) {
  try {
    service.invoke('setAppList', <String, dynamic>{
      'apps': List<String>.from(apps),
    });
  } catch (e) {
    debugPrint('setAppList invoke failed (non-fatal): $e');
  }
}

Future<void> stopWatchdogService() async {
  try {
    await _persistSessionStateMain(active: false, blockedApps: const []);
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  } catch (e, st) {
    debugPrint('Failed to stop watchdog: $e\n$st');
  }
}

Future<void> _persistSessionStateMain({
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
    debugPrint('Failed to persist session state: $e');
  }
}

/// Safe overlay check for the UI isolate (never crashes).
Future<OverlayGuardResult> checkOverlayGuard() async {
  try {
    final raw =
        await _interventionChannel.invokeMethod<dynamic>('checkOverlay');
    if (raw is Map) {
      return OverlayGuardResult(
        canDrawOverlays: raw['canDrawOverlays'] == true,
        detail: raw['detail'] as String? ?? '',
      );
    }
    return const OverlayGuardResult(canDrawOverlays: true, detail: 'ok');
  } catch (e) {
    debugPrint('checkOverlay failed: $e');
    return OverlayGuardResult(
      canDrawOverlays: false,
      detail: e.toString(),
    );
  }
}

class OverlayGuardResult {
  const OverlayGuardResult({
    required this.canDrawOverlays,
    required this.detail,
  });

  final bool canDrawOverlays;
  final String detail;
}
