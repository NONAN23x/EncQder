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
                            await StorageService().saveItem(
                              _currentInput.trim(),
                            );
                            if (!context.mounted) return;
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
