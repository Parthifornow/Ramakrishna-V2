import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../models/cache_model.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  Box<CacheEntry>? _cacheBox;

  Future<void> init() async {
    await Hive.initFlutter();
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CacheEntryAdapter());
    }
    
    _cacheBox = await Hive.openBox<CacheEntry>(AppConstants.cacheBox);
    print('✅ CacheManager initialized');
  }

  Future<void> saveToCache({
    required String key,
    required dynamic data,
    Duration? duration,
  }) async {
    try {
      final cacheEntry = CacheEntry(
        key: key,
        data: jsonEncode(data),
        cachedAt: DateTime.now(),
        validDuration: duration ?? AppConstants.cacheDuration,
      );

      await _cacheBox?.put(key, cacheEntry);
      print('💾 Cached data for key: $key');
    } catch (e) {
      print('❌ Error saving to cache: $e');
    }
  }

  T? getFromCache<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final cacheEntry = _cacheBox?.get(key);

      if (cacheEntry == null || cacheEntry.isExpired) {
        _cacheBox?.delete(key);
        return null;
      }

      final data = jsonDecode(cacheEntry.data);
      return fromJson(data as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error parsing cache for key $key: $e');
      return null;
    }
  }

  List<T>? getListFromCache<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final cacheEntry = _cacheBox?.get(key);

      if (cacheEntry == null || cacheEntry.isExpired) {
        _cacheBox?.delete(key);
        return null;
      }

      final data = jsonDecode(cacheEntry.data) as List;
      return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('❌ Error parsing list cache for key $key: $e');
      return null;
    }
  }

  Future<void> clearCache(String key) async {
    await _cacheBox?.delete(key);
    print('🗑️ Cleared cache for key: $key');
  }

  Future<void> clearAllCache() async {
    await _cacheBox?.clear();
    print('🗑️ Cleared all cache');
  }

  bool isCacheValid(String key) {
    final cacheEntry = _cacheBox?.get(key);
    return cacheEntry != null && !cacheEntry.isExpired;
  }
}