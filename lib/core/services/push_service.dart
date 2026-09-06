import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';
import '../../features/auth/viewmodels/auth_viewmodel.dart';

// Must be top-level — called by FCM when app is in background/terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.i('📱 [Push] Background: ${message.notification?.title}');
}

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Call once from main() before runApp, after Firebase.initializeApp().
Future<void> initPushBackground() async {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Android channel for high-priority foreground notifications.
  const androidChannel = AndroidNotificationChannel(
    'fixly_high',
    'Fixly Alerts',
    description: 'Issue and device alerts from Fixly',
    importance: Importance.high,
  );

  await _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  await _localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
}

class PushService {
  final ApiClient _apiClient;

  PushService(this._apiClient);

  /// Request permission, get FCM token, and register it with the backend.
  /// Call this right after a successful login.
  Future<void> registerToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        AppLogger.w('⚠️ [Push] Permission denied by user');
        return;
      }

      // On iOS, also request APNs token first.
      if (Platform.isIOS) await messaging.getAPNSToken();

      final token = await messaging.getToken();
      if (token == null) {
        AppLogger.w('⚠️ [Push] Could not get FCM token');
        return;
      }

      await _sendTokenToBackend(token);

      // Keep token fresh — re-register when FCM rotates it.
      messaging.onTokenRefresh.listen(_sendTokenToBackend);
    } catch (e) {
      AppLogger.e('❌ [Push] registerToken failed', e);
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      await _apiClient.dio.post(
        '/auth/device-token',
        data: {'token': token, 'platform': platform},
      );
      AppLogger.i('✅ [Push] Token registered with backend');
    } catch (e) {
      AppLogger.e('❌ [Push] Failed to send token to backend', e);
    }
  }

  /// Show FCM messages as local notifications while the app is in foreground.
  void listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      final android = message.notification?.android;
      if (n == null) return;

      AppLogger.i('📬 [Push] Foreground: ${n.title}');

      _localNotifications.show(
        message.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fixly_high',
            'Fixly Alerts',
            channelDescription: 'Issue and device alerts from Fixly',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PushService(apiClient);
});
