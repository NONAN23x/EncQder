import 'dart:convert';
import 'dart:io';

import 'package:encqder/data/history_store.dart';
import 'package:encqder/domain/qr_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late SharedPreferences preferences;
  late DateTime now;
  late int nextId;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('encqder-history-test-');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    now = DateTime.utc(2026, 7, 17, 12);
    nextId = 0;
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  HistoryStore createStore({HistoryFileWriter? fileWriter}) => HistoryStore(
    directory: directory,
    clock: () => now,
    idFactory: () => 'id-${++nextId}',
    preferencesProvider: () async => preferences,
    fileWriter: fileWriter,
  );

  QrItem item({
    required String id,
    required String data,
    String label = '',
    QrKind kind = QrKind.text,
  }) => QrItem(
    id: id,
    data: data,
    createdAt: now,
    kind: kind,
    origin: QrOrigin.imported,
    label: label,
  );

  test('writes schema v2 and exposes an unmodifiable list', () async {
    final store = createStore();
    await store.initialize();
    await store.saveItem('hello', kind: QrKind.text);

    expect(store.items, hasLength(1));
    expect(
      () => store.items.add(item(id: 'x', data: 'x')),
      throwsUnsupportedError,
    );

    final file = File('${directory.path}/${HistoryStore.fileName}');
    final document =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(document['format'], historyDocumentFormat);
    expect(document['schemaVersion'], historySchemaVersion);
    expect(document['generatedAt'], now.toIso8601String());
    expect((document['items'] as List).single['data'], 'hello');
  });

  test(
    'duplicate save preserves identity, label, and suggestion setting',
    () async {
      final store = createStore();
      const upi = 'upi://pay?pa=person%40bank&cu=INR';
      final first = await store.saveItem(upi, kind: QrKind.upi, label: 'Rent');
      await store.forgetUpiId('person@bank');

      now = now.add(const Duration(minutes: 1));
      final repeated = await store.saveItem(
        upi,
        kind: QrKind.upi,
        origin: QrOrigin.scanned,
      );

      expect(repeated.id, first.id);
      expect(repeated.label, 'Rent');
      expect(repeated.hiddenFromUpiSuggestions, isTrue);
      expect(repeated.createdAt, now);
      expect(repeated.origin, QrOrigin.scanned);
    },
  );

  test('serializes concurrent mutations without losing an item', () async {
    final store = createStore();
    await Future.wait(<Future<void>>[
      store.saveItem('first', kind: QrKind.text),
      store.saveItem('second', kind: QrKind.text),
      store.saveItem('third', kind: QrKind.text),
    ]);

    expect(store.items.map((entry) => entry.data), <String>[
      'third',
      'second',
      'first',
    ]);
  });

  test('failed write leaves memory and primary file unchanged', () async {
    var failWrites = false;
    Future<void> writer(File file, List<int> bytes) async {
      if (failWrites && file.path.endsWith('${HistoryStore.fileName}.tmp')) {
        throw const FileSystemException('simulated write failure');
      }
      await file.writeAsBytes(bytes, flush: true);
    }

    final store = createStore(fileWriter: writer);
    await store.saveItem('safe', kind: QrKind.text);
    final primary = File('${directory.path}/${HistoryStore.fileName}');
    final before = await primary.readAsString();

    failWrites = true;
    await expectLater(
      store.saveItem('not persisted', kind: QrKind.text),
      throwsA(isA<FileSystemException>()),
    );

    expect(store.items.map((entry) => entry.data), <String>['safe']);
    expect(await primary.readAsString(), before);
    expect(store.lastError, isA<FileSystemException>());
  });

  test('recovers a corrupt primary from the last known-good backup', () async {
    final store = createStore();
    await store.saveItem('first', kind: QrKind.text);
    now = now.add(const Duration(minutes: 1));
    await store.saveItem('second', kind: QrKind.text);

    final primary = File('${directory.path}/${HistoryStore.fileName}');
    await primary.writeAsString('{damaged', flush: true);

    final recovered = createStore();
    await recovered.initialize();

    expect(recovered.items.map((entry) => entry.data), <String>['first']);
    expect(
      recovered.recoveryNotice?.status,
      HistoryRecoveryStatus.recoveredFromBackup,
    );
    expect(recovered.recoveryNotice?.quarantinedPaths, hasLength(1));
    expect(
      await File(recovered.recoveryNotice!.quarantinedPaths.single).exists(),
      isTrue,
    );
    expect(
      HistoryDocumentCodec.decode(
        await primary.readAsString(),
      ).items.single.data,
      'first',
    );
    expect(
      File('${directory.path}/${HistoryStore.fileName}.bak').existsSync(),
      isTrue,
    );
  });

  test(
    'quarantines corrupt history instead of silently overwriting it',
    () async {
      final primary = File('${directory.path}/${HistoryStore.fileName}');
      await primary.writeAsString('not json', flush: true);

      final store = createStore();
      await store.initialize();

      expect(store.items, isEmpty);
      expect(
        store.recoveryNotice?.status,
        HistoryRecoveryStatus.startedEmptyAfterCorruption,
      );
      expect(await primary.exists(), isFalse);
      expect(store.recoveryNotice?.quarantinedPaths, hasLength(1));
    },
  );

  test('future schema is rejected without moving or rewriting it', () async {
    final primary = File('${directory.path}/${HistoryStore.fileName}');
    final futureDocument = jsonEncode(<String, Object>{
      'format': historyDocumentFormat,
      'schemaVersion': historySchemaVersion + 1,
      'generatedAt': now.toIso8601String(),
      'items': <Object>[],
    });
    await primary.writeAsString(futureDocument, flush: true);

    final store = createStore();
    await expectLater(
      store.initialize(),
      throwsA(isA<UnsupportedHistorySchemaException>()),
    );

    expect(store.isInitialized, isFalse);
    expect(store.items, isEmpty);
    expect(await primary.readAsString(), futureDocument);
    expect(
      directory.listSync().whereType<File>().where(
        (file) => file.path.contains('.corrupt-'),
      ),
      isEmpty,
    );
  });

  test('v2 rejects legacy types and unknown enum values', () {
    Map<String, Object?> validItem() => <String, Object?>{
      'id': 'strict-id',
      'data': 'payload',
      'createdAt': now.toIso8601String(),
      'origin': 'generated',
      'kind': 'text',
      'label': '',
      'hiddenFromUpiSuggestions': false,
    };

    String document(Map<String, Object?> item) => jsonEncode(<String, Object>{
      'format': historyDocumentFormat,
      'schemaVersion': historySchemaVersion,
      'generatedAt': now.toIso8601String(),
      'items': <Object>[item],
    });

    final numericId = validItem()..['id'] = 7;
    final numericDate = validItem()..['createdAt'] = now.millisecondsSinceEpoch;
    final unknownKind = validItem()..['kind'] = 'future-kind';
    final missingOrigin = validItem()..remove('origin');
    final nullLabel = validItem()..['label'] = null;
    final nullHidden = validItem()..['hiddenFromUpiSuggestions'] = null;

    for (final source in <String>[
      document(numericId),
      document(numericDate),
      document(unknownKind),
      document(missingOrigin),
      document(nullLabel),
      document(nullHidden),
    ]) {
      expect(() => HistoryDocumentCodec.decode(source), throwsFormatException);
    }
  });

  test('migrates a legacy bare-array file to schema v2', () async {
    final legacy = <Map<String, Object>>[
      <String, Object>{
        'id': 'legacy-1',
        'data': 'legacy payload',
        'createdAt': '2025-01-01T00:00:00Z',
        'originType': 'scanned',
        'dataType': 'TEXT',
        'label': 'Old label',
      },
    ];
    final primary = File('${directory.path}/${HistoryStore.fileName}');
    await primary.writeAsString(jsonEncode(legacy), flush: true);

    final store = createStore();
    await store.initialize();

    expect(store.items.single.origin, QrOrigin.scanned);
    expect(store.items.single.label, 'Old label');
    expect(
      store.recoveryNotice?.status,
      HistoryRecoveryStatus.migratedLegacyFile,
    );
    final migrated =
        jsonDecode(await primary.readAsString()) as Map<String, dynamic>;
    expect(migrated['schemaVersion'], historySchemaVersion);
  });

  test('migrates SharedPreferences only after durable persistence', () async {
    final legacy = <Map<String, Object>>[
      <String, Object>{
        'id': 'legacy-pref',
        'data': 'from preferences',
        'createdAt': '2025-01-01T00:00:00Z',
        'originType': 'generated',
        'dataType': 'TEXT',
      },
    ];
    await preferences.setString(
      HistoryStore.legacyPreferencesKey,
      jsonEncode(legacy),
    );

    final store = createStore();
    await store.initialize();

    expect(store.items.single.data, 'from preferences');
    expect(preferences.containsKey(HistoryStore.legacyPreferencesKey), isFalse);
    expect(
      store.recoveryNotice?.status,
      HistoryRecoveryStatus.migratedSharedPreferences,
    );
    expect(
      File('${directory.path}/${HistoryStore.fileName}').existsSync(),
      isTrue,
    );
  });

  test('keeps legacy preferences when migration cannot be persisted', () async {
    final legacy = <Map<String, Object>>[
      <String, Object>{
        'id': 'legacy-pref',
        'data': 'must survive',
        'createdAt': '2025-01-01T00:00:00Z',
        'originType': 'generated',
        'dataType': 'TEXT',
      },
    ];
    final source = jsonEncode(legacy);
    await preferences.setString(HistoryStore.legacyPreferencesKey, source);
    final store = createStore(
      fileWriter: (file, bytes) async {
        throw const FileSystemException('simulated migration failure');
      },
    );

    await expectLater(store.initialize(), throwsA(isA<FileSystemException>()));

    expect(preferences.getString(HistoryStore.legacyPreferencesKey), source);
    expect(store.items, isEmpty);
    expect(store.isInitialized, isFalse);
  });

  test('merge reports duplicates and remaps colliding ids', () async {
    final store = createStore();
    final saved = await store.saveItem('existing', kind: QrKind.text);

    final summary = await store.mergeItems(<QrItem>[
      item(id: 'different', data: 'existing'),
      item(id: saved.id, data: 'new'),
    ]);

    expect(summary.added, 1);
    expect(summary.duplicates, 1);
    expect(
      store.items.map((entry) => entry.data),
      containsAll(<String>['existing', 'new']),
    );
    expect(store.items.map((entry) => entry.id).toSet(), hasLength(2));
  });

  test('wipe removes history, backups, preferences, and quarantines', () async {
    final store = createStore();
    await store.saveItem('first', kind: QrKind.text);
    await store.saveItem('second', kind: QrKind.text);
    await preferences.setString(HistoryStore.legacyPreferencesKey, 'stale');
    final quarantine = File(
      '${directory.path}/encqder_history.corrupt-20260717-120000000.json',
    );
    await quarantine.writeAsString('sensitive', flush: true);

    await store.clearHistory();

    expect(store.items, isEmpty);
    expect(
      File('${directory.path}/${HistoryStore.fileName}.bak').existsSync(),
      isFalse,
    );
    expect(quarantine.existsSync(), isFalse);
    expect(preferences.containsKey(HistoryStore.legacyPreferencesKey), isFalse);
    final primary = File('${directory.path}/${HistoryStore.fileName}');
    expect(
      HistoryDocumentCodec.decode(await primary.readAsString()).items,
      isEmpty,
    );
  });
}
