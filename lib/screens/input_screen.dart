import 'dart:io';
import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/storage_service.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _textController = TextEditingController();
  String _currentInput = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _generateAndSaveImageToGallery(String data) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000), // Default high-contrast dark
          emptyColor: const Color(0xFFFFFFFF), // Force white background for gallery
          gapless: true,
        );

        final picData = await painter.toImageData(
            1024, format: dart_ui.ImageByteFormat.png);

        if (picData != null) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/encqder_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await file.writeAsBytes(picData.buffer.asUint8List());

          // Check permissions
          final access = await Gal.hasAccess();
          if (!access) {
            final request = await Gal.requestAccess();
            if (!request) return; // User denied
          }

          await Gal.putImage(file.path, album: 'EncQder');
          
          // Cleanup temp
          if (await file.exists()) {
             await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to save to gallery: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create QR')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _textController,
                maxLength: 500,
                maxLines: 4,
                onChanged: (value) {
                  setState(() {
                    _currentInput = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Enter text, link, or data here...',
                ),
              ),
              const SizedBox(height: 32),

              if (_currentInput.isNotEmpty) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ready to Encode',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Save to add text into history',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextButton(
                        onPressed: () {
                          _textController.clear();
                          setState(() {
                            _currentInput = '';
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentInput.trim().isNotEmpty) {
                            final inputData = _currentInput.trim();
                            
                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            await StorageService().saveItem(
                              inputData,
                            ); // generated type defaults to generated
                            
                            await _generateAndSaveImageToGallery(inputData);

                            if (!context.mounted) return;
                            Navigator.pop(context); // Dismiss loading
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saved to History & Gallery!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            _textController.clear();
                            setState(() {
                              _currentInput = '';
                            });
                          }
                        },
                        child: const Text('Save to History'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Text(
                      'Type something to\ngenerate a QR code.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
