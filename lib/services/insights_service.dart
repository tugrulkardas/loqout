import '../models/app_models.dart';
import '../models/session_telemetry.dart';
import 'session_repository.dart';

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
    if (topCount <= 0) topTrigger = null;

    final last7 = sessions.where((s) => !s.startedAt.isBefore(weekAgo));
    final interventionsLast7Days =
        last7.fold<int>(0, (sum, s) => sum + s.interventionCount);
    final savedAttentionMinutes =
        interventionsLast7Days * minutesSavedPerIntervention;

    final withPost = sessions.where((s) => s.hasPostMood).toList();
    double? avgValence;
    double? avgEnergy;
    MoodQuadrant? typicalStart;
    MoodQuadrant? typicalEnd;
    String? typicalStartLabel;
    String? typicalEndLabel;
    MoodShiftStory? moodStory;
    if (withPost.isNotEmpty) {
      avgValence = withPost
              .map((s) => s.valenceDelta ?? 0)
              .reduce((a, b) => a + b) /
          withPost.length;
      avgEnergy = withPost
              .map((s) => s.energyDelta ?? 0)
              .reduce((a, b) => a + b) /
          withPost.length;

      // Most common start → end pair for the "You mostly shift…" line.
      final pairCounts = <String, int>{};
      final pairLookup = <String, (MoodQuadrant, MoodQuadrant)>{};
      final pairSample = <String, FocusSessionRecord>{};
      for (final s in withPost) {
        final end = s.postMoodQuadrant!;
        final key = '${s.moodQuadrant.name}->${end.name}';
        pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        pairLookup[key] = (s.moodQuadrant, end);
        pairSample.putIfAbsent(key, () => s);
      }
      var bestKey = pairCounts.keys.first;
      var bestCount = 0;
      for (final entry in pairCounts.entries) {
        if (entry.value > bestCount) {
          bestCount = entry.value;
          bestKey = entry.key;
        }
      }
      final pair = pairLookup[bestKey]!;
      typicalStart = pair.$1;
      typicalEnd = pair.$2;
      final sample = pairSample[bestKey]!;
      typicalStartLabel = MoodAxes.getMoodLabel(sample.valence, sample.energy);
      final postV = sample.postValence;
      final postE = sample.postEnergy;
      typicalEndLabel = (postV != null && postE != null)
          ? MoodAxes.getMoodLabel(postV, postE)
          : MoodAxes.representativeLabelForQuadrant(typicalEnd);

      // Mood "better" ≈ higher valence; near-zero = steadies.
      if (avgValence > 0.35) {
        moodStory = MoodShiftStory.improves;
      } else if (avgValence < -0.35) {
        moodStory = MoodShiftStory.declines;
      } else {
        moodStory = MoodShiftStory.steadies;
      }
    }

    final daypartTotals = {for (final d in FocusDaypart.values) d: 0.0};
    final daypartCounts = {for (final d in FocusDaypart.values) d: 0};
    for (final s in sessions) {
      final minutes = (s.durationMinutes ?? 0).toDouble();
      if (minutes <= 0) continue;
      final part = FocusDaypartLabel.fromHour(s.startedAt.hour);
      daypartTotals[part] = daypartTotals[part]! + minutes;
      daypartCounts[part] = daypartCounts[part]! + 1;
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
    if (peakAvg <= 0) peak = null;

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
      postMoodSampleSize: withPost.length,
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
