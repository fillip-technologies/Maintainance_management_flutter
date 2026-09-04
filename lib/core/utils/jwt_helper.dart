import 'dart:convert';

/// Lightweight utility for inspecting and validating JWT claims without external dependencies.
class JwtHelper {
  /// Decodes and returns the JWT payload map, or null if invalid.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the token is expired or will expire within the given [buffer].
  static bool isExpired(String token, {Duration buffer = const Duration(seconds: 30)}) {
    final payload = decodePayload(token);
    if (payload == null) return true;

    final exp = payload['exp'];
    if (exp is num) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return DateTime.now().isAfter(expiryDate.subtract(buffer));
    }
    return false;
  }
}
