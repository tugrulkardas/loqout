import 'package:flutter_test/flutter_test.dart';
import 'package:tapfocus_project/services/ios_shield_service.dart';

void main() {
  test('empty Family Controls selection has no shield targets', () {
    const selection = IosShieldSelection();
    expect(selection.hasTargets, isFalse);
    expect(selection.markerPackages, isEmpty);
    expect(selection.isApproved, isFalse);
  });

  test('summary map keeps opaque counts, not bundle ids', () {
    final selection = IosShieldSelection.fromMap({
      'authorizationStatus': 'approved',
      'applicationCount': 2,
      'categoryCount': 1,
      'webDomainCount': 0,
    });

    expect(selection.isApproved, isTrue);
    expect(selection.hasTargets, isTrue);
    expect(
      selection.markerPackages,
      ['ios.familycontrols.applications', 'ios.familycontrols.categories'],
    );
  });

  test('cancelled picker does not look like a new empty save', () {
    final selection = IosShieldSelection.fromMap({
      'authorizationStatus': 'approved',
      'applicationCount': 1,
      'cancelled': true,
    });
    expect(selection.cancelled, isTrue);
    expect(selection.hasTargets, isTrue);
  });

  test('a missing passcode is not shown as Screen Time approved', () {
    expect(
      iosLockAvailability(
        passcode: 'missing',
        authorizationStatus: 'approved',
        failureCode: null,
      ),
      IosLockAvailability.passcodeRequired,
    );
    expect(
      iosLockFailureCode(IosLockAvailability.passcodeRequired),
      'passcodeRequired',
    );
  });

  test('denied, restricted, and network stay distinct from granted', () {
    expect(
      iosLockAvailability(
        passcode: 'available',
        authorizationStatus: 'notDetermined',
        failureCode: 'restricted',
      ),
      IosLockAvailability.restricted,
    );
    expect(
      iosLockAvailability(
        passcode: 'available',
        authorizationStatus: 'denied',
        failureCode: null,
      ),
      IosLockAvailability.denied,
    );
    expect(
      iosLockAvailability(
        passcode: 'available',
        authorizationStatus: 'notDetermined',
        failureCode: 'network',
      ),
      IosLockAvailability.network,
    );
    expect(
      iosLockAvailability(
        passcode: 'available',
        authorizationStatus: 'approved',
        failureCode: null,
      ),
      IosLockAvailability.ready,
    );
  });
}
