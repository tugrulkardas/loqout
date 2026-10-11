import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable view of the Impact Wallet / Monthly Impact Quota.
@immutable
class WalletSnapshot {
  const WalletSnapshot({
    required this.tokenBalance,
    required this.monthlyOverrideCount,
    required this.lastOverrideMonth,
    required this.lifetimeTokensBurned,
  });

  /// Remaining Monthly Impact Quota (Impact Credits).
  final int tokenBalance;

  /// Overrides already used in the current calendar month.
  final int monthlyOverrideCount;

  /// `YYYY-MM` key used to roll the monthly counter.
  final String lastOverrideMonth;

  /// Lifetime Impact Credits burned via emergency overrides.
  final int lifetimeTokensBurned;

  /// Cost of the *next* emergency override this month (capped ladder).
  int get nextOverrideCost =>
      WalletManager.costForOverride(monthlyOverrideCount);

  /// 1-based ordinal of the next override (for copy: "your 3rd time").
  int get nextOverrideOrdinal => monthlyOverrideCount + 1;

  bool canAffordNextOverride() => tokenBalance >= nextOverrideCost;

  WalletSnapshot copyWith({
    int? tokenBalance,
    int? monthlyOverrideCount,
    String? lastOverrideMonth,
    int? lifetimeTokensBurned,
  }) {
    return WalletSnapshot(
      tokenBalance: tokenBalance ?? this.tokenBalance,
      monthlyOverrideCount: monthlyOverrideCount ?? this.monthlyOverrideCount,
      lastOverrideMonth: lastOverrideMonth ?? this.lastOverrideMonth,
      lifetimeTokensBurned:
          lifetimeTokensBurned ?? this.lifetimeTokensBurned,
    );
  }
}

enum BurnTokensResult {
  success,
  insufficientTokens,
  failed,
}

/// Local Impact Credits / Emergency Quota economy.
///
/// Reactive via [ChangeNotifier] so Impact Wallet + session UI stay in sync.
class WalletManager extends ChangeNotifier {
  WalletManager._();

  static final WalletManager instance = WalletManager._();

  static const int baseCost = 10;

  /// Hard ceiling for any single emergency unlock this month.
  static const int maxOverrideCost = 40;

  /// Subscription-provided monthly quota (~$10 equivalent for beta narrative).
  static const int initialBalance = 100;

  static const String currencyName = 'Impact Credits';
  static const String quotaLabel = 'Monthly Impact Quota';

  static const String _keyBalance = 'tapfocus_token_balance';
  static const String _keyMonthlyCount = 'tapfocus_monthly_override_count';
  static const String _keyLastMonth = 'tapfocus_last_override_month';
  static const String _keyLifetimeBurned = 'tapfocus_lifetime_tokens_burned';

  WalletSnapshot _snapshot = WalletSnapshot(
    tokenBalance: initialBalance,
    monthlyOverrideCount: 0,
    lastOverrideMonth: currentMonthKey(),
    lifetimeTokensBurned: 0,
  );

  bool _loaded = false;

  WalletSnapshot get snapshot => _snapshot;

  /// Capped monthly ladder: 10 → 20 → 40, then stays at [maxOverrideCost].
  ///
  /// [monthlyOverrideCount] is how many overrides were already used this month
  /// (0 = first unlock costs 10).
  static int costForOverride(int monthlyOverrideCount) {
    final n = monthlyOverrideCount < 0 ? 0 : monthlyOverrideCount;
    if (n <= 0) return baseCost; // 10
    if (n == 1) return baseCost * 2; // 20
    return maxOverrideCost; // 40 (3rd unlock and beyond)
  }

  static String currentMonthKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    return '${d.year}-$m';
  }

  static String ordinalLabel(int n) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  Future<WalletSnapshot> ensureLoaded() async {
    if (_loaded) {
      return _applyMonthRollover(_snapshot);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasBalance = prefs.containsKey(_keyBalance);
      var snap = WalletSnapshot(
        tokenBalance: hasBalance
            ? (prefs.getInt(_keyBalance) ?? initialBalance)
            : initialBalance,
        monthlyOverrideCount: prefs.getInt(_keyMonthlyCount) ?? 0,
        lastOverrideMonth:
            prefs.getString(_keyLastMonth) ?? currentMonthKey(),
        lifetimeTokensBurned: prefs.getInt(_keyLifetimeBurned) ?? 0,
      );
      if (!hasBalance) {
        await prefs.setInt(_keyBalance, initialBalance);
      }
      snap = await _applyMonthRollover(snap);
      _snapshot = snap;
      _loaded = true;
      notifyListeners();
      return _snapshot;
    } catch (e, st) {
      debugPrint('WalletManager.ensureLoaded failed: $e\n$st');
      _loaded = true;
      return _snapshot;
    }
  }

  Future<WalletSnapshot> _applyMonthRollover(WalletSnapshot snap) async {
    final nowKey = currentMonthKey();
    if (snap.lastOverrideMonth == nowKey) return snap;
    // New calendar month: reset override ladder; replenish quota if depleted.
    final rolled = snap.copyWith(
      monthlyOverrideCount: 0,
      lastOverrideMonth: nowKey,
      tokenBalance: snap.tokenBalance > 0 ? snap.tokenBalance : initialBalance,
    );
    await _persist(rolled);
    _snapshot = rolled;
    notifyListeners();
    return rolled;
  }

  Future<void> _persist(WalletSnapshot snap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyBalance, snap.tokenBalance);
      await prefs.setInt(_keyMonthlyCount, snap.monthlyOverrideCount);
      await prefs.setString(_keyLastMonth, snap.lastOverrideMonth);
      await prefs.setInt(_keyLifetimeBurned, snap.lifetimeTokensBurned);
    } catch (e, st) {
      debugPrint('WalletManager._persist failed: $e\n$st');
    }
  }

  /// Burns Impact Credits for an emergency unlock. Does not unlock the session.
  Future<BurnTokensResult> burnForEmergencyOverride() async {
    await ensureLoaded();
    final cost = _snapshot.nextOverrideCost;
    if (_snapshot.tokenBalance < cost) {
      return BurnTokensResult.insufficientTokens;
    }

    try {
      final next = _snapshot.copyWith(
        tokenBalance: _snapshot.tokenBalance - cost,
        monthlyOverrideCount: _snapshot.monthlyOverrideCount + 1,
        lastOverrideMonth: currentMonthKey(),
        lifetimeTokensBurned: _snapshot.lifetimeTokensBurned + cost,
      );
      await _persist(next);
      _snapshot = next;
      notifyListeners();
      return BurnTokensResult.success;
    } catch (e, st) {
      debugPrint('WalletManager.burnForEmergencyOverride failed: $e\n$st');
      return BurnTokensResult.failed;
    }
  }

  /// Visible for tests — forces the next [ensureLoaded] to re-read prefs.
  @visibleForTesting
  void debugUnload() {
    _loaded = false;
  }

  /// Visible for tests — overwrites persisted wallet fields.
  @visibleForTesting
  Future<void> debugReset({
    int balance = initialBalance,
    int monthlyCount = 0,
    int lifetimeBurned = 0,
    String? monthKey,
  }) async {
    final snap = WalletSnapshot(
      tokenBalance: balance,
      monthlyOverrideCount: monthlyCount,
      lastOverrideMonth: monthKey ?? currentMonthKey(),
      lifetimeTokensBurned: lifetimeBurned,
    );
    await _persist(snap);
    _snapshot = snap;
    _loaded = true;
    notifyListeners();
  }
}
