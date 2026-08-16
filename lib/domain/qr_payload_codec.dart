import 'qr_models.dart';

abstract final class QrPayloadCodec {
  static final RegExp _upiAddressPattern = RegExp(
    r'^[A-Za-z0-9](?:[A-Za-z0-9._-]{0,254}[A-Za-z0-9])?@'
    r'[A-Za-z0-9](?:[A-Za-z0-9.-]{0,62}[A-Za-z0-9])?$',
  );
  static final RegExp _amountPattern = RegExp(r'^\d+(?:\.\d{1,2})?$');
  static const Set<String> _wifiEscapableCharacters = <String>{
    r'\',
    ';',
    ',',
    ':',
    '"',
  };

  static ParsedQrPayload classify(String rawData) {
    final wifi = parseWifi(rawData);
    if (wifi != null) {
      return ParsedQrPayload(rawData: rawData, kind: QrKind.wifi, wifi: wifi);
    }

    final upi = parseUpi(rawData);
    if (upi != null) {
      return ParsedQrPayload(rawData: rawData, kind: QrKind.upi, upi: upi);
    }

    return ParsedQrPayload(
      rawData: rawData,
      kind: QrKind.text,
      webUri: parseAllowedWebUri(rawData),
    );
  }

  static String encodeWifi(WifiPayload payload) {
    if (payload.ssid.isEmpty) {
      throw ArgumentError.value(
        payload.ssid,
        'ssid',
        'SSID must not be empty.',
      );
    }

    final password = payload.password;
    if (payload.security != WifiSecurity.open &&
        (password == null || password.isEmpty)) {
      throw ArgumentError.value(
        password,
        'password',
        'A password is required for secured Wi-Fi networks.',
      );
    }

    final type = switch (payload.security) {
      WifiSecurity.wpa => 'WPA',
      WifiSecurity.wep => 'WEP',
      WifiSecurity.open => 'nopass',
    };
    final buffer = StringBuffer('WIFI:T:$type;S:${_escapeWifi(payload.ssid)};');

    if (payload.security != WifiSecurity.open) {
      buffer.write('P:${_escapeWifi(password!)};');
    }
    if (payload.hidden) buffer.write('H:true;');
    buffer.write(';');
    return buffer.toString();
  }

  static WifiPayload? parseWifi(String rawData) {
    final data = rawData.trim();
    if (!data.startsWith('WIFI:')) return null;

    final tokens = _splitWifiTokens(data.substring('WIFI:'.length));
    if (tokens == null) return null;

    final fields = <String, String>{};
    for (final token in tokens) {
      if (token.isEmpty) continue;
      final separator = _firstUnescapedColon(token);
      if (separator <= 0) return null;

      final key = token.substring(0, separator).trim().toUpperCase();
      if (key.isEmpty || fields.containsKey(key)) return null;

      final value = _unescapeWifi(token.substring(separator + 1));
      if (value == null) return null;
      fields[key] = value;
    }

    final ssid = fields['S'];
    if (ssid == null || ssid.isEmpty) return null;

    final security = WifiSecurity.tryParse(fields['T'] ?? 'nopass');
    if (security == null) return null;

    final hiddenValue = fields['H']?.trim().toLowerCase();
    final hidden = switch (hiddenValue) {
      null || '' || 'false' => false,
      'true' => true,
      _ => null,
    };
    if (hidden == null) return null;

    final password = fields['P'];
    if (security != WifiSecurity.open &&
        (password == null || password.isEmpty)) {
      return null;
    }

    return WifiPayload(
      ssid: ssid,
      security: security,
      password: security == WifiSecurity.open ? null : password,
      hidden: hidden,
    );
  }

