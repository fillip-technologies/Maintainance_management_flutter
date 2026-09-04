import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../models/user_model.dart';
import '../../devices/models/zone_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final StorageService storage;

  AuthRepository({
    required this.apiClient,
    required this.storage,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    AppLogger.i('🔐 [AuthRepository] Attempting login for: $cleanEmail');

    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {
          'email': cleanEmail,
          'password': password,
        },
      );

      AppLogger.d('📥 [AuthRepository] Raw Login Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;

        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;
        final userJson = Map<String, dynamic>.from(data['user'] as Map<String, dynamic>);

        // Decode JWT payload to extract technicianId, role, sub if missing in user
        try {
          final parts = accessToken.split('.');
          if (parts.length >= 2) {
            final normalizedBase64 = base64Url.normalize(parts[1]);
            final payloadJson = utf8.decode(base64Url.decode(normalizedBase64));
            final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
            if (payload.containsKey('technicianId') && payload['technicianId'] != null) {
              userJson['technicianId'] ??= payload['technicianId'];
            }
            if (payload.containsKey('role') && payload['role'] != null) {
              userJson['role'] ??= payload['role'];
            }
          }
        } catch (e) {
          AppLogger.w('⚠️ [AuthRepository] Could not parse JWT payload: $e');
        }

        // Backend user object might omit email, inject it
        if (!userJson.containsKey('email') || userJson['email'] == null || (userJson['email'] as String).isEmpty) {
          userJson['email'] = cleanEmail;
        }

        // Parse zone trees if returned (for zone_incharge / zone_staff)
        final descendantsJson = data['zoneDescendants'] as List<dynamic>? ?? [];
        final ancestorsJson = data['zoneAncestors'] as List<dynamic>? ?? [];

        final descendants = descendantsJson
            .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final ancestors = ancestorsJson
            .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // If zone name is not in user object, resolve it from zone tree
        final zoneId = (userJson['zoneId'] ?? userJson['assigned_zone_id']) as String?;
        if (zoneId != null && !userJson.containsKey('assigned_zone_name')) {
          final matchedZone = descendants.where((z) => z.id == zoneId).firstOrNull ??
              ancestors.where((z) => z.id == zoneId).firstOrNull;
          if (matchedZone != null) {
            userJson['assigned_zone_name'] = matchedZone.name;
          }
        }

        final user = UserModel.fromJson(userJson);
        AppLogger.i('👤 [AuthRepository] Parsed User: ${user.name} (${user.role.value}) - Zone: ${user.assignedZoneName}');
        AppLogger.i('🌳 [AuthRepository] Parsed ${descendants.length} descendants, ${ancestors.length} ancestors');

        // Persist session
        await storage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await storage.saveUser(user);
        await storage.saveZoneTree(
          descendants: descendants,
          ancestors: ancestors,
        );

        AppLogger.i('🎉 [AuthRepository] Session persisted successfully for ${user.email}');
        return user;
      } else {
        final message = response.data['message'] as String? ?? 'Login failed';
        AppLogger.w('⚠️ [AuthRepository] Login failed: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      if (e.response != null && e.response?.data is Map) {
        final resData = e.response!.data as Map<String, dynamic>;
        if (resData['details'] is List && (resData['details'] as List).isNotEmpty) {
          final firstDetail = (resData['details'] as List).first;
          if (firstDetail is Map && firstDetail.containsKey('message')) {
            errorMessage = firstDetail['message'] as String;
          }
        } else if (resData['message'] != null) {
          errorMessage = resData['message'] as String;
        }
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Check server URL and network.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot reach server. Check if backend is running.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      AppLogger.e('❌ [AuthRepository] DioException during login: $errorMessage', e);
      throw Exception(errorMessage);
    } catch (e, st) {
      AppLogger.e('💥 [AuthRepository] Unexpected error during login: $e', e, st);
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    AppLogger.i('🚪 [AuthRepository] Logging out current session');
    final refreshToken = storage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await apiClient.dio.post(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      } catch (e) {
        AppLogger.w('⚠️ [AuthRepository] Remote logout failed (continuing local wipe): $e');
      }
    }
    await storage.clearSession();
    AppLogger.i('🧹 [AuthRepository] Session cleared from local storage');
  }

  UserModel? getCurrentUser() => storage.getUser();

  bool get isAuthenticated => storage.hasSession;
}
