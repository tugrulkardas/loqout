import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart' show supabase;
import '../models/session_telemetry.dart';
import 'intervention_counts.dart';

/// Local-first session store with best-effort Supabase sync.
class SessionRepository {
  static const _prefsKey = 'tapfocus_session_records_v1';
  static const _activeSessionKey = 'tapfocus_active_session_json';
  static const _interventionKey = 'tapfocus_intervention_count';

  Future<List<FocusSessionRecord>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FocusSessionRecord.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (e, st) {
      debugPrint('SessionRepository.loadAll failed: $e\n$st');
      return [];
    }
  }

  Future<void> _saveAll(List<FocusSessionRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> upsert(FocusSessionRecord record) async {
    final all = await loadAll();
    final idx = all.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      all[idx] = record;
    } else {
      all.insert(0, record);
    }
    await _saveAll(all);
    // Never push demo seed rows to Supabase.
    if (!isDemoSessionId(record.id)) {
      await _syncSupabase(record);
    }
  }

  /// Local-only write (no Supabase). Used by the demo seeder.
  Future<void> upsertLocal(FocusSessionRecord record) async {
    final all = await loadAll();
    final idx = all.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      all[idx] = record;
    } else {
      all.insert(0, record);
    }
    await _saveAll(all);
  }

  /// Replace all demo rows, keeping real user sessions intact.
  Future<void> replaceDemoSessions(List<FocusSessionRecord> demos) async {
    final all = await loadAll();
    all.removeWhere((r) => isDemoSessionId(r.id));
    all.addAll(demos);
    await _saveAll(all);
  }

  /// Remove demo seed rows only. Returns how many were deleted.
  Future<int> clearDemoSessions() async {
    final all = await loadAll();
    final before = all.length;
    all.removeWhere((r) => isDemoSessionId(r.id));
    await _saveAll(all);
    return before - all.length;
  }

  static bool isDemoSessionId(String id) => id.startsWith(demoSessionIdPrefix);

  static const demoSessionIdPrefix = 'demo_sess_';

  Future<void> saveActiveDraft(FocusSessionRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSessionKey, jsonEncode(record.toJson()));
    await prefs.setInt(_interventionKey, record.interventionCount);
  }

  Future<FocusSessionRecord?> loadActiveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_activeSessionKey);
      if (raw == null || raw.isEmpty) return null;
      return FocusSessionRecord.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSessionKey);
    await prefs.setInt(_interventionKey, 0);
    await prefs.setString(kInterventionByPackageKey, '{}');
  }

  Future<void> resetInterventionCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_interventionKey, 0);
    await prefs.setString(kInterventionByPackageKey, '{}');
  }

  Future<int> readInterventionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_interventionKey) ?? 0;
  }

  /// Attempts per package for the open session. Written by the watchdog.
  Future<Map<String, int>> readInterventionCountsByPackage() async {
    final prefs = await SharedPreferences.getInstance();
    return decodeInterventionCounts(
      prefs.getString(kInterventionByPackageKey),
    );
  }

  Future<int> incrementInterventionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_interventionKey) ?? 0) + 1;
    await prefs.setInt(_interventionKey, next);
    return next;
  }

  Future<void> _syncSupabase(FocusSessionRecord record) async {
    try {
      // Prefer upsert on id; fall back to insert; never throw to UI.
      await supabase.from('focus_sessions').upsert(
            record.toSupabaseRow(),
            onConflict: 'id',
          );
    } catch (e) {
      debugPrint('Supabase upsert failed, trying insert: $e');
      try {
        await supabase.from('focus_sessions').insert(record.toSupabaseRow());
      } catch (e2) {
        // Schema may not have enriched columns yet — try legacy minimal row.
        debugPrint('Supabase insert failed, trying legacy row: $e2');
        try {
          await supabase.from('focus_sessions').insert({
            'nfc_uid': record.nfcUid,
            'mood_quadrant': record.moodQuadrant.name,
            'mood_intensity': record.intensity,
            'user_id':
                'anon_user_${record.id.length >= 8 ? record.id.substring(0, 8) : record.id}',
            'mood_x_coord': record.moodX,
            'mood_y_coord': record.moodY,
          });
        } catch (e3) {
          debugPrint('Supabase sync skipped (local-first OK): $e3');
        }
      }
    }
  }

  /// Best-effort early mood checkpoint (pre-session), non-blocking.
  Future<void> syncInitialMoodCheckpoint({
    required String nfcUid,
    required String quadrant,
    required int intensity,
    required int x,
    required int y,
    required int valence,
    required int energy,
  }) async {
    try {
      await supabase.from('focus_sessions').insert({
        'nfc_uid': nfcUid,
        'mood_quadrant': quadrant,
        'mood_intensity': intensity,
        'mood_x_coord': x,
        'mood_y_coord': y,
        'valence': valence,
        'energy': energy,
        'user_id':
            'anon_user_${nfcUid.length >= 8 ? nfcUid.substring(0, 8) : nfcUid}',
        'completion_status': 'setup',
      });
    } catch (e) {
      debugPrint('Initial mood checkpoint sync skipped: $e');
    }
  }
}
