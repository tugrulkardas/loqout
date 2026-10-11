import 'package:flutter_test/flutter_test.dart';
import 'package:tapfocus_project/models/session_telemetry.dart';

void main() {
  group('MoodAxes.getMoodLabel', () {
    test('maps high-negative energy edge adjectives', () {
      expect(MoodAxes.getMoodLabel(-5, 5), 'Enraged');
      expect(MoodAxes.getMoodLabel(-3, 4), 'Furious');
      expect(MoodAxes.getMoodLabel(-2, 5), 'Panicked');
    });

    test('maps mid-negative energy adjectives', () {
      expect(MoodAxes.getMoodLabel(-5, 2), 'Stressed');
      expect(MoodAxes.getMoodLabel(-3, 1), 'Frustrated');
      expect(MoodAxes.getMoodLabel(-2, 2), 'Annoyed');
    });

    test('maps low-negative energy edge adjectives', () {
      expect(MoodAxes.getMoodLabel(-5, -5), 'Despair');
      expect(MoodAxes.getMoodLabel(-3, -4), 'Depressed');
      expect(MoodAxes.getMoodLabel(-2, -5), 'Exhausted');
    });

    test('maps high-positive energy edge adjectives', () {
      expect(MoodAxes.getMoodLabel(5, 5), 'Ecstatic');
      expect(MoodAxes.getMoodLabel(3, 4), 'Thrilled');
      expect(MoodAxes.getMoodLabel(2, 5), 'Energized');
    });

    test('maps mid-positive energy adjectives', () {
      expect(MoodAxes.getMoodLabel(5, 2), 'Happy');
      expect(MoodAxes.getMoodLabel(3, 1), 'Productive');
      expect(MoodAxes.getMoodLabel(2, 2), 'Focused');
    });

    test('maps low-positive energy edge adjectives', () {
      expect(MoodAxes.getMoodLabel(5, -5), 'Serene');
      expect(MoodAxes.getMoodLabel(3, -4), 'Peaceful');
      expect(MoodAxes.getMoodLabel(2, -5), 'Chill');
    });

    test('neutral center stays Neutral', () {
      expect(MoodAxes.getMoodLabel(0, 0), 'Neutral');
      expect(MoodAxes.getMoodLabel(1, -1), 'Neutral');
    });

    test('cell mapping uses valence/energy transform', () {
      // Top-left cell → high energy, negative valence
      expect(
        MoodAxes.getMoodLabelFromCell(0, 0, gridSize: 10),
        isNot(equals(MoodAxes.getMoodLabelFromCell(9, 9, gridSize: 10))),
      );
    });
  });
}
