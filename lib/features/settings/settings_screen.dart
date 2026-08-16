import 'dart:io';

import 'package:file_selector/file_selector.dart' as selector;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme_controller.dart';
import '../../data/backup_service.dart';
import '../../data/history_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.historyStore,
    required this.backupService,
    required this.themeController,
  });

  final HistoryStore historyStore;
  final BackupService backupService;
  final ThemeController themeController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _busyLabel;
  bool _savingTheme = false;

  bool get _busy => _busyLabel != null;

  Future<void> _setThemeMode(ThemeMode mode) async {
    if (_savingTheme) return;
    setState(() => _savingTheme = true);
    try {
      await widget.themeController.setThemeMode(mode);
    } catch (error) {
      if (mounted) _showError('Theme preference could not be saved', error);
    } finally {
      if (mounted) setState(() => _savingTheme = false);
    }
  }

  Future<void> _exportData() async {
    if (widget.historyStore.items.isEmpty) {
      _showMessage('There are no saved QR codes to export.');
      return;
    }

    await _runDataAction('Creating backup…', () async {
      final directory = await getTemporaryDirectory();
      await widget.backupService.clearTemporaryExports(directory);
      File? file;
      try {
        file = await widget.backupService.exportToDirectory(directory);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'EncQder history backup',
            subject: 'EncQder backup',
          ),
        );
      } finally {
        if (file != null && await file.exists()) await file.delete();
      }
    });
  }

  Future<void> _importData() async {
    const typeGroup = selector.XTypeGroup(
      label: 'EncQder backups',
      extensions: <String>['json', 'zip'],
    );
    final selector.XFile? selected;
    try {
      selected = await selector.openFile(
        acceptedTypeGroups: const <selector.XTypeGroup>[typeGroup],
      );
    } catch (error) {
      if (mounted) _showError('Could not open the file picker', error);
      return;
    }
    if (selected == null || !mounted) return;
    final selectedPath = selected.path;

    ImportSummary? summary;
    final succeeded = await _runDataAction('Importing backup…', () async {
      summary = await widget.backupService.importFile(File(selectedPath));
    });
    if (!succeeded || !mounted || summary == null) return;

    final result = summary!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImportResultRow(label: 'Added', value: result.added),
            _ImportResultRow(label: 'Already saved', value: result.duplicates),
            _ImportResultRow(label: 'Rejected', value: result.rejected),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmWipe() async {
    final itemCount = widget.historyStore.items.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all history?'),
        content: Text(
          itemCount == 0
              ? 'This permanently deletes any local history and recovery '
                    'copies. Backups you exported elsewhere are not affected.'
              : 'This permanently deletes $itemCount saved QR '
                    '${itemCount == 1 ? 'code' : 'codes'} and local recovery '
                    'copies. Backups you exported elsewhere are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final succeeded = await _runDataAction('Deleting history…', () async {
      await widget.historyStore.clearHistory();
      await widget.backupService.clearTemporaryExports(
        await getTemporaryDirectory(),
      );
    });
    if (succeeded && mounted) _showMessage('History deleted.');
  }

  Future<void> _openProject() async {
    try {
      final opened = await launchUrl(
        Uri.parse('https://github.com/NONAN23x/EncQder'),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showMessage('No browser is available.');
    } catch (error) {
      if (mounted) _showError('Could not open the project page', error);
    }
  }

  Future<bool> _runDataAction(
    String label,
    Future<void> Function() operation,
  ) async {
    if (_busy) return false;
    setState(() => _busyLabel = label);
    try {
      await operation();
      return true;
    } catch (error) {
      if (mounted) _showError('Data action failed', error);
      return false;
    } finally {
      if (mounted) setState(() => _busyLabel = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String prefix, Object error) {
    final details = switch (error) {
      FormatException error => error.message,
      _ => error.toString(),
    };
    _showMessage('$prefix: $details');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            key: const ValueKey('return-home'),
            tooltip: 'Home',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionTitle('Appearance'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Align(
                  alignment: Alignment.center,
                  child: ListenableBuilder(
                    listenable: widget.themeController,
                    builder: (context, _) => Semantics(
                      label: 'App theme',
                      child: SegmentedButton<ThemeMode>(
                        key: const ValueKey('theme-selector'),
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_rounded),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_suggest_rounded),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_rounded),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: <ThemeMode>{widget.themeController.themeMode},
                        showSelectedIcon: false,
                        onSelectionChanged: _savingTheme
                            ? null
                            : (selection) => _setThemeMode(selection.single),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const _SectionTitle('Data management'),
          const SizedBox(height: 12),
          _SettingsActionCard(
            key: const ValueKey('export-data'),
            title: 'Export backup',
            subtitle: 'Share a versioned JSON copy of your saved QR codes',
            icon: Icons.share_rounded,
            onTap: _busy ? null : _exportData,
          ),
          const SizedBox(height: 12),
          _SettingsActionCard(
            key: const ValueKey('import-data'),
            title: 'Import backup',
            subtitle: 'Restore an EncQder JSON or legacy ZIP backup',
            icon: Icons.file_download_outlined,
            onTap: _busy ? null : _importData,
          ),
          const SizedBox(height: 12),
          _SettingsActionCard(
            key: const ValueKey('wipe-data'),
            title: 'Delete all history',
            subtitle: 'Permanently remove saved QR codes from this device',
            icon: Icons.delete_forever_rounded,
            destructive: true,
            onTap: _busy ? null : _confirmWipe,
          ),
          if (_busyLabel case final label?) ...[
            const SizedBox(height: 20),
            Semantics(
              liveRegion: true,
              label: label,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          const _SectionTitle('About'),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.qr_code_2_rounded),
                  title: Text('EncQder'),
                  subtitle: Text('Version 1.1.0 (8) · Android'),
                ),
                const Divider(height: 1),
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('View project on GitHub'),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: _openProject,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsActionCard extends StatelessWidget {
  const _SettingsActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = destructive ? colors.error : colors.onSurface;
    final iconBackground = destructive
        ? colors.errorContainer
        : colors.primaryContainer;
    final iconForeground = destructive
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;

    return Card(
      color: destructive
          ? colors.errorContainer.withValues(alpha: 0.24)
          : colors.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minTileHeight: 80,
        enabled: onTap != null,
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconForeground),
        ),
        title: Text(
          title,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ImportResultRow extends StatelessWidget {
  const _ImportResultRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            MaterialLocalizations.of(context).formatDecimal(value),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
