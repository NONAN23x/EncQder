import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QrItem {
  final String id;
  final String data;
  final DateTime createdAt;
  final String originType; // "generated" or "scanned"
  String label;
  final Map<String, dynamic> extraData;

  QrItem({
    required this.id,
    required this.data,
    required this.createdAt,
    this.originType = 'generated', // Default for older items
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
      'label': label,
    };
    map.addAll(extraData);
    return map;
  }

  factory QrItem.fromJson(Map<String, dynamic> json) {
    final standardKeys = {'id', 'data', 'createdAt', 'originType', 'label'};
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
      originType: json['originType'] ?? 'generated', // Fallback for backward compatibility
      label: json['label'] as String? ?? '',
      extraData: extra,
    );
  }
}

class StorageService {
  static const String _historyKey = 'encqder_history';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<QrItem>> getHistory() async {
    if (_prefs == null) await init();
    
    final String? historyJson = _prefs!.getString(_historyKey);
    if (historyJson == null) return [];

    try {
      final List<dynamic> decodedList = json.decode(historyJson);
      return decodedList.map((item) => QrItem.fromJson(item)).toList();
    } catch (e) {
      // In case of parsing error, return empty and perhaps clear corrupted data
      return [];
    }
  }

  Future<void> saveItem(String data, {String originType = 'generated'}) async {
    final List<QrItem> currentHistory = await getHistory();
    
    // Check for duplicates to bring them to top
    currentHistory.removeWhere((item) => item.data == data);

    final existingLabels = currentHistory
        .map((e) => e.label)
        .where((l) => l.startsWith('QR Code'))
        .toList();

    int nextNumber = 1;
    String candidateLabel = 'QR Code';
    while (existingLabels.contains(candidateLabel)) {
      nextNumber++;
      candidateLabel = 'QR Code $nextNumber';
    }

    final newItem = QrItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: data,
      createdAt: DateTime.now(),
      originType: originType,
      label: candidateLabel,
    );

    // Add to top of list
    currentHistory.insert(0, newItem);

    await _saveHistory(currentHistory);
  }

  Future<void> updateLabel(String id, String newLabel) async {
    final List<QrItem> history = await getHistory();
    final index = history.indexWhere((e) => e.id == id);
    if (index != -1) {
      history[index].label = newLabel.trim();
      await _saveHistory(history);
    }
  }

  Future<void> removeItem(String id) async {
    final List<QrItem> currentHistory = await getHistory();
    currentHistory.removeWhere((item) => item.id == id);
    await _saveHistory(currentHistory);
  }

  Future<void> clearHistory() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_historyKey);
  }

  Future<void> _saveHistory(List<QrItem> history) async {
    if (_prefs == null) await init();
    
    final List<Map<String, dynamic>> jsonList = 
        history.map((item) => item.toJson()).toList();
    
    await _prefs!.setString(_historyKey, json.encode(jsonList));
  }

  Future<void> mergeItems(List<QrItem> newItems) async {
    final List<QrItem> currentHistory = await getHistory();
    
    // Create a set of existing data to avoid O(N^2) lookups
    final Set<String> existingData = currentHistory.map((e) => e.data).toSet();

    bool hasChanges = false;
    for (final item in newItems) {
      if (!existingData.contains(item.data)) {
        currentHistory.add(item);
        existingData.add(item.data); // Keep tracking
        hasChanges = true;
      }
    }

    if (hasChanges) {
      // Re-sort by date descending to maintain order after merge
      currentHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveHistory(currentHistory);
    }
  }
}
