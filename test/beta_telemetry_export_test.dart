import 'package:flutter_test/flutter_test.dart';
import 'package:tapfocus_project/models/app_models.dart';
import 'package:tapfocus_project/models/session_telemetry.dart';
import 'package:tapfocus_project/services/beta_telemetry_export.dart';

void main() {
  group('BetaTelemetryExport.sessionsToCsv', () {
    test('includes headers and escapes commas in package list', () {
      final session = FocusSessionRecord(
        id: 'sess_1',
        nfcUid: 'qr:tapfocus_beta_auth',
        moodQuadrant: MoodQuadrant.red,
        valence: -3,
        energy: 2,
        intensity: 3,
        moodX: 1,
        moodY: 2,
        blockedPackages: const ['com.foo,bar', 'com.baz'],
        blockedAppNames: const ['Foo'],
        startedAt: DateTime.utc(2026, 9, 1, 10),
        endedAt: DateTime.utc(2026, 9, 1, 10, 25),
        interventionCount: 2,
        postValence: 2,
        postEnergy: 1,
        postIntensity: 2,
        postMoodQuadrant: MoodQuadrant.yellow,
        durationMinutes: 25,
        scheduledMinutes: 30,
      );

      final csv = BetaTelemetryExport.sessionsToCsv([session]);
      final lines = csv.trimRight().split('\n');

      expect(lines.first, BetaTelemetryExport.csvHeaders.join(','));
      expect(lines, hasLength(2));
      expect(lines[1], contains('sess_1'));
      expect(lines[1], contains(',-3,'));
      expect(lines[1], contains(',2,'));
      expect(lines[1], contains('"com.foo,bar|com.baz"'));
      expect(csv, contains('session_start'));
      expect(csv, contains('ending_valence'));
      expect(csv, contains('interventions_count'));
    });

    test('empty list still emits header row', () {
      final csv = BetaTelemetryExport.sessionsToCsv(const []);
      expect(csv.trimRight(), BetaTelemetryExport.csvHeaders.join(','));
    });
  });
}
