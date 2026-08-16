import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/qr_models.dart';
import '../domain/qr_payload_codec.dart';

const String historyDocumentFormat = 'encqder-history';
const int historySchemaVersion = 2;
const int maximumQrPayloadBytes = 16 * 1024;
const int maximumQrLabelCharacters = 80;

typedef HistoryClock = DateTime Function();
typedef HistoryIdFactory = String Function();
typedef PreferencesProvider = Future<SharedPreferences> Function();
typedef HistoryFileWriter = Future<void> Function(File file, List<int> bytes);

final class UnsupportedHistorySchemaException extends FormatException {
  const UnsupportedHistorySchemaException(super.message);
}

final class DecodedHistoryDocument {
  const DecodedHistoryDocument({
    required this.items,
    required this.isLegacy,
    this.rejectedItems = 0,
  });

  final List<QrItem> items;
  final bool isLegacy;
  final int rejectedItems;
}

/// The single wire-format implementation shared by on-device history and
/// manually exported backups.
abstract final class HistoryDocumentCodec {
  static Map<String, dynamic> toJson(
    Iterable<QrItem> items, {
    required DateTime generatedAt,
  }) {
    return <String, dynamic>{
      'format': historyDocumentFormat,
      'schemaVersion': historySchemaVersion,
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }

  static String encode(
    Iterable<QrItem> items, {
    required DateTime generatedAt,
    bool pretty = false,
  }) {
    final document = toJson(items, generatedAt: generatedAt);
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(document)
        : jsonEncode(document);
  }

  /// Decodes schema v2 and the pre-v2 bare JSON array.
  ///
  /// On-device files use strict mode. Backup imports use partial mode so a
  /// malformed record can be reported without hiding otherwise valid records.
  static DecodedHistoryDocument decode(
    String source, {
    bool allowPartial = false,
  }) {
    final Object? root;
    try {
      root = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('History is not valid JSON: ${error.message}');
    }

    final List<dynamic> rawItems;
    final bool isLegacy;
    if (root is List<dynamic>) {
      rawItems = root;
      isLegacy = true;
    } else if (root is Map<String, dynamic>) {
      final schema = root['schemaVersion'];
      if (schema is int && schema > historySchemaVersion) {
        throw UnsupportedHistorySchemaException(
          'This backup uses newer schema version $schema.',
        );
      }
      if (root['format'] != historyDocumentFormat ||
          schema != historySchemaVersion) {
        throw const FormatException('Unsupported EncQder history format.');
      }

      final generatedAt = root['generatedAt'];
      if (generatedAt is! String || DateTime.tryParse(generatedAt) == null) {
        throw const FormatException('History generatedAt is invalid.');
      }

      final items = root['items'];
      if (items is! List<dynamic>) {
        throw const FormatException('History items must be a JSON array.');
      }
      rawItems = items;
      isLegacy = false;
    } else {
      throw const FormatException(
        'History must be an EncQder object or a legacy JSON array.',
      );
    }

    final items = <QrItem>[];
    var rejectedItems = 0;
    final ids = <String>{};
    for (var index = 0; index < rawItems.length; index++) {
      try {
        final rawItem = rawItems[index];
        if (rawItem is! Map) {
          throw const FormatException('QR item must be a JSON object.');
        }
        final item = QrItem.fromJson(
          Map<String, dynamic>.from(rawItem),
          strict: !isLegacy,
        );
        validateQrItem(item);
        if (!ids.add(item.id)) {
          throw FormatException('Duplicate QR item id ${item.id}.');
        }
        items.add(item);
      } catch (error) {
        if (!allowPartial) {
          throw FormatException('Invalid QR item at index $index: $error');
        }
        rejectedItems++;
      }
    }

    return DecodedHistoryDocument(
      items: items,
      isLegacy: isLegacy,
      rejectedItems: rejectedItems,
    );
  }

  static void validateQrItem(QrItem item) {
    if (item.id.trim().isEmpty) {
      throw const FormatException('QR item id must not be empty.');
    }
    if (item.data.trim().isEmpty) {
      throw const FormatException('QR item data must not be empty.');
    }
    if (utf8.encode(item.data).length > maximumQrPayloadBytes) {
      throw const FormatException('QR item payload exceeds 16 KiB.');
    }
    if (item.label.runes.length > maximumQrLabelCharacters) {
      throw const FormatException('QR item label exceeds 80 characters.');
    }
  }
}

enum HistoryRecoveryStatus {
  recoveredFromBackup,
  migratedLegacyFile,
  migratedSharedPreferences,
  startedEmptyAfterCorruption,
}

final class HistoryRecoveryNotice {
  const HistoryRecoveryNotice({
    required this.status,
    required this.message,
    this.quarantinedPaths = const <String>[],
  });