  static String encodeUpi(UpiPayload payload) {
    final payeeAddress = payload.payeeAddress.trim();
    if (!isValidUpiAddress(payeeAddress)) {
      throw ArgumentError.value(
        payload.payeeAddress,
        'payeeAddress',
        'Enter a structurally valid UPI ID.',
      );
    }

    final currency = payload.currency.trim().toUpperCase();
    if (currency != 'INR') {
      throw ArgumentError.value(
        payload.currency,
        'currency',
        'Only INR is supported.',
      );
    }

    final amount = _nonEmptyTrimmed(payload.amount);
    if (amount != null && !isValidUpiAmount(amount)) {
      throw ArgumentError.value(
        payload.amount,
        'amount',
        'Amount must be positive with at most two decimal places.',
      );
    }

    final parameters = <String, String>{'pa': payeeAddress, 'cu': currency};
    final payeeName = _nonEmptyTrimmed(payload.payeeName);
    final transactionNote = _nonEmptyTrimmed(payload.transactionNote);
    if (payeeName != null) parameters['pn'] = payeeName;
    if (amount != null) parameters['am'] = amount;
    if (transactionNote != null) parameters['tn'] = transactionNote;

    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: parameters,
    ).toString();
  }

  static UpiPayload? parseUpi(String rawData) {
    final uri = Uri.tryParse(rawData.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'upi' ||
        uri.host.toLowerCase() != 'pay' ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.fragment.isNotEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }

    const supportedKeys = <String>{'pa', 'pn', 'am', 'cu', 'tn'};
    final parameters = <String, String>{};
    for (final key in supportedKeys) {
      final values = uri.queryParametersAll[key];
      if (values == null || values.isEmpty) continue;
      if (values.length != 1) return null;
      parameters[key] = values.single;
    }

    final payeeAddress = parameters['pa']?.trim();
    if (payeeAddress == null || !isValidUpiAddress(payeeAddress)) return null;

    final amount = _nonEmptyTrimmed(parameters['am']);
    if (amount != null && !isValidUpiAmount(amount)) return null;

    final currency = (parameters['cu'] ?? 'INR').trim().toUpperCase();
    if (currency != 'INR') return null;

    return UpiPayload(
      payeeAddress: payeeAddress,
      payeeName: _nonEmptyTrimmed(parameters['pn']),
      amount: amount,
      transactionNote: _nonEmptyTrimmed(parameters['tn']),
      currency: currency,
    );
  }

  static bool isValidUpiAddress(String value) =>
      _upiAddressPattern.hasMatch(value.trim());

  static bool isValidUpiAmount(String value) {
    final amount = value.trim();
    if (!_amountPattern.hasMatch(amount)) return false;

    final digits = amount.replaceAll('.', '');
    return digits.contains(RegExp('[1-9]'));
  }

  static Uri? parseAllowedWebUri(String rawData) {
    final uri = Uri.tryParse(rawData.trim());
    if (uri == null) return null;

    final scheme = uri.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  static bool isAllowedWebUri(String rawData) =>
      parseAllowedWebUri(rawData) != null;

  static String _escapeWifi(String value) {
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final character = value[index];
      if (_wifiEscapableCharacters.contains(character)) buffer.write(r'\');
      buffer.write(character);
    }
    return buffer.toString();
  }

  static List<String>? _splitWifiTokens(String input) {
    final tokens = <String>[];
    final current = StringBuffer();

    for (var index = 0; index < input.length; index++) {
      final character = input[index];
      if (character == r'\') {
        if (index + 1 >= input.length) return null;
        current
          ..write(character)
          ..write(input[++index]);
      } else if (character == ';') {
        tokens.add(current.toString());
        current.clear();
      } else {
        current.write(character);
      }
    }

    if (current.isNotEmpty) tokens.add(current.toString());
    return tokens;
  }

  static int _firstUnescapedColon(String token) {
    for (var index = 0; index < token.length; index++) {
      if (token[index] == r'\') {
        index++;
      } else if (token[index] == ':') {
        return index;
      }
    }
    return -1;
  }

  static String? _unescapeWifi(String value) {
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final character = value[index];
      if (character != r'\') {
        buffer.write(character);
        continue;
      }

      if (index + 1 >= value.length) return null;
      final escaped = value[++index];
      if (!_wifiEscapableCharacters.contains(escaped)) return null;
      buffer.write(escaped);
    }
    return buffer.toString();
  }

  static String? _nonEmptyTrimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
