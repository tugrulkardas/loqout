import 'app_models.dart';

/// Maps Mood Meter grid coordinates to Valence / Energy (-5…+5).
/// Does not alter the grid UI — pure telemetry transform.
class MoodAxes {
  static int valenceFromX(int x, {int gridSize = 10}) {
    if (gridSize <= 1) return 0;
    return ((x / (gridSize - 1)) * 10 - 5).round().clamp(-5, 5);
  }

  /// Y=0 is High Energy (top of meter).
  static int energyFromY(int y, {int gridSize = 10}) {
    if (gridSize <= 1) return 0;
    return ((1 - y / (gridSize - 1)) * 10 - 5).round().clamp(-5, 5);
  }

  /// Quadrant zone for a Mood Meter cell (matches FocusSetupScreen logic).
  static MoodQuadrant quadrantFromCell(int x, int y, {int gridSize = 10}) {
    final mid = gridSize / 2;
    if (y < mid) {
      return x >= mid ? MoodQuadrant.yellow : MoodQuadrant.red;
    }
    return x >= mid ? MoodQuadrant.green : MoodQuadrant.blue;
  }

  /// Coordinate-accurate Stanford Mood Meter adjective from valence × energy.
  ///
  /// Axes: valence −5…+5 (negative → positive), energy −5…+5 (low → high).
  static String getMoodLabel(int valence, int energy) {
    final v = valence.clamp(-5, 5);
    final e = energy.clamp(-5, 5);

    if (v.abs() <= 1 && e.abs() <= 1) return 'Neutral';

    if (v < 0) {
      // Unpleasant (left side)
      if (e >= 3) {
        if (v <= -4) return 'Enraged';
        if (v == -3) return 'Furious';
        return 'Panicked';
      }
      if (e >= 1) {
        if (v <= -4) return 'Stressed';
        if (v == -3) return 'Frustrated';
        return 'Annoyed';
      }
      if (e >= -1) {
        if (v <= -4) return 'Anxious';
        return 'Uneasy';
      }
      // Low energy, unpleasant
      if (v <= -4) return 'Despair';
      if (v == -3) return 'Depressed';
      return 'Exhausted';
    }

    if (v == 0) {
      if (e >= 3) return 'Alert';
      if (e <= -3) return 'Tired';
      return 'Neutral';
    }

    // Pleasant (right side)
    if (e >= 3) {
      if (v >= 4) return 'Ecstatic';
      if (v == 3) return 'Thrilled';
      return 'Energized';
    }
    if (e >= 1) {
      if (v >= 4) return 'Happy';
      if (v == 3) return 'Productive';
      return 'Focused';
    }
    if (e >= -1) {
      if (v >= 4) return 'Content';
      return 'At ease';
    }
    if (v >= 4) return 'Serene';
    if (v == 3) return 'Peaceful';
    return 'Chill';
  }

  /// Label for a Mood Meter cell using the same valence/energy transform as telemetry.
  static String getMoodLabelFromCell(int x, int y, {int gridSize = 10}) {
    return getMoodLabel(
      valenceFromX(x, gridSize: gridSize),
      energyFromY(y, gridSize: gridSize),
    );
  }

  /// Mid-quadrant stand-in when only a quadrant aggregate exists (Insights bars).
  static String representativeLabelForQuadrant(MoodQuadrant q) {
    switch (q) {
      case MoodQuadrant.red:
        return getMoodLabel(-3, 3);
      case MoodQuadrant.blue:
        return getMoodLabel(-3, -3);
      case MoodQuadrant.green:
        return getMoodLabel(3, -3);
      case MoodQuadrant.yellow:
        return getMoodLabel(3, 3);
    }
  }
}

extension MoodInsightLabels on MoodQuadrant {
  /// Dashboard / analytics short name.
  String get insightLabel {
    switch (this) {
      case MoodQuadrant.red:
        return 'Anxious Red';
      case MoodQuadrant.blue:
        return 'Bored Blue';
      case MoodQuadrant.green:
        return 'Calm Green';
      case MoodQuadrant.yellow:
        return 'Excited Yellow';
    }
  }

  /// Human-centric check-in label (post-session / quick mood chips).
  String get checkInLabel {
    switch (this) {
      case MoodQuadrant.red:
        return 'Stressed / Frustrated';
      case MoodQuadrant.blue:
        return 'Drained / Distracted';
      case MoodQuadrant.green:
        return 'Calm / Focused';
      case MoodQuadrant.yellow:
        return 'Energized / Productive';
    }
  }

  String get energyDescriptor =>
      this == MoodQuadrant.red || this == MoodQuadrant.yellow
          ? 'High Energy'
          : 'Low Energy';

  String get valenceDescriptor =>
      this == MoodQuadrant.yellow || this == MoodQuadrant.green
          ? 'Pleasant'
          : 'Unpleasant';
}

enum SessionCompletionStatus {
  completed,
  earlyExit,
  abandoned,
}

extension SessionCompletionStatusLabel on SessionCompletionStatus {
  String get wireName {
    switch (this) {
      case SessionCompletionStatus.completed:
        return 'completed';
      case SessionCompletionStatus.earlyExit:
        return 'early_exit';
      case SessionCompletionStatus.abandoned:
        return 'abandoned';
    }
  }

