import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/qr_display.dart';
import 'history_screen.dart' show ShareOverlay;

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> with AutomaticKeepAliveClientMixin {
  int _expandedIndex = 0; // 0 = Text, 1 = Wi-Fi, 2 = UPI

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
                  child: QrDisplay(data: tempItem.data),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).cardTheme.shape is RoundedRectangleBorder
                        ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side.color
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  tempItem.data,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
    final theme = Theme.of(context);
    
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
              child: ExpansionPanelList(
                elevation: 0,
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _expandedIndex = isExpanded ? index : -1;
                  });
                },
                children: [
                  _buildTextPanel(theme),
                  _buildWifiPanel(theme),
                  _buildUpiPanel(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ExpansionPanel _buildTextPanel(ThemeData theme) {
    return ExpansionPanel(
      backgroundColor: theme.cardTheme.color,
      headerBuilder: (BuildContext context, bool isExpanded) {
        return const ListTile(
          leading: Icon(Icons.text_fields_rounded),
          title: Text('Text / URL', style: TextStyle(fontWeight: FontWeight.w600)),
        );
      },
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
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
                  borderRadius: BorderRadius.circular(12),
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
            ),
          ],
        ),
      ),
      isExpanded: _expandedIndex == 0,
      canTapOnHeader: true,
    );
  }

  ExpansionPanel _buildWifiPanel(ThemeData theme) {
    return ExpansionPanel(
      backgroundColor: theme.cardTheme.color,
      headerBuilder: (BuildContext context, bool isExpanded) {
        return const ListTile(
          leading: Icon(Icons.wifi_rounded),
          title: Text('Wi-Fi Network', style: TextStyle(fontWeight: FontWeight.w600)),
        );
      },
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _wifiSsidController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Network Name (SSID)',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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
            ),
          ],
        ),
      ),
      isExpanded: _expandedIndex == 1,
      canTapOnHeader: true,
    );
  }

  ExpansionPanel _buildUpiPanel(ThemeData theme) {
    return ExpansionPanel(
      backgroundColor: theme.cardTheme.color,
      headerBuilder: (BuildContext context, bool isExpanded) {
        return const ListTile(
          leading: Icon(Icons.account_balance_wallet_rounded),
          title: Text('UPI Payment', style: TextStyle(fontWeight: FontWeight.w600)),
        );
      },
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _upiIdController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'UPI ID (VPA)',
                hintText: 'example@upi',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _upiNameController,
              decoration: InputDecoration(
                labelText: 'Payee Name (Optional)',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _upiAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (Optional)',
                prefixText: '₹ ',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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
            ),
          ],
        ),
      ),
      isExpanded: _expandedIndex == 2,
      canTapOnHeader: true,
    );
  }
}