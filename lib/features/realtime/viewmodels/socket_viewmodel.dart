import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/jwt_helper.dart';
import '../../auth/auth.dart';
import '../../daily_logs/daily_logs.dart';
import '../../devices/devices.dart';
import '../../issues/issues.dart';
import '../models/socket_event_model.dart';

/// Singleton SocketService instance provider.
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of real-time socket connection state.
final socketConnectionStateProvider = StreamProvider<SocketConnectionState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.connectionStateStream;
});

/// Stream of newly created issues from backend (`issue:created`).
final socketIssueCreatedStreamProvider = StreamProvider<IssueModel>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onIssueCreated;
});

/// Stream of updated issues from backend (`issue:updated`).
final socketIssueUpdatedStreamProvider = StreamProvider<IssueModel>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onIssueUpdated;
});

/// Stream of submitted daily logs from backend (`log:submitted`).
final socketLogSubmittedStreamProvider = StreamProvider<DailyStatusLogModel>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.onLogSubmitted;
});

/// Watches authentication state, connects on login, disconnects on logout,
/// and catches up on missed items when reconnecting.
final socketSyncManagerProvider = Provider<void>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  final socketService = ref.watch(socketServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);

  // Automatically update socket auth when ApiClient refreshes tokens
  final tokenSub = apiClient.onTokenRefreshed.listen((newToken) {
    socketService.updateTokenAndReconnect(newToken);
  });
  ref.onDispose(() => tokenSub.cancel());

  if (authUser != null) {
    // User is logged in: retrieve token & connect with dynamic refresh handlers
    final token = storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      final serverUrl = AppConfig.getSocketUrl(apiClient.dio.options.baseUrl);

      if (JwtHelper.isExpired(token)) {
        AppLogger.i('🔄 [SocketProvider] Stored access token is expired. Refreshing before connecting socket...');
        apiClient.refreshToken().then((freshToken) {
          final effectiveToken = freshToken ?? token;
          socketService.connect(
            serverUrl: serverUrl,
            token: effectiveToken,
            tokenProvider: () => storage.getAccessToken(),
            onUnauthorized: () => apiClient.refreshToken(),
          );
        });
      } else {
        socketService.connect(
          serverUrl: serverUrl,
          token: token,
          tokenProvider: () => storage.getAccessToken(),
          onUnauthorized: () => apiClient.refreshToken(),
        );
      }
    }
  } else {
    // User is logged out: disconnect socket
    socketService.disconnect();
  }

  // Listen to connection state: on reconnect, invalidate caches to catch up
  ref.listen<AsyncValue<SocketConnectionState>>(
    socketConnectionStateProvider,
    (previous, next) {
      if (previous?.value != SocketConnectionState.connected &&
          next.value == SocketConnectionState.connected) {
        // Just reconnected: refresh active data
        ref.invalidate(staffIssuesProvider);
        ref.invalidate(technicianIssuesProvider);
        ref.invalidate(todayLogsProvider);
        ref.invalidate(staffDevicesProvider);
        ref.invalidate(staffDashboardSummaryProvider);
      }
    },
  );
});
