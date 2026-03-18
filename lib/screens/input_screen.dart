import 'package:flutter/material.dart';

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
                decoration: InputDecoration(
                  hintText: 'Enter text, link, or data here...',
                  suffixIcon: _currentInput.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded),
                          onPressed: () {
                            _textController.clear();
                            setState(() {
                              _currentInput = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 32),

              if (_currentInput.isNotEmpty) ...[
                const Spacer(),
                ElevatedButton.icon(
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

                      if (!context.mounted) return;
                      Navigator.pop(context); // Dismiss loading

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saved to History!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );                            
                      _textController.clear();
                      setState(() {
                        _currentInput = '';
                      });
                    }
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save to History'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Type something to\ngenerate a QR code.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
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
