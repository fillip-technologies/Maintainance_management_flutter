import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
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
      final message = e.extractErrorMessage('Network error fetching devices');
      AppLogger.e('❌ [DeviceRepository] DioException in getDevices: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [DeviceRepository] Unexpected error in getDevices: $e', e, st);
      throw Exception('Failed to load devices: $e');
    }
  }

  /// Fetches all devices across pagination pages (up to maxPages * 100 items),
  /// matching the web frontend implementation in src/app/api/devicesApi.js.
  /// Fetches page 1, then fetches remaining pages concurrently via Future.wait.
  Future<List<DeviceModel>> getAllDevices({
    String? zoneId,
    bool includeSubzones = true,
    String? status,
    String? search,
    int maxPages = 10,
  }) async {
    try {
      final baseParams = <String, dynamic>{
        'limit': 100,
        if (includeSubzones) 'includeSubzones': 'true',
        if (zoneId != null && zoneId.isNotEmpty) 'zoneId': zoneId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      AppLogger.d('📡 [DeviceRepository] GET /devices?page=1&limit=100');
      final firstRes = await apiClient.dio.get(
        '/devices',
        queryParameters: {'page': 1, ...baseParams},
      );

      if ((firstRes.statusCode != 200 && firstRes.statusCode != 201) ||
          firstRes.data['success'] != true) {
        return const [];
      }

      final firstData = firstRes.data['data'] as Map<String, dynamic>;
      final firstItems = (firstData['items'] as List<dynamic>?) ?? [];
      final meta = firstData['meta'] as Map<String, dynamic>?;
      final totalPages = (firstData['totalPages'] as num?)?.toInt() ??
          (meta?['totalPages'] as num?)?.toInt() ??
          ((firstData['totalItems'] as num?) != null ? ((firstData['totalItems'] as num) / 100).ceil() : 1);

      final allItems = <DeviceModel>[
        ...firstItems.map((e) => DeviceModel.fromJson(e as Map<String, dynamic>)),
      ];

      if (totalPages > 1) {
        final lastPage = totalPages > maxPages ? maxPages : totalPages;
        final remainingPageNumbers = [for (var p = 2; p <= lastPage; p++) p];

        final pageFutures = remainingPageNumbers.map((p) async {
          try {
            AppLogger.d('📡 [DeviceRepository] GET /devices?page=$p&limit=100');
            final res = await apiClient.dio.get(
              '/devices',
              queryParameters: {'page': p, ...baseParams},
            );
            if (res.data is Map && res.data['success'] == true) {
              final pageData = res.data['data'] as Map<String, dynamic>;
              final pageItems = (pageData['items'] as List<dynamic>?) ?? [];
              return pageItems
                  .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          } catch (e) {
            AppLogger.w('⚠️ [DeviceRepository] Error fetching page $p of devices: $e');
          }
          return <DeviceModel>[];
        });

        final pageResults = await Future.wait(pageFutures);
        for (final pageList in pageResults) {
          allItems.addAll(pageList);
        }
      }

      AppLogger.i('📱 [DeviceRepository] Fetched ${allItems.length} total devices across pages');
      return allItems;
    } catch (e) {
      AppLogger.e('❌ [DeviceRepository] Error in getAllDevices: $e');
      return const [];
    }
  }
}
