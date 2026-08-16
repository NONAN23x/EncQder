enum QrKind {
  text('text'),
  wifi('wifi'),
  upi('upi');

  const QrKind(this.wireName);

  final String wireName;

  static QrKind? tryParse(Object? value) {
    if (value is QrKind) return value;
    if (value is! String) return null;

    return switch (value.trim().toLowerCase()) {
      'text' => QrKind.text,
      'wifi' || 'wi-fi' => QrKind.wifi,
      'upi' => QrKind.upi,
      _ => null,
    };
  }

  static QrKind parse(Object? value, {QrKind fallback = QrKind.text}) =>
      tryParse(value) ?? fallback;
}

enum QrOrigin {
  generated('generated'),
  scanned('scanned'),
  imported('imported');

  const QrOrigin(this.wireName);

  final String wireName;

  static QrOrigin? tryParse(Object? value) {
    if (value is QrOrigin) return value;
    if (value is! String) return null;

    return switch (value.trim().toLowerCase()) {
      'generated' => QrOrigin.generated,
      'scanned' => QrOrigin.scanned,
      'imported' => QrOrigin.imported,
      _ => null,
    };
  }

  static QrOrigin parse(
    Object? value, {
    QrOrigin fallback = QrOrigin.generated,
  }) => tryParse(value) ?? fallback;
}

enum WifiSecurity {
  wpa('wpa'),
  wep('wep'),
  open('open');

  const WifiSecurity(this.wireName);

  final String wireName;

  static WifiSecurity? tryParse(Object? value) {
    if (value is WifiSecurity) return value;
    if (value is! String) return null;

    return switch (value.trim().toLowerCase()) {
      'wpa' || 'wpa2' || 'wpa3' || 'sae' => WifiSecurity.wpa,
      'wep' => WifiSecurity.wep,
      'open' || 'none' || 'nopass' => WifiSecurity.open,
      _ => null,
    };
  }

  static WifiSecurity parse(
    Object? value, {
    WifiSecurity fallback = WifiSecurity.wpa,
  }) => tryParse(value) ?? fallback;
}

final class QrItem {
  QrItem({
    required this.id,
    required this.data,
    required DateTime createdAt,
    required this.kind,
    this.origin = QrOrigin.generated,
    this.label = '',
    this.hiddenFromUpiSuggestions = false,
  }) : createdAt = createdAt.toUtc();

  factory QrItem.fromJson(Map<String, dynamic> json, {bool strict = false}) {
    final id = _requiredString(json, 'id', allowNumber: !strict);
    final data = _requiredString(json, 'data');
    final createdAt = _parseDateTime(
      json['createdAt'],
      allowEpochMilliseconds: !strict,
    );

    final labelValue = json['label'];
    if ((strict && !json.containsKey('label')) ||
        (labelValue is! String && (strict || labelValue != null))) {
      throw const FormatException('QR item label must be a string.');
    }

    final Object? hiddenValue;
    if (strict) {
      if (!json.containsKey('hiddenFromUpiSuggestions')) {
        throw const FormatException(
          'QR item hiddenFromUpiSuggestions must be a boolean.',
        );
      }
      hiddenValue = json['hiddenFromUpiSuggestions'];
    } else {
      final extraData = json['extraData'];
      final legacyExtra = extraData is Map
          ? Map<String, dynamic>.from(extraData)
          : const <String, dynamic>{};
      hiddenValue =
          json['hiddenFromUpiSuggestions'] ??
          json['hiddenFromSuggestions'] ??
          legacyExtra['hiddenFromUpiSuggestions'] ??
          legacyExtra['hiddenFromSuggestions'];
    }

    if (hiddenValue is! bool && (strict || hiddenValue != null)) {
      throw const FormatException(
        'QR item hiddenFromUpiSuggestions must be a boolean.',
      );
    }

    final originValue = strict
        ? json['origin']
        : json['origin'] ?? json['originType'];
    final kindValue = strict ? json['kind'] : json['kind'] ?? json['dataType'];
    final origin = QrOrigin.tryParse(originValue);
    final kind = QrKind.tryParse(kindValue);
    if (strict && origin == null) {
      throw const FormatException('QR item origin is invalid.');
    }
    if (strict && kind == null) {
      throw const FormatException('QR item kind is invalid.');
    }

    return QrItem(
      id: id,
      data: data,
      createdAt: createdAt,
      origin: origin ?? QrOrigin.generated,
      kind: kind ?? QrKind.text,
      label: labelValue as String? ?? '',
      hiddenFromUpiSuggestions: hiddenValue as bool? ?? false,
    );
  }

