import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../models/app_models.dart';
import '../theme/tapfocus_theme.dart';

/// Lightweight ~3s post-session mood check-in (4-quadrant tap).
class PostSessionMoodPrompt extends StatefulWidget {
  const PostSessionMoodPrompt({super.key});

  static Future<MoodSelection?> show(BuildContext context) {
    return showDialog<MoodSelection>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PostSessionMoodPrompt(),
    );
  }

  @override
  State<PostSessionMoodPrompt> createState() => _PostSessionMoodPromptState();
}

class MoodSelection {
  const MoodSelection({
    required this.quadrant,
    required this.valence,
    required this.energy,
    required this.intensity,
  });

  final MoodQuadrant quadrant;
  final int valence;
  final int energy;
  final int intensity;
}

String _checkInLabel(AppLocalizations l10n, MoodQuadrant quadrant) {
  switch (quadrant) {
    case MoodQuadrant.red:
      return l10n.checkInStressedFrustrated;
    case MoodQuadrant.blue:
      return l10n.checkInDrainedDistracted;
    case MoodQuadrant.green:
      return l10n.checkInCalmFocused;
    case MoodQuadrant.yellow:
      return l10n.checkInEnergizedProductive;
  }
}

class _PostSessionMoodPromptState extends State<PostSessionMoodPrompt> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.postSessionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.postSessionPrompt,
            style: TextStyle(
              fontSize: 14,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in MoodQuadrant.values)
                _MoodChip(
                  quadrant: q,
                  label: _checkInLabel(l10n, q),
                  onTap: () {
                    // Representative valence/energy for the quadrant center.
                    final valence =
                        q == MoodQuadrant.yellow || q == MoodQuadrant.green
                            ? 3
                            : -3;
                    final energy =
                        q == MoodQuadrant.red || q == MoodQuadrant.yellow
                            ? 3
                            : -3;
                    Navigator.of(context).pop(
                      MoodSelection(
                        quadrant: q,
                        valence: valence,
                        energy: energy,
                        intensity: 3,
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.postSessionSkip),
        ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.quadrant,
    required this.label,
    required this.onTap,
  });

  final MoodQuadrant quadrant;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: quadrant.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: quadrant.color.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: quadrant.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
