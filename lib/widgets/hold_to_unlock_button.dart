import 'package:flutter/material.dart';

import '../theme/tapfocus_theme.dart';

/// Ends the session only after a short hold, so unlock is a deliberate act.
class HoldToUnlockButton extends StatefulWidget {
  const HoldToUnlockButton({
    super.key,
    required this.label,
    required this.onUnlocked,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onUnlocked;
  final bool enabled;

  static const holdDuration = Duration(milliseconds: 1200);

  @override
  State<HoldToUnlockButton> createState() => _HoldToUnlockButtonState();
}

class _HoldToUnlockButtonState extends State<HoldToUnlockButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: HoldToUnlockButton.holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && widget.enabled) {
          widget.onUnlocked();
          _hold.value = 0;
        }
      });
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _start() {
    if (!widget.enabled) return;
    _hold.forward(from: 0);
  }

  void _cancel() {
    if (_hold.status == AnimationStatus.completed) return;
    _hold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _cancel(),
        onTapCancel: _cancel,
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.surfaceBorder),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _hold.value,
                      child: ColoredBox(color: c.accent.withValues(alpha: 0.35)),
                    ),
                    Center(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
