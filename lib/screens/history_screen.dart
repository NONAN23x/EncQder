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

enum FilterType { all, month, year }

class _HistoryScreenState extends State<HistoryScreen> {
  List<QrItem> _history = [];
  bool _isLoading = true;

  FilterType _filterType = FilterType.all;
  DateTime? _filterDate;
  bool _isAscending = false;

  List<QrItem> get _filteredAndSortedHistory {
    List<QrItem> items = List.from(_history);

    if (_filterType == FilterType.month && _filterDate != null) {
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

    return items;
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await StorageService().getHistory();
    if (mounted) {
      setState(() {
        _history = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EncQder History'),
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
                        child: _filteredAndSortedHistory.isEmpty
                            ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.7,
                                  child: _buildEmptyState(),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredAndSortedHistory.length,
                                itemBuilder: (context, index) {
                                  return _buildHistoryCard(_filteredAndSortedHistory[index]);
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
    final bool hasHistoryButNoMatch = _history.isNotEmpty && _filteredAndSortedHistory.isEmpty;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasHistoryButNoMatch ? Icons.filter_alt_off_rounded : Icons.qr_code_2,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          Text(
            hasHistoryButNoMatch ? 'No matches' : 'No History Yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasHistoryButNoMatch ? 'Try changing your filter settings' : 'Swipe left to Create, right to Scan',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Filter Pills
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterPill('All', FilterType.all),
                _buildFilterPill('Month', FilterType.month),
                _buildFilterPill('Year', FilterType.year),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // Active Filter Chip
          if (_filterType != FilterType.all && _filterDate != null)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Chip(
                  label: Text(
                    _filterType == FilterType.month
                        ? DateFormat('MMM yyyy').format(_filterDate!)
                        : DateFormat('yyyy').format(_filterDate!),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onDeleted: () {
                    setState(() {
                      _filterType = FilterType.all;
                      _filterDate = null;
                    });
                  },
                  deleteIcon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            )
          else
            const Spacer(),
            
          // Sort Toggle
          IconButton(
            icon: Icon(_isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
            tooltip: _isAscending ? 'Oldest first' : 'Newest first',
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
              });
            },
          ),
        ],
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
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
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
      });
      return;
    }

    final initialDate = _filterDate ?? DateTime.now();

    if (type == FilterType.year) {
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Icon(
                    item.originType == 'scanned'
                        ? Icons.qr_code_scanner_rounded
                        : Icons.qr_code_rounded,
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.originType == 'scanned' 
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.originType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: item.originType == 'scanned' 
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          ),
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
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 16, item.data.contains('://') ? 88 : 48, 16),
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
                    child: SelectableText(
                      item.data,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.data.contains('://'))
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
                    child: ElevatedButton.icon(
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
                      style: ElevatedButton.styleFrom(
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
        errorCorrectLevel: QrErrorCorrectLevel.Q,
      );

      final qrImage = QrImage(qrCode);
      
      const qrBrush = PrettyQrBrush.gradient(
        gradient: RadialGradient(
          colors: [
            Color(0xFF1565C0), // Colors.blue.shade800
            Color(0xFF000000), // black
          ],
        ),
      );

      const decoration = PrettyQrDecoration(
        // ignore: experimental_member_use
        shape: PrettyQrShape.custom(
          PrettyQrDotsSymbol(color: qrBrush),
          finderPattern: PrettyQrSquaresSymbol(
            color: qrBrush,
            rounding: 1.0,
          ),
          alignmentPatterns: PrettyQrSquaresSymbol(
            color: qrBrush,
            rounding: 1.0,
          ),
        ),
        background: Color(0xFFFFFFFF),
        quietZone: PrettyQrQuietZone.modules(2),
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
