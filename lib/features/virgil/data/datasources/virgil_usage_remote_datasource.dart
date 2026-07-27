import 'package:supabase_flutter/supabase_flutter.dart';

enum VirgilUsageAction { recommendation, upload }

class VirgilUsageToday {
  const VirgilUsageToday({
    required this.recommendationsCount,
    required this.uploadsCount,
    this.recommendationsLimit = 3,
    this.uploadsLimit = 3,
  });

  final int recommendationsCount;
  final int uploadsCount;
  final int recommendationsLimit;
  final int uploadsLimit;

  bool get canRecommend => recommendationsCount < recommendationsLimit;
  bool get canUpload => uploadsCount < uploadsLimit;

  int get recommendationsRemaining =>
      (recommendationsLimit - recommendationsCount).clamp(0, recommendationsLimit);

  int get uploadsRemaining =>
      (uploadsLimit - uploadsCount).clamp(0, uploadsLimit);
}

class VirgilUsageLimitException implements Exception {
  const VirgilUsageLimitException(this.action);

  final VirgilUsageAction action;

  @override
  String toString() => 'VirgilUsageLimitException($action)';
}

class VirgilUsageRemoteDataSource {
  VirgilUsageRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const recommendationsPerDay = 3;
  static const uploadsPerDay = 3;

  Future<VirgilUsageToday> fetchToday() async {
    final raw = await _client.rpc('get_virgil_usage_today');
    final row = _firstRow(raw);
    if (row == null) {
      return const VirgilUsageToday(
        recommendationsCount: 0,
        uploadsCount: 0,
      );
    }
    return VirgilUsageToday(
      recommendationsCount: _asInt(row['recommendations_count']),
      uploadsCount: _asInt(row['uploads_count']),
      recommendationsLimit: _asInt(
        row['recommendations_limit'],
        fallback: recommendationsPerDay,
      ),
      uploadsLimit: _asInt(row['uploads_limit'], fallback: uploadsPerDay),
    );
  }

  /// Atomically consumes one quota unit. Throws [VirgilUsageLimitException]
  /// when the daily limit is already reached.
  Future<void> consume(VirgilUsageAction action) async {
    final allowed = await _client.rpc(
      'try_consume_virgil_usage',
      params: <String, dynamic>{'p_action': action.name},
    );
    if (allowed != true) {
      throw VirgilUsageLimitException(action);
    }
  }

  Map<String, dynamic>? _firstRow(dynamic raw) {
    if (raw is List) {
      if (raw.isEmpty) return null;
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
      return null;
    }
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
