import 'package:hive/hive.dart';

part 'cache_model.g.dart';

@HiveType(typeId: 0)
class CacheEntry {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final String data;

  @HiveField(2)
  final DateTime cachedAt;

  @HiveField(3)
  final int validDurationMs; // Store as milliseconds instead of Duration

  CacheEntry({
    required this.key,
    required this.data,
    required this.cachedAt,
    required Duration validDuration,
  }) : validDurationMs = validDuration.inMilliseconds;

  bool get isExpired {
    final validDuration = Duration(milliseconds: validDurationMs);
    return DateTime.now().difference(cachedAt) > validDuration;
  }
}