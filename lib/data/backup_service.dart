import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';

import '../domain/qr_models.dart';
import '../domain/qr_payload_codec.dart';
import 'history_store.dart';

const int maximumBackupBytes = 10 * 1024 * 1024;
const int maximumBackupItems = 10000;

final class BackupFormatException extends FormatException {
  const BackupFormatException(super.message);
}

final class BackupLimitException extends FormatException {
  const BackupLimitException(super.message);
}

final class ImportSummary {
  const ImportSummary({
    required this.added,
    required this.duplicates,
    required this.rejected,
  });

  final int added;
  final int duplicates;
  final int rejected;

  int get total => added + duplicates + rejected;
}

final class _ParsedBackup {
  const _ParsedBackup({required this.items, required this.rejected});

  final List<QrItem> items;
  final int rejected;
}

/// Creates schema-v2 JSON backups and imports both current and legacy backups.
final class BackupService {
  BackupService({
    required this.historyStore,
    HistoryClock? clock,
    HistoryIdFactory? idFactory,
  }) : _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? const Uuid().v4;

  final HistoryStore historyStore;
  final HistoryClock _clock;
  final HistoryIdFactory _idFactory;

  Future<File> exportToDirectory(Directory directory) async {
    await historyStore.initialize();
    await directory.create(recursive: true);

    final now = _clock();
    final basePath =
        '${directory.path}${Platform.pathSeparator}'
        'encqder-backup-${_fileTimestamp(now)}';
    var file = File('$basePath.json');
    var suffix = 2;
    while (await file.exists()) {
      file = File('$basePath-${suffix++}.json');
    }
    final temporary = File('${file.path}.tmp');
    final bytes = encodeBackup();

    await temporary.writeAsBytes(bytes, flush: true);
    HistoryDocumentCodec.decode(await temporary.readAsString());
    await temporary.rename(file.path);
    return file;
  }

