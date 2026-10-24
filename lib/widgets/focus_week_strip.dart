import 'package:flutter/material.dart';

import '../theme/tapfocus_theme.dart';

/// Monday-first week. Completed days are filled; today is outlined.
/// Decorative: the parent supplies the spoken summary.
class FocusWeekStrip extends StatelessWidget {
  const FocusWeekStrip({
    super.key,
    required this.completed,
    required this.todayIndex,
  });

  /// Seven marks, Monday at index 0.
  final List<bool> completed;

  /// 0 = Monday ... 6 = Sunday.
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final material = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final marks = completed.length == 7
        ? completed
        : const [false, false, false, false, false, false, false];
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 7; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DayDot(
                    filled: marks[i],
                    isToday: i == todayIndex,
                    color: c.accent,
                    track: c.textMuted.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _narrowWeekday(material, i + 1),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i == todayIndex ? c.textPrimary : c.textMuted,
                      fontWeight:
                          i == todayIndex ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// [weekday] uses [DateTime.weekday] (Monday = 1). Material narrow names
/// start on Sunday.
String _narrowWeekday(MaterialLocalizations material, int weekday) {
  return material.narrowWeekdays[weekday % 7];
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.filled,
    required this.isToday,
    required this.color,
    required this.track,
  });

  final bool filled;
  final bool isToday;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : Colors.transparent,
          border: filled ? null : Border.all(color: track),
        ),
      ),
    );
  }
}
