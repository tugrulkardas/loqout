import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapfocus_project/models/app_models.dart';
import 'package:tapfocus_project/models/session_telemetry.dart';
import 'package:tapfocus_project/services/demo_telemetry_seeder.dart';
import 'package:tapfocus_project/services/insights_service.dart';
import 'package:tapfocus_project/services/session_repository.dart';

FocusSessionRecord _session({
  required String id,
  required DateTime startedAt,
  required MoodQuadrant quadrant,
  required int interventions,
  required int durationMinutes,
  int valence = -2,
  int energy = 2,
  MoodQuadrant? postQuadrant,
  int? postValence,
  int? postEnergy,
}) {
  return FocusSessionRecord(
    id: id,
    nfcUid: 'mock:$id',
    moodQuadrant: quadrant,
    valence: valence,
    energy: energy,
    intensity: 3,
    moodX: 2,
    moodY: 2,
    blockedPackages: const ['com.instagram.android'],
    blockedAppNames: const ['Instagram'],
    startedAt: startedAt,
    endedAt: startedAt.add(Duration(minutes: durationMinutes)),
    durationMinutes: durationMinutes,
    interventionCount: interventions,
    postMoodQuadrant: postQuadrant,
    postValence: postValence,
    postEnergy: postEnergy,
    postIntensity: postQuadrant == null ? null : 3,
    completionStatus: SessionCompletionStatus.completed,
  );
}

