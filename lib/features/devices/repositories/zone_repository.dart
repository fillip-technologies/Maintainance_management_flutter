import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/auth.dart';
import '../models/device_model.dart';
import '../models/technician_zone_node.dart';

class ZoneRepository {
  final ApiClient apiClient;

  ZoneRepository({required this.apiClient});

  /// Fetches top-level zones assigned to the current technician.
  Future<List<TechnicianZoneNode>> getMyZones() async {
    try {
      AppLogger.d('📡 [ZoneRepository] GET /technicians/me/zones');
      final response = await apiClient.dio.get('/technicians/me/zones');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map &&
          response.data['success'] == true) {
        final items = (response.data['data'] as List<dynamic>?) ?? [];
        final list = items
            .map((e) => TechnicianZoneNode.fromJson(e as Map<String, dynamic>))
            .toList();
        AppLogger.i('📍 [ZoneRepository] Fetched ${list.length} technician assigned zones');
        return list;
      }
      return const [];
    } on DioException catch (e) {
      final msg = e.extractErrorMessage('Failed to load technician zones');
      AppLogger.e('❌ [ZoneRepository] DioException in getMyZones: $msg', e);
      throw Exception(msg);
    } catch (e, st) {
      AppLogger.e('💥 [ZoneRepository] Unexpected error in getMyZones: $e', e, st);
      throw Exception('Failed to load technician zones: $e');
    }
  }

  /// Fetches all zones accessible to the caller across pagination pages (up to maxPages * 100 items),
  /// matching the web frontend implementation in src/app/api/zonesApi.js.
  /// Fetches page 1, then fetches remaining pages concurrently via Future.wait.
  Future<List<TechnicianZoneNode>> getAllZones({
    int maxPages = 10,
    String? clientId,
  }) async {
    try {
      final baseParams = <String, dynamic>{
        'limit': 100,
        if (clientId != null && clientId.isNotEmpty) 'clientId': clientId,
      };

      AppLogger.d('📡 [ZoneRepository] GET /zones?page=1&limit=100');
      final firstResponse = await apiClient.dio.get(
        '/zones',
        queryParameters: {'page': 1, ...baseParams},
      );

      if ((firstResponse.statusCode != 200 && firstResponse.statusCode != 201) ||
          firstResponse.data is! Map ||
          firstResponse.data['success'] != true) {
        return const [];
      }

      final data = firstResponse.data['data'] as Map<String, dynamic>;
      final firstItems = (data['items'] as List<dynamic>?) ?? [];
      final meta = data['meta'] as Map<String, dynamic>?;
      final totalPages = (data['totalPages'] as num?)?.toInt() ??
          (meta?['totalPages'] as num?)?.toInt() ??
          ((data['totalItems'] as num?) != null ? ((data['totalItems'] as num) / 100).ceil() : 1);

      final allItems = <TechnicianZoneNode>[
        ...firstItems.map((e) => TechnicianZoneNode.fromJson(e as Map<String, dynamic>)),
      ];

      if (totalPages > 1) {
        final lastPage = totalPages > maxPages ? maxPages : totalPages;
        final remainingPages = [for (var p = 2; p <= lastPage; p++) p];

        final pageFutures = remainingPages.map((p) async {
          try {
            AppLogger.d('📡 [ZoneRepository] GET /zones?page=$p&limit=100');
            final res = await apiClient.dio.get(
              '/zones',
              queryParameters: {'page': p, ...baseParams},
            );
            if (res.data is Map && res.data['success'] == true) {
              final pageData = res.data['data'] as Map<String, dynamic>;
              final pageItems = (pageData['items'] as List<dynamic>?) ?? [];
              return pageItems
                  .map((e) => TechnicianZoneNode.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          } catch (e) {
            AppLogger.w('⚠️ [ZoneRepository] Error fetching page $p of zones: $e');
          }
          return <TechnicianZoneNode>[];
        });

        final pageResults = await Future.wait(pageFutures);
        for (final list in pageResults) {
          allItems.addAll(list);
        }
      }

      AppLogger.i('📡 [ZoneRepository] Fetched ${allItems.length} total zones across pages');
      return allItems;
    } catch (e) {
      AppLogger.w('⚠️ [ZoneRepository] Failed to load all zones: $e');
      return const [];
    }
  }

  /// Fetches zone detail with devices and open issues for a specific zone.
  Future<TechnicianZoneNode> getZoneDetail(String zoneId) async {
    try {
      AppLogger.d('📡 [ZoneRepository] GET /technicians/me/zones/$zoneId');
      final response = await apiClient.dio.get('/technicians/me/zones/$zoneId');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return TechnicianZoneNode.fromJson(data);
      }
      throw Exception('Failed to load zone detail');
    } on DioException catch (e) {
      final msg = e.extractErrorMessage('Failed to load zone detail');
      AppLogger.e('❌ [ZoneRepository] DioException in getZoneDetail: $msg', e);
      throw Exception(msg);
    } catch (e, st) {
      AppLogger.e('💥 [ZoneRepository] Unexpected error in getZoneDetail: $e', e, st);
      throw Exception('Failed to load zone detail: $e');
    }
  }

  /// Fetches child sub-zones under a given parent zone.
  Future<List<TechnicianZoneNode>> getSubzones(String parentZoneId) async {
    try {
      AppLogger.d('📡 [ZoneRepository] GET /zones?parentZoneId=$parentZoneId');
      final response = await apiClient.dio.get(
        '/zones',
        queryParameters: {'parentZoneId': parentZoneId, 'limit': 100},
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];
        return items
            .map((e) => TechnicianZoneNode.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      final msg = e.extractErrorMessage('Failed to load subzones');
      AppLogger.e('❌ [ZoneRepository] DioException in getSubzones: $msg', e);
      throw Exception(msg);
    } catch (e, st) {
      AppLogger.e('💥 [ZoneRepository] Unexpected error in getSubzones: $e', e, st);
      throw Exception('Failed to load subzones: $e');
    }
  }

  /// Fetches device status breakdown for a zone and its sub-tree.
  Future<Map<String, Map<String, int>>> getZoneBreakdown(String zoneId) async {
    try {
      AppLogger.d('📡 [ZoneRepository] GET /dashboard/zone-breakdown?scope=zone&id=$zoneId&includeSubzones=true');
      final response = await apiClient.dio.get(
        '/dashboard/zone-breakdown',
        queryParameters: {
          'scope': 'zone',
          'id': zoneId,
          'includeSubzones': 'true',
        },
      );

      final result = <String, Map<String, int>>{};
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final zones = (data['zones'] as List<dynamic>?) ?? [];
        for (final z in zones) {
          final map = z as Map<String, dynamic>;
          final zId = map['zoneId'] as String?;
          if (zId != null) {
            result[zId] = {
              'total': (map['total'] as num?)?.toInt() ?? 0,
              'working': (map['working'] as num?)?.toInt() ?? 0,
              'faulty': (map['faulty'] as num?)?.toInt() ?? 0,
              'underMaintenance': (map['underMaintenance'] as num?)?.toInt() ?? 0,
            };
          }
        }
      }
      return result;
    } on DioException catch (e) {
      final msg = e.extractErrorMessage('Failed to load zone breakdown');
      AppLogger.e('❌ [ZoneRepository] DioException in getZoneBreakdown: $msg', e);
      throw Exception(msg);
    } catch (e, st) {
      AppLogger.e('💥 [ZoneRepository] Unexpected error in getZoneBreakdown: $e', e, st);
      throw Exception('Failed to load zone breakdown: $e');
    }
  }

  /// Fetches devices situated directly in this zone (includeSubzones = false).
  Future<List<DeviceModel>> getZoneDevices(String zoneId) async {
    try {
      AppLogger.d('📡 [ZoneRepository] GET /devices?zoneId=$zoneId&includeSubzones=false');
      final response = await apiClient.dio.get(
        '/devices',
        queryParameters: {
          'zoneId': zoneId,
          'includeSubzones': 'false',
          'limit': 100,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];
        return items
            .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (e) {
      AppLogger.w('⚠️ [ZoneRepository] Failed to fetch zone devices: $e');
      return const [];
    }
  }
}

final zoneRepositoryProvider = Provider<ZoneRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ZoneRepository(apiClient: apiClient);
});
