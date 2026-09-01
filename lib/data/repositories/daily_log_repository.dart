import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/daily_log_model.dart';

class DailyLogRepository {
  final ApiClient apiClient;

  DailyLogRepository({required this.apiClient});

  /// Submits or updates today's status log for a device.
  Future<DailyStatusLogModel> createOrUpdateLog({
    required String deviceId,
    required DailyLogStatus status,
    String? notes,
    bool overwrite = true,
  }) async {
    try {
      final payload = {
        'deviceId': deviceId,
        'status': status.value,
        'overwrite': overwrite,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      AppLogger.d('📡 [DailyLogRepository] POST /daily-logs with: $payload');

      final response = await apiClient.dio.post(
        '/daily-logs',
        data: payload,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final log = DailyStatusLogModel.fromJson(data);
        AppLogger.i('✅ [DailyLogRepository] Log recorded for ${log.deviceId}: ${log.status.label}');
        return log;
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to submit status log';
        AppLogger.w('⚠️ [DailyLogRepository] Error response: $msg');
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error submitting log';
      AppLogger.e('❌ [DailyLogRepository] DioException: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [DailyLogRepository] Unexpected error: $e', e, st);
      throw Exception('Failed to record daily log: $e');
    }
  }

  /// Fetches daily logs for a given zone or device.
  Future<List<DailyStatusLogModel>> getDailyLogs({
    String? zoneId,
    String? deviceId,
    String? date,
    bool includeSubzones = true,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (includeSubzones) 'includeSubzones': 'true',
        if (zoneId != null && zoneId.isNotEmpty) 'zoneId': zoneId,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        if (date != null && date.isNotEmpty) 'date': date,
      };

      AppLogger.d('📡 [DailyLogRepository] GET /daily-logs with params: $queryParams');

      final response = await apiClient.dio.get(
        '/daily-logs',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];

        return items
            .map((e) => DailyStatusLogModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to fetch daily logs';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error fetching daily logs';
      AppLogger.e('❌ [DailyLogRepository] DioException: $message', e);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to fetch daily logs: $e');
    }
  }
}
