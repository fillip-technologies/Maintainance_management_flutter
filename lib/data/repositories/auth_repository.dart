import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../models/user_model.dart';
import '../models/zone_model.dart';

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
    AppLogger.i('🔐 [AuthRepository] Attempting login for: $email');
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      AppLogger.d('📥 [AuthRepository] Raw Login Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;

        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String;
        final userJson = data['user'] as Map<String, dynamic>;

        final user = UserModel.fromJson(userJson);
        AppLogger.i('👤 [AuthRepository] Parsed User: ${user.name} (${user.role.value})');

        // Parse zone trees if returned (for zone_incharge / zone_staff)
        final descendantsJson = data['zoneDescendants'] as List<dynamic>? ?? [];
        final ancestorsJson = data['zoneAncestors'] as List<dynamic>? ?? [];

        final descendants = descendantsJson
            .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final ancestors = ancestorsJson
            .map((e) => ZoneModel.fromJson(e as Map<String, dynamic>))
            .toList();

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
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error';
      AppLogger.e('❌ [AuthRepository] DioException during login: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [AuthRepository] Unexpected parsing error: $e', e, st);
      throw Exception('Failed to process login data: $e');
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