  final String id;
  final String data;
  final DateTime createdAt;
  final QrOrigin origin;
  final QrKind kind;
  final String label;
  final bool hiddenFromUpiSuggestions;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'data': data,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'origin': origin.wireName,
    'kind': kind.wireName,
    'label': label,
    'hiddenFromUpiSuggestions': hiddenFromUpiSuggestions,
  };

  QrItem copyWith({
    String? id,
    String? data,
    DateTime? createdAt,
    QrOrigin? origin,
    QrKind? kind,
    String? label,
    bool? hiddenFromUpiSuggestions,
  }) {
    return QrItem(
      id: id ?? this.id,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      origin: origin ?? this.origin,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      hiddenFromUpiSuggestions:
          hiddenFromUpiSuggestions ?? this.hiddenFromUpiSuggestions,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QrItem &&
            other.id == id &&
            other.data == data &&
            other.createdAt == createdAt &&
            other.origin == origin &&
            other.kind == kind &&
            other.label == label &&
            other.hiddenFromUpiSuggestions == hiddenFromUpiSuggestions;
  }

  @override
  int get hashCode => Object.hash(
    id,
    data,
    createdAt,
    origin,
    kind,
    label,
    hiddenFromUpiSuggestions,
  );

  @override
  String toString() =>
      'QrItem(id: $id, kind: ${kind.wireName}, origin: ${origin.wireName})';

  static String _requiredString(
    Map<String, dynamic> json,
    String key, {
    bool allowNumber = false,
  }) {
    final value = json[key];
    final stringValue = switch (value) {
      String value => value,
      num value when allowNumber => value.toString(),
      _ => throw FormatException('QR item $key must be a string.'),
    };

    if (stringValue.isEmpty) {
      throw FormatException('QR item $key must not be empty.');
    }
    return stringValue;
  }

  static DateTime _parseDateTime(
    Object? value, {
    required bool allowEpochMilliseconds,
  }) {
    final parsed = switch (value) {
      String value => DateTime.tryParse(value),
      int value when allowEpochMilliseconds =>
        DateTime.fromMillisecondsSinceEpoch(value, isUtc: true),
      _ => null,
    };

    if (parsed == null) {
      throw const FormatException('QR item createdAt is invalid.');
    }
    return parsed.toUtc();
  }
}

final class WifiPayload {
  const WifiPayload({
    required this.ssid,
    this.security = WifiSecurity.wpa,
    this.password,
    this.hidden = false,
  });

  final String ssid;
  final WifiSecurity security;
  final String? password;
  final bool hidden;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WifiPayload &&
            other.ssid == ssid &&
            other.security == security &&
            other.password == password &&
            other.hidden == hidden;
  }

  @override
  int get hashCode => Object.hash(ssid, security, password, hidden);

  @override
  String toString() =>
      'WifiPayload(ssid: $ssid, security: ${security.wireName}, hidden: $hidden)';
}

final class UpiPayload {
  const UpiPayload({
    required this.payeeAddress,
    this.payeeName,
    this.amount,
    this.transactionNote,
    this.currency = 'INR',
  });

  final String payeeAddress;
  final String? payeeName;
  final String? amount;
  final String? transactionNote;
  final String currency;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UpiPayload &&
            other.payeeAddress == payeeAddress &&
            other.payeeName == payeeName &&
            other.amount == amount &&
            other.transactionNote == transactionNote &&
            other.currency == currency;
  }

  @override
  int get hashCode =>
      Object.hash(payeeAddress, payeeName, amount, transactionNote, currency);

  @override
  String toString() => 'UpiPayload(payeeAddress: $payeeAddress)';
}

final class ParsedQrPayload {
  const ParsedQrPayload({
    required this.rawData,
    required this.kind,
    this.wifi,
    this.upi,
    this.webUri,
  }) : assert(kind == QrKind.wifi ? wifi != null : wifi == null),
       assert(kind == QrKind.upi ? upi != null : upi == null),
       assert(kind == QrKind.text || webUri == null);

  final String rawData;
  final QrKind kind;
  final WifiPayload? wifi;
  final UpiPayload? upi;
  final Uri? webUri;

  bool get isActionable => actionableUri != null;

  Uri? get actionableUri {
    if (upi != null) return Uri.tryParse(rawData.trim());
    return webUri;
  }

  bool get requiresLaunchConfirmation =>
      upi != null || webUri?.scheme.toLowerCase() == 'http';
}
