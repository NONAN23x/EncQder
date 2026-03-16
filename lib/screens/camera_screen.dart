import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/storage_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
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
              ElevatedButton(
                onPressed: () async {
                  await StorageService().saveItem(rawData);
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved to History!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context); // Close sheet
                  setState(() {
                    _isProcessing = false;
                  });
                },
                child: const Text('Save to History'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isProcessing = false;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Discard'),
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
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // Custom Overlay for scanning area
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  title: const Text(
                    'Scan QR Code',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                const Spacer(),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Add corner indicators if desired
                      Positioned(
                        top: -2,
                        left: -2,
                        child: _buildCorner(isTopLeft: true),
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: _buildCorner(isTopLeft: false, isTopRight: true),
                      ),
                      Positioned(
                        bottom: -2,
                        left: -2,
                        child: _buildCorner(isBottomLeft: true),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: _buildCorner(isBottomRight: true),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        color: Colors.white,
                        iconSize: 32,
                        icon: const Icon(Icons.flash_on),
                        onPressed: () => _scannerController.toggleTorch(),
                      ),
                      const SizedBox(width: 32),
                      IconButton(
                        color: Colors.white,
                        iconSize: 32,
                        icon: const Icon(Icons.cameraswitch),
                        onPressed: () => _scannerController.switchCamera(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isTopLeft || isTopRight
                ? Colors.greenAccent
                : Colors.transparent,
            width: 4,
          ),
          bottom: BorderSide(
            color: isBottomLeft || isBottomRight
                ? Colors.greenAccent
                : Colors.transparent,
            width: 4,
          ),
          left: BorderSide(
            color: isTopLeft || isBottomLeft
                ? Colors.greenAccent
                : Colors.transparent,
            width: 4,
          ),
          right: BorderSide(
            color: isTopRight || isBottomRight
                ? Colors.greenAccent
                : Colors.transparent,
            width: 4,
          ),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTopLeft ? 24 : 0),
          topRight: Radius.circular(isTopRight ? 24 : 0),
          bottomLeft: Radius.circular(isBottomLeft ? 24 : 0),
          bottomRight: Radius.circular(isBottomRight ? 24 : 0),
        ),
      ),
    );
  }
}
