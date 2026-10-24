import '../models/app_models.dart';
import '../models/session_telemetry.dart';
import 'focus_stats.dart';
import 'session_repository.dart';

/// Peak-focus copy is withheld until this many completed sessions exist.
const int kPeakMinCompletedSessions = 5;

/// Those sessions must also fall on at least this many different local days.
const int kPeakMinDistinctDays = 3;

/// Before & after is withheld until this many post-mood check-ins exist.
const int kMoodShiftMinCheckIns = 5;

/// The vulnerability sentence is withheld until this many recorded attempts.
const int kTriggerMinInterventions = 5;

enum FocusDaypart { morning, afternoon, evening, night }

extension FocusDaypartLabel on FocusDaypart {
  String get label {
    switch (this) {
      case FocusDaypart.morning:
        return 'Morning';
      case FocusDaypart.afternoon:
        return 'Afternoon';
      case FocusDaypart.evening:
        return 'Evening';
      case FocusDaypart.night:
        return 'Night';
    }
  }

  String get windowHint {
    switch (this) {
      case FocusDaypart.morning:
        return '5:00 – 11:59';
      case FocusDaypart.afternoon:
        return '12:00 – 16:59';
      case FocusDaypart.evening:
        return '17:00 – 20:59';
      case FocusDaypart.night:
        return '21:00 – 4:59';
    }
  }

  /// Actionable coach line for the Peak Focus card.
  String get coachAdvice {
    switch (this) {
      case FocusDaypart.morning:
        return 'Morning is your superpower. Schedule your hardest deep work before noon.';
      case FocusDaypart.afternoon:
        return 'Your focus peaks after lunch. Block distractions and protect that window.';
      case FocusDaypart.evening:
        return 'Evenings are when you lock in. Guard that block from meetings and scroll traps.';
      case FocusDaypart.night:
        return 'You are a night owl. Protect your evening focus blocks.';
    }
  }

  static FocusDaypart fromHour(int hour) {
    if (hour >= 5 && hour < 12) return FocusDaypart.morning;
    if (hour >= 12 && hour < 17) return FocusDaypart.afternoon;
    if (hour >= 17 && hour < 21) return FocusDaypart.evening;
    return FocusDaypart.night;
  }
}

/// Narrative outcome for pre → post mood (presentation layer).
enum MoodShiftStory { improves, steadies, declines }

extension MoodShiftStoryCopy on MoodShiftStory {
  String get headline {
    switch (this) {
      case MoodShiftStory.improves:
        return 'Focusing improves your mood.';
      case MoodShiftStory.steadies:
        return 'Focusing steadies your emotional state.';
      case MoodShiftStory.declines:
        return 'Sessions leave you more drained — protect recovery.';
    }
  }
}

class InsightsSnapshot {
  const InsightsSnapshot({
    required this.computedAt,
    required this.sessionCount,
    required this.interventionsByQuadrant,
    required this.topTriggerQuadrant,
    required this.topTriggerInterventionCount,
    required this.interventionsLast7Days,
    required this.savedAttentionMinutes,
    required this.avgValenceDelta,
    required this.avgEnergyDelta,
    required this.postMoodSampleSize,
    required this.typicalStartMood,
    required this.typicalEndMood,
    this.typicalStartMoodLabel,
    this.typicalEndMoodLabel,
    required this.moodShiftStory,
    required this.peakFocusDaypart,
    required this.peakFocusAvgMinutes,
    required this.daypartAvgMinutes,
  });

  final DateTime computedAt;
  final int sessionCount;

  /// Card 1
  final Map<MoodQuadrant, int> interventionsByQuadrant;
  final MoodQuadrant? topTriggerQuadrant;
  final int topTriggerInterventionCount;

  /// Card 2
  final int interventionsLast7Days;
  final int savedAttentionMinutes;

