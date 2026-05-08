import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// LocalCacheService
/// Handles caching of JSON-serializable data using SharedPreferences.
/// Used to show last available data when there is no internet connection.
class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> data) async {
    await init();
    final jsonString = jsonEncode(data);
    await _prefs!.setString(key, jsonString);
    await _prefs!.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> saveObject(String key, Map<String, dynamic> data) async {
    await init();
    final jsonString = jsonEncode(data);
    await _prefs!.setString(key, jsonString);
    await _prefs!.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  List<Map<String, dynamic>>? getList(String key) {
    if (_prefs == null) return null;
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return null;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? getObject(String key) {
    if (_prefs == null) return null;
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return null;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  DateTime? getCacheTime(String key) {
    if (_prefs == null) return null;
    final timestamp = _prefs!.getInt('${key}_timestamp');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  bool hasCache(String key) {
    if (_prefs == null) return false;
    return _prefs!.containsKey(key);
  }

  Future<void> clearCache(String key) async {
    await init();
    await _prefs!.remove(key);
    await _prefs!.remove('${key}_timestamp');
  }

  Future<void> clearAll() async {
    await init();
    final keys = _prefs!.getKeys().where((k) => k.startsWith('cache_'));
    for (final key in keys) {
      await _prefs!.remove(key);
      await _prefs!.remove('${key}_timestamp');
    }
  }
}
