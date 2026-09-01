class AppConfig {
  /// Default base URL can be passed at build time via:
  /// `flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1`
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// Formats and normalizes any user-pasted URL (e.g. `https://my-backend.onrender.com`
  /// or `192.168.1.100:3000` or `https://my-backend.com/api/v1/`)
  static String normalizeBaseUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return defaultBaseUrl;

    // Add protocol if missing (default to https unless localhost/ip is used)
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('localhost') ||
          url.startsWith('127.0.0.1') ||
          url.startsWith('10.0.2.2') ||
          url.startsWith('192.168.')) {
        url = 'http://$url';
      } else {
        url = 'https://$url';
      }
    }

    // Strip trailing slashes
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    // Append /api/v1 if not already present
    if (!url.endsWith('/api/v1')) {
      url = '$url/api/v1';
    }

    return url;
  }
}
