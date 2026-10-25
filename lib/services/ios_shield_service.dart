import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// One shielded app on iOS. The slot is a stable anonymous index, not a name.
class IosBlockedAppImpulse {
  const IosBlockedAppImpulse({required this.slot, required this.count});

  final int slot;
  final int count;
}

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

/// What the lock UI is allowed to claim.
enum IosLockAvailability {
  ready,
  needsAuthorization,
  passcodeRequired,
  denied,
  restricted,
  network,
  unknown,
}

/// Passcode missing always wins, including over a stale `approved` status.
IosLockAvailability iosLockAvailability({
  required String passcode,
  required String authorizationStatus,
  String? failureCode,
}) {
  if (passcode == 'missing' || failureCode == 'passcodeRequired') {
    return IosLockAvailability.passcodeRequired;
  }
  if (failureCode == 'restricted') return IosLockAvailability.restricted;
  if (failureCode == 'network') return IosLockAvailability.network;
  if (failureCode == 'denied' || authorizationStatus == 'denied') {
    return IosLockAvailability.denied;
  }
  if (failureCode == 'authorizationRequired') {
    return IosLockAvailability.needsAuthorization;
  }
  if (failureCode != null && failureCode.isNotEmpty) {
    return IosLockAvailability.unknown;
  }
  if (authorizationStatus == 'approved') return IosLockAvailability.ready;
  return IosLockAvailability.needsAuthorization;
}

String? iosLockFailureCode(IosLockAvailability availability) {
  switch (availability) {
    case IosLockAvailability.passcodeRequired:
      return 'passcodeRequired';
    case IosLockAvailability.denied:
      return 'denied';
    case IosLockAvailability.restricted:
      return 'restricted';
    case IosLockAvailability.network:
      return 'network';
    case IosLockAvailability.unknown:
      return 'unknown';
    case IosLockAvailability.ready:
    case IosLockAvailability.needsAuthorization:
      return null;
  }
}

String iosLockMessage(AppLocalizations l10n, IosLockAvailability availability) {
  switch (availability) {
    case IosLockAvailability.passcodeRequired:
      return l10n.iosShieldPasscodeBody;
    case IosLockAvailability.denied:
      return l10n.iosShieldDenied;
    case IosLockAvailability.restricted:
      return l10n.iosShieldRestricted;
    case IosLockAvailability.network:
      return l10n.iosShieldNetwork;
    case IosLockAvailability.unknown:
      return l10n.iosShieldUnknown;
    case IosLockAvailability.needsAuthorization:
      return l10n.iosShieldNeedApprovalBody;
    case IosLockAvailability.ready:
      return '';
  }
}

String iosAuthErrorMessage(AppLocalizations l10n, String? code) {
  final availability = iosLockAvailability(
    passcode: code == 'passcodeRequired' ? 'missing' : 'available',
    authorizationStatus: code == 'denied' ? 'denied' : 'notDetermined',
    failureCode: code,
  );
  final text = iosLockMessage(l10n, availability);
  return text.isEmpty ? l10n.iosShieldUnknown : text;
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

  static const _authCacheKey = 'ios_family_authorization_status';

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
    final selection =
        raw is Map ? IosShieldSelection.fromMap(raw) : const IosShieldSelection();
    await _cacheStatus(selection.authorizationStatus);
    return selection;
  }

  /// Last status read from Family Controls. Cold start uses this so the
  /// Focus tab does not touch AuthorizationCenter before the user asks.
  Future<String> cachedAuthorizationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authCacheKey) ?? 'notDetermined';
    } catch (e, st) {
      debugPrint('cachedAuthorizationStatus failed: $e\n$st');
      return 'notDetermined';
    }
  }

  Future<void> _cacheStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authCacheKey, status);
    } catch (e, st) {
      debugPrint('cache authorization status failed: $e\n$st');
    }
  }

  /// `available`, `missing`, or `unknown`. Does not prompt.
  Future<String> devicePasscodeStatus() async {
    if (!isSupported) return 'available';
    try {
      final raw = await _channel.invokeMethod<String>('devicePasscodeStatus');
      return raw ?? 'unknown';
    } on PlatformException catch (e, st) {
      debugPrint('devicePasscodeStatus failed: ${e.code} ${e.message}\n$st');
      return 'unknown';
    }
  }

  /// Local counter on the phone. [code] is a stable token, not the Apple text.
  Future<void> noteAuthFailure(String code) async {
    debugPrint('family_controls_auth_failure code=$code');
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('noteAuthFailure', code);
    } catch (e, st) {
      debugPrint('noteAuthFailure failed: $e\n$st');
    }
  }

  Future<IosShieldSelection> requestAuthorization() async {
    final raw = await _channel.invokeMethod<dynamic>('requestAuthorization');
    if (raw is Map) {
      final selection = IosShieldSelection.fromMap(raw);
      await _cacheStatus(selection.authorizationStatus);
      return selection;
    }
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

  /// Shield-button taps for the open session. Not locked-app launches.
  Future<int> impulseCount() async {
    if (!isSupported) return 0;
    try {
      final raw = await _channel.invokeMethod<int>('impulseCount');
      return raw ?? 0;
    } catch (e) {
      debugPrint('impulseCount failed: $e');
      return 0;
    }
  }

  /// One row per shielded app. Slot numbers are anonymous. Apple does not
  /// give the app name for an [ApplicationToken].
  Future<List<IosBlockedAppImpulse>> impulseBreakdown() async {
    if (!isSupported) return const [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('impulseBreakdown');
      if (raw == null) return const [];
      final rows = <IosBlockedAppImpulse>[];
      for (final item in raw) {
        if (item is! Map) continue;
        rows.add(
          IosBlockedAppImpulse(
            slot: IosShieldSelection._asInt(item['slot']),
            count: IosShieldSelection._asInt(item['count']),
          ),
        );
      }
      return rows;
    } catch (e) {
      debugPrint('impulseBreakdown failed: $e');
      return const [];
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
