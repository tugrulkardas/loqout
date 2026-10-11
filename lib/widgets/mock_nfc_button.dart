import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tapfocus_theme.dart';

/// Result of a mock (or real) NFC authentication attempt.
enum NfcAuthResult { success, cancelled }

/// Simulates a physical NFC tap with a fixed wait (default 10s).
///
/// Used when hardware is unavailable during development/testing.
class MockNfcSimulator {
  static const Duration simulationDuration = Duration(seconds: 10);

  /// Shows a blocking countdown dialog and returns [NfcAuthResult].
  ///
  /// Pass a short [duration] in widget tests to avoid long waits.
  static Future<NfcAuthResult> authenticate({
    required BuildContext context,
    required String title,
    String subtitle =
        'Simulating hardware NFC tap… Hold still until the timer finishes.',
    Duration? duration,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MockNfcCountdownDialog(
        title: title,
        subtitle: subtitle,
        duration: duration ?? simulationDuration,
      ),
    );
    return result == true ? NfcAuthResult.success : NfcAuthResult.cancelled;
  }

  /// Convenience wrapper — `true` on success, `false` on cancel.
  static Future<bool> run({
    required BuildContext context,
    required String title,
    String subtitle =
        'Simulating hardware NFC tap… Hold still until the timer finishes.',
    Duration? duration,
  }) async {
    final result = await authenticate(
      context: context,
      title: title,
      subtitle: subtitle,
      duration: duration,
    );
    return result == NfcAuthResult.success;
  }
}

/// Countdown dialog used by [MockNfcSimulator] (public for widget tests).
class MockNfcCountdownDialog extends StatefulWidget {
  const MockNfcCountdownDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.duration,
  });

  final String title;
  final String subtitle;
  final Duration duration;

  @override
  State<MockNfcCountdownDialog> createState() =>
      _MockNfcCountdownDialogState();
}

class _MockNfcCountdownDialogState extends State<MockNfcCountdownDialog> {
  late int _secondsLeft;
  Timer? _timer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.duration.inSeconds.clamp(1, 3600);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _completed = true;
        });
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = widget.duration.inSeconds.clamp(1, 3600);
    final progress = 1.0 - (_secondsLeft / total).clamp(0.0, 1.0);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _completed ? Icons.check_circle : Icons.sensors,
            color: _completed ? c.accent : c.warning,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.subtitle, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  color: _completed ? c.accent : c.warning,
                ),
                Text(
                  _completed ? 'OK' : '$_secondsLeft',
                  style: TextStyle(
                    fontSize: _completed ? 22 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _completed
                ? 'Mock NFC authenticated'
                : 'Mock NFC Tap (Test Mode)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _completed ? c.accent : c.warning,
            ),
          ),
        ],
      ),
      actions: [
        if (!_completed)
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}

/// Clearly labeled debug/test action for Mock NFC.
class MockNfcTapButton extends StatelessWidget {
  const MockNfcTapButton({
    super.key,
    required this.onAuthenticated,
    required this.label,
    this.dialogTitle = 'Mock NFC Tap (Test Mode)',
    this.enabled = true,
    this.simulationDuration,
    this.variant = MockNfcButtonVariant.outline,
  });

  final Future<void> Function() onAuthenticated;
  final String label;
  final String dialogTitle;
  final bool enabled;
  final Duration? simulationDuration;
  final MockNfcButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Future<void> handleTap() async {
      final result = await MockNfcSimulator.authenticate(
        context: context,
        title: dialogTitle,
        duration: simulationDuration,
      );
      if (result == NfcAuthResult.success) await onAuthenticated();
    }

    if (variant == MockNfcButtonVariant.filledSurface) {
      return FilledButton.icon(
        onPressed: enabled ? handleTap : null,
        icon: const Icon(Icons.nfc),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.accent,
          disabledBackgroundColor: c.surfaceElevated,
          side: BorderSide(color: c.surfaceBorder),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: enabled ? handleTap : null,
      icon: const Icon(Icons.bug_report_outlined),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.warning,
        side: BorderSide(color: c.warning),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum MockNfcButtonVariant {
  /// Amber outline — used on Focus setup (test mode cue).
  outline,

  /// Solid charcoal surface — primary unlock action on Focus Active.
  filledSurface,
}
