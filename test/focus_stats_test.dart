import 'package:flutter_test/flutter_test.dart';
import 'package:tapfocus_project/models/app_models.dart';
import 'package:tapfocus_project/models/session_telemetry.dart';
import 'package:tapfocus_project/services/focus_stats.dart';
import 'package:tapfocus_project/services/intervention_counts.dart';

FocusSessionRecord _ended({
  required String id,
  required String localEndDate,
  required int minutes,
  SessionCompletionStatus status = SessionCompletionStatus.completed,
}) {
  return FocusSessionRecord(
    id: id,
    nfcUid: 'mock:$id',
    moodQuadrant: MoodQuadrant.green,
    valence: 1,
    energy: 1,
    intensity: 2,
    moodX: 6,
    moodY: 3,
    blockedPackages: const ['com.instagram.android'],
    blockedAppNames: const ['Instagram'],
    startedAt: DateTime(2026, 10, 23, 23, 40),
    endedAt: DateTime(2026, 10, 24, 0, 10),
    localEndDate: localEndDate,
    durationMinutes: minutes,
    completionStatus: status,
  );
}

void main() {
  final now = DateTime(2026, 10, 24, 18);

  test('a session that crosses midnight counts on its end date', () {
    final stats = FocusStats.fromSessions(
      [
        _ended(id: 'night', localEndDate: '2026-10-24', minutes: 12),
      ],
      now: now,
    );

    expect(focusLocalDateKey(DateTime(2026, 10, 24, 0, 10)), '2026-10-24');
    expect(stats.todayFocusMinutes, 12);
    expect(stats.streakDays, 1);
  });

  test('streak needs 10 completed minutes and ignores early exits', () {
    final stats = FocusStats.fromSessions(
      [
        _ended(id: 'short', localEndDate: '2026-10-24', minutes: 9),
        _ended(
          id: 'bail',
          localEndDate: '2026-10-24',
          minutes: 4,
          status: SessionCompletionStatus.earlyExit,
        ),
        _ended(id: 'yesterday', localEndDate: '2026-10-23', minutes: 10),
        _ended(id: 'also', localEndDate: '2026-10-22', minutes: 6),
        _ended(id: 'also2', localEndDate: '2026-10-22', minutes: 6),
      ],
      now: now,
    );

    expect(stats.todayCompletedMinutes, 9);
    expect(stats.todayFocusMinutes, 13);
    expect(stats.streakDays, 2);
    expect(kStreakMinimumFocusMinutes, 10);
  });

  test('today not finished yet does not erase yesterday', () {
    final stats = FocusStats.fromSessions(
      [
        _ended(id: 'yesterday', localEndDate: '2026-10-23', minutes: 15),
      ],
      now: now,
    );
    expect(stats.streakDays, 1);
    expect(
      streakEffectOfEnding(
        elapsedMinutes: 4,
        todayCompletedMinutes: stats.todayCompletedMinutes,
        countsAsCompleted: false,
      ),
      StreakEndEffect.doesNotCountToday,
    );
    expect(
      streakEffectOfEnding(
        elapsedMinutes: 10,
        todayCompletedMinutes: 0,
        countsAsCompleted: true,
      ),
      StreakEndEffect.keepsToday,
    );
  });

  test('ring fills toward the streak threshold and stays full past it', () {
    final under = streakRingState(todayCompletedMinutes: 6, elapsedMinutes: 2);
    expect(under.reached, isFalse);
    expect(under.minutesRemaining, 2);
    expect(under.fraction, closeTo(0.8, 0.001));

    final partial = streakRingState(todayCompletedMinutes: 0, elapsedMinutes: 0.5);
    expect(partial.minutesRemaining, 10);
    expect(partial.fraction, closeTo(0.05, 0.001));

    final over = streakRingState(todayCompletedMinutes: 0, elapsedMinutes: 25);
    expect(over.reached, isTrue);
    expect(over.fraction, 1);
    expect(over.minutesRemaining, 0);
  });

  test('week strip is Monday through Sunday and only fills completed days', () {
    final stats = FocusStats.fromSessions(
      [
        _ended(id: 'thu', localEndDate: '2026-10-22', minutes: 10),
        _ended(id: 'short', localEndDate: '2026-10-23', minutes: 9),
      ],
      now: now,
    );

    expect(DateTime(2026, 10, 24).weekday, DateTime.saturday);
    expect(stats.weekCompleted, [
      false,
      false,
      false,
      true,
      false,
      false,
      false,
    ]);
    expect(const FocusStats.empty().isFreshRecord, isTrue);
    expect(stats.isFreshRecord, isFalse);
  });

  test('reclaimed day percent stays visible under one percent', () {
    expect(
      formatReclaimedDayPercent(
        focusMinutes: 0,
        wakingMinutes: kWakingMinutesPerDay,
      ),
      '0.0',
    );
    expect(
      formatReclaimedDayPercent(
        focusMinutes: 37 / 60,
        wakingMinutes: kWakingMinutesPerDay,
      ),
      '0.1',
    );
    expect(
      formatReclaimedDayPercent(
        focusMinutes: 10,
        wakingMinutes: kWakingMinutesPerDay,
      ),
      '1',
    );
    expect(
      formatReclaimedDayPercent(
        focusMinutes: 20 * 60,
        wakingMinutes: kWakingMinutesPerDay,
      ),
      '100',
    );
  });

  test('per-app attempt json keeps positive counts only', () {
    expect(decodeInterventionCounts(null), isEmpty);
    expect(
      decodeInterventionCounts('{"com.instagram.android":3,"com.x":0}'),
      {'com.instagram.android': 3},
    );
    expect(decodeInterventionCounts('not-json'), isEmpty);
  });

  test('focus share is capped waking time inside LoqOut', () {
    expect(kWakingMinutesPerDay, 16 * 60);
    expect(
      focusSharePercent(focusMinutes: 96, wakingMinutes: kWakingMinutesPerDay),
      10,
    );
    expect(
      focusSharePercent(focusMinutes: 1, wakingMinutes: kWakingMinutesPerDay),
      0,
    );
    expect(
      focusSharePercent(
        focusMinutes: 20 * 60,
        wakingMinutes: kWakingMinutesPerDay,
      ),
      100,
    );
    expect(
      focusSharePercent(
        focusMinutes: 96,
        wakingMinutes: kWakingMinutesPerDay * 7,
      ),
      1,
    );
  });

  test('all-time focus keeps short sessions and today counts stored attempts', () {
    final stats = FocusStats.fromSessions(
      [
        _ended(id: 'done', localEndDate: '2026-10-24', minutes: 20),
        _ended(
          id: 'bail',
          localEndDate: '2026-10-20',
          minutes: 4,
          status: SessionCompletionStatus.earlyExit,
        ),
      ],
      now: now,
    );
    expect(stats.allTimeFocusMinutes, 24);
    expect(stats.todayFocusMinutes, 20);
    expect(stats.weekCompletedMinutes, 20);
    expect(stats.todayAttemptCount, 0);
  });

  test('clock stays numeric', () {
    expect(formatFocusClock(const Duration(minutes: 4, seconds: 2)), '04:02');
    expect(formatFocusClock(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });
}
