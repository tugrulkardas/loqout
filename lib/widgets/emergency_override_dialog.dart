import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../services/wallet_manager.dart';
import '../theme/tapfocus_theme.dart';

/// Severe confirmation flow for burning Impact Credits to unlock without NFC.
///
/// Returns `true` if quota was burned successfully (caller should unlock).
Future<bool> showEmergencyOverrideDialog(BuildContext context) async {
  final wallet = WalletManager.instance;
  await wallet.ensureLoaded();

  if (!context.mounted) return false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _EmergencyOverrideDialog(),
  );
  return result == true;
}

class _EmergencyOverrideDialog extends StatefulWidget {
  const _EmergencyOverrideDialog();

  @override
  State<_EmergencyOverrideDialog> createState() =>
      _EmergencyOverrideDialogState();
}

class _EmergencyOverrideDialogState extends State<_EmergencyOverrideDialog> {
  final WalletManager _wallet = WalletManager.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _wallet.addListener(_onChanged);
  }

  @override
  void dispose() {
    _wallet.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmBurn() async {
    setState(() => _busy = true);
    try {
      final result = await _wallet.burnForEmergencyOverride();
      if (!mounted) return;
      switch (result) {
        case BurnTokensResult.success:
          Navigator.of(context).pop(true);
          return;
        case BurnTokensResult.insufficientTokens:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.emergencyInsufficient),
              backgroundColor: TapFocusColors.of(context).danger,
            ),
          );
        case BurnTokensResult.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.retry),
              backgroundColor: TapFocusColors.of(context).danger,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final snap = _wallet.snapshot;
    final cost = snap.nextOverrideCost;
    final ordinal = WalletManager.ordinalLabel(snap.nextOverrideOrdinal);
    final canAfford = snap.canAffordNextOverride();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: c.warning),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.emergencyOverrideTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.emergencyOverrideBody(cost),
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.emergencyOverrideOrdinal(ordinal),
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.impactMonthlyQuota}: ${snap.tokenBalance}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: canAfford ? c.accent : c.danger,
            ),
          ),
          if (!canAfford) ...[
            const SizedBox(height: 10),
            Text(
              l10n.emergencyInsufficientHint,
              style: TextStyle(color: c.danger, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.emergencyKeepLocked),
        ),
        if (canAfford)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: _busy ? null : _confirmBurn,
            child: Text(
              _busy ? l10n.sessionActivating : l10n.emergencyConfirmBurn,
            ),
          ),
      ],
    );
  }
}
