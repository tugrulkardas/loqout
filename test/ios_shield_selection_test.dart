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
}
