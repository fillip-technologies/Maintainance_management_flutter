import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../features/daily_logs/daily_logs.dart';
import '../../features/issues/issues.dart';
import '../../features/realtime/models/socket_event_model.dart';
import '../utils/app_logger.dart';

/// Manages the real-time Socket.IO WebSocket connection with JWT handshake authentication
/// and exposes reactive streams for domain events.
class SocketService {
  io.Socket? _socket;
  String? _currentToken;
  String? _currentServerUrl;
  String? Function()? _tokenProvider;
  Future<String?> Function()? _onUnauthorized;
  bool _isRefreshing = false;

  final _connectionStateController = StreamController<SocketConnectionState>.broadcast();
  final _issueCreatedController = StreamController<IssueModel>.broadcast();
  final _issueUpdatedController = StreamController<IssueModel>.broadcast();
  final _logSubmittedController = StreamController<DailyStatusLogModel>.broadcast();

  SocketConnectionState _currentState = SocketConnectionState.disconnected;
  SocketConnectionState get currentState => _currentState;

  Stream<SocketConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<IssueModel> get onIssueCreated => _issueCreatedController.stream;
  Stream<IssueModel> get onIssueUpdated => _issueUpdatedController.stream;
  Stream<DailyStatusLogModel> get onLogSubmitted => _logSubmittedController.stream;

  /// Connects to the backend Socket.IO server with dynamic JWT token resolution.
  void connect({
    required String serverUrl,
    required String token,
    String? Function()? tokenProvider,
    Future<String?> Function()? onUnauthorized,
  }) {
    _tokenProvider = tokenProvider;
    _onUnauthorized = onUnauthorized;

    if (_socket != null && _currentToken == token && _currentServerUrl == serverUrl && _socket!.connected) {
      AppLogger.d('⚡ [SocketService] Already connected to $serverUrl');
      return;
    }

    disconnect();

    _currentServerUrl = serverUrl;
    _currentToken = token;
    _updateState(SocketConnectionState.connecting);

    try {
      AppLogger.i('⚡ [SocketService] Connecting to $serverUrl...');

      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(999)
            .setAuth({'token': token})
            .setAuthFn((cb) {
              final activeToken = _tokenProvider?.call() ?? _currentToken ?? token;
              cb({'token': activeToken});
            })
            .build(),
      );

      _setupListeners();
      _socket?.connect();
    } catch (e, st) {
      AppLogger.e('❌ [SocketService] Failed to initialize socket: $e', e, st);
      _updateState(SocketConnectionState.disconnected);
    }
  }

  /// Updates current token in memory and triggers reconnect with the new credentials.
  void updateTokenAndReconnect(String newToken) {
    _currentToken = newToken;
    if (_socket != null) {
      _socket?.auth = {'token': newToken};
      _socket?.disconnect();
      _socket?.connect();
    }
  }

  void _setupListeners() {
    final socket = _socket;
    if (socket == null) return;

    socket.onConnect((_) {
      AppLogger.i('⚡ [SocketService] Connected to real-time server: $_currentServerUrl');
      _updateState(SocketConnectionState.connected);
    });

    socket.onConnectError((err) async {
      AppLogger.w('⚠️ [SocketService] Connection error: $err');
      _updateState(SocketConnectionState.connecting);

      final errStr = err.toString().toLowerCase();
      if (errStr.contains('unauthorized') && !_isRefreshing) {
        _isRefreshing = true;
        AppLogger.i('🔄 [SocketService] Unauthorized error detected. Requesting fresh token...');
        try {
          final newToken = await _onUnauthorized?.call();
          if (newToken != null && newToken.isNotEmpty) {
            AppLogger.i('⚡ [SocketService] Token refreshed. Reconnecting socket...');
            updateTokenAndReconnect(newToken);
          }
        } catch (e) {
          AppLogger.w('⚠️ [SocketService] Refresh failed on socket unauthorized: $e');
        } finally {
          _isRefreshing = false;
        }
      }
    });

    socket.onDisconnect((_) {
      AppLogger.i('🔌 [SocketService] Disconnected from server');
      _updateState(SocketConnectionState.disconnected);
    });

    socket.on('issue:created', (data) {
      AppLogger.d('📢 [SocketService] Received issue:created: $data');
      if (data is Map) {
        try {
          final issue = IssueModel.fromJson(Map<String, dynamic>.from(data));
          _issueCreatedController.add(issue);
        } catch (e) {
          AppLogger.e('❌ [SocketService] Error parsing issue:created: $e');
        }
      }
    });

    socket.on('issue:updated', (data) {
      AppLogger.d('📢 [SocketService] Received issue:updated: $data');
      if (data is Map) {
        try {
          final issue = IssueModel.fromJson(Map<String, dynamic>.from(data));
          _issueUpdatedController.add(issue);
        } catch (e) {
          AppLogger.e('❌ [SocketService] Error parsing issue:updated: $e');
        }
      }
    });

    socket.on('log:submitted', (data) {
      AppLogger.d('📢 [SocketService] Received log:submitted: $data');
      if (data is Map) {
        try {
          final log = DailyStatusLogModel.fromJson(Map<String, dynamic>.from(data));
          _logSubmittedController.add(log);
        } catch (e) {
          AppLogger.e('❌ [SocketService] Error parsing log:submitted: $e');
        }
      }
    });
  }

  /// Disconnects and destroys the current socket connection.
  void disconnect() {
    if (_socket != null) {
      try {
        _socket?.disconnect();
        _socket?.dispose();
      } catch (_) {}
      _socket = null;
    }
    _currentToken = null;
    _currentServerUrl = null;
    _updateState(SocketConnectionState.disconnected);
  }

  void _updateState(SocketConnectionState newState) {
    _currentState = newState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(newState);
    }
  }

  /// Closes all stream controllers permanently.
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _issueCreatedController.close();
    _issueUpdatedController.close();
    _logSubmittedController.close();
  }
}