  /// Removes plaintext export remnants from app-owned temporary storage.
  Future<void> clearTemporaryExports(Directory directory) async {
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = _basename(entity.path).toLowerCase();
      final isCurrentExport =
          name.startsWith('encqder-backup-') &&
          (name.endsWith('.json') || name.endsWith('.json.tmp'));
      final isLegacyExport =
          name.startsWith('encqder_backup_') && name.endsWith('.zip');
      if (isCurrentExport || isLegacyExport) await entity.delete();
    }
  }

  Uint8List encodeBackup() {
    final source = HistoryDocumentCodec.encode(
      historyStore.items,
      generatedAt: _clock(),
      pretty: true,
    );
    return Uint8List.fromList(utf8.encode(source));
  }

  Future<ImportSummary> importFile(File file) async {
    final length = await file.length();
    if (length > maximumBackupBytes) {
      throw const BackupLimitException('Backup files are limited to 10 MiB.');
    }
    return importBytes(
      await file.readAsBytes(),
      fileName: _basename(file.path),
    );
  }

  Future<ImportSummary> importBytes(List<int> bytes, {String? fileName}) async {
    if (bytes.length > maximumBackupBytes) {
      throw const BackupLimitException('Backup files are limited to 10 MiB.');
    }
    if (bytes.isEmpty) {
      throw const BackupFormatException('The selected backup is empty.');
    }

    final isZip =
        _hasZipSignature(bytes) ||
        (fileName?.toLowerCase().endsWith('.zip') ?? false);
    final parsed = isZip
        ? _parseLegacyZip(bytes)
        : _parseTextDocument(bytes, fileName: fileName);
    final merged = await historyStore.mergeItems(parsed.items);
    return ImportSummary(
      added: merged.added,
      duplicates: merged.duplicates,
      rejected: parsed.rejected,
    );
  }

  _ParsedBackup _parseLegacyZip(List<int> bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (error) {
      throw BackupFormatException('The ZIP backup is invalid: $error');
    }

    ArchiveFile? jsonEntry;
    ArchiveFile? textEntry;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = _basename(entry.name).toLowerCase();
      if (name == 'encqder_history.json') {
        jsonEntry ??= entry;
      } else if (name == 'encqder_history.txt') {
        textEntry ??= entry;
      }
    }
    final entry = jsonEntry ?? textEntry;
    if (entry == null) {
      throw const BackupFormatException(
        'ZIP backup does not contain EncQder history.',
      );
    }
    if (entry.size > maximumBackupBytes) {
      throw const BackupLimitException(
        'Uncompressed backup data is limited to 10 MiB.',
      );
    }

    final content = entry.readBytes();
    if (content == null || content.length > maximumBackupBytes) {
      throw const BackupLimitException(
        'Uncompressed backup data is limited to 10 MiB.',
      );
    }
    return _parseTextDocument(
      content,
      fileName: jsonEntry != null
          ? 'encqder_history.json'
          : 'encqder_history.txt',
    );
  }

  _ParsedBackup _parseTextDocument(List<int> bytes, {String? fileName}) {
    final String source;
    try {
      source = utf8.decode(bytes, allowMalformed: false);
    } on FormatException catch (error) {
      throw BackupFormatException('Backup is not valid UTF-8: $error');
    }

    final normalizedName = fileName?.toLowerCase();
    final firstCharacter = source.trimLeft().isEmpty
        ? ''
        : source.trimLeft()[0];
    final looksLikeJson =
        normalizedName?.endsWith('.json') == true ||
        firstCharacter == '{' ||
        firstCharacter == '[';
    if (looksLikeJson) return _parseJson(source);
    if (normalizedName?.endsWith('.txt') == true) {
      return _parseLegacyText(source);
    }
    throw const BackupFormatException(
      'Select an EncQder JSON backup or a legacy ZIP backup.',
    );
  }

  _ParsedBackup _parseJson(String source) {
    final int itemCount;
    try {
      final root = jsonDecode(source);
      if (root is List) {
        itemCount = root.length;
      } else if (root is Map && root['items'] is List) {
        itemCount = (root['items'] as List).length;
      } else {
        itemCount = 0;
      }
    } on FormatException catch (error) {
      throw BackupFormatException('Backup is not valid JSON: ${error.message}');
    }
    if (itemCount > maximumBackupItems) {
      throw const BackupLimitException(
        'Backups are limited to 10,000 QR items.',
      );
    }

    try {
      final decoded = HistoryDocumentCodec.decode(source, allowPartial: true);
      return _ParsedBackup(
        items: decoded.items,
        rejected: decoded.rejectedItems,
      );
    } on UnsupportedHistorySchemaException {
      rethrow;
    } on FormatException catch (error) {
      throw BackupFormatException(error.message);
    }
  }

  _ParsedBackup _parseLegacyText(String source) {
    final chunks = source
        .split(RegExp(r'^\s*---\s*$', multiLine: true))
        .where((chunk) => chunk.trim().isNotEmpty)
        .toList(growable: false);
    if (chunks.length > maximumBackupItems) {
      throw const BackupLimitException(
        'Backups are limited to 10,000 QR items.',
      );
    }

    final items = <QrItem>[];
    final ids = <String>{};
    var rejected = 0;
    for (final chunk in chunks) {
      try {
        final dateMatch = RegExp(
          r'^Date:\s*(.+)$',
          multiLine: true,
          caseSensitive: false,
        ).firstMatch(chunk);
        final contentMatch = RegExp(
          r'^Content:\s*',
          multiLine: true,
          caseSensitive: false,
        ).firstMatch(chunk);
        if (contentMatch == null) {
          throw const FormatException('Legacy item has no Content field.');
        }
        final data = chunk.substring(contentMatch.end).trim();
        final parsed = QrPayloadCodec.classify(data);
        final item = QrItem(
          id: _uniqueImportId(ids),
          data: data,
          createdAt:
              DateTime.tryParse(dateMatch?.group(1)?.trim() ?? '') ?? _clock(),
          origin: QrOrigin.imported,
          kind: parsed.kind,
        );
        HistoryDocumentCodec.validateQrItem(item);
        ids.add(item.id);
        items.add(item);
      } catch (_) {
        rejected++;
      }
    }
    return _ParsedBackup(items: items, rejected: rejected);
  }

  String _uniqueImportId(Set<String> usedIds) {
    for (var attempt = 0; attempt < 100; attempt++) {
      final candidate = _idFactory();
      if (candidate.trim().isNotEmpty && !usedIds.contains(candidate)) {
        return candidate;
      }
    }
    throw StateError('The QR item id factory did not produce a unique id.');
  }

  static bool _hasZipSignature(List<int> bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4b &&
      (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
      (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08);

  static String _fileTimestamp(DateTime utc) =>
      '${utc.year.toString().padLeft(4, '0')}'
      '${utc.month.toString().padLeft(2, '0')}'
      '${utc.day.toString().padLeft(2, '0')}-'
      '${utc.hour.toString().padLeft(2, '0')}'
      '${utc.minute.toString().padLeft(2, '0')}'
      '${utc.second.toString().padLeft(2, '0')}';

  static String _basename(String path) =>
      path.replaceAll('\\', '/').split('/').last;
}
