import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tapfocus_theme.dart';

/// Ends the session only after a short hold, so unlock is a deliberate act.
///
/// VoiceOver and TalkBack activate [onUnlocked] with a double-tap. When the
/// system reports accessible navigation, a separate button is also shown.
class HoldToUnlockButton extends StatefulWidget {
  const HoldToUnlockButton({
    super.key,
    required this.label,
    required this.onUnlocked,
    required this.semanticsHint,
    required this.accessibleLabel,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onUnlocked;
  final String semanticsHint;
  final String accessibleLabel;
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
    _hold = AnimationController(
      vsync: this,
      duration: HoldToUnlockButton.holdDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && widget.enabled) {
          HapticFeedback.mediumImpact();
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
    _hold.duration = HoldToUnlockButton.holdDuration;
    HapticFeedback.lightImpact();
    _hold.forward();
  }

  void _cancel() {
    if (_hold.value == 0 || _hold.status == AnimationStatus.completed) return;
    _hold.animateBack(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _activateFromAccessibility() {
    if (!widget.enabled) return;
    HapticFeedback.mediumImpact();
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final showAlternative = MediaQuery.of(context).accessibleNavigation;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          enabled: widget.enabled,
          label: widget.label,
          hint: widget.semanticsHint,
          onTap: widget.enabled ? _activateFromAccessibility : null,
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.enabled ? (_) => _start() : null,
              onTapUp: (_) => _cancel(),
              onTapCancel: _cancel,
              child: AnimatedBuilder(
                animation: _hold,
                builder: (context, _) {
                  final t = _hold.value.clamp(0.0, 1.0);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 52,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          Widget labelOn(Color color) {
                            return Center(
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }

                          final fillWidth = constraints.maxWidth * t;
                          return DecoratedBox(
                            decoration: BoxDecoration(color: c.surface),
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                if (fillWidth > 0)
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: fillWidth,
                                    child: ColoredBox(color: c.accent),
                                  ),
                                Positioned.fill(child: labelOn(c.textPrimary)),
                                if (fillWidth > 0)
                                  ClipRect(
                                    child: SizedBox(
                                      width: fillWidth,
                                      height: constraints.maxHeight,
                                      child: OverflowBox(
                                        alignment: Alignment.centerLeft,
                                        minWidth: constraints.maxWidth,
                                        maxWidth: constraints.maxWidth,
                                        minHeight: constraints.maxHeight,
                                        maxHeight: constraints.maxHeight,
                                        child: labelOn(c.onAccent),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (showAlternative)
          TextButton(
            onPressed: widget.enabled ? _activateFromAccessibility : null,
            child: Text(widget.accessibleLabel),
          ),
      ],
    );
  }
}
