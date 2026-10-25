import '../models/session_telemetry.dart';

/// A local day counts toward the streak only when completed focus on that
/// day reaches this many minutes. Early exits do not count.
///
/// One constant so the rule can be changed in a single place.
const int kStreakMinimumFocusMinutes = 10;

/// Assumed waking day. LoqOut does not store a sleep schedule, so the
/// focus-share line uses this instead of a personal wake time.
/// 16 hours. Not screen time and not phone time.
const int kWakingMinutesPerDay = 16 * 60;

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
    required this.weekCompletedMinutes,
    required this.allTimeFocusMinutes,
    required this.todayAttemptCount,
    required this.weekCompleted,
  });

  const FocusStats.empty()
      : todayFocusMinutes = 0,
        weekFocusMinutes = 0,
        streakDays = 0,
        todayCompletedMinutes = 0,
        weekCompletedMinutes = 0,
        allTimeFocusMinutes = 0,
        todayAttemptCount = 0,
        weekCompleted = const [false, false, false, false, false, false, false];

  /// All saved focus minutes whose end date is today, including short sessions.
  final int todayFocusMinutes;

  /// Completed minutes today. This is what the streak rule uses.
  final int todayCompletedMinutes;

  /// Completed minutes whose end date is in the last 7 local days.
  /// The weekly focus-share line uses this, not [weekFocusMinutes].
  final int weekCompletedMinutes;

  /// Every saved focus minute on the device, including short sessions.
  final int allTimeFocusMinutes;

  /// Blocked-app attempts already stored on sessions that ended today.
  /// Android writes these. iOS sessions stay at 0 because attempts are not measured.
  final int todayAttemptCount;

  /// Saved focus minutes ending in the last 7 local days, including today.
  final int weekFocusMinutes;

  /// Consecutive local days, ending today or yesterday, with at least
  /// [kStreakMinimumFocusMinutes] of completed focus.
  final int streakDays;

  /// Monday-through-Sunday marks for the calendar week containing today.
  /// A day is true only when completed focus that day reaches
  /// [kStreakMinimumFocusMinutes].
  final List<bool> weekCompleted;

  /// Nothing saved this week and no live streak. The lock screen uses this
  /// for the "start today" empty state.
  bool get isFreshRecord =>
      streakDays == 0 && weekFocusMinutes == 0 && todayFocusMinutes == 0;

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
    var weekCompleted = 0;
    var allTime = 0;
    var todayAttempts = 0;

    for (final session in sessions) {
      final key = sessionEndDateKey(session);
      final minutes = session.durationMinutes ?? 0;
      if (key == today) todayAttempts += session.interventionCount;
      if (minutes <= 0) continue;
      allTime += minutes;
      if (key == null) continue;
      if (key == today) todayFocus += minutes;
      if (weekKeys.contains(key)) weekFocus += minutes;
      if (session.completionStatus != SessionCompletionStatus.completed) {
        continue;
      }
      completedByDay[key] = (completedByDay[key] ?? 0) + minutes;
      if (weekKeys.contains(key)) weekCompleted += minutes;
    }

    return FocusStats(
      todayFocusMinutes: todayFocus,
      weekFocusMinutes: weekFocus,
      streakDays: _streakEndingAt(today, completedByDay),
      todayCompletedMinutes: completedByDay[today] ?? 0,
      weekCompletedMinutes: weekCompleted,
      allTimeFocusMinutes: allTime,
      todayAttemptCount: todayAttempts,
      weekCompleted: _calendarWeekCompleted(now ?? DateTime.now(), completedByDay),
    );
  }
}

List<bool> _calendarWeekCompleted(
  DateTime now,
  Map<String, int> completedByDay,
) {
  final local = now.toLocal();
  final today = DateTime(local.year, local.month, local.day);
  final monday = today.subtract(Duration(days: today.weekday - DateTime.monday));
  return [
    for (var i = 0; i < 7; i++)
      (completedByDay[focusLocalDateKey(monday.add(Duration(days: i)))] ?? 0) >=
          kStreakMinimumFocusMinutes,
  ];
}

/// Live progress toward today's streak threshold. [fraction] stays in 0...1.
class StreakRingState {
  const StreakRingState({
    required this.fraction,
    required this.minutesRemaining,
    required this.reached,
  });

  final double fraction;
  final int minutesRemaining;
  final bool reached;
}

/// Lock-screen day share, including the open session from the first second.
///
/// Under 1% uses one decimal. Any positive share that would show as 0.0 is
/// raised to 0.1 so a short session does not look like zero. At or above 1%
/// the value is a whole number, capped at 100. This is LoqOut focus time
/// against [kWakingMinutesPerDay], not screen time.
String formatReclaimedDayPercent({
  required double focusMinutes,
  required int wakingMinutes,
}) {
  if (wakingMinutes <= 0 || focusMinutes <= 0) return '0.0';
  final percent = (focusMinutes * 100) / wakingMinutes;
  if (percent >= 100) return '100';
  if (percent < 1) {
    final tenths = (percent * 10).ceil().clamp(1, 9);
    return (tenths / 10).toStringAsFixed(1);
  }
  final rounded = percent.round().clamp(1, 99);
  return '$rounded';
}

/// Percent of waking time spent in LoqOut focus, rounded and capped at 100.
///
/// [focusMinutes] is completed focus in the window, plus the open session
/// only after that session has reached 2 minutes. [wakingMinutes] is
/// [kWakingMinutesPerDay] for today, or seven times that for the week.
/// This is focus time inside LoqOut. It is not screen time or phone time.
int focusSharePercent({
  required int focusMinutes,
  required int wakingMinutes,
}) {
  if (wakingMinutes <= 0 || focusMinutes <= 0) return 0;
  final percent = ((focusMinutes * 100) / wakingMinutes).round();
  if (percent < 0) return 0;
  if (percent > 100) return 100;
  return percent;
}

/// [elapsedMinutes] is wall-clock time in the open session. Past the
/// threshold the fraction stays at 1 instead of wrapping.
StreakRingState streakRingState({
  required int todayCompletedMinutes,
  required double elapsedMinutes,
}) {
  final threshold = kStreakMinimumFocusMinutes;
  if (threshold <= 0) {
    return const StreakRingState(fraction: 1, minutesRemaining: 0, reached: true);
  }
  final toward = todayCompletedMinutes + (elapsedMinutes < 0 ? 0 : elapsedMinutes);
  final deficit = threshold - toward;
  final reached = deficit <= 0;
  return StreakRingState(
    fraction: (toward / threshold).clamp(0.0, 1.0),
    minutesRemaining: reached ? 0 : deficit.ceil(),
    reached: reached,
  );
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
