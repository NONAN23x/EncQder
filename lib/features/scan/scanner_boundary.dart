import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef ScannerDetectionCallback = Future<void> Function(ScanCapture capture);
typedef ScannerErrorBuilder =
    Widget Function(BuildContext context, String errorCode);
typedef ScannerOverlayBuilder =
    Widget Function(BuildContext context, BoxConstraints constraints);

final class ScannerException implements Exception {
  const ScannerException(this.errorCode, [this.cause]);

  final String errorCode;
  final Object? cause;

  @override
  String toString() => cause == null
      ? 'ScannerException($errorCode)'
      : 'ScannerException($errorCode): $cause';
}

final class ScanCapture {
  const ScanCapture({required this.data, this.image});

  final String data;
  final Uint8List? image;
}

/// The small platform seam used by [ScanScreen].
///
/// Keeping lifecycle policy outside this interface lets widget tests exercise
/// start/stop sequencing without creating an Android camera platform view.
abstract interface class ScannerBoundary {
  Future<void> start();

  Future<void> stop();

  Future<String?> analyzeImage(String path);

  Widget buildPreview({
    required Rect scanWindow,
    required ScannerDetectionCallback onDetect,
    required ScannerErrorBuilder errorBuilder,
    required ScannerOverlayBuilder overlayBuilder,
  });

  Future<void> dispose();
}

final class MobileScannerBoundary implements ScannerBoundary {
  MobileScannerBoundary({MobileScannerController? controller})
    : _controller =
          controller ??
          MobileScannerController(
            autoStart: false,
            detectionSpeed: DetectionSpeed.normal,
            facing: CameraFacing.back,
            returnImage: true,
          );

  final MobileScannerController _controller;

  @override
  Future<void> start() async {
    try {
      await _controller.start();
    } on MobileScannerException catch (error) {
      throw ScannerException(error.errorCode.name, error);
    }
  }

  @override
  Future<void> stop() => _controller.stop();

  @override
  Future<String?> analyzeImage(String path) async {
    final capture = await _controller.analyzeImage(path);
    return capture?.barcodes.firstOrNull?.rawValue?.trim();
  }

  @override
  Widget buildPreview({
    required Rect scanWindow,
    required ScannerDetectionCallback onDetect,
    required ScannerErrorBuilder errorBuilder,
    required ScannerOverlayBuilder overlayBuilder,
  }) {
    return MobileScanner(
      controller: _controller,
      useAppLifecycleState: false,
      scanWindow: scanWindow,
      onDetect: (capture) async {
        final data = capture.barcodes.firstOrNull?.rawValue?.trim();
        if (data == null || data.isEmpty) return;
        await onDetect(ScanCapture(data: data, image: capture.image));
      },
      placeholderBuilder: (_) => const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorBuilder: (context, error) =>
          errorBuilder(context, error.errorCode.name),
      overlayBuilder: overlayBuilder,
    );
  }

  @override
  Future<void> dispose() => _controller.dispose();
}