  /// Card 3 (raw deltas kept for tests / analytics; UI uses narrative fields)
  final double? avgValenceDelta;
  final double? avgEnergyDelta;
  final int postMoodSampleSize;
  final MoodQuadrant? typicalStartMood;
  final MoodQuadrant? typicalEndMood;
  /// Granular Stanford adjectives when valence/energy are available.
  final String? typicalStartMoodLabel;
  final String? typicalEndMoodLabel;
  final MoodShiftStory? moodShiftStory;

  /// Card 4
  final FocusDaypart? peakFocusDaypart;
  final double peakFocusAvgMinutes;
  final Map<FocusDaypart, double> daypartAvgMinutes;

  bool get hasData => sessionCount > 0;
}

/// Async insights engine with short-lived in-memory cache.
class InsightsService {
  InsightsService({SessionRepository? repository})
      : _repository = repository ?? SessionRepository();

  final SessionRepository _repository;

  InsightsSnapshot? _cache;
  Future<InsightsSnapshot>? _inFlight;

  static const _cacheTtl = Duration(seconds: 45);
  static const minutesSavedPerIntervention = 15;

  void invalidate() {
    _cache = null;
    _inFlight = null;
  }

  Future<InsightsSnapshot> load({bool forceRefresh = false}) {
    if (!forceRefresh &&
        _cache != null &&
        DateTime.now().difference(_cache!.computedAt) < _cacheTtl) {
      return Future.value(_cache!);
    }
    if (!forceRefresh && _inFlight != null) return _inFlight!;

    _inFlight = _compute().then((snap) {
      _cache = snap;
      _inFlight = null;
      return snap;
    }).catchError((Object e) {
      _inFlight = null;
      throw e;
    });
    return _inFlight!;
  }

  Future<InsightsSnapshot> _compute() async {
    final sessions = await _repository.loadAll();
    return computeFromSessions(sessions, now: DateTime.now());
  }

