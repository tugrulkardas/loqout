import '../models/app_models.dart';
import '../models/session_telemetry.dart';
import 'session_repository.dart';

/// Dev-only utility that seeds realistic 7-day telemetry for Insights UAT.
///
/// Demo rows use ids prefixed with [SessionRepository.demoSessionIdPrefix]
/// and are **local-only** (never synced to Supabase).
class DemoTelemetrySeeder {
  DemoTelemetrySeeder({SessionRepository? repository})
      : _repository = repository ?? SessionRepository();

  final SessionRepository _repository;

  static const demoAppCatalog = <Map<String, String>>[
    {'package': 'com.instagram.android', 'name': 'Instagram'},
    {'package': 'com.google.android.youtube', 'name': 'YouTube'},
    {'package': 'com.zhiliaoapp.musically', 'name': 'TikTok'},
    {'package': 'com.twitter.android', 'name': 'X'},
    {'package': 'com.reddit.frontpage', 'name': 'Reddit'},
    {'package': 'com.facebook.katana', 'name': 'Facebook'},
  ];

  /// Builds 12 realistic sessions across the last 7 days (pure, no I/O).
  static List<FocusSessionRecord> buildSevenDayDemo({DateTime? now}) {
    final anchor = now ?? DateTime.now();
    final specs = <_DemoSpec>[
      // Day 0 — morning deep work (calm → calmer)
      _DemoSpec(
        daysAgo: 0,
        hour: 9,
        durationMinutes: 55,
        moodX: 7,
        moodY: 7,
        interventions: 0,
        postQuadrant: MoodQuadrant.green,
        postValence: 4,
        postEnergy: -2,
      ),
      // Day 0 — evening scroll trap
      _DemoSpec(
        daysAgo: 0,
        hour: 20,
        durationMinutes: 25,
        moodX: 2,
        moodY: 2,
        interventions: 4,
        postQuadrant: MoodQuadrant.yellow,
        postValence: 2,
        postEnergy: 1,
      ),
      // Day 1 — afternoon focus
      _DemoSpec(
        daysAgo: 1,
        hour: 14,
        durationMinutes: 40,
        moodX: 8,
        moodY: 3,
        interventions: 1,
        postQuadrant: MoodQuadrant.yellow,
        postValence: 4,
        postEnergy: 2,
      ),
      // Day 1 — bored blue evening
      _DemoSpec(
        daysAgo: 1,
        hour: 19,
        durationMinutes: 18,
        moodX: 1,
        moodY: 8,
        interventions: 5,
        postQuadrant: MoodQuadrant.green,
        postValence: 2,
        postEnergy: -1,
      ),
      // Day 2 — morning peak
      _DemoSpec(
        daysAgo: 2,
        hour: 8,
        durationMinutes: 70,
        moodX: 6,
        moodY: 6,
        interventions: 0,
        postQuadrant: MoodQuadrant.green,
        postValence: 5,
        postEnergy: -1,
      ),
      // Day 2 — anxious red midday
      _DemoSpec(
        daysAgo: 2,
        hour: 13,
        durationMinutes: 22,
        moodX: 1,
        moodY: 1,
        interventions: 3,
        postQuadrant: MoodQuadrant.yellow,
        postValence: 1,
        postEnergy: 2,
      ),
      // Day 3 — afternoon solid
      _DemoSpec(
        daysAgo: 3,
        hour: 15,
        durationMinutes: 45,
        moodX: 7,
        moodY: 4,
        interventions: 2,
        postQuadrant: MoodQuadrant.yellow,
        postValence: 3,
        postEnergy: 1,
      ),
      // Day 3 — evening
      _DemoSpec(
        daysAgo: 3,
        hour: 18,
        durationMinutes: 30,
        moodX: 3,
        moodY: 7,
        interventions: 3,
        postQuadrant: MoodQuadrant.green,
        postValence: 2,
        postEnergy: -2,
      ),
      // Day 4 — morning
      _DemoSpec(
        daysAgo: 4,
        hour: 10,
        durationMinutes: 60,
        moodX: 8,
        moodY: 8,
        interventions: 0,
        postQuadrant: MoodQuadrant.green,
        postValence: 4,
        postEnergy: -3,
      ),
      // Day 5 — afternoon distractible
      _DemoSpec(
        daysAgo: 5,
        hour: 16,
        durationMinutes: 20,
        moodX: 2,
        moodY: 3,
        interventions: 5,
        postQuadrant: MoodQuadrant.blue,
        postValence: -1,
        postEnergy: -2,
      ),
      // Day 5 — evening recovery
      _DemoSpec(
        daysAgo: 5,
        hour: 21,
        durationMinutes: 35,
        moodX: 6,
        moodY: 5,
        interventions: 1,
        postQuadrant: MoodQuadrant.green,
        postValence: 3,
        postEnergy: -1,
      ),
      // Day 6 — morning quiet
      _DemoSpec(
        daysAgo: 6,
        hour: 7,
        durationMinutes: 50,
        moodX: 5,
        moodY: 6,
        interventions: 0,
        postQuadrant: MoodQuadrant.green,
        postValence: 3,
        postEnergy: -2,
      ),
    ];

    return [
      for (var i = 0; i < specs.length; i++)
        _toRecord(specs[i], index: i, now: anchor),
    ];
  }