  final HistoryRecoveryStatus status;
  final String message;
  final List<String> quarantinedPaths;
}

final class HistoryMergeSummary {
  const HistoryMergeSummary({required this.added, required this.duplicates});

  final int added;
  final int duplicates;
}

/// Durable, serialised storage for EncQder history.
///
/// All mutations write a fully validated temporary document before replacing
/// the primary file. The in-memory list changes only after that replacement
/// succeeds.
final class HistoryStore extends ChangeNotifier {
  HistoryStore({
    required this.directory,
    HistoryClock? clock,
    HistoryIdFactory? idFactory,
    PreferencesProvider? preferencesProvider,
    HistoryFileWriter? fileWriter,
  }) : _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? const Uuid().v4,
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance,
       _fileWriter = fileWriter ?? _defaultFileWriter;

  static const String legacyPreferencesKey = 'encqder_history';
  static const String fileName = 'encqder_history.json';

  final Directory directory;
  final HistoryClock _clock;
  final HistoryIdFactory _idFactory;
  final PreferencesProvider _preferencesProvider;
  final HistoryFileWriter _fileWriter;

  List<QrItem> _items = const <QrItem>[];
  Future<void> _operationTail = Future<void>.value();
  bool _initialized = false;
  Object? _lastError;
  StackTrace? _lastStackTrace;
  HistoryRecoveryNotice? _recoveryNotice;

  File get _primaryFile => File(_pathFor(fileName));
  File get _temporaryFile => File(_pathFor('$fileName.tmp'));
  File get _backupFile => File(_pathFor('$fileName.bak'));
  File get _backupTemporaryFile => File(_pathFor('$fileName.bak.tmp'));

  bool get isInitialized => _initialized;
  UnmodifiableListView<QrItem> get items => UnmodifiableListView(_items);
  Object? get lastError => _lastError;
  StackTrace? get lastStackTrace => _lastStackTrace;
  HistoryRecoveryNotice? get recoveryNotice => _recoveryNotice;

  Future<void> initialize() {
    return _serialized(() async {
      if (_initialized) return;

      try {
        await directory.create(recursive: true);
        final loaded = await _loadInitialItems();
        _items = List<QrItem>.unmodifiable(loaded);
        _initialized = true;
        notifyListeners();
      } catch (error, stackTrace) {
        _recordFailure(error, stackTrace);
        rethrow;
      }
    });
  }

  Future<List<QrItem>> getHistory() async {
    await initialize();
    return List<QrItem>.unmodifiable(_items);
  }

  List<String> getRecentUpiIds() {
    final ids = <String, String>{};
    for (final item in _items) {
      if (item.kind != QrKind.upi || item.hiddenFromUpiSuggestions) continue;
      final upi = QrPayloadCodec.parseUpi(item.data);
      if (upi != null) {
        ids.putIfAbsent(upi.payeeAddress.toLowerCase(), () => upi.payeeAddress);
      }
    }
    return List<String>.unmodifiable(ids.values);
  }

  Future<QrItem> saveItem(
    String data, {
    required QrKind kind,
    QrOrigin origin = QrOrigin.generated,
    String? label,
  }) async {
    await initialize();
    return _serializedMutation(() async {
      final existingIndex = _items.indexWhere((item) => item.data == data);
      final now = _clock().toUtc();
      final next = List<QrItem>.of(_items);
      late final QrItem saved;

      if (existingIndex >= 0) {
        final existing = next.removeAt(existingIndex);
        saved = existing.copyWith(
          createdAt: now,
          origin: origin,
          kind: kind,
          label: label == null ? existing.label : _validatedLabel(label),
        );
      } else {
        final explicitLabel = label == null ? null : _validatedLabel(label);
        saved = QrItem(
          id: _uniqueId(next.map((item) => item.id).toSet()),
          data: data,
          createdAt: now,
          origin: origin,
          kind: kind,
          label: explicitLabel ?? _nextDefaultLabel(kind, next),
        );
      }

      HistoryDocumentCodec.validateQrItem(saved);
      next.insert(0, saved);
      await _commit(next);
      return saved;
    });
  }

  Future<void> updateLabel(String id, String newLabel) async {
    await initialize();
    await _serializedMutation(() async {
      final index = _items.indexWhere((item) => item.id == id);
      if (index < 0) return;

      final next = List<QrItem>.of(_items);
      next[index] = next[index].copyWith(label: _validatedLabel(newLabel));
      await _commit(next);
    });
  }

  Future<void> removeItem(String id) async {
    await initialize();
    await _serializedMutation(() async {
      final next = _items.where((item) => item.id != id).toList();
      if (next.length == _items.length) return;
      await _commit(next);
    });
  }

