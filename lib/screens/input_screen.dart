import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../widgets/expandable_text_card.dart';
import '../widgets/qr_display.dart';
import '../widgets/enlarged_qr_dialog.dart';
import 'history_screen.dart' show ShareOverlay;

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> with AutomaticKeepAliveClientMixin {
  int _expandedIndex = -1; // 0 = Text, 1 = Wi-Fi, 2 = UPI

  // Text
  final TextEditingController _textController = TextEditingController();

  // Wi-Fi
  final TextEditingController _wifiSsidController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  String _wifiSecurity = 'WPA';

  // UPI
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _upiNameController = TextEditingController();
  final TextEditingController _upiAmountController = TextEditingController();
  final TextEditingController _upiNoteController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _textController.dispose();
    _wifiSsidController.dispose();
    _wifiPasswordController.dispose();
    _upiIdController.dispose();
    _upiNameController.dispose();
    _upiAmountController.dispose();
    _upiNoteController.dispose();
    super.dispose();
  }

  void _showQrPreview(String data, String dataType) {
    if (data.trim().isEmpty) return;
    
    FocusScope.of(context).unfocus();
    setState(() { _expandedIndex = -1; });

    final tempItem = QrItem(
      id: 'preview',
      data: data.trim(),
      createdAt: DateTime.now(),
      dataType: dataType,
      label: 'Preview',
    );

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
                'Preview',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => EnlargedQrDialog(
                          item: tempItem,
                          heroTag: 'qr_preview_${tempItem.id}',
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'qr_preview_${tempItem.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: QrDisplay(data: tempItem.data),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ExpandableTextCard(
                text: tempItem.data,
                padding: const EdgeInsets.all(16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                         Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (context, animation, secondaryAnimation) => ShareOverlay(item: tempItem),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
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
                      onPressed: () {
                        Navigator.pop(context);
                        _saveData(data, dataType);
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
    );
  }

  void _saveData(String data, String dataType) async {
    if (data.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await StorageService().saveItem(
      data.trim(),
      dataType: dataType,
    );

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to Home!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Clear fields
    if (dataType == 'TEXT') {
      _textController.clear();
    } else if (dataType == 'WIFI') {
      _wifiSsidController.clear();
      _wifiPasswordController.clear();
      _wifiSecurity = 'WPA';
    } else if (dataType == 'UPI') {
      _upiIdController.clear();
      _upiNameController.clear();
      _upiAmountController.clear();
      _upiNoteController.clear();
    }
    setState(() {});
  }

  String _generateWifiString() {
    final ssid = _wifiSsidController.text.trim();
    final pass = _wifiPasswordController.text.trim();
    if (ssid.isEmpty) return '';
    if (_wifiSecurity == 'None' || _wifiSecurity == 'nopass') {
      return 'WIFI:T:nopass;S:$ssid;;';
    }
    return 'WIFI:T:$_wifiSecurity;S:$ssid;P:$pass;;';
  }

  String _generateUpiString() {
    final upiId = _upiIdController.text.trim();
    if (upiId.isEmpty) return '';
    final name = _upiNameController.text.trim();
    final amount = _upiAmountController.text.trim();
    final note = _upiNoteController.text.trim();

    String uri = 'upi://pay?pa=$upiId';
    if (name.isNotEmpty) uri += '&pn=${Uri.encodeComponent(name)}';
    if (amount.isNotEmpty) uri += '&am=$amount';
    uri += '&cu=INR';
    if (note.isNotEmpty) uri += '&tn=${Uri.encodeComponent(note)}';
    return uri;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Create QR')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _AnimatedExpandableCard(
                    isExpanded: _expandedIndex == 0,
                    onTap: () => setState(() => _expandedIndex = _expandedIndex == 0 ? -1 : 0),
                    title: 'Text / URL',
                    icon: Icons.text_fields_rounded,
                    body: _buildTextBody(),
                  ),
                  _AnimatedExpandableCard(
                    isExpanded: _expandedIndex == 1,
                    onTap: () => setState(() => _expandedIndex = _expandedIndex == 1 ? -1 : 1),
                    title: 'Wi-Fi Network',
                    icon: Icons.wifi_rounded,
                    body: _buildWifiBody(),
                  ),
                  _AnimatedExpandableCard(
                    isExpanded: _expandedIndex == 2,
                    onTap: () => setState(() => _expandedIndex = _expandedIndex == 2 ? -1 : 2),
                    title: 'UPI Payment',
                    icon: Icons.account_balance_wallet_rounded,
                    body: _buildUpiBody(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _textController,
          maxLength: 500,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Enter text, link, or data here...',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _textController.text.trim().isNotEmpty
              ? () => _showQrPreview(_textController.text, 'TEXT')
              : null,
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text('Generate QR Code'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWifiBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _wifiSsidController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Network Name (SSID)',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownMenu<String>(
          initialSelection: _wifiSecurity,
          expandedInsets: EdgeInsets.zero,
          label: const Text('Security'),
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 'WPA', label: 'WPA/WPA2/WPA3'),
            DropdownMenuEntry(value: 'WEP', label: 'WEP'),
            DropdownMenuEntry(value: 'nopass', label: 'None'),
          ],
          onSelected: (val) {
            if (val != null) {
              setState(() => _wifiSecurity = val);
            }
          },
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_wifiSecurity != 'nopass') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _wifiPasswordController,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _wifiSsidController.text.trim().isNotEmpty
              ? () => _showQrPreview(_generateWifiString(), 'WIFI')
              : null,
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text('Generate Wi-Fi QR Code'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpiBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final recentIds = StorageService().getRecentUpiIds();
                if (textEditingValue.text.isEmpty) {
                  return recentIds.take(5);
                }
                return recentIds.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _upiIdController.text = selection;
                setState(() {});
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                controller.addListener(() {
                  if (_upiIdController.text != controller.text) {
                    _upiIdController.text = controller.text;
                    setState(() {});
                  }
                });
                if (controller.text.isEmpty && _upiIdController.text.isNotEmpty) {
                  controller.text = _upiIdController.text;
                }
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'UPI ID (VPA)',
                    hintText: 'example@upi',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        maxWidth: constraints.maxWidth,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final String option = options.elementAt(index);
                          return ListTile(
                            leading: Icon(Icons.history_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                            title: Text(option),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                StorageService().forgetUpiId(option);
                                // Hack to force autocomplete to refresh options or close
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _upiNameController,
          decoration: InputDecoration(
            labelText: 'Payee Name (Optional)',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _upiAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
          ],
          decoration: InputDecoration(
            labelText: 'Amount (Optional)',
            prefixText: '₹ ',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _upiNoteController,
          decoration: InputDecoration(
            labelText: 'Note (Optional)',
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _upiIdController.text.trim().isNotEmpty && _upiIdController.text.contains('@')
              ? () => _showQrPreview(_generateUpiString(), 'UPI')
              : null,
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text('Generate UPI QR Code'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedExpandableCard extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;
  final String title;
  final IconData icon;
  final Widget body;

  const _AnimatedExpandableCard({
    required this.isExpanded,
    required this.onTap,
    required this.title,
    required this.icon,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: isExpanded ? 24 : 12, top: isExpanded ? 12 : 0),
      decoration: BoxDecoration(
        color: isExpanded ? theme.colorScheme.surfaceContainerHigh : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(isExpanded ? 24 : 16),
        border: Border.all(
          color: isExpanded ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isExpanded ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isExpanded ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: isExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600,
                            color: isExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: body,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}