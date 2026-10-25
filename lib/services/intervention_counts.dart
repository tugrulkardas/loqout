import 'dart:convert';

/// JSON object of package name to attempts for the open session.
/// Written by the Android watchdog and read on the lock screen.
const String kInterventionByPackageKey = 'tapfocus_intervention_by_package';

/// Parses the open-session per-app attempt map. Unknown shapes count as none.
Map<String, int> decodeInterventionCounts(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    final counts = <String, int>{};
    for (final entry in decoded.entries) {
      final key = '${entry.key}'.trim();
      if (key.isEmpty) continue;
      final value = entry.value;
      final count = value is int
          ? value
          : value is num
              ? value.toInt()
              : int.tryParse('$value') ?? 0;
      if (count > 0) counts[key] = count;
    }
    return counts;
  } catch (_) {
    return {};
  }
}