  /// Seeds local storage with demo telemetry. Returns session count.
  Future<int> seedSevenDayDemo({DateTime? now}) async {
    final sessions = buildSevenDayDemo(now: now);
    await _repository.replaceDemoSessions(sessions);
    return sessions.length;
  }

  /// Clears demo rows only. Returns deleted count.
  Future<int> clearDemoData() => _repository.clearDemoSessions();

  static FocusSessionRecord _toRecord(
    _DemoSpec spec, {
    required int index,
    required DateTime now,
  }) {
    final started = DateTime(
      now.year,
      now.month,
      now.day,
      spec.hour,
      10 + (index % 20),
    ).subtract(Duration(days: spec.daysAgo));

    final quadrant = MoodAxes.quadrantFromCell(spec.moodX, spec.moodY);
    final valence = MoodAxes.valenceFromX(spec.moodX);
    final energy = MoodAxes.energyFromY(spec.moodY);
    final apps = demoAppCatalog.take(2 + (index % 4)).toList();

    return FocusSessionRecord(
      id: '${SessionRepository.demoSessionIdPrefix}$index',
      nfcUid: 'mock:demo-tag-$index',
      moodQuadrant: quadrant,
      valence: valence,
      energy: energy,
      intensity: 2 + (index % 4),
      moodX: spec.moodX,
      moodY: spec.moodY,
      blockedPackages: apps.map((a) => a['package']!).toList(),
      blockedAppNames: apps.map((a) => a['name']!).toList(),
      startedAt: started,
      endedAt: started.add(Duration(minutes: spec.durationMinutes)),
      durationMinutes: spec.durationMinutes,
      interventionCount: spec.interventions,
      postMoodQuadrant: spec.postQuadrant,
      postValence: spec.postValence,
      postEnergy: spec.postEnergy,
      postIntensity: 3,
      completionStatus: SessionCompletionStatus.completed,
    );
  }
}

class _DemoSpec {
  const _DemoSpec({
    required this.daysAgo,
    required this.hour,
    required this.durationMinutes,
    required this.moodX,
    required this.moodY,
    required this.interventions,
    required this.postQuadrant,
    required this.postValence,
    required this.postEnergy,
  });

  final int daysAgo;
  final int hour;
  final int durationMinutes;
  final int moodX;
  final int moodY;
  final int interventions;
  final MoodQuadrant postQuadrant;
  final int postValence;
  final int postEnergy;
}
