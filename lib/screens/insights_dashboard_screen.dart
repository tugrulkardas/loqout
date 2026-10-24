import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:share_plus/share_plus.dart' show ShareResultStatus;

import '../l10n/l10n_ext.dart';
import '../models/app_models.dart';
import '../models/session_telemetry.dart';
import '../services/beta_telemetry_export.dart';
import '../services/demo_telemetry_seeder.dart';
import '../services/insights_service.dart';
import '../services/launcher_apps_service.dart';
import '../theme/tapfocus_theme.dart';
import '../widgets/language_menu_button.dart';
import '../widgets/product_motto.dart';

/// Minimalist behavioral insights dashboard (async + cached).
class InsightsDashboardScreen extends StatefulWidget {
  const InsightsDashboardScreen({
    super.key,
    this.insightsService,
    this.onToggleTheme,
    this.themeIcon,
    this.themeTooltip,
  });

  final InsightsService? insightsService;
  final VoidCallback? onToggleTheme;
  final IconData? themeIcon;
  final String? themeTooltip;

  @override
  State<InsightsDashboardScreen> createState() =>
      _InsightsDashboardScreenState();
}

class _InsightsDashboardScreenState extends State<InsightsDashboardScreen> {
  late final InsightsService _insights =
      widget.insightsService ?? InsightsService();
  final DemoTelemetrySeeder _seeder = DemoTelemetrySeeder();

