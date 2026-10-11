import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Brings TapFocus to the foreground from the **main** isolate.
///
/// Used when the watchdog emits a `violation` event while the UI is alive.
/// Background-isolate interventions go through SharedPreferences →
/// [TapFocusApplication] (see watchdog_entry.dart).
class InterventionService {
  static const MethodChannel _channel =
      MethodChannel('com.tugrul.tapfocus/intervention');

  static Future<bool> bringToForeground({String? blockedPackage}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'bringToForeground',
        <String, dynamic>{'package': blockedPackage},
      );
      return result ?? false;
    } catch (e, st) {
      debugPrint('bringToForeground failed: $e\n$st');
      return false;
    }
  }
}