  /// Pure aggregation used by the dashboard and unit tests.
  static InsightsSnapshot computeFromSessions(
    List<FocusSessionRecord> sessions, {
    DateTime? now,
  }) {
    final computedAt = now ?? DateTime.now();
    final weekAgo = computedAt.subtract(const Duration(days: 7));

    final interventionsByQuadrant = {
      for (final q in MoodQuadrant.values) q: 0,
    };
    for (final s in sessions) {
      interventionsByQuadrant[s.moodQuadrant] =
          interventionsByQuadrant[s.moodQuadrant]! + s.interventionCount;
    }

    MoodQuadrant? topTrigger;
    var topCount = -1;
    for (final entry in interventionsByQuadrant.entries) {
      if (entry.value > topCount) {
        topCount = entry.value;
        topTrigger = entry.key;
      }
    }
    if (topCount < kTriggerMinInterventions) topTrigger = null;

    final last7 = sessions.where((s) => !s.startedAt.isBefore(weekAgo));
    final interventionsLast7Days =
        last7.fold<int>(0, (sum, s) => sum + s.interventionCount);
    final savedAttentionMinutes =
        interventionsLast7Days * minutesSavedPerIntervention;

    final withPost = sessions.where((s) => s.hasPostMood).toList();
    final withAxes = withPost
        .where((s) => s.postValence != null && s.postEnergy != null)
        .toList();
    double? avgValence;
    double? avgEnergy;
    MoodQuadrant? typicalStart;
    MoodQuadrant? typicalEnd;
    String? typicalStartLabel;
    String? typicalEndLabel;
    MoodShiftStory? moodStory;
    if (withAxes.isNotEmpty) {
      final startValence = _mean(withAxes.map((s) => s.valence));
      final startEnergy = _mean(withAxes.map((s) => s.energy));
      final endValence = _mean(withAxes.map((s) => s.postValence!));
      final endEnergy = _mean(withAxes.map((s) => s.postEnergy!));
      avgValence = endValence - startValence;
      avgEnergy = endEnergy - startEnergy;

      // Headline and arrow use this same average. A modal pair is not shown
      // on its own, because it can point the opposite way from the average.
      if (withAxes.length >= kMoodShiftMinCheckIns) {
        final startV = startValence.round().clamp(-5, 5);
        final startE = startEnergy.round().clamp(-5, 5);
        final endV = endValence.round().clamp(-5, 5);
        final endE = endEnergy.round().clamp(-5, 5);
        typicalStartLabel = MoodAxes.getMoodLabel(startV, startE);
        typicalEndLabel = MoodAxes.getMoodLabel(endV, endE);
        typicalStart = _quadrantForAxes(startV, startE);
        typicalEnd = _quadrantForAxes(endV, endE);
        if (avgValence > 0.35) {
          moodStory = MoodShiftStory.improves;
        } else if (avgValence < -0.35) {
          moodStory = MoodShiftStory.declines;
        } else {
          moodStory = MoodShiftStory.steadies;
        }
      }
    }

    final daypartTotals = {for (final d in FocusDaypart.values) d: 0.0};
    final daypartCounts = {for (final d in FocusDaypart.values) d: 0};
    final peakDays = <String>{};
    for (final s in sessions) {
      if (s.completionStatus != SessionCompletionStatus.completed) continue;
      final minutes = (s.durationMinutes ?? 0).toDouble();
      if (minutes <= 0) continue;
      final part = FocusDaypartLabel.fromHour(s.startedAt.toLocal().hour);
      daypartTotals[part] = daypartTotals[part]! + minutes;
      daypartCounts[part] = daypartCounts[part]! + 1;
      final day = sessionEndDateKey(s) ?? focusLocalDateKey(s.startedAt);
      peakDays.add(day);
    }
    final daypartAvg = <FocusDaypart, double>{};
    for (final d in FocusDaypart.values) {
      final c = daypartCounts[d]!;
      daypartAvg[d] = c == 0 ? 0 : daypartTotals[d]! / c;
    }

    FocusDaypart? peak;
    var peakAvg = 0.0;
    for (final entry in daypartAvg.entries) {
      if (entry.value > peakAvg) {
        peakAvg = entry.value;
        peak = entry.key;
      }
    }
    final completedForPeak = daypartCounts.values.fold<int>(0, (a, b) => a + b);
    if (peakAvg <= 0 ||
        completedForPeak < kPeakMinCompletedSessions ||
        peakDays.length < kPeakMinDistinctDays) {
      peak = null;
    }

    return InsightsSnapshot(
      computedAt: computedAt,
      sessionCount: sessions.length,
      interventionsByQuadrant: interventionsByQuadrant,
      topTriggerQuadrant: topTrigger,
      topTriggerInterventionCount: topCount < 0 ? 0 : topCount,
      interventionsLast7Days: interventionsLast7Days,
      savedAttentionMinutes: savedAttentionMinutes,
      avgValenceDelta: avgValence,
      avgEnergyDelta: avgEnergy,
      postMoodSampleSize: withAxes.length,
      typicalStartMood: typicalStart,
      typicalEndMood: typicalEnd,
      typicalStartMoodLabel: typicalStartLabel,
      typicalEndMoodLabel: typicalEndLabel,
      moodShiftStory: moodStory,
      peakFocusDaypart: peak,
      peakFocusAvgMinutes: peakAvg,
      daypartAvgMinutes: daypartAvg,
    );
  }
}

double _mean(Iterable<int> values) {
  final list = values.toList();
  if (list.isEmpty) return 0;
  return list.reduce((a, b) => a + b) / list.length;
}

MoodQuadrant _quadrantForAxes(int valence, int energy) {
  final pleasant = valence >= 0;
  final high = energy >= 0;
  if (high && pleasant) return MoodQuadrant.yellow;
  if (high && !pleasant) return MoodQuadrant.red;
  if (!high && pleasant) return MoodQuadrant.green;
  return MoodQuadrant.blue;
}
