import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrItem {
  final String id;
  final String data;
  final DateTime createdAt;
  final String originType; // "generated" or "scanned"
  final String dataType; // "TEXT", "WIFI", "UPI"
  String label;
  final Map<String, dynamic> extraData;

  QrItem({
    required this.id,
    required this.data,
    required this.createdAt,
    this.originType = 'generated',
    this.dataType = 'TEXT',
    String? label,
    Map<String, dynamic>? extraData,
  }) : label = label ?? '',
       extraData = extraData ?? <String, dynamic>{};

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'originType': originType,
      'dataType': dataType,
      'label': label,
    };
    map.addAll(extraData);
    return map;
  }

  factory QrItem.fromJson(Map<String, dynamic> json) {
    final standardKeys = {'id', 'data', 'createdAt', 'originType', 'dataType', 'label'};
    final extra = <String, dynamic>{};
    for (final key in json.keys) {
      if (!standardKeys.contains(key)) {
        extra[key] = json[key];
      }
    }

    return QrItem(
      id: json['id'],
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
      originType: json['originType'] ?? 'generated',
      dataType: json['dataType'] ?? 'TEXT',
      label: json['label'] as String? ?? '',
      extraData: extra,
    );
  }
}

class StorageService extends ChangeNotifier {
  static const String _historyKey = 'encqder_history';
  static const String _fileName = 'encqder_history.json';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  List<QrItem> _items = [];
  bool _initialized = false;
  File? _file;

  Future<void> init() async {
    if (_initialized) return;
    
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/$_fileName');

    if (await _file!.exists()) {
      try {
        final String historyJson = await _file!.readAsString();
        final List<dynamic> decodedList = json.decode(historyJson);
        _items = decodedList.map((item) => QrItem.fromJson(item)).toList();
      } catch (e) {
        _items = [];
      }
    } else {
      // Migrate from SharedPreferences if file doesn't exist
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        try {
          final List<dynamic> decodedList = json.decode(historyJson);
          _items = decodedList.map((item) => QrItem.fromJson(item)).toList();
          await _saveHistory(_items); // Save to file
          await prefs.remove(_historyKey); // Clear after migration
        } catch (e) {
          _items = [];
        }
      }
    }
    
    _initialized = true;
    notifyListeners();
  }

  Future<List<QrItem>> getHistory() async {
    if (!_initialized) await init();
    return List.from(_items);
  }

  Future<void> saveItem(String data, {String originType = 'generated', String dataType = 'TEXT'}) async {
    if (!_initialized) await init();
    
    // Check for duplicates to bring them to top
    _items.removeWhere((item) => item.data == data);

    String baseLabel = 'QR Code';
    if (dataType == 'WIFI') {
      baseLabel = 'WIFI Code';
    } else if (dataType == 'UPI') {
      baseLabel = 'UPI Code';
    }

    final existingLabels = _items
        .map((e) => e.label)
        .where((l) => l.startsWith(baseLabel))
        .toList();

    int nextNumber = 1;
    String candidateLabel = baseLabel;
    while (existingLabels.contains(candidateLabel)) {
      nextNumber++;
      candidateLabel = '$baseLabel $nextNumber';
    }

    final newItem = QrItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: data,
      createdAt: DateTime.now(),
      originType: originType,
      dataType: dataType,
      label: candidateLabel,
    );

    // Add to top of list
    _items.insert(0, newItem);
    await _saveHistory(_items);
  }

  Future<void> updateLabel(String id, String newLabel) async {
    if (!_initialized) await init();
    final index = _items.indexWhere((e) => e.id == id);
    if (index != -1) {
      _items[index].label = newLabel.trim();
      await _saveHistory(_items);
    }
  }

  Future<void> removeItem(String id) async {
    if (!_initialized) await init();
    _items.removeWhere((item) => item.id == id);
    await _saveHistory(_items);
  }

  Future<void> clearHistory() async {
    if (!_initialized) await init();
    _items.clear();
    await _saveHistory(_items);
  }

  Future<void> _saveHistory(List<QrItem> history) async {
    if (_file != null) {
      final List<Map<String, dynamic>> jsonList = 
          history.map((item) => item.toJson()).toList();
      await _file!.writeAsString(json.encode(jsonList));
      notifyListeners();
    }
  }

  Future<void> mergeItems(List<QrItem> newItems) async {
    if (!_initialized) await init();
    
    final Set<String> existingData = _items.map((e) => e.data).toSet();

    bool hasChanges = false;
    for (final item in newItems) {
      if (!existingData.contains(item.data)) {
        _items.add(item);
        existingData.add(item.data); // Keep tracking
        hasChanges = true;
      }
    }

    if (hasChanges) {
      // Re-sort by date descending to maintain order after merge
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveHistory(_items);
    }
  }
}