  InsightsSnapshot? _snapshot;
  bool _loading = true;
  bool _seeding = false;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await _insights.load(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load insights: $e';
        _loading = false;
      });
    }
  }

  Future<void> _showDevSeederSheet() async {
    if (!kDebugMode) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Dev tools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Demo sessions are local-only (never synced to Supabase).',
                  style: TextStyle(fontSize: 12, color: ctx.colors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _seeding
                      ? null
                      : () async {
                          Navigator.of(ctx).pop();
                          await _seedDemo();
                        },
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Seed 7-Day Demo Telemetry'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _seeding
                      ? null
                      : () async {
                          Navigator.of(ctx).pop();
                          await _clearDemo();
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear Demo Data'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _seedDemo() async {
    setState(() => _seeding = true);
    try {
      final count = await _seeder.seedSevenDayDemo();
      _insights.invalidate();
      await _load(forceRefresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seeded $count demo sessions (local only).'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seed failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _exportBetaTelemetry() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final result = await BetaTelemetryExport().exportAndShare();
      if (!mounted) return;
      // Dismissed share sheet is normal — no error toast.
      if (result.shareStatus == ShareResultStatus.dismissed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.ok ? null : Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _clearDemo() async {
    setState(() => _seeding = true);
    try {
      final removed = await _seeder.clearDemoData();
      _insights.invalidate();
      await _load(forceRefresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cleared $removed demo sessions.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clear failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.insightsTitle),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Dev: Seed / Clear demo data',
              onPressed: _seeding ? null : _showDevSeederSheet,
              icon: const Icon(Icons.science_outlined),
            ),
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh),
          ),
          const LanguageMenuButton(),
          if (widget.onToggleTheme != null)
            IconButton(
              tooltip: widget.themeTooltip ?? l10n.themeSystem,
              onPressed: widget.onToggleTheme,
              icon: Icon(widget.themeIcon ?? Icons.brightness_auto),
            ),
        ],
      ),
      body: _loading && _snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  GestureDetector(
                    onLongPress: kDebugMode ? _showDevSeederSheet : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.insightsHeroTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.insightsHeroSubtitle,
                          style: TextStyle(
                            color: c.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Long-press title for Seed 7-Day Demo Telemetry',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                  ],
                  const SizedBox(height: 20),
                  if (_snapshot == null || !_snapshot!.hasData)
                    _EmptyState(onRefresh: () => _load(forceRefresh: true))
                  else ...[
                    _MoodDistractionCard(snapshot: _snapshot!),
                    const SizedBox(height: 14),
                    _FrictionScoreCard(snapshot: _snapshot!),
                    const SizedBox(height: 14),
                    _EmotionalDeltaCard(snapshot: _snapshot!),
                    const SizedBox(height: 14),
                    _PeakFocusCard(snapshot: _snapshot!),
                    const SizedBox(height: 20),
                    Text(
                      l10n.insightsSessionsAnalyzed(
                        _snapshot!.sessionCount,
                        _formatTime(_snapshot!.computedAt),
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Center(
                    child: TextButton(
                      onPressed: _exporting ? null : _exportBetaTelemetry,
                      style: TextButton.styleFrom(
                        foregroundColor: c.textMuted.withValues(alpha: 0.45),
                        disabledForegroundColor:
                            c.textMuted.withValues(alpha: 0.25),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _exporting
                            ? l10n.insightsExporting
                            : l10n.insightsExportBeta,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.surfaceBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.insights_outlined,
              size: 32,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.insightsEmptyTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.insightsEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const ProductMotto(compact: true),
          const SizedBox(height: 16),
          TextButton(onPressed: onRefresh, child: Text(l10n.refresh)),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MoodDistractionCard extends StatelessWidget {
  const _MoodDistractionCard({required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final attemptsAreMeasured = !useDesktopMockLauncherApps;
    final top = attemptsAreMeasured ? snapshot.topTriggerQuadrant : null;
    final topCount = snapshot.topTriggerInterventionCount;
    final topMood = top == null
        ? null
        : localizeMoodLabel(
            l10n,
            MoodAxes.representativeLabelForQuadrant(top),
          );

    return _InsightCard(
      title: l10n.insightsMoodDistractionTitle,
      subtitle: l10n.insightsMoodDistractionSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!attemptsAreMeasured || top == null || topMood == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.insightsNotEnoughData,
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            )
          else ...[
            Text(
              l10n.insightsVulnerability(topMood, topCount),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (attemptsAreMeasured) ...[
          for (final q in MoodQuadrant.values)
            _BarRow(
              label: localizeMoodLabel(
                l10n,
                MoodAxes.representativeLabelForQuadrant(q),
              ),
              color: q.color,
              value: snapshot.interventionsByQuadrant[q] ?? 0,
              max: snapshot.interventionsByQuadrant.values.fold<int>(
                1,
                (a, b) => a > b ? a : b,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.color,
    required this.value,
    required this.max,
  });

  final String label;
  final Color color;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 13)),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrictionScoreCard extends StatelessWidget {
  const _FrictionScoreCard({required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final hours = snapshot.savedAttentionMinutes / 60;
    final l10n = context.l10n;
    return _InsightCard(
      title: l10n.insightsFrictionTitle,
      subtitle: l10n.insightsFrictionEstimate,
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              value: '${snapshot.interventionsLast7Days}',
              label: 'Interventions',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricTile(
              value: hours >= 1
                  ? '${hours.toStringAsFixed(1)}h'
                  : '${snapshot.savedAttentionMinutes}m',
              label: l10n.insightsEstimatedAttention,
              emphasize: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    this.emphasize = false,
  });

  final String value;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: emphasize ? c.accentDim : c.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: emphasize ? c.accent : c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionalDeltaCard extends StatelessWidget {
  const _EmotionalDeltaCard({required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final hasDelta = snapshot.postMoodSampleSize > 0;
    final belowThreshold = snapshot.postMoodSampleSize < kMoodShiftMinCheckIns;
    final story = snapshot.moodShiftStory;
    final start = snapshot.typicalStartMood;
    final end = snapshot.typicalEndMood;

    String? storyHeadline;
    if (story != null) {
      storyHeadline = switch (story) {
        MoodShiftStory.improves => l10n.insightsMoodImproves,
        MoodShiftStory.steadies => l10n.insightsMoodSteadies,
        MoodShiftStory.declines => l10n.insightsMoodDeclines,
      };
    }

    final startLabel = start == null
        ? null
        : localizeMoodLabel(
            l10n,
            snapshot.typicalStartMoodLabel ??
                MoodAxes.representativeLabelForQuadrant(start),
          );
    final endLabel = end == null
        ? null
        : localizeMoodLabel(
            l10n,
            snapshot.typicalEndMoodLabel ??
                MoodAxes.representativeLabelForQuadrant(end),
          );

    return _InsightCard(
      title: l10n.insightsBeforeAfterTitle,
      subtitle: l10n.insightsBeforeAfterSubtitle,
      child: !hasDelta ||
              story == null ||
              start == null ||
              end == null ||
              storyHeadline == null ||
              startLabel == null ||
              endLabel == null
          ? Text(
              hasDelta && belowThreshold
                  ? l10n.insightsNotEnoughData
                  : l10n.insightsBeforeAfterEmpty,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storyHeadline,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.surfaceBorder),
                  ),
                  child: Text(
                    l10n.insightsShiftFromTo(startLabel, endLabel),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Based on ${snapshot.postMoodSampleSize} check-in'
                  '${snapshot.postMoodSampleSize == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
    );
  }
}

String _peakAdvice(AppLocalizations l10n, FocusDaypart daypart) {
  switch (daypart) {
    case FocusDaypart.morning:
      return l10n.insightsPeakMorning;
    case FocusDaypart.afternoon:
      return l10n.insightsPeakAfternoon;
    case FocusDaypart.evening:
      return l10n.insightsPeakEvening;
    case FocusDaypart.night:
      return l10n.insightsPeakNight;
  }
}

String _daypartLabel(AppLocalizations l10n, FocusDaypart daypart) {
  switch (daypart) {
    case FocusDaypart.morning:
      return l10n.daypartMorning;
    case FocusDaypart.afternoon:
      return l10n.daypartAfternoon;
    case FocusDaypart.evening:
      return l10n.daypartEvening;
    case FocusDaypart.night:
      return l10n.daypartNight;
  }
}

class _PeakFocusCard extends StatelessWidget {
  const _PeakFocusCard({required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final peak = snapshot.peakFocusDaypart;
    return _InsightCard(
      title: l10n.insightsPeakTitle,
      subtitle: 'When your uninterrupted sessions run longest',
      child: peak == null
          ? Text(
              l10n.insightsNotEnoughData,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _daypartLabel(l10n, peak),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _peakAdvice(l10n, peak),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  peak.windowHint,
                  style: TextStyle(color: c.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Avg ${snapshot.peakFocusAvgMinutes.toStringAsFixed(0)} min '
                  'uninterrupted',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                for (final d in FocusDaypart.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 88,
                          child: Text(
                            _daypartLabel(l10n, d),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: d == peak
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: snapshot.peakFocusAvgMinutes <= 0
                                ? 0
                                : ((snapshot.daypartAvgMinutes[d] ?? 0) /
                                        snapshot.peakFocusAvgMinutes)
                                    .clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: c.surfaceElevated,
                            color: d == peak ? c.accent : c.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${(snapshot.daypartAvgMinutes[d] ?? 0).round()}m',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
