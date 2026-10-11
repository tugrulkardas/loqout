import 'package:flutter_test/flutter_test.dart';
import 'package:tapfocus_project/models/app_models.dart';
import 'package:tapfocus_project/models/session_telemetry.dart';

void main() {
  group('MoodAxes / Mood Matrix mapping', () {
    test('maps corners to valence and energy extremes (-5..+5)', () {
      expect(MoodAxes.valenceFromX(0), -5);
      expect(MoodAxes.valenceFromX(9), 5);
      expect(MoodAxes.energyFromY(0), 5); // top = high energy
      expect(MoodAxes.energyFromY(9), -5); // bottom = low energy
    });

    test('maps center cells near neutral axes', () {
      expect(MoodAxes.valenceFromX(4).abs(), lessThanOrEqualTo(1));
      expect(MoodAxes.valenceFromX(5).abs(), lessThanOrEqualTo(1));
      expect(MoodAxes.energyFromY(4).abs(), lessThanOrEqualTo(1));
      expect(MoodAxes.energyFromY(5).abs(), lessThanOrEqualTo(1));
    });

    test('quadrant zones match Stanford Mood Meter layout', () {
      // High energy / unpleasant → red (anxious)
      expect(MoodAxes.quadrantFromCell(1, 1), MoodQuadrant.red);
      // High energy / pleasant → yellow (excited)
      expect(MoodAxes.quadrantFromCell(8, 1), MoodQuadrant.yellow);
      // Low energy / unpleasant → blue (bored)
      expect(MoodAxes.quadrantFromCell(1, 8), MoodQuadrant.blue);
      // Low energy / pleasant → green (calm)
      expect(MoodAxes.quadrantFromCell(8, 8), MoodQuadrant.green);
    });

    test('every grid cell maps to a valid quadrant without leakage', () {
      const gridSize = 10;
      for (var y = 0; y < gridSize; y++) {
        for (var x = 0; x < gridSize; x++) {
          final q = MoodAxes.quadrantFromCell(x, y, gridSize: gridSize);
          expect(MoodQuadrant.values.contains(q), isTrue);

          final valence = MoodAxes.valenceFromX(x, gridSize: gridSize);
          final energy = MoodAxes.energyFromY(y, gridSize: gridSize);
          expect(valence, inInclusiveRange(-5, 5));
          expect(energy, inInclusiveRange(-5, 5));

          // Axis signs must agree with quadrant descriptors.
          if (q == MoodQuadrant.red || q == MoodQuadrant.yellow) {
            expect(energy, greaterThanOrEqualTo(0));
          }
          if (q == MoodQuadrant.blue || q == MoodQuadrant.green) {
            expect(energy, lessThanOrEqualTo(0));
          }
          if (q == MoodQuadrant.yellow || q == MoodQuadrant.green) {
            expect(valence, greaterThanOrEqualTo(0));
          }
          if (q == MoodQuadrant.red || q == MoodQuadrant.blue) {
            expect(valence, lessThanOrEqualTo(0));
          }
        }
      }
    });

    test('9x9 grid also stays within valence/energy bounds', () {
      const gridSize = 9;
      for (var y = 0; y < gridSize; y++) {
        for (var x = 0; x < gridSize; x++) {
          expect(
            MoodAxes.valenceFromX(x, gridSize: gridSize),
            inInclusiveRange(-5, 5),
          );
          expect(
            MoodAxes.energyFromY(y, gridSize: gridSize),
            inInclusiveRange(-5, 5),
          );
          expect(
            MoodAxes.quadrantFromCell(x, y, gridSize: gridSize),
            isA<MoodQuadrant>(),
          );
        }
      }
    });
  });
}
