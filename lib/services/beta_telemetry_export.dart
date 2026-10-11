import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../models/session_telemetry.dart';
import 'beta_telemetry_file_io.dart'
    if (dart.library.html) 'beta_telemetry_file_stub.dart' as telemetry_file;
import 'session_repository.dart';

/// Converts local session telemetry into a CSV for beta ML extraction.
///
/// Source of truth is [SessionRepository] (local session store). No schema changes.
class BetaTelemetryExport {
  BetaTelemetryExport({SessionRepository? repository})
      : _repository = repository ?? SessionRepository();

  final SessionRepository _repository;

  static const String fileName = 'loqout_beta_telemetry.csv';

  static const List<String> csvHeaders = [
    'session_id',
    'session_start',
    'session_end',
    'initial_valence',
    'initial_energy',
    'initial_intensity',
    'initial_quadrant',
    'mood_x',
    'mood_y',
    'ending_valence',
    'ending_energy',
    'ending_intensity',
    'ending_quadrant',
    'interventions_count',
    'duration_minutes',
    'scheduled_minutes',
    'completion_status',
    'nfc_uid',
    'blocked_app_count',
    'blocked_packages',
  ];

  /// Builds a CSV string (header + rows) from [sessions]. Pure / testable.
  static String sessionsToCsv(List<FocusSessionRecord> sessions) {
    final buffer = StringBuffer();
    buffer.writeln(csvHeaders.join(','));
    for (final s in sessions) {
      buffer.writeln(_row(s).map(_escapeCsv).join(','));
    }
    return buffer.toString();
  }

  static List<Object?> _row(FocusSessionRecord s) => [
        s.id,
        s.startedAt.toIso8601String(),
        s.endedAt?.toIso8601String() ?? '',
        s.valence,
        s.energy,
        s.intensity,
        s.moodQuadrant.name,
        s.moodX,
        s.moodY,
        s.postValence ?? '',
        s.postEnergy ?? '',
        s.postIntensity ?? '',
        s.postMoodQuadrant?.name ?? '',
        s.interventionCount,
        s.durationMinutes ?? '',
        s.scheduledMinutes ?? '',
        s.completionStatus.wireName,
        s.nfcUid,
        s.blockedPackages.length,
        s.blockedPackages.join('|'),
      ];

  static String _escapeCsv(Object? value) {
    final raw = value?.toString() ?? '';
    if (raw.contains(',') ||
        raw.contains('"') ||
        raw.contains('\n') ||
        raw.contains('\r')) {
      return '"${raw.replaceAll('"', '""')}"';
    }
    return raw;
  }

  /// Loads all local sessions, writes CSV to temp dir, opens native share sheet.
  ///
  /// Never throws to the UI caller — returns a short status message instead.
  Future<BetaTelemetryExportResult> exportAndShare() async {
    try {
      final sessions = await _repository.loadAll();
      final csv = sessionsToCsv(sessions);
      final bytes = utf8.encode(csv);

      XFile xFile;
      try {
        final path = await telemetry_file.writeBetaTelemetryCsvFile(
          csv: csv,
          fileName: fileName,
        );
        xFile = XFile(path, mimeType: 'text/csv', name: fileName);
      } catch (_) {
        // Web / filesystem-unavailable: share in-memory CSV bytes.
        xFile = XFile.fromData(
          bytes,
          mimeType: 'text/csv',
          name: fileName,
        );
      }

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'LoqOut beta telemetry',
          text:
              'LoqOut beta session telemetry (${sessions.length} rows). '
              'Attach and send for ML modeling.',
        ),
      );

      return BetaTelemetryExportResult(
        ok: true,
        sessionCount: sessions.length,
        shareStatus: result.status,
        message: sessions.isEmpty
            ? 'Exported empty CSV (no sessions yet).'
            : 'Shared ${sessions.length} session row'
                '${sessions.length == 1 ? '' : 's'}.',
      );
    } catch (e, st) {
      debugPrint('BetaTelemetryExport failed: $e\n$st');
      return BetaTelemetryExportResult(
        ok: false,
        sessionCount: 0,
        shareStatus: ShareResultStatus.unavailable,
        message:
            'Could not export telemetry. Try again or share from another app.',
      );
    }
  }
}

class BetaTelemetryExportResult {
  const BetaTelemetryExportResult({
    required this.ok,
    required this.sessionCount,
    required this.shareStatus,
    required this.message,
  });

  final bool ok;
  final int sessionCount;
  final ShareResultStatus shareStatus;
  final String message;
}
