import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:encqder/data/backup_service.dart';
import 'package:encqder/data/history_store.dart';
import 'package:encqder/domain/qr_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory sourceDirectory;
  late Directory targetDirectory;
  late SharedPreferences preferences;
  late DateTime now;
  var nextId = 0;

  setUp(() async {
    sourceDirectory = await Directory.systemTemp.createTemp(
      'encqder-backup-source-',
    );
    targetDirectory = await Directory.systemTemp.createTemp(
      'encqder-backup-target-',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    now = DateTime.utc(2026, 7, 17, 12, 34, 56);
    nextId = 0;
  });

  tearDown(() async {
    if (await sourceDirectory.exists()) {
      await sourceDirectory.delete(recursive: true);
    }
    if (await targetDirectory.exists()) {
      await targetDirectory.delete(recursive: true);
    }
  });

  HistoryStore storeFor(Directory directory) => HistoryStore(
    directory: directory,
    clock: () => now,
    idFactory: () => 'id-${++nextId}',
    preferencesProvider: () async => preferences,
  );

  BackupService serviceFor(HistoryStore store) => BackupService(
    historyStore: store,
    clock: () => now,
    idFactory: () => 'import-${++nextId}',
  );

  Map<String, dynamic> rawItem({
    required String id,
    required String data,
    String label = '',
  }) => <String, dynamic>{
    'id': id,
    'data': data,
    'createdAt': now.toIso8601String(),
    'origin': 'imported',
    'kind': 'text',
    'label': label,
    'hiddenFromUpiSuggestions': false,
  };

  test(
    'exports a versioned JSON document with the required filename',
    () async {
      final store = storeFor(sourceDirectory);
      await store.saveItem('saved', kind: QrKind.text);
      final service = serviceFor(store);

      final file = await service.exportToDirectory(targetDirectory);

      expect(file.path, endsWith('encqder-backup-20260717-123456.json'));
      final document =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(document['format'], historyDocumentFormat);
      expect(document['schemaVersion'], historySchemaVersion);
      expect((document['items'] as List).single['data'], 'saved');
    },
  );

  test('cleans current and legacy plaintext temp exports only', () async {
    final store = storeFor(sourceDirectory);
    final service = serviceFor(store);
    final current = File(
      '${targetDirectory.path}/encqder-backup-20260717-123456.json',
    );
    final partial = File('${current.path}.tmp');
    final legacy = File('${targetDirectory.path}/encqder_backup_123.zip');
    final unrelated = File('${targetDirectory.path}/keep.json');
    for (final file in <File>[current, partial, legacy, unrelated]) {
      await file.writeAsString('sensitive', flush: true);
    }

    await service.clearTemporaryExports(targetDirectory);

    expect(await current.exists(), isFalse);
    expect(await partial.exists(), isFalse);
    expect(await legacy.exists(), isFalse);
    expect(await unrelated.exists(), isTrue);
  });

  test(
    'imports v2 JSON and reports added, duplicate, and rejected records',
    () async {
      final store = storeFor(targetDirectory);
      await store.saveItem('existing', kind: QrKind.text);
      final service = serviceFor(store);
      final document = <String, dynamic>{
        'format': historyDocumentFormat,
        'schemaVersion': historySchemaVersion,
        'generatedAt': now.toIso8601String(),
        'items': <Object?>[
          rawItem(id: 'new-1', data: 'new'),
          rawItem(id: 'duplicate-data', data: 'existing'),
          <String, Object>{'id': 'invalid'},
        ],
      };

      final summary = await service.importBytes(
        utf8.encode(jsonEncode(document)),
        fileName: 'backup.json',
      );

      expect(summary.added, 1);
      expect(summary.duplicates, 1);
      expect(summary.rejected, 1);
      expect(summary.total, 3);
    },
  );

  test('imports the legacy ZIP JSON format', () async {
    final legacy = jsonEncode(<Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'legacy',
        'data': 'legacy data',
        'createdAt': '2025-01-01T00:00:00Z',
        'originType': 'scanned',
        'dataType': 'TEXT',
      },
    ]);
    final archive = Archive()
      ..add(ArchiveFile.string('encqder_history.json', legacy));
    final zip = ZipEncoder().encode(archive);
    final store = storeFor(targetDirectory);

    final summary = await serviceFor(
      store,
    ).importBytes(zip, fileName: 'old-backup.zip');

    expect(summary.added, 1);
    expect(store.items.single.data, 'legacy data');
    expect(store.items.single.origin, QrOrigin.scanned);
  });

  test('imports legacy ZIP text and classifies its payload', () async {
    const legacy = '''
Date: 2025-01-01T00:00:00Z
Content: WIFI:T:nopass;S:Cafe;;
---
Date: invalid
Content: plain text
''';
    final archive = Archive()
      ..add(ArchiveFile.string('encqder_history.txt', legacy));
    final zip = ZipEncoder().encode(archive);
    final store = storeFor(targetDirectory);

    final summary = await serviceFor(
      store,
    ).importBytes(zip, fileName: 'old.zip');

    expect(summary.added, 2);
    expect(summary.rejected, 0);
    expect(store.items.map((entry) => entry.kind), contains(QrKind.wifi));
    expect(
      store.items.every((entry) => entry.origin == QrOrigin.imported),
      isTrue,
    );
  });

  test('rejects future schemas instead of guessing', () async {
    final document = <String, dynamic>{
      'format': historyDocumentFormat,
      'schemaVersion': historySchemaVersion + 1,
      'generatedAt': now.toIso8601String(),
      'items': <Object>[],
    };
    final store = storeFor(targetDirectory);

    await expectLater(
      serviceFor(
        store,
      ).importBytes(utf8.encode(jsonEncode(document)), fileName: 'future.json'),
      throwsA(isA<UnsupportedHistorySchemaException>()),
    );
  });

  test('rejects oversized files before parsing them', () async {
    final store = storeFor(targetDirectory);
    final bytes = List<int>.filled(maximumBackupBytes + 1, 0);

    await expectLater(
      serviceFor(store).importBytes(bytes, fileName: 'huge.json'),
      throwsA(isA<BackupLimitException>()),
    );
    expect(store.items, isEmpty);
  });

  test('rejects backups with more than 10,000 items', () async {
    final items = List<Map<String, dynamic>>.generate(
      maximumBackupItems + 1,
      (index) => rawItem(id: 'id-$index', data: 'data-$index'),
    );
    final source = jsonEncode(items);
    final store = storeFor(targetDirectory);

    await expectLater(
      serviceFor(store).importBytes(utf8.encode(source), fileName: 'many.json'),
      throwsA(isA<BackupLimitException>()),
    );
  });

  test('rejects overlong payloads and labels as individual records', () async {
    final document = <String, dynamic>{
      'format': historyDocumentFormat,
      'schemaVersion': historySchemaVersion,
      'generatedAt': now.toIso8601String(),
      'items': <Object>[
        rawItem(
          id: 'payload',
          data: List<String>.filled(maximumQrPayloadBytes + 1, 'x').join(),
        ),
        rawItem(
          id: 'label',
          data: 'valid data',
          label: List<String>.filled(maximumQrLabelCharacters + 1, 'x').join(),
        ),
      ],
    };
    final store = storeFor(targetDirectory);

    final summary = await serviceFor(
      store,
    ).importBytes(utf8.encode(jsonEncode(document)), fileName: 'limits.json');

    expect(summary.added, 0);
    expect(summary.rejected, 2);
  });
}
