import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/auth.dart';
import '../../features/devices/devices.dart';

class StorageService {
  final SharedPreferences _prefs;

  const StorageService(this._prefs);

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userKey = 'auth_user_profile';
  static const String _zoneDescendantsKey = 'auth_zone_descendants';
  static const String _zoneAncestorsKey = 'auth_zone_ancestors';
  static const String _baseUrlKey = 'api_base_url';

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Base URL ---

  Future<void> saveBaseUrl(String url) async {
    await _prefs.setString(_baseUrlKey, url);
  }

  String? getBaseUrl() {
    return _prefs.getString(_baseUrlKey);
  }

  // --- Tokens ---

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) async {
    await _prefs.setString(_accessTokenKey, accessToken);
  }

  String? getAccessToken() {
    return _prefs.getString(_accessTokenKey);
  }

  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  // --- User Profile ---

  Future<void> saveUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _prefs.setString(_userKey, jsonStr);
  }

  UserModel? getUser() {
    final jsonStr = _prefs.getString(_userKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // --- Zone Trees (Cached at login) ---

  Future<void> saveZoneTree({
    required List<ZoneModel> descendants,
    required List<ZoneModel> ancestors,
  }) async {
    final descJson = jsonEncode(descendants.map((e) => e.toJson()).toList());
    final ancJson = jsonEncode(ancestors.map((e) => e.toJson()).toList());
    await _prefs.setString(_zoneDescendantsKey, descJson);
    await _prefs.setString(_zoneAncestorsKey, ancJson);
  }

  List<ZoneModel> getZoneDescendants() {
    final str = _prefs.getString(_zoneDescendantsKey);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((e) => ZoneModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  List<ZoneModel> getZoneAncestors() {
    final str = _prefs.getString(_zoneAncestorsKey);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((e) => ZoneModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Clear Session on Logout ---

  Future<void> clearSession() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userKey);
    await _prefs.remove(_zoneDescendantsKey);
    await _prefs.remove(_zoneAncestorsKey);
  }

  bool get hasSession => getAccessToken() != null && getUser() != null;
}