  Future<void> clearHistory() async {
    await initialize();
    await _serializedMutation(() async {
      await _persistItems(const <QrItem>[], preservePrevious: false);
      await _deletePrivateRecoveryCopies();
      final preferences = await _preferencesProvider();
      await preferences.remove(legacyPreferencesKey);
      _items = const <QrItem>[];
      _recoveryNotice = null;
      notifyListeners();
    });
  }

  Future<void> forgetUpiId(String upiId) async {
    await initialize();
    await _serializedMutation(() async {
      final normalizedUpiId = upiId.trim().toLowerCase();
      var changed = false;
      final next = <QrItem>[];
      for (final item in _items) {
        final parsed = item.kind == QrKind.upi
            ? QrPayloadCodec.parseUpi(item.data)
            : null;
        if (parsed?.payeeAddress.toLowerCase() == normalizedUpiId &&
            !item.hiddenFromUpiSuggestions) {
          next.add(item.copyWith(hiddenFromUpiSuggestions: true));
          changed = true;
        } else {
          next.add(item);
        }
      }
      if (changed) await _commit(next);
    });
  }

  Future<HistoryMergeSummary> mergeItems(Iterable<QrItem> importedItems) async {
    await initialize();
    return _serializedMutation(() async {
      final next = List<QrItem>.of(_items);
      final dataValues = next.map((item) => item.data).toSet();
      final ids = next.map((item) => item.id).toSet();
      var added = 0;
      var duplicates = 0;

      for (var item in importedItems) {
        HistoryDocumentCodec.validateQrItem(item);
        if (!dataValues.add(item.data)) {
          duplicates++;
          continue;
        }
        if (!ids.add(item.id)) {
          item = item.copyWith(id: _uniqueId(ids));
          ids.add(item.id);
        }
        next.add(item);
        added++;
      }

      if (added > 0) {
        next.sort((left, right) => right.createdAt.compareTo(left.createdAt));
        await _commit(next);
      }
      return HistoryMergeSummary(added: added, duplicates: duplicates);
    });
  }

  void acknowledgeRecoveryNotice() {
    if (_recoveryNotice == null) return;
    _recoveryNotice = null;
    notifyListeners();
  }

  void clearLastError() {
    if (_lastError == null) return;
    _lastError = null;
    _lastStackTrace = null;
    notifyListeners();
  }

  Future<List<QrItem>> _loadInitialItems() async {
    final quarantined = <String>[];
    Object? corruptionError;

    if (await _primaryFile.exists()) {
      DecodedHistoryDocument? decoded;
      try {
        decoded = await _readDocument(_primaryFile);
      } on UnsupportedHistorySchemaException {
        rethrow;
      } on FormatException catch (error) {
        corruptionError = error;
        quarantined.add(await _quarantine(_primaryFile));
      }
      if (decoded != null) {
        if (decoded.isLegacy) {
          await _persistItems(decoded.items);
          _recoveryNotice = const HistoryRecoveryNotice(
            status: HistoryRecoveryStatus.migratedLegacyFile,
            message: 'Your history was upgraded to the current format.',
          );
        }
        return decoded.items;
      }
    }

    if (await _backupFile.exists()) {
      DecodedHistoryDocument? decoded;
      try {
        decoded = await _readDocument(_backupFile);
      } on UnsupportedHistorySchemaException {
        rethrow;
      } on FormatException catch (error) {
        corruptionError ??= error;
        quarantined.add(await _quarantine(_backupFile));
      }
      if (decoded != null) {
        // The backup remains a second known-good copy after recovery.
        await _persistItems(decoded.items);
        _lastError = corruptionError;
        _recoveryNotice = HistoryRecoveryNotice(
          status: HistoryRecoveryStatus.recoveredFromBackup,
          message: 'History was recovered from the last known-good backup.',
          quarantinedPaths: List<String>.unmodifiable(quarantined),
        );
        return decoded.items;
      }
    }

    final preferences = await _preferencesProvider();
    final legacySource = preferences.getString(legacyPreferencesKey);
    if (legacySource != null) {
      DecodedHistoryDocument? decoded;
      try {
        decoded = HistoryDocumentCodec.decode(legacySource);
      } on UnsupportedHistorySchemaException {
        rethrow;
      } on FormatException catch (error) {
        corruptionError ??= error;
      }
      if (decoded != null) {
        await _persistItems(decoded.items);
        await preferences.remove(legacyPreferencesKey);
        _lastError = corruptionError;
        _recoveryNotice = HistoryRecoveryNotice(
          status: HistoryRecoveryStatus.migratedSharedPreferences,
          message: quarantined.isEmpty
              ? 'Your legacy history was migrated successfully.'
              : 'History was restored from legacy app storage.',
          quarantinedPaths: List<String>.unmodifiable(quarantined),
        );
        return decoded.items;
      }
    }

    if (corruptionError != null || quarantined.isNotEmpty) {
      _lastError = corruptionError;
      _recoveryNotice = HistoryRecoveryNotice(
        status: HistoryRecoveryStatus.startedEmptyAfterCorruption,
        message:
            'Saved history could not be read. The damaged data was preserved '
            'for recovery and EncQder started with an empty history.',
        quarantinedPaths: List<String>.unmodifiable(quarantined),
      );
    }
    return const <QrItem>[];
  }

