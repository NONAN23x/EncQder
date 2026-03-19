import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/storage_service.dart';

class CameraScreen extends StatefulWidget {
  final PageController? pageController; // Allow manual swipe fallback

  const CameraScreen({super.key, this.pageController});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with AutomaticKeepAliveClientMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  Timer? _idleTimer;
  static const _idleTimeout = Duration(minutes: 2);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startIdleTimer();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () {
      if (mounted && !_isProcessing) {
         // Auto-redirect to home index if idle for 2 min saving battery
         if (widget.pageController != null) {
            widget.pageController!.animateToPage(
              1, // Home screen index
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
         }
      }
    });
  }

  void _resetIdleTimer() {
    _startIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          _isProcessing = true;
        });

        // Show result overlay
        _showResultOverlay(barcode.rawValue!);
      }
    }
  }

  void _showResultOverlay(String rawData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Scanned Content',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        Theme.of(context).cardTheme.shape
                            is RoundedRectangleBorder
                        ? (Theme.of(context).cardTheme.shape
                                  as RoundedRectangleBorder)
                              .side
                              .color
                        : Colors.transparent,
                  ),
                ),
                child: SelectableText(
                  rawData,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _isProcessing = false;
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Discard'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        await StorageService().saveItem(rawData, originType: 'scanned');

                        if (!context.mounted) return;
                        Navigator.pop(context); // Dismiss loading

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved to Home!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pop(context); // Close sheet
                        setState(() {
                          _isProcessing = false;
                        });
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      setState(() {
        _isProcessing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Determine screen size for central cutout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // We want a square cutout that takes up roughly 70% of the screen width
    final cutoutSize = screenWidth * 0.7;
    // Calculate the left and top offsets to center it
    final cutoutLeft = (screenWidth - cutoutSize) / 2;
    // Position it slightly above center vertically
    final cutoutTop = (screenHeight - cutoutSize) / 2.5;
    
    final cutoutRect = Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Deep black base
      body: GestureDetector(
        onTapDown: (_) => _resetIdleTimer(),
        onPanDown: (_) => _resetIdleTimer(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. The actual Camera feed
            MobileScanner(
              controller: _scannerController,
              scanWindow: cutoutRect,
              onDetect: _handleBarcode,
            ),

            // 2. The Dark Overlay with Transparent Center
            CustomPaint(
              painter: _ScannerOverlayPainter(
                cutoutRect: cutoutRect,
                overlayColor: Theme.of(context).scaffoldBackgroundColor, // Sleek semi-transparent black
              ),
            ),
            
            // 3. The Corner Brackets indicating the scan area
            CustomPaint(
               painter: _ScannerBracketsPainter(
                 cutoutRect: cutoutRect,
                 color: Theme.of(context).colorScheme.primary,
                 strokeWidth: 4.0,
                 bracketLength: 30.0,
                 radius: 12.0,
               )
            ),

            // 4. Instructional Text
            Positioned(
              left: 0,
              right: 0,
              top: cutoutRect.bottom + 40,
              child: const Text(
                'Align QR code within the frame to scan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            // 5. Warning indicator if scanning is paused (e.g. processing result)
            if (_isProcessing)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        ),
                        SizedBox(width: 12),
                        Text('Processing...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw a semi-transparent dark overlay over the camera,
// punching out a clear rectangular "window" in the middle.
class _ScannerOverlayPainter extends CustomPainter {
  final Rect cutoutRect;
  final Color overlayColor;

  _ScannerOverlayPainter({required this.cutoutRect, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)));

    // Subtract the cutout from the background
    final finalPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return cutoutRect != oldDelegate.cutoutRect || overlayColor != oldDelegate.overlayColor;
  }
}

// Custom Painter to draw only the elegant rounded corner brackets around the cutout
class _ScannerBracketsPainter extends CustomPainter {
  final Rect cutoutRect;
  final Color color;
  final double strokeWidth;
  final double bracketLength;
  final double radius;

  _ScannerBracketsPainter({
    required this.cutoutRect,
    required this.color,
    required this.strokeWidth,
    required this.bracketLength,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Top Left
    path.moveTo(cutoutRect.left, cutoutRect.top + bracketLength);
    path.lineTo(cutoutRect.left, cutoutRect.top + radius);
    path.arcToPoint(
      Offset(cutoutRect.left + radius, cutoutRect.top),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(cutoutRect.left + bracketLength, cutoutRect.top);

    // Top Right
    path.moveTo(cutoutRect.right - bracketLength, cutoutRect.top);
    path.lineTo(cutoutRect.right - radius, cutoutRect.top);
    path.arcToPoint(
      Offset(cutoutRect.right, cutoutRect.top + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(cutoutRect.right, cutoutRect.top + bracketLength);

    // Bottom Left
    path.moveTo(cutoutRect.left, cutoutRect.bottom - bracketLength);
    path.lineTo(cutoutRect.left, cutoutRect.bottom - radius);
    path.arcToPoint(
      Offset(cutoutRect.left + radius, cutoutRect.bottom),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(cutoutRect.left + bracketLength, cutoutRect.bottom);

    // Bottom Right
    path.moveTo(cutoutRect.right - bracketLength, cutoutRect.bottom);
    path.lineTo(cutoutRect.right - radius, cutoutRect.bottom);
    path.arcToPoint(
      Offset(cutoutRect.right, cutoutRect.bottom - radius),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    path.lineTo(cutoutRect.right, cutoutRect.bottom - bracketLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerBracketsPainter oldDelegate) {
    return cutoutRect != oldDelegate.cutoutRect || 
           color != oldDelegate.color ||
           strokeWidth != oldDelegate.strokeWidth ||
           bracketLength != oldDelegate.bracketLength ||
           radius != oldDelegate.radius;
  }
}
