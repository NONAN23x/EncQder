import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QrItem {
  final String id;
  final String data;
  final DateTime createdAt;
  final String originType; // "generated" or "scanned"

  QrItem({
    required this.id,
    required this.data,
    required this.createdAt,
    this.originType = 'generated', // Default for older items
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'originType': originType,
      };

  factory QrItem.fromJson(Map<String, dynamic> json) => QrItem(
        id: json['id'],
        data: json['data'],
        createdAt: DateTime.parse(json['createdAt']),
        originType: json['originType'] ?? 'generated', // Fallback for backward compatibility
      );
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

    final newItem = QrItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: data,
      createdAt: DateTime.now(),
      originType: originType,
    );

    // Add to top of list
    currentHistory.insert(0, newItem);

    await _saveHistory(currentHistory);
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
}
