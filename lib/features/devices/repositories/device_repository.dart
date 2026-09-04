import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../../daily_logs/daily_logs.dart';
import '../models/device_model.dart';

class DeviceRepository {
  final ApiClient apiClient;

  DeviceRepository({required this.apiClient});

  /// Fetches devices list with optional zone scoping, status filter, and search query.
  Future<List<DeviceModel>> getDevices({
    String? zoneId,
    bool includeSubzones = true,
    String? status,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (includeSubzones) 'includeSubzones': 'true',
        if (zoneId != null && zoneId.isNotEmpty) 'zoneId': zoneId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      AppLogger.d('📡 [DeviceRepository] GET /devices with params: $queryParams');

      final response = await apiClient.dio.get(
        '/devices',
        queryParameters: queryParams,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];

        final devices = items
            .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
            .toList();

        AppLogger.i('📱 [DeviceRepository] Fetched ${devices.length} devices successfully');
        return devices;
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to load devices';
        AppLogger.w('⚠️ [DeviceRepository] Error response: $msg');
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error fetching devices';
      AppLogger.e('❌ [DeviceRepository] DioException in getDevices: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [DeviceRepository] Unexpected error in getDevices: $e', e, st);
      throw Exception('Failed to load devices: $e');
    }
  }

  /// Fetches KPI Dashboard Summary for a zone or client scope.
  Future<DashboardSummaryModel> getDashboardSummary({
    String? zoneId,
    String? clientId,
    bool includeSubzones = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (includeSubzones) 'includeSubzones': 'true',
      };

      if (zoneId != null && zoneId.isNotEmpty) {
        queryParams['scope'] = 'zone';
        queryParams['id'] = zoneId;
      } else if (clientId != null && clientId.isNotEmpty) {
        queryParams['scope'] = 'client';
        queryParams['id'] = clientId;
      } else {
        queryParams['scope'] = 'platform';
      }

      AppLogger.d('📡 [DeviceRepository] GET /dashboard/summary with params: $queryParams');

      final response = await apiClient.dio.get(
        '/dashboard/summary',
        queryParameters: queryParams,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final summary = DashboardSummaryModel.fromJson(data);
        AppLogger.i('📊 [DeviceRepository] Fetched summary: Total=${summary.totalDevices}, OpenIssues=${summary.openIssues}');
        return summary;
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to load summary';
        AppLogger.w('⚠️ [DeviceRepository] Error response: $msg');
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error fetching summary';
      AppLogger.e('❌ [DeviceRepository] DioException in getDashboardSummary: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [DeviceRepository] Unexpected error in getDashboardSummary: $e', e, st);
      throw Exception('Failed to load dashboard summary: $e');
    }
  }
}
