import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../utils/app_logger.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.i('🔔 [FCM] Handling background message: ${message.messageId} - ${message.notification?.title}');
  } catch (e) {
    AppLogger.w('⚠️ [FCM] Error in background handler: $e');
  }
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important maintenance defect and ticket updates.',
    importance: Importance.high,
  );

  static Future<void> init({
    Future<void> Function(String token)? onTokenRefresh,
  }) async {
    try {
      AppLogger.i('🔔 [PushNotificationService] Initializing Push Notifications...');

      // 1. Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.i('🔔 [PushNotificationService] Authorization status: ${settings.authorizationStatus}');

      // 2. Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Initialize local notification channel for foreground display on Android
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

        await _localNotifications.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            AppLogger.i('🔔 [PushNotificationService] Notification tapped: ${response.payload}');
          },
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // 4. Set foreground presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Listen for incoming foreground messages and show banner via local notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.i('🔔 [PushNotificationService] Foreground message received: ${message.notification?.title}');

        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null && !kIsWeb) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: android.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            payload: message.data['issueId'] as String?,
          );
        }
      });

      // 6. Handle notification click when app opened from background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.i('🔔 [PushNotificationService] App opened from notification: ${message.data}');
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.i('🔔 [PushNotificationService] App launched from terminated state via notification: ${initialMessage.data}');
      }

      // 7. Get and register FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        AppLogger.i('📲 [PushNotificationService] FCM Token: ${token.substring(0, 15)}...');
        if (onTokenRefresh != null) {
          await onTokenRefresh(token);
        }
      }

      // 8. Listen for token refresh events
      _messaging.onTokenRefresh.listen((newToken) async {
        AppLogger.i('📲 [PushNotificationService] FCM Token refreshed: ${newToken.substring(0, 15)}...');
        if (onTokenRefresh != null) {
          await onTokenRefresh(newToken);
        }
      });
    } catch (e) {
      AppLogger.w('⚠️ [PushNotificationService] Push notification setup warning: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.w('⚠️ [PushNotificationService] Could not retrieve FCM token: $e');
      return null;
    }
  }
}
