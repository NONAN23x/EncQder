import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/qr_models.dart';
import '../../domain/qr_payload_codec.dart';

typedef QrPreviewCallback = void Function(String data, QrKind kind);

class TextQrForm extends StatefulWidget {
  const TextQrForm({super.key, required this.onPreview});

  final QrPreviewCallback onPreview;

  @override
  State<TextQrForm> createState() => _TextQrFormState();
}

class _TextQrFormState extends State<TextQrForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 7,
          maxLength: 16384,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Text or URL',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => widget.onPreview(_controller.text.trim(), QrKind.text),
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text('Preview QR code'),
        ),
      ],
    );
  }
}

class WifiQrForm extends StatefulWidget {
  const WifiQrForm({super.key, required this.onPreview});

  final QrPreviewCallback onPreview;

  @override
  State<WifiQrForm> createState() => _WifiQrFormState();
}

class _WifiQrFormState extends State<WifiQrForm> {
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  WifiSecurity _security = WifiSecurity.wpa;
  String? _error;

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  void _preview() {
    try {
      final payload = WifiPayload(
        ssid: _ssid.text.trim(),
        password: _security == WifiSecurity.open ? null : _password.text,
        security: _security,
      );
      final encoded = QrPayloadCodec.encodeWifi(payload);
      setState(() => _error = null);
      widget.onPreview(encoded, QrKind.wifi);
    } on ArgumentError catch (error) {
      setState(() => _error = error.message?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ssid,
          maxLength: 256,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Network name (SSID)'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<WifiSecurity>(
          initialValue: _security,
          decoration: const InputDecoration(labelText: 'Security'),
          items: const [
            DropdownMenuItem(
              value: WifiSecurity.wpa,
              child: Text('WPA/WPA2/WPA3'),
            ),
            DropdownMenuItem(value: WifiSecurity.wep, child: Text('WEP')),
            DropdownMenuItem(
              value: WifiSecurity.open,
              child: Text('Open network'),
            ),
          ],
          onChanged: (value) => setState(() => _security = value!),
        ),
        if (_security != WifiSecurity.open) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            maxLength: 512,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _error,
            ),
          ),
        ],
        if (_security == WifiSecurity.open && _error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _ssid.text.trim().isEmpty ? null : _preview,
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text('Preview Wi-Fi QR code'),
        ),
      ],
    );
  }
}

class UpiQrForm extends StatefulWidget {
  const UpiQrForm({
    super.key,
    required this.onPreview,
    required this.suggestions,
    required this.onForgetSuggestion,
  });

  final QrPreviewCallback onPreview;
  final List<String> suggestions;
  final ValueChanged<String> onForgetSuggestion;

  @override
  State<UpiQrForm> createState() => _UpiQrFormState();
}

class _UpiQrFormState extends State<UpiQrForm> {
  final _vpa = TextEditingController();
  final _vpaFocus = FocusNode();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _vpa.addListener(_onVpaChanged);
  }

  @override
  void dispose() {
    _vpa.removeListener(_onVpaChanged);
    _vpa.dispose();
    _vpaFocus.dispose();
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onVpaChanged() {
    setState(() => _error = null);
  }

  void _preview() {
    try {
      final payload = UpiPayload(
        payeeAddress: _vpa.text.trim(),
        payeeName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        amount: _amount.text.trim().isEmpty ? null : _amount.text.trim(),
        transactionNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      final encoded = QrPayloadCodec.encodeUpi(payload);
      setState(() => _error = null);
      widget.onPreview(encoded, QrKind.upi);
    } on ArgumentError catch (error) {
      setState(() => _error = error.message?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RawAutocomplete<String>(
          textEditingController: _vpa,
          focusNode: _vpaFocus,
          optionsBuilder: (value) {
            final query = value.text.toLowerCase();
            return widget.suggestions.where(
              (candidate) =>
                  query.isEmpty || candidate.toLowerCase().contains(query),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(
                labelText: 'UPI ID',
                hintText: 'name@bank',
                errorText: _error,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final values = options.toList();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                    maxWidth: 420,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: values.length,
                    itemBuilder: (context, index) {
                      final value = values[index];
                      return ListTile(
                        title: Text(value),
                        onTap: () => onSelected(value),
                        trailing: IconButton(
                          tooltip: 'Forget $value',
                          onPressed: () => widget.onForgetSuggestion(value),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Payee name (optional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*(?:\.\d{0,2})?')),
          ],
          decoration: const InputDecoration(
            labelText: 'Amount (optional)',
            prefixText: '₹ ',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _vpa.text.trim().isEmpty ? null : _preview,
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text('Preview payment QR code'),
        ),
      ],
    );
  }
}
