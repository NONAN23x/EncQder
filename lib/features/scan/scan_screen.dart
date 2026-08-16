import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../domain/qr_models.dart';
import '../../domain/qr_payload_codec.dart';
import 'scan_result_sheet.dart';
import 'scanner_boundary.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.active,
    required this.onIdle,
    required this.onSave,
    this.scanner,
  });

  final bool active;
  final VoidCallback onIdle;
  final Future<void> Function(String data, QrKind kind, QrOrigin origin) onSave;

  /// Overrides the Android camera implementation for tests or alternate hosts.
  final ScannerBoundary? scanner;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  static const _idleTimeout = Duration(minutes: 2);
  static const _imageTypes = XTypeGroup(
    label: 'QR code images',
    extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
    mimeTypes: ['image/*'],
  );

  late final ScannerBoundary _scanner;
  late AppLifecycleState _lifecycleState;
  Future<void> _cameraOperation = Future<void>.value();
  Timer? _idleTimer;
  bool _processing = false;
  bool _cameraStarted = false;
  bool _holdLastFrame = false;
  Uint8List? _lastFrame;
  String? _cameraError;

  bool get _shouldRunCamera =>
      widget.active &&
      _lifecycleState == AppLifecycleState.resumed &&
      !_processing;

  @override
  void initState() {
    super.initState();
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _scanner = widget.scanner ?? MobileScannerBoundary();
    WidgetsBinding.instance.addObserver(this);
    _syncCamera();
  }

  @override
  void didUpdateWidget(ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _lifecycleState = state);
    _syncCamera();
  }

  void _syncCamera() {
    _idleTimer?.cancel();
    if (_shouldRunCamera) {
      _idleTimer = Timer(_idleTimeout, widget.onIdle);
    }

    _cameraOperation = _cameraOperation.then((_) => _applyCameraState());
  }

  Future<void> _applyCameraState() async {
    if (!mounted) return;
    try {
      if (_shouldRunCamera && !_cameraStarted) {
        await _scanner.start();
        if (!mounted) return;
        _cameraStarted = true;
        if (_cameraError != null) setState(() => _cameraError = null);
      } else if (!_shouldRunCamera && _cameraStarted) {
        await _scanner.stop();
        if (!mounted) return;
        _cameraStarted = false;
      }
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _cameraError = error is ScannerException
            ? error.errorCode
            : error.toString(),
      );
    }
  }

  void _retryCamera() {
    setState(() => _cameraError = null);
    _syncCamera();
  }

  void _markInteraction() {
    if (!_shouldRunCamera) return;
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, widget.onIdle);
  }

  Future<void> _showResult(ScanCapture capture) async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _lastFrame = capture.image;
      _holdLastFrame = capture.image != null;
    });
    _syncCamera();
    try {
      await _cameraOperation;
      if (!mounted) return;
      final payload = QrPayloadCodec.classify(capture.data);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        barrierColor: Colors.transparent,
        builder: (context) => ScanResultSheet(
          payload: payload,
          onSave: () =>
              widget.onSave(capture.data, payload.kind, QrOrigin.scanned),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
        _syncCamera();
        await _cameraOperation;
        if (mounted && _lastFrame != null) {
          setState(() => _holdLastFrame = false);
        }
      }
    }
  }

  Future<void> _pickImage() async {
    if (_processing) return;
    final file = await openFile(acceptedTypeGroups: const [_imageTypes]);
    if (file == null || !mounted) return;

    setState(() => _processing = true);
    _syncCamera();
    try {
      await _cameraOperation;
      final data = await _scanner.analyzeImage(file.path);
      if (!mounted) return;
      if (data == null || data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No QR code was found in that image.')),
        );
        return;
      }
      final image = await file.readAsBytes();
      await _showResult(ScanCapture(data: data, image: image));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not scan that image: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
        _syncCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    unawaited(_cameraOperation.then((_) => _scanner.dispose()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Listener(
        onPointerDown: (_) => _markInteraction(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final side = size.width * 0.72;
                final scanWindow = Rect.fromCenter(
                  center: Offset(size.width / 2, size.height * 0.42),
                  width: side,
                  height: side,
                );
                if (!widget.active ||
                    _lifecycleState != AppLifecycleState.resumed) {
                  return const ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Text(
                        'Camera paused',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
                if (_cameraError case final error?) {
                  return _CameraErrorView(
                    errorCode: error,
                    onRetry: _retryCamera,
                  );
                }
                return _scanner.buildPreview(
                  scanWindow: scanWindow,
                  onDetect: _showResult,
                  errorBuilder: (context, errorCode) => _CameraErrorView(
                    errorCode: errorCode,
                    onRetry: _retryCamera,
                  ),
                  overlayBuilder: (context, constraints) => SizedBox.expand(
                    child: CustomPaint(
                      painter: _ScannerOverlayPainter(scanWindow),
                    ),
                  ),
                );
              },
            ),
            if (_lastFrame != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _holdLastFrame ? 1 : 0,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    onEnd: () {
                      if (mounted && !_holdLastFrame) {
                        setState(() => _lastFrame = null);
                      }
                    },
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Image.memory(
                        _lastFrame!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: FilledButton.tonalIcon(
                onPressed: _processing ? null : _pickImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Scan from gallery'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.errorCode, required this.onRetry});

  final String errorCode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final permissionDenied = errorCode == 'permissionDenied';
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                permissionDenied
                    ? Icons.no_photography_rounded
                    : Icons.camera_alt_outlined,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                permissionDenied
                    ? 'Camera permission needed'
                    : 'Camera unavailable',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                permissionDenied
                    ? 'Allow camera access in Android settings, then retry.'
                    : 'EncQder could not start the camera ($errorCode).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry camera'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter(this.cutout);

  final Rect cutout;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(cutout, const Radius.circular(28)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutout, const Radius.circular(28)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) =>
      oldDelegate.cutout != cutout;
}