  Future<DecodedHistoryDocument> _readDocument(File file) async {
    final source = await file.readAsString();
    return HistoryDocumentCodec.decode(source);
  }

  Future<void> _commit(List<QrItem> next) async {
    for (final item in next) {
      HistoryDocumentCodec.validateQrItem(item);
    }
    await _persistItems(next);
    _items = List<QrItem>.unmodifiable(next);
    _lastError = null;
    _lastStackTrace = null;
    notifyListeners();
  }

  Future<void> _persistItems(
    Iterable<QrItem> items, {
    bool preservePrevious = true,
  }) async {
    final encoded = HistoryDocumentCodec.encode(items, generatedAt: _clock());
    final bytes = utf8.encode(encoded);

    await _fileWriter(_temporaryFile, bytes);
    HistoryDocumentCodec.decode(await _temporaryFile.readAsString());

    if (preservePrevious && await _primaryFile.exists()) {
      // Never bless a damaged primary file as the known-good backup.
      HistoryDocumentCodec.decode(await _primaryFile.readAsString());
      await _fileWriter(_backupTemporaryFile, await _primaryFile.readAsBytes());
      HistoryDocumentCodec.decode(await _backupTemporaryFile.readAsString());
      await _backupTemporaryFile.rename(_backupFile.path);
    }

    await _temporaryFile.rename(_primaryFile.path);
    if (!preservePrevious && await _backupFile.exists()) {
      await _backupFile.delete();
    }
  }

  Future<String> _quarantine(File file) async {
    final utc = _clock().toUtc();
    final stamp =
        '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}-'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        '${utc.millisecond.toString().padLeft(3, '0')}';
    var candidate = File(_pathFor('encqder_history.corrupt-$stamp.json'));
    var suffix = 1;
    while (await candidate.exists()) {
      candidate = File(
        _pathFor('encqder_history.corrupt-$stamp-${suffix++}.json'),
      );
    }
    await file.rename(candidate.path);
    return candidate.path;
  }

  Future<void> _deletePrivateRecoveryCopies() async {
    if (await _backupFile.exists()) await _backupFile.delete();
    if (await _temporaryFile.exists()) await _temporaryFile.delete();
    if (await _backupTemporaryFile.exists()) {
      await _backupTemporaryFile.delete();
    }
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File &&
          _basename(entity.path).startsWith('encqder_history.corrupt-')) {
        await entity.delete();
      }
    }
  }

  Future<T> _serialized<T>(Future<T> Function() operation) async {
    final previous = _operationTail;
    final turn = Completer<void>();
    _operationTail = turn.future;
    try {
      await previous;
      return await operation();
    } finally {
      turn.complete();
    }
  }

  Future<T> _serializedMutation<T>(Future<T> Function() operation) {
    return _serialized(() async {
      try {
        return await operation();
      } catch (error, stackTrace) {
        _recordFailure(error, stackTrace);
        rethrow;
      }
    });
  }

  void _recordFailure(Object error, StackTrace stackTrace) {
    _lastError = error;
    _lastStackTrace = stackTrace;
    notifyListeners();
  }

  String _uniqueId(Set<String> usedIds) {
    for (var attempt = 0; attempt < 100; attempt++) {
      final candidate = _idFactory();
      if (candidate.trim().isNotEmpty && !usedIds.contains(candidate)) {
        return candidate;
      }
    }
    throw StateError('The QR item id factory did not produce a unique id.');
  }

  String _nextDefaultLabel(QrKind kind, Iterable<QrItem> items) {
    final base = switch (kind) {
      QrKind.text => 'QR Code',
      QrKind.wifi => 'Wi-Fi Code',
      QrKind.upi => 'UPI Code',
    };
    final labels = items.map((item) => item.label).toSet();
    if (!labels.contains(base)) return base;
    for (var number = 2; ; number++) {
      final candidate = '$base $number';
      if (!labels.contains(candidate)) return candidate;
    }
  }

  String _validatedLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.runes.length > maximumQrLabelCharacters) {
      throw ArgumentError.value(
        value,
        'label',
        'Labels are limited to 80 characters.',
      );
    }
    return trimmed;
  }

  String _pathFor(String child) =>
      '${directory.path}${Platform.pathSeparator}$child';

  static String _basename(String path) =>
      path.split(Platform.pathSeparator).last;

  static Future<void> _defaultFileWriter(File file, List<int> bytes) =>
      file.writeAsBytes(bytes, flush: true);
}
