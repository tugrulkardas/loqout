import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opaque Family Controls selection. Apple does not expose bundle ids.
class IosShieldSelection {
  const IosShieldSelection({
    this.authorizationStatus = 'notDetermined',
    this.applicationCount = 0,
    this.categoryCount = 0,
    this.webDomainCount = 0,
    this.cancelled = false,
  });

  final String authorizationStatus;
  final int applicationCount;
  final int categoryCount;
  final int webDomainCount;
  final bool cancelled;

  bool get hasTargets =>
      applicationCount > 0 || categoryCount > 0 || webDomainCount > 0;

  bool get isApproved => authorizationStatus == 'approved';

  /// Stable telemetry keys. Not Android package names.
  List<String> get markerPackages => [
        if (applicationCount > 0) 'ios.familycontrols.applications',
        if (categoryCount > 0) 'ios.familycontrols.categories',
        if (webDomainCount > 0) 'ios.familycontrols.webDomains',
      ];

  factory IosShieldSelection.fromMap(Map<dynamic, dynamic>? raw) {
    if (raw == null) return const IosShieldSelection();
    return IosShieldSelection(
      authorizationStatus:
          raw['authorizationStatus'] as String? ?? 'notDetermined',
      applicationCount: _asInt(raw['applicationCount']),
      categoryCount: _asInt(raw['categoryCount']),
      webDomainCount: _asInt(raw['webDomainCount']),
      cancelled: raw['cancelled'] == true,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

/// iOS counterpart of the Android watchdog.
///
/// Shielding starts only from [startShield], after the user has authenticated
/// the focus session. Nothing here runs at launch.
class IosShieldService {
  IosShieldService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.tugrul.tapfocus/family_controls');

  static final IosShieldService instance = IosShieldService();

  final MethodChannel _channel;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<String> authorizationStatus() async {
    if (!isSupported) return 'unsupported';
    final raw = await _channel.invokeMethod<String>('authorizationStatus');
    return raw ?? 'notDetermined';
  }

  Future<IosShieldSelection> summary() async {
    if (!isSupported) return const IosShieldSelection();
    final raw = await _channel.invokeMethod<dynamic>('selectionSummary');
    if (raw is Map) return IosShieldSelection.fromMap(raw);
    return const IosShieldSelection();
  }

  Future<IosShieldSelection> requestAuthorization() async {
    final raw = await _channel.invokeMethod<dynamic>('requestAuthorization');
    if (raw is Map) return IosShieldSelection.fromMap(raw);
    return summary();
  }

  Future<IosShieldSelection> presentActivityPicker() async {
    final raw = await _channel.invokeMethod<dynamic>('presentActivityPicker');
    if (raw is Map) return IosShieldSelection.fromMap(raw);
    return summary();
  }

  /// Applies ManagedSettings and arms the DeviceActivity monitor.
  Future<IosShieldSelection> startShield() async {
    final raw = await _channel.invokeMethod<dynamic>('startShield');
    if (raw is Map) return IosShieldSelection.fromMap(raw);
    return summary();
  }

  /// True when a focus session already applied the shield. Reads the App
  /// Group flag only. Does not request Family Controls authorization.
  Future<bool> isSessionActive() async {
    if (!isSupported) return false;
    try {
      final raw = await _channel.invokeMethod<bool>('isSessionActive');
      return raw ?? false;
    } on PlatformException catch (e, st) {
      debugPrint('isSessionActive failed: ${e.code} ${e.message}\n$st');
      return false;
    }
  }

  /// Puts an already-started shield back in place after the UI process died.
  /// Does not begin a new session.
  Future<void> restoreShield() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('restoreShield');
    } on PlatformException catch (e, st) {
      debugPrint('restoreShield failed: ${e.code} ${e.message}\n$st');
    }
  }

  Future<void> stopShield() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('stopShield');
    } on PlatformException catch (e, st) {
      debugPrint('stopShield failed: ${e.code} ${e.message}\n$st');
    }
  }
}
