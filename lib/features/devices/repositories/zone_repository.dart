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
      final msg = e.response?.data?['message'] as String? ?? e.message ?? 'Failed to load technician zones';
      AppLogger.e('❌ [ZoneRepository] DioException in getMyZones: $msg', e);
      throw Exception(msg);
    } catch (e, st) {
      AppLogger.e('💥 [ZoneRepository] Unexpected error in getMyZones: $e', e, st);
      throw Exception('Failed to load technician zones: $e');
    }
  }

  /// Fetches zone detail with devices and open issues for a specific zone.
  Future<TechnicianZoneNode> getZoneDetail(String zoneId) async {
    try {
      AppLogger.d('📡 [ZoneRepository] GET /technicians/me/zones/$zoneId');
      final response = await apiClient.dio.get('/technicians/me/zones/$zoneId');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return TechnicianZoneNode.fromJson(data);
      }
      throw Exception('Failed to load zone detail');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? e.message ?? 'Failed to load zone detail';
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
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];
        return items
            .map((e) => TechnicianZoneNode.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? e.message ?? 'Failed to load subzones';
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
      final msg = e.response?.data?['message'] as String? ?? e.message ?? 'Failed to load zone breakdown';
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
