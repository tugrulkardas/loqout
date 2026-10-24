import '../models/session_telemetry.dart';

/// A local day counts toward the streak only when completed focus on that
/// day reaches this many minutes. Early exits do not count.
///
/// One constant so the rule can be changed in a single place.
const int kStreakMinimumFocusMinutes = 10;

/// Calendar date of [instant] in the device timezone, `yyyy-MM-dd`.
///
/// A session that crosses midnight is attributed to the day it ends, not the
/// day it started. Call this once when the session ends and store the result.
/// Reading [DateTime.toLocal] again later would move the day if the timezone
/// changes.
String focusLocalDateKey(DateTime instant) {
  final local = instant.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String? _previousDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  final date = DateTime(year, month, day).subtract(const Duration(days: 1));
  return focusLocalDateKey(DateTime(date.year, date.month, date.day, 12));
}

/// End date frozen at unlock, or the local end time for older records.
String? sessionEndDateKey(FocusSessionRecord session) {
  final stored = session.localEndDate;
  if (stored != null && stored.isNotEmpty) return stored;
  final ended = session.endedAt;
  if (ended == null) return null;
  return focusLocalDateKey(ended);
}

/// Focus minutes already saved on the phone. Not screen time, and not the
/// intervention estimate.
class FocusStats {
  const FocusStats({
    required this.todayFocusMinutes,
    required this.weekFocusMinutes,
    required this.streakDays,
    required this.todayCompletedMinutes,
  });

  const FocusStats.empty()
      : todayFocusMinutes = 0,
        weekFocusMinutes = 0,
        streakDays = 0,
        todayCompletedMinutes = 0;

  /// All saved focus minutes whose end date is today, including short sessions.
  final int todayFocusMinutes;

  /// Completed minutes today. This is what the streak rule uses.
  final int todayCompletedMinutes;

  /// Saved focus minutes ending in the last 7 local days, including today.
  final int weekFocusMinutes;

  /// Consecutive local days, ending today or yesterday, with at least
  /// [kStreakMinimumFocusMinutes] of completed focus.
  final int streakDays;

  static FocusStats fromSessions(
    List<FocusSessionRecord> sessions, {
    DateTime? now,
  }) {
    final today = focusLocalDateKey(now ?? DateTime.now());
    final weekKeys = <String>{today};
    var cursor = today;
    for (var i = 0; i < 6; i++) {
      final previous = _previousDateKey(cursor);
      if (previous == null) break;
      weekKeys.add(previous);
      cursor = previous;
    }

    final completedByDay = <String, int>{};
    var todayFocus = 0;
    var weekFocus = 0;

    for (final session in sessions) {
      final key = sessionEndDateKey(session);
      final minutes = session.durationMinutes ?? 0;
      if (key == null || minutes <= 0) continue;
      if (key == today) todayFocus += minutes;
      if (weekKeys.contains(key)) weekFocus += minutes;
      if (session.completionStatus != SessionCompletionStatus.completed) {
        continue;
      }
      completedByDay[key] = (completedByDay[key] ?? 0) + minutes;
    }

    return FocusStats(
      todayFocusMinutes: todayFocus,
      weekFocusMinutes: weekFocus,
      streakDays: _streakEndingAt(today, completedByDay),
      todayCompletedMinutes: completedByDay[today] ?? 0,
    );
  }
}

int _streakEndingAt(String today, Map<String, int> completedByDay) {
  var cursor = (completedByDay[today] ?? 0) >= kStreakMinimumFocusMinutes
      ? today
      : _previousDateKey(today);
  var days = 0;
  while (cursor != null &&
      (completedByDay[cursor] ?? 0) >= kStreakMinimumFocusMinutes) {
    days++;
    cursor = _previousDateKey(cursor);
  }
  return days;
}

enum StreakEndEffect { keepsToday, doesNotCountToday, alreadyCounted }

/// What a normal unlock would do to today's streak. Emergency exits never add
/// completed minutes.
StreakEndEffect streakEffectOfEnding({
  required int elapsedMinutes,
  required int todayCompletedMinutes,
  required bool countsAsCompleted,
}) {
  if (todayCompletedMinutes >= kStreakMinimumFocusMinutes) {
    return StreakEndEffect.alreadyCounted;
  }
  if (countsAsCompleted &&
      todayCompletedMinutes + elapsedMinutes >= kStreakMinimumFocusMinutes) {
    return StreakEndEffect.keepsToday;
  }
  return StreakEndEffect.doesNotCountToday;
}

String formatFocusClock(Duration elapsed) {
  final safe = elapsed.isNegative ? Duration.zero : elapsed;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) return '$hours:$minutes:$seconds';
  return '$minutes:$seconds';
}
