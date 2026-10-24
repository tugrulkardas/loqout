import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tapfocus_theme.dart';

/// Circular progress around the live session clock.
///
/// [progress] is clamped here as well as by the caller, so a session past
/// the streak threshold cannot draw more than one turn.
class StreakProgressRing extends StatelessWidget {
  const StreakProgressRing({
    super.key,
    required this.progress,
    required this.timeLabel,
    required this.caption,
    required this.semanticsLabel,
    required this.diameter,
    this.reached = false,
  });

  final double progress;
  final String timeLabel;
  final String caption;
  final String semanticsLabel;
  final double diameter;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final fraction = progress.clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: diameter,
              height: diameter,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: fraction,
                  track: c.textMuted.withValues(alpha: 0.28),
                  value: c.accent,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        timeLabel,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: reached ? c.textPrimary : c.textSecondary,
                fontWeight: reached ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.value,
  });

  final double progress;
  final Color track;
  final Color value;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 7.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, base);

    if (progress <= 0) return;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = progress >= 1 ? StrokeCap.butt : StrokeCap.round
      ..color = value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.track != track ||
        oldDelegate.value != value;
  }
}
