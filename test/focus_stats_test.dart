import 'package:flutter_test/flutter_test.dart';
import 'package:tapfocus_project/models/app_models.dart';
import 'package:tapfocus_project/models/session_telemetry.dart';
import 'package:tapfocus_project/services/focus_stats.dart';

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

  test('clock stays numeric', () {
    expect(formatFocusClock(const Duration(minutes: 4, seconds: 2)), '04:02');
    expect(formatFocusClock(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });
}
