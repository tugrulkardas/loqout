import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/l10n_ext.dart';
import '../theme/tapfocus_theme.dart';

/// Exact payload expected from beta QR stickers (physical friction stand-in).
const String kTapFocusBetaQrPayload = 'tapfocus_beta_auth';

/// Session auth UID written when beta QR succeeds (mirrors mock NFC shape).
const String kTapFocusBetaQrUid = 'qr:tapfocus_beta_auth';

/// Opens the beta QR scanner and returns true when [kTapFocusBetaQrPayload] is read.
Future<bool> scanTapFocusBetaQr(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const BetaQrScannerScreen(),
    ),
  );
  return result == true;
}

/// Primary / unlock action that replaces Mock NFC for beta distribution.
class BetaQrAuthButton extends StatelessWidget {
  const BetaQrAuthButton({
    super.key,
    required this.onAuthenticated,
    required this.label,
    this.enabled = true,
    this.filled = false,
  });

  final Future<void> Function() onAuthenticated;
  final String label;
  final bool enabled;
  final bool filled;

  Future<void> _handleTap(BuildContext context) async {
    final ok = await scanTapFocusBetaQr(context);
    if (ok) await onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (filled) {
      return FilledButton.icon(
        onPressed: enabled ? () => _handleTap(context) : null,
        icon: const Icon(Icons.qr_code_scanner),
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
      onPressed: enabled ? () => _handleTap(context) : null,
      icon: const Icon(Icons.qr_code_scanner),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.accent,
        side: BorderSide(color: c.accent),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum _ScannerPhase { checking, ready, denied, desktop }

class BetaQrScannerScreen extends StatefulWidget {
  const BetaQrScannerScreen({super.key});

  @override
  State<BetaQrScannerScreen> createState() => _BetaQrScannerScreenState();
}

class _BetaQrScannerScreenState extends State<BetaQrScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  _ScannerPhase _phase = _ScannerPhase.checking;
  bool _handling = false;
  bool _requesting = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from system Settings after granting camera.
    if (state == AppLifecycleState.resumed &&
        _phase == _ScannerPhase.denied) {
      _ensureCamera();
    }
  }

  bool get _isDesktop =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> _disposeController() async {
    final c = _controller;
    _controller = null;
    if (c == null) return;
    try {
      await c.stop();
    } catch (_) {}
    await c.dispose();
  }

  Future<void> _ensureCamera() async {
    if (_requesting) return;
    _requesting = true;
    try {
      if (_isDesktop) {
        if (!mounted) return;
        setState(() {
          _phase = _ScannerPhase.desktop;
          _status = context.l10n.qrDesktopHint;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _phase = _ScannerPhase.checking;
        _status = null;
      });

      // Never start the camera until CAMERA is granted.
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (!mounted) return;

      if (!status.isGranted) {
        await _disposeController();
        setState(() {
          _phase = _ScannerPhase.denied;
          _status = context.l10n.qrPermissionRequired;
        });
        return;
      }

      await _disposeController();
      final controller = MobileScannerController(
        // Start only after permission — avoids "No cameras available".
        autoStart: false,
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
        lensType: CameraLensType.any,
        autoZoom: true,
      );

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _phase = _ScannerPhase.ready;
        _status = null;
      });

      try {
        await controller.start();
      } catch (e, st) {
        debugPrint('MobileScanner start failed: $e\n$st');
        if (!mounted) return;
        await _disposeController();
        setState(() {
          _phase = _ScannerPhase.denied;
          _status = context.l10n.qrCameraOpenFailed;
        });
      }
    } finally {
      _requesting = false;
    }
  }

  Future<void> _openAppSettingsForCamera() async {
    await openAppSettings();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    for (final barcode in capture.barcodes) {
      debugPrint('Scanned Raw Data: ${barcode.rawValue}');
      final scannedCode = barcode.rawValue?.trim();
      if (scannedCode == null || scannedCode.isEmpty) continue;
      if (scannedCode == kTapFocusBetaQrPayload) {
        _handling = true;
        try {
          await _controller?.stop();
        } catch (_) {}
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }
      if (mounted) {
        setState(() {
          _status = context.l10n.qrUnrecognized(
            scannedCode,
            kTapFocusBetaQrPayload,
          );
        });
      }
    }
  }

  Future<void> _submitManualCode(String value) async {
    if (value.trim() == kTapFocusBetaQrPayload) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }
    if (!mounted) return;
    setState(
      () => _status = context.l10n.qrInvalidCode(kTapFocusBetaQrPayload),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.qrScanTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.white)),
        ),
        leadingWidth: 80,
      ),
      body: switch (_phase) {
        _ScannerPhase.checking => const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
        _ScannerPhase.desktop => _ManualBetaCodePane(
            status: _status,
            onSubmit: _submitManualCode,
          ),
        _ScannerPhase.denied => _CameraPermissionFallback(
            message: _status ?? l10n.qrPermissionRequired,
            onGrant: _openAppSettingsForCamera,
            onRetry: _ensureCamera,
            onManualSubmit: _submitManualCode,
          ),
        _ScannerPhase.ready => Stack(
            fit: StackFit.expand,
            children: [
              if (_controller != null)
                MobileScanner(
                  controller: _controller!,
                  onDetect: _onDetect,
                  // Continuous autofocus (package has no separate autoFocus flag).
                  tapToFocus: false,
                  errorBuilder: (context, error) {
                    return _CameraPermissionFallback(
                      message: error.errorDetails?.message ??
                          error.errorCode.message,
                      onGrant: _openAppSettingsForCamera,
                      onRetry: _ensureCamera,
                      onManualSubmit: _submitManualCode,
                    );
                  },
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black54,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _status ??
                            l10n.qrScanPrompt(kTapFocusBetaQrPayload),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      },
    );
  }
}

class _CameraPermissionFallback extends StatelessWidget {
  const _CameraPermissionFallback({
    required this.message,
    required this.onGrant,
    required this.onRetry,
    required this.onManualSubmit,
  });

  final String message;
  final Future<void> Function() onGrant;
  final Future<void> Function() onRetry;
  final Future<void> Function(String value) onManualSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              await onGrant();
            },
            child: Text(l10n.qrGrantPermission),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await onRetry();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            child: Text(l10n.retry),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.qrOrEnterManually,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _ManualBetaCodePane(
              onSubmit: onManualSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualBetaCodePane extends StatefulWidget {
  const _ManualBetaCodePane({
    required this.onSubmit,
    this.status,
  });

  final Future<void> Function(String value) onSubmit;
  final String? status;

  @override
  State<_ManualBetaCodePane> createState() => _ManualBetaCodePaneState();
}

class _ManualBetaCodePaneState extends State<_ManualBetaCodePane> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.status != null) ...[
          Text(
            widget.status!,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: l10n.qrBetaAuthCode,
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: c.accent),
            ),
          ),
          onSubmitted: widget.onSubmit,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => widget.onSubmit(_controller.text),
          child: Text(l10n.confirm),
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
          ),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
