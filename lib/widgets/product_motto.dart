import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../theme/tapfocus_theme.dart';

/// Product motto — italic amber quote, wraps for longer Turkish copy.
class ProductMotto extends StatelessWidget {
  const ProductMotto({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      context.l10n.productMotto,
      textAlign: TextAlign.center,
      softWrap: true,
      style: TextStyle(
        fontSize: compact ? 12 : 13.5,
        height: 1.4,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: c.accent,
      ),
    );
  }
}