void main() {
  group('InsightsService.computeFromSessions', () {
    final now = DateTime(2026, 8, 1, 12, 0);

    test('Card 1: Mood vs Distraction picks highest intervention quadrant', () {
      final sessions = [
        _session(
          id: 'a',
          startedAt: now.subtract(const Duration(hours: 2)),
          quadrant: MoodQuadrant.red,
          interventions: 5,
          durationMinutes: 20,
        ),
        _session(
          id: 'b',
          startedAt: now.subtract(const Duration(hours: 5)),
          quadrant: MoodQuadrant.blue,
          interventions: 2,
          durationMinutes: 15,
        ),
        _session(
          id: 'c',
          startedAt: now.subtract(const Duration(days: 1)),
          quadrant: MoodQuadrant.red,
          interventions: 3,
          durationMinutes: 30,
        ),
      ];

      final snap = InsightsService.computeFromSessions(sessions, now: now);

      expect(snap.interventionsByQuadrant[MoodQuadrant.red], 8);
      expect(snap.interventionsByQuadrant[MoodQuadrant.blue], 2);
      expect(snap.topTriggerQuadrant, MoodQuadrant.red);
      expect(snap.topTriggerInterventionCount, 8);
    });

    test('Card 2: Friction score and saved attention (×15 min)', () {
      final sessions = [
        _session(
          id: 'a',
          startedAt: now.subtract(const Duration(days: 1)),
          quadrant: MoodQuadrant.yellow,
          interventions: 4,
          durationMinutes: 25,
        ),
        _session(
          id: 'b',
          startedAt: now.subtract(const Duration(days: 2)),
          quadrant: MoodQuadrant.green,
          interventions: 2,
          durationMinutes: 40,
        ),
        // Outside 7-day window — ignored for friction card.
        _session(
          id: 'old',
          startedAt: now.subtract(const Duration(days: 10)),
          quadrant: MoodQuadrant.red,
          interventions: 99,
          durationMinutes: 10,
        ),
      ];

      final snap = InsightsService.computeFromSessions(sessions, now: now);

      expect(snap.interventionsLast7Days, 6);
      expect(
        snap.savedAttentionMinutes,
        6 * InsightsService.minutesSavedPerIntervention,
      );
      expect(snap.sessionCount, 3);
    });

    test('Card 3: Emotional delta averages post − initial mood', () {
      final sessions = [
        _session(
          id: 'a',
          startedAt: now.subtract(const Duration(hours: 3)),
          quadrant: MoodQuadrant.red,
          interventions: 1,
          durationMinutes: 30,
          valence: -3,
          energy: 3,
          postQuadrant: MoodQuadrant.green,
          postValence: 2,
          postEnergy: -1,
        ),
        _session(
          id: 'b',
          startedAt: now.subtract(const Duration(hours: 8)),
          quadrant: MoodQuadrant.blue,
          interventions: 0,
          durationMinutes: 40,
          valence: -2,
          energy: -2,
          postQuadrant: MoodQuadrant.green,
          postValence: 1,
          postEnergy: -1,
        ),
      ];

      final snap = InsightsService.computeFromSessions(sessions, now: now);

      // Valence deltas: (2 - (-3)) = 5, (1 - (-2)) = 3 → avg 4.0
      expect(snap.avgValenceDelta, closeTo(4.0, 0.001));
      // Energy deltas: (-1 - 3) = -4, (-1 - (-2)) = 1 → avg -1.5
      expect(snap.avgEnergyDelta, closeTo(-1.5, 0.001));
      expect(snap.postMoodSampleSize, 2);
      expect(snap.moodShiftStory, MoodShiftStory.improves);
      expect(snap.moodShiftStory!.headline, 'Focusing improves your mood.');
      expect(snap.typicalEndMood, MoodQuadrant.green);
      expect(snap.typicalStartMood, isNotNull);
      expect(
        snap.typicalStartMood,
        anyOf(MoodQuadrant.red, MoodQuadrant.blue),
      );
    });

    test('Card 4: Peak focus window uses longest average daypart', () {
      final sessions = [
        // Morning — long sessions
        _session(
          id: 'm1',
          startedAt: DateTime(2026, 7, 30, 9, 0),
          quadrant: MoodQuadrant.green,
          interventions: 0,
          durationMinutes: 60,
        ),
        _session(
          id: 'm2',
          startedAt: DateTime(2026, 7, 31, 8, 30),
          quadrant: MoodQuadrant.green,
          interventions: 0,
          durationMinutes: 50,
        ),
        // Afternoon — shorter
        _session(
          id: 'a1',
          startedAt: DateTime(2026, 7, 30, 14, 0),
          quadrant: MoodQuadrant.yellow,
          interventions: 1,
          durationMinutes: 20,
        ),
        // Evening — medium
        _session(
          id: 'e1',
          startedAt: DateTime(2026, 7, 29, 19, 0),
          quadrant: MoodQuadrant.blue,
          interventions: 2,
          durationMinutes: 30,
        ),
      ];

      final snap = InsightsService.computeFromSessions(sessions, now: now);

      expect(snap.peakFocusDaypart, FocusDaypart.morning);
      expect(snap.peakFocusAvgMinutes, closeTo(55.0, 0.001)); // (60+50)/2
      expect(
        snap.peakFocusDaypart!.coachAdvice,
        contains('Morning is your superpower'),
      );
      expect(snap.daypartAvgMinutes[FocusDaypart.afternoon], 20);
      expect(snap.daypartAvgMinutes[FocusDaypart.evening], 30);
    });
  });

  group('DemoTelemetrySeeder', () {
    test('buildSevenDayDemo yields 12 sessions across quadrants and dayparts',
        () {
      final now = DateTime(2026, 8, 1, 12);
      final sessions = DemoTelemetrySeeder.buildSevenDayDemo(now: now);

      expect(sessions.length, 12);
      expect(
        sessions.every((s) => SessionRepository.isDemoSessionId(s.id)),
        isTrue,
      );

      final quadrants = sessions.map((s) => s.moodQuadrant).toSet();
      expect(quadrants.length, greaterThanOrEqualTo(3));

      final hours = sessions.map((s) => s.startedAt.hour).toSet();
      expect(hours.any((h) => h >= 5 && h < 12), isTrue); // morning
      expect(hours.any((h) => h >= 12 && h < 17), isTrue); // afternoon
      expect(hours.any((h) => h >= 17), isTrue); // evening+

      expect(sessions.any((s) => s.interventionCount == 0), isTrue);
      expect(sessions.any((s) => s.interventionCount >= 3), isTrue);
      expect(sessions.every((s) => s.hasPostMood), isTrue);

      // Positive ROI tilt on average valence delta.
      final snap = InsightsService.computeFromSessions(sessions, now: now);
      expect(snap.hasData, isTrue);
      expect(snap.avgValenceDelta, isNotNull);
      expect(snap.avgValenceDelta! > 0, isTrue);
      expect(snap.peakFocusDaypart, isNotNull);
    });

    test('seed + clear only touch demo rows in local storage', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = SessionRepository();
      final seeder = DemoTelemetrySeeder(repository: repo);

      // Real user session must survive clear.
      await repo.upsertLocal(
        _session(
          id: 'real_user_1',
          startedAt: DateTime(2026, 8, 1, 10),
          quadrant: MoodQuadrant.green,
          interventions: 0,
          durationMinutes: 15,
        ),
      );

      final seeded = await seeder.seedSevenDayDemo(now: DateTime(2026, 8, 1));
      expect(seeded, 12);

      var all = await repo.loadAll();
      expect(all.length, 13);
      expect(all.where((s) => SessionRepository.isDemoSessionId(s.id)).length, 12);

      final removed = await seeder.clearDemoData();
      expect(removed, 12);

      all = await repo.loadAll();
      expect(all.length, 1);
      expect(all.first.id, 'real_user_1');
    });
  });
}