  static SessionCompletionStatus fromWire(String? value) {
    switch (value) {
      case 'early_exit':
        return SessionCompletionStatus.earlyExit;
      case 'abandoned':
        return SessionCompletionStatus.abandoned;
      default:
        return SessionCompletionStatus.completed;
    }
  }
}

/// Enriched behavioral telemetry for one focus session.
class FocusSessionRecord {
  FocusSessionRecord({
    required this.id,
    required this.nfcUid,
    required this.moodQuadrant,
    required this.valence,
    required this.energy,
    required this.intensity,
    required this.moodX,
    required this.moodY,
    required this.blockedPackages,
    required this.blockedAppNames,
    required this.startedAt,
    this.interventionCount = 0,
    this.postMoodQuadrant,
    this.postValence,
    this.postEnergy,
    this.postIntensity,
    this.endedAt,
    this.durationMinutes,
    this.scheduledMinutes,
    this.completionStatus = SessionCompletionStatus.completed,
  });

  final String id;
  final String nfcUid;

  final MoodQuadrant moodQuadrant;
  final int valence;
  final int energy;
  final int intensity;
  final int moodX;
  final int moodY;

  final List<String> blockedPackages;
  final List<String> blockedAppNames;

  int interventionCount;

  MoodQuadrant? postMoodQuadrant;
  int? postValence;
  int? postEnergy;
  int? postIntensity;

  final DateTime startedAt;
  DateTime? endedAt;
  int? durationMinutes;
  int? scheduledMinutes;
  SessionCompletionStatus completionStatus;

  bool get hasPostMood => postMoodQuadrant != null;

  /// Rough valence delta (post − initial). Positive ≈ more pleasant.
  int? get valenceDelta {
    if (postValence == null) return null;
    return postValence! - valence;
  }

  int? get energyDelta {
    if (postEnergy == null) return null;
    return postEnergy! - energy;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nfc_uid': nfcUid,
        'initial_mood': {
          'quadrant': moodQuadrant.name,
          'valence': valence,
          'energy': energy,
          'intensity': intensity,
          'x': moodX,
          'y': moodY,
        },
        'blocked_apps': {
          'packages': blockedPackages,
          'names': blockedAppNames,
        },
        'intervention_count': interventionCount,
        'post_session_mood': postMoodQuadrant == null
            ? null
            : {
                'quadrant': postMoodQuadrant!.name,
                'valence': postValence,
                'energy': postEnergy,
                'intensity': postIntensity,
              },
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'duration_minutes': durationMinutes,
        'scheduled_minutes': scheduledMinutes,
        'completion_status': completionStatus.wireName,
      };

  /// Flat map for Supabase `focus_sessions` (extra columns ignored if absent).
  Map<String, dynamic> toSupabaseRow() => {
        'id': id,
        'nfc_uid': nfcUid,
        'user_id': 'anon_user_${id.length >= 8 ? id.substring(0, 8) : id}',
        'mood_quadrant': moodQuadrant.name,
        'mood_intensity': intensity,
        'mood_x_coord': moodX,
        'mood_y_coord': moodY,
        'valence': valence,
        'energy': energy,
        'blocked_packages': blockedPackages,
        'blocked_app_names': blockedAppNames,
        'intervention_count': interventionCount,
        'post_mood_quadrant': postMoodQuadrant?.name,
        'post_valence': postValence,
        'post_energy': postEnergy,
        'post_mood_intensity': postIntensity,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'duration_minutes': durationMinutes,
        'scheduled_minutes': scheduledMinutes,
        'completion_status': completionStatus.wireName,
      };

  factory FocusSessionRecord.fromJson(Map<String, dynamic> json) {
    final initial = Map<String, dynamic>.from(json['initial_mood'] as Map? ?? {});
    final blocked = Map<String, dynamic>.from(json['blocked_apps'] as Map? ?? {});
    final post = json['post_session_mood'] is Map
        ? Map<String, dynamic>.from(json['post_session_mood'] as Map)
        : null;

    MoodQuadrant parseQ(String? name) => MoodQuadrant.values.firstWhere(
          (q) => q.name == name,
          orElse: () => MoodQuadrant.green,
        );

    return FocusSessionRecord(
      id: json['id'] as String? ??
          'sess_${DateTime.now().millisecondsSinceEpoch}',
      nfcUid: json['nfc_uid'] as String? ?? '',
      moodQuadrant: parseQ(initial['quadrant'] as String?),
      valence: initial['valence'] as int? ?? 0,
      energy: initial['energy'] as int? ?? 0,
      intensity: initial['intensity'] as int? ?? 1,
      moodX: initial['x'] as int? ?? 4,
      moodY: initial['y'] as int? ?? 4,
      blockedPackages: List<String>.from(blocked['packages'] as List? ?? const []),
      blockedAppNames: List<String>.from(blocked['names'] as List? ?? const []),
      interventionCount: json['intervention_count'] as int? ?? 0,
      postMoodQuadrant:
          post == null ? null : parseQ(post['quadrant'] as String?),
      postValence: post?['valence'] as int?,
      postEnergy: post?['energy'] as int?,
      postIntensity: post?['intensity'] as int?,
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.now(),
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int?,
      scheduledMinutes: json['scheduled_minutes'] as int?,
      completionStatus: SessionCompletionStatusLabel.fromWire(
        json['completion_status'] as String?,
      ),
    );
  }
}
