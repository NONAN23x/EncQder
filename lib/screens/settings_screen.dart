import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
            const SnackBar(content: Text('No saved items to export')),
          );
        }
        return;
      }

      final jsonList = history.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      final archive = Archive();
      final textBytes = utf8.encode(jsonString);
      archive.addFile(ArchiveFile('encqder_history.json', textBytes.length, textBytes));

      final zipData = ZipEncoder().encode(archive);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/encqder_backup_$timestamp.zip');
      await file.writeAsBytes(zipData);

      if (context.mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'EncQder Data Backup',
          ),
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

      String? jsonContent;
      String? txtContent;

      for (final file in archive) {
        if (file.isFile && file.name == 'encqder_history.json') {
          jsonContent = utf8.decode(file.content as List<int>);
        } else if (file.isFile && file.name == 'encqder_history.txt') {
          txtContent = utf8.decode(file.content as List<int>);
        }
      }

      if (jsonContent == null && txtContent == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid backup file format')),
          );
        }
        return;
      }

      final items = <QrItem>[];

      if (jsonContent != null) {
        final decodedList = jsonDecode(jsonContent) as List<dynamic>;
        for (final item in decodedList) {
          items.add(QrItem.fromJson(item as Map<String, dynamic>));
        }
      } else if (txtContent != null) {
        final parts = txtContent.split('---');
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Home',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          _buildSectionHeader(context, 'Appearance'),
          const SizedBox(height: 16),
          _buildThemeSelector(context),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Data Management'),
          const SizedBox(height: 16),
          _buildDataCard(
            context: context,
            title: 'Export Data',
            subtitle: 'Export all QR codes to a .zip file',
            icon: Icons.upload_file_rounded,
            onTap: () => _exportData(context),
          ),
          const SizedBox(height: 12),
          _buildDataCard(
            context: context,
            title: 'Import Data',
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
          const SizedBox(height: 32),
          Center(
            child: Text(
              'EncQder v1.0.4+7',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: InkWell(
              onTap: () async {
                final url = Uri.parse('https://github.com/NONAN23x');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Developer Information',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_rounded),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.settings_suggest_rounded),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_rounded),
            ),
          ],
          selected: {themeProvider.themeMode},
          onSelectionChanged: (Set<ThemeMode> newSelection) {
            themeProvider.setThemeMode(newSelection.first);
          },
          showSelectedIcon: false,
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
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    final containerColor = isDestructive ? theme.colorScheme.errorContainer.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainer;
    final iconBgColor = isDestructive ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer;
    final iconColor = isDestructive ? theme.colorScheme.onErrorContainer : theme.colorScheme.primary;
    final splashColor = isDestructive ? theme.colorScheme.error.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1);
    
    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDestructive ? theme.colorScheme.error.withValues(alpha: 0.3) : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: splashColor,
          highlightColor: splashColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDestructive ? theme.colorScheme.error.withValues(alpha: 0.5) : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


