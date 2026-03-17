import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/storage_service.dart';
import '../services/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeProvider themeProvider;

  const SettingsScreen({super.key, required this.themeProvider});

  void _confirmWipe(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wipe All Data?'),
        content: const Text('This will permanently delete all scanned and generated QR codes. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await StorageService().clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data wiped successfully')),
                );
              }
            },
            child: const Text('Wipe Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final history = await StorageService().getHistory();
      if (history.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No history to export')),
          );
        }
        return;
      }

      final buffer = StringBuffer();
      for (final item in history) {
        buffer.writeln('Date: ${item.createdAt.toIso8601String()}');
        buffer.writeln('Content: ${item.data}');
        buffer.writeln('---');
      }

      final archive = Archive();
      final textBytes = utf8.encode(buffer.toString());
      archive.addFile(ArchiveFile('encqder_history.txt', textBytes.length, textBytes));

      final zipData = ZipEncoder().encode(archive);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/encqder_backup_$timestamp.zip');
      await file.writeAsBytes(zipData);

      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'EncQder History Backup',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null || path.isEmpty) return;

      final bytes = await File(path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      String? fileContent;
      for (final file in archive) {
        if (file.isFile && file.name == 'encqder_history.txt') {
          fileContent = utf8.decode(file.content as List<int>);
          break;
        }
      }

      if (fileContent == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid backup file format')),
          );
        }
        return;
      }

      final items = <QrItem>[];
      final parts = fileContent.split('---');
      for (final part in parts) {
        if (part.trim().isEmpty) continue;
        
        final lines = part.trim().split('\n');
        String? dateStr;
        String? content;

        for (final line in lines) {
          if (line.startsWith('Date: ')) {
            dateStr = line.substring('Date: '.length).trim();
          } else if (line.startsWith('Content: ')) {
            content = line.substring('Content: '.length).trim();
          }
        }

        if (dateStr != null && content != null) {
          items.add(QrItem(
            id: DateTime.now().millisecondsSinceEpoch.toString() + items.length.toString(),
            data: content,
            createdAt: DateTime.tryParse(dateStr) ?? DateTime.now(),
            originType: 'imported',
          ));
        }
      }

      await StorageService().mergeItems(items);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${items.length} entries successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 16),
          _buildThemeSelector(context),
          const SizedBox(height: 32),
          _buildSectionHeader('Data Management'),
          const SizedBox(height: 16),
          _buildDataCard(
            context: context,
            title: 'Export History',
            subtitle: 'Export all QR codes to a .zip file',
            icon: Icons.upload_file_rounded,
            onTap: () => _exportData(context),
          ),
          const SizedBox(height: 12),
          _buildDataCard(
            context: context,
            title: 'Import History',
            subtitle: 'Restore QR codes from a backup .zip file',
            icon: Icons.download_rounded,
            onTap: () => _importData(context),
          ),
          const SizedBox(height: 12),
          _buildDataCard(
            context: context,
            title: 'Wipe Data',
            subtitle: 'Permanently delete all saved entries',
            icon: Icons.delete_forever_rounded,
            isDestructive: true,
            onTap: () => _confirmWipe(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]!
                  : const Color(0xFF2C2C2C),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _ThemeOption(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                isSelected: themeProvider.themeMode == ThemeMode.light,
                onTap: () => themeProvider.setThemeMode(ThemeMode.light),
              ),
              _ThemeOption(
                label: 'System',
                icon: Icons.settings_system_daydream_rounded,
                isSelected: themeProvider.themeMode == ThemeMode.system,
                onTap: () => themeProvider.setThemeMode(ThemeMode.system),
              ),
              _ThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                isSelected: themeProvider.themeMode == ThemeMode.dark,
                onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Theme.of(context).colorScheme.onSurface;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey[200]!
                : const Color(0xFF2C2C2C),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? colorScheme.surface
                    : (isLight ? Colors.black54 : Colors.white54),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.surface
                      : (isLight ? Colors.black54 : Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
