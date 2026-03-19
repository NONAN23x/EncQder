import 'dart:io';
import 'dart:ui' as dart_ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storage_service.dart';
import '../services/theme_provider.dart';
import '../widgets/qr_display.dart';
import 'settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const HistoryScreen({super.key, required this.themeProvider});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum FilterType { all, day, month, year }

class _HistoryScreenState extends State<HistoryScreen> with AutomaticKeepAliveClientMixin {
  List<QrItem> _history = [];
  bool _isLoading = true;

  FilterType _filterType = FilterType.all;
  DateTime? _filterDate;
  bool _isAscending = false;

  @override
  bool get wantKeepAlive => true;

  List<QrItem> _filteredHistory = [];

  void _updateFilteredHistory() {
    List<QrItem> items = List.from(_history);

    if (_filterType == FilterType.day && _filterDate != null) {
      items = items.where((item) {
        return item.createdAt.year == _filterDate!.year &&
               item.createdAt.month == _filterDate!.month &&
               item.createdAt.day == _filterDate!.day;
      }).toList();
    } else if (_filterType == FilterType.month && _filterDate != null) {
      items = items.where((item) {
        return item.createdAt.year == _filterDate!.year &&
               item.createdAt.month == _filterDate!.month;
      }).toList();
    } else if (_filterType == FilterType.year && _filterDate != null) {
      items = items.where((item) {
        return item.createdAt.year == _filterDate!.year;
      }).toList();
    }

    items.sort((a, b) {
      if (_isAscending) {
        return a.createdAt.compareTo(b.createdAt);
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    _filteredHistory = items;
  }

  @override
  void initState() {
    super.initState();
    StorageService().addListener(_onStorageChanged);
    _loadHistory();
  }

  void _onStorageChanged() {
    _loadHistory();
  }

  @override
  void dispose() {
    StorageService().removeListener(_onStorageChanged);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final items = await StorageService().getHistory();
    if (mounted) {
      setState(() {
        _history = items;
        _updateFilteredHistory();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('EncQder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    themeProvider: widget.themeProvider,
                  ),
                ),
              );
              _loadHistory();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: Column(
                    children: [
                      if (_history.isNotEmpty) _buildControlBar(),
                      Expanded(
                        child: _filteredHistory.isEmpty
                            ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.7,
                                  child: _buildEmptyState(),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredHistory.length,
                                itemBuilder: (context, index) {
                                  return _buildHistoryCard(_filteredHistory[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool hasItemsButNoMatch = _history.isNotEmpty && _filteredHistory.isEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasItemsButNoMatch ? Icons.filter_alt_off_rounded : Icons.qr_code_2,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            hasItemsButNoMatch ? 'No matches' : 'Home is Empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              hasItemsButNoMatch 
                  ? 'Try changing your filter settings to find what you\'re looking for.' 
                  : 'Swipe left to Create, right to Scan. Your saved items will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filter Pills
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterPill('All', FilterType.all),
                  _buildFilterPill('Day', FilterType.day),
                  _buildFilterPill('Month', FilterType.month),
                  _buildFilterPill('Year', FilterType.year),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            // Active Filter Chip
            if (_filterType != FilterType.all && _filterDate != null)
              Chip(
                label: Text(
                  _filterType == FilterType.day
                      ? DateFormat('MMM d, yyyy').format(_filterDate!)
                      : _filterType == FilterType.month
                          ? DateFormat('MMM yyyy').format(_filterDate!)
                          : DateFormat('yyyy').format(_filterDate!),
                ),
                onDeleted: () {
                  setState(() {
                    _filterType = FilterType.all;
                    _filterDate = null;
                    _updateFilteredHistory();
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                visualDensity: VisualDensity.compact,
              ),
              
            const SizedBox(width: 8),
              
            // Sort Toggle
            IconButton(
              icon: Icon(_isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
              tooltip: _isAscending ? 'Oldest first' : 'Newest first',
              onPressed: () {
                setState(() {
                  _isAscending = !_isAscending;
                  _updateFilteredHistory();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, FilterType type) {
    final isSelected = _filterType == type;
    return InkWell(
      onTap: () => _handleFilterTap(type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _handleFilterTap(FilterType type) async {
    if (type == FilterType.all) {
      setState(() {
        _filterType = FilterType.all;
        _filterDate = null;
        _updateFilteredHistory();
      });
      return;
    }

    final initialDate = _filterDate ?? DateTime.now();

    if (type == FilterType.day) {
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (selectedDate != null) {
        setState(() {
          _filterType = FilterType.day;
          _filterDate = selectedDate;
          _updateFilteredHistory();
        });
      }
    } else if (type == FilterType.year) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              selectedDate: initialDate,
              onChanged: (DateTime dateTime) {
                Navigator.pop(context);
                setState(() {
                  _filterType = FilterType.year;
                  _filterDate = dateTime;
                  _updateFilteredHistory();
                });
              },
            ),
          ),
        ),
      );
    } else if (type == FilterType.month) {
      int selectedYear = initialDate.year;
      int selectedMonth = initialDate.month;
      
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Month'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<int>(
                    value: selectedMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(DateFormat('MMM').format(DateTime(2000, index + 1))),
                      );
                    }),
                    onChanged: (val) {
                      setDialogState(() => selectedMonth = val!);
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: selectedYear,
                    items: List.generate(DateTime.now().year - 1999, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (val) {
                      setDialogState(() => selectedYear = val!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _filterType = FilterType.month;
                      _filterDate = DateTime(selectedYear, selectedMonth);
                      _updateFilteredHistory();
                    });
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          });
        },
      );
    }
  }

  Widget _buildHistoryCard(QrItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showQrDetails(item);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    item.originType == 'scanned'
                        ? Icons.qr_code_scanner_rounded
                        : Icons.qr_code_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label.isNotEmpty ? item.label : 'QR Code',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.originType == 'scanned' 
                                    ? Theme.of(context).colorScheme.tertiaryContainer
                                    : Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.originType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: item.originType == 'scanned' 
                                      ? Theme.of(context).colorScheme.onTertiaryContainer
                                      : Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.dataType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.data,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(item.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showWifiDetails(BuildContext context, String data) {
    String ssid = 'Unknown';
    String password = '';
    
    final ssidMatch = RegExp(r'S:([^;]+);').firstMatch(data);
    if (ssidMatch != null) ssid = ssidMatch.group(1) ?? 'Unknown';
    
    final passMatch = RegExp(r'P:([^;]+);').firstMatch(data);
    if (passMatch != null) password = passMatch.group(1) ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_rounded),
            SizedBox(width: 12),
            Text('Wi-Fi Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Network Name (SSID)', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(ssid, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (password.isNotEmpty) ...[
              Text('Password', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              SelectableText(password, style: Theme.of(context).textTheme.bodyLarge),
            ] else ...[
              const Text('No password required (Open Network)'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Note: To connect, your device camera must scan the QR directly, or you can copy the password and connect manually in Settings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (password.isNotEmpty)
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: password));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy Password'),
            ),
        ],
      ),
    );
  }

  void _showQrDetails(QrItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      item.label.isNotEmpty ? item.label : 'QR Code',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      final controller = TextEditingController(text: item.label);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Rename'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'Enter new label',
                            ),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final newLabel = controller.text.trim();
                                await StorageService().updateLabel(item.id, newLabel);
                                setModalState(() {
                                  item.label = newLabel;
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                                _loadHistory();
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrDisplay(data: item.data),
                ),
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 16, (item.data.contains('://') || item.dataType == 'WIFI') ? 88 : 48, 16),
                    width: double.infinity,
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
                    child: Text(
                      item.data,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.dataType == 'WIFI')
                          IconButton(
                            icon: const Icon(Icons.wifi_rounded, size: 20),
                            tooltip: 'View Wi-Fi details',
                            onPressed: () {
                              _showWifiDetails(context, item.data);
                            },
                          )
                        else if (item.data.contains('://'))
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded, size: 20),
                            tooltip: 'Open link',
                            onPressed: () async {
                              final url = Uri.tryParse(item.data);
                              if (url != null && await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open link')),
                                  );
                                }
                              }
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          tooltip: 'Copy to clipboard',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: item.data));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (context, animation, secondaryAnimation) => ShareOverlay(item: item),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await StorageService().removeItem(item.id);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _loadHistory();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
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
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class ShareOverlay extends StatefulWidget {
  final QrItem item;

  const ShareOverlay({super.key, required this.item});

  @override
  State<ShareOverlay> createState() => _ShareOverlayState();
}

class _ShareOverlayState extends State<ShareOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideBottom;
  late final Animation<Offset> _slideTop;
  late final Animation<double> _fadeBottom;
  late final Animation<double> _fadeTop;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slideBottom = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.71, curve: Curves.easeOutCubic),
      ),
    );
    _fadeBottom = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.71, curve: Curves.easeIn),
      ),
    );

    _slideTop = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.29, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _fadeTop = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.29, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<File> _generateImageFile() async {
    try {
      final qrCode = QrCode.fromData(
        data: widget.item.data,
        errorCorrectLevel: QrErrorCorrectLevel.H,
      );

      final qrImage = QrImage(qrCode);
      
      // Get the current primary color to match the dynamic theme
      final primaryColor = Theme.of(context).colorScheme.primary;
      final subtleGradientColor = Color.lerp(primaryColor, const Color(0xFF000000), 0.4) ?? primaryColor;
      
      final qrBrush = PrettyQrBrush.gradient(
        gradient: RadialGradient(
          colors: [
            subtleGradientColor,
            const Color(0xFF000000), // black
          ],
        ),
      );

      final decoration = PrettyQrDecoration(
        // ignore: experimental_member_use
        shape: PrettyQrShape.custom(
          PrettyQrSmoothSymbol(
            color: qrBrush,
            roundFactor: 0.5,
          ),
          finderPattern: PrettyQrSmoothSymbol(
            color: qrBrush,
            roundFactor: 0.8,
          ),
          alignmentPatterns: PrettyQrSmoothSymbol(
            color: qrBrush,
            roundFactor: 0.8,
          ),
        ),
        background: Color(0xFFFFFFFF),
        quietZone: const PrettyQrQuietZone.modules(2),
      );

      final configuration = createLocalImageConfiguration(context);
      final bytes = await qrImage.toImageAsBytes(
        size: 1024,
        decoration: decoration,
        configuration: configuration,
      );

      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/encqder_${widget.item.id}.png');
        await file.writeAsBytes(bytes.buffer.asUint8List());
        return file;
      } else {
        throw Exception('Failed to generate image data');
      }
    } catch (e) {
      throw Exception('Image generation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: dart_ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40 + MediaQuery.of(context).padding.bottom + 64, // Adjusted relative to the original button
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FadeTransition(
                  opacity: _fadeTop,
                  child: SlideTransition(
                    position: _slideTop,
                    child: FilledButton.icon(
                      onPressed: () async {
                        try {
                          final file = await _generateImageFile();
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(file.path)],
                              text: '${widget.item.label.isNotEmpty ? widget.item.label : "QR Code"}\nScanned via EncQder: ${widget.item.data}',
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to share: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeBottom,
                  child: SlideTransition(
                    position: _slideBottom,
                    child: FilledButton.icon(
                      onPressed: () async {
                        try {
                          final file = await _generateImageFile();
                          final access = await Gal.hasAccess();
                          if (!access) {
                            final request = await Gal.requestAccess();
                            if (!request) {
                               if (context.mounted) Navigator.pop(context);
                               return;
                            }
                          }
                          await Gal.putImage(file.path, album: 'EncQder');
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved to Gallery ✓'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save to gallery: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_alt_rounded),
                      label: const Text('Save to Gallery'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
