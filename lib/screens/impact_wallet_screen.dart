import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../services/wallet_manager.dart';
import '../theme/tapfocus_theme.dart';
import '../widgets/language_menu_button.dart';

/// Impact hub: Monthly Impact Quota, penalty ladder, corporate pledge board.
class ImpactWalletScreen extends StatefulWidget {
  const ImpactWalletScreen({
    super.key,
    this.onToggleTheme,
    this.themeIcon,
    this.themeTooltip,
  });

  final VoidCallback? onToggleTheme;
  final IconData? themeIcon;
  final String? themeTooltip;

  @override
  State<ImpactWalletScreen> createState() => _ImpactWalletScreenState();
}

class _ImpactWalletScreenState extends State<ImpactWalletScreen> {
  final WalletManager _wallet = WalletManager.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _wallet.addListener(_onWalletChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _wallet.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onWalletChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    await _wallet.ensureLoaded();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final snap = _wallet.snapshot;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.impactTitle),
        actions: [
          const LanguageMenuButton(),
          if (widget.onToggleTheme != null)
            IconButton(
              tooltip: widget.themeTooltip ?? l10n.themeSystem,
              onPressed: widget.onToggleTheme,
              icon: Icon(widget.themeIcon ?? Icons.brightness_auto),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _HowThisWorksCard(),
                const SizedBox(height: 20),
                _QuotaCard(balance: snap.tokenBalance),
                const SizedBox(height: 20),
                _PenaltyLadderCard(snapshot: snap),
                const SizedBox(height: 20),
                _ImpactBoardCard(lifetimeBurned: snap.lifetimeTokensBurned),
              ],
            ),
    );
  }
}

class _HowThisWorksCard extends StatelessWidget {
  const _HowThisWorksCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: c.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.impactHowThisWorks,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.impactHowThisWorksBody,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.accentDeep, c.accentDim],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.impactMonthlyQuota,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$balance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          Text(
            l10n.impactCredits,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.impactQuotaBlurb,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PenaltyLadderCard extends StatelessWidget {
  const _PenaltyLadderCard({required this.snapshot});

  final WalletSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final nextCost = snapshot.nextOverrideCost;
    final used = snapshot.monthlyOverrideCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.dangerDim,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: c.warning.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: c.warning),
              const SizedBox(width: 8),
              Text(
                l10n.impactPenaltyLadder,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.impactPenaltyIntro,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.impactPenaltyMonthStats(used, nextCost),
            style: TextStyle(
              color: c.warning,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (i) {
            final cost = WalletManager.costForOverride(i);
            final isNext = i == used;
            final isPast = i < used;
            final fraction =
                (cost / WalletManager.maxOverrideCost).clamp(0.15, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      WalletManager.ordinalLabel(i + 1),
                      style: TextStyle(
                        fontWeight: isNext ? FontWeight.w800 : FontWeight.w500,
                        color: isNext ? c.warning : c.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: fraction,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 11,
                            decoration: BoxDecoration(
                              gradient: isPast || isNext
                                  ? LinearGradient(
                                      colors: [
                                        c.warningDeep,
                                        cost >= WalletManager.maxOverrideCost
                                            ? c.warning
                                            : c.danger,
                                      ],
                                    )
                                  : null,
                              color:
                                  isPast || isNext ? null : c.surfaceElevated,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '$cost',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: isNext ? FontWeight.w800 : FontWeight.w500,
                        color: isNext ? c.danger : c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            l10n.impactPenaltyCapDisclaimer,
            style: TextStyle(fontSize: 11, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ImpactBoardCard extends StatelessWidget {
  const _ImpactBoardCard({required this.lifetimeBurned});

  final int lifetimeBurned;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.impactCorporatePledge.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$lifetimeBurned',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w300,
              letterSpacing: -1,
              color: c.textPrimary,
            ),
          ),
          Text(
            l10n.impactLifetimePledged,
            style: TextStyle(
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            l10n.impactPledgeBody,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: c.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
