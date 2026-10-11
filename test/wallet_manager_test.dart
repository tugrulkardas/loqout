import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapfocus_project/services/wallet_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await WalletManager.instance.debugReset(
      balance: WalletManager.initialBalance,
      monthlyCount: 0,
      lifetimeBurned: 0,
    );
  });

  group('WalletManager cost ladder', () {
    test('capped ladder: 10 → 20 → 40 → 40…', () {
      expect(WalletManager.costForOverride(0), 10);
      expect(WalletManager.costForOverride(1), 20);
      expect(WalletManager.costForOverride(2), 40);
      expect(WalletManager.costForOverride(3), 40);
      expect(WalletManager.costForOverride(4), 40);
      expect(WalletManager.costForOverride(10), 40);
      expect(WalletManager.maxOverrideCost, 40);
    });

    test('ordinal labels', () {
      expect(WalletManager.ordinalLabel(1), '1st');
      expect(WalletManager.ordinalLabel(2), '2nd');
      expect(WalletManager.ordinalLabel(3), '3rd');
      expect(WalletManager.ordinalLabel(4), '4th');
      expect(WalletManager.ordinalLabel(11), '11th');
      expect(WalletManager.ordinalLabel(21), '21st');
    });
  });

  group('WalletManager persistence', () {
    test('seeds initial Monthly Impact Quota of 100', () async {
      SharedPreferences.setMockInitialValues({});
      WalletManager.instance.debugUnload();
      final snap = await WalletManager.instance.ensureLoaded();
      expect(snap.tokenBalance, 100);
      expect(WalletManager.initialBalance, 100);
      expect(WalletManager.currencyName, 'Impact Credits');
      expect(WalletManager.quotaLabel, 'Monthly Impact Quota');
      expect(snap.monthlyOverrideCount, 0);
    });

    test('burn escalates and tracks lifetime burned', () async {
      await WalletManager.instance.debugReset(balance: 200, monthlyCount: 0);

      expect(WalletManager.instance.snapshot.nextOverrideCost, 10);
      var result = await WalletManager.instance.burnForEmergencyOverride();
      expect(result, BurnTokensResult.success);
      expect(WalletManager.instance.snapshot.tokenBalance, 190);
      expect(WalletManager.instance.snapshot.monthlyOverrideCount, 1);
      expect(WalletManager.instance.snapshot.lifetimeTokensBurned, 10);
      expect(WalletManager.instance.snapshot.nextOverrideCost, 20);

      result = await WalletManager.instance.burnForEmergencyOverride();
      expect(result, BurnTokensResult.success);
      expect(WalletManager.instance.snapshot.tokenBalance, 170);
      expect(WalletManager.instance.snapshot.monthlyOverrideCount, 2);
      expect(WalletManager.instance.snapshot.lifetimeTokensBurned, 30);
      expect(WalletManager.instance.snapshot.nextOverrideCost, 40);

      result = await WalletManager.instance.burnForEmergencyOverride();
      expect(result, BurnTokensResult.success);
      expect(WalletManager.instance.snapshot.tokenBalance, 130);
      expect(WalletManager.instance.snapshot.monthlyOverrideCount, 3);
      expect(WalletManager.instance.snapshot.lifetimeTokensBurned, 70);
      expect(WalletManager.instance.snapshot.nextOverrideCost, 40);
    });

    test('insufficient credits refuses burn', () async {
      await WalletManager.instance.debugReset(balance: 5, monthlyCount: 0);
      final result = await WalletManager.instance.burnForEmergencyOverride();
      expect(result, BurnTokensResult.insufficientTokens);
      expect(WalletManager.instance.snapshot.tokenBalance, 5);
      expect(WalletManager.instance.snapshot.monthlyOverrideCount, 0);
    });

    test('new calendar month resets override count', () async {
      await WalletManager.instance.debugReset(
        balance: 100,
        monthlyCount: 3,
        monthKey: '2020-01',
      );
      final snap = await WalletManager.instance.ensureLoaded();
      expect(snap.monthlyOverrideCount, 0);
      expect(snap.lastOverrideMonth, WalletManager.currentMonthKey());
      expect(snap.nextOverrideCost, 10);
    });
  });
}
