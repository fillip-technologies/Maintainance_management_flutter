import 'daily_log_model.dart';
import 'issue_model.dart';

/// Represents the real-time Socket.IO connection status.
enum SocketConnectionState {
  connected,
  connecting,
  disconnected,
}

/// Strongly typed wrapper for `issue:created` and `issue:updated` socket broadcasts.
class SocketIssueEvent {
  final String eventType; // 'issue:created' | 'issue:updated'
  final IssueModel issue;

  const SocketIssueEvent({
    required this.eventType,
    required this.issue,
  });

  factory SocketIssueEvent.fromJson(String type, Map<String, dynamic> json) {
    return SocketIssueEvent(
      eventType: type,
      issue: IssueModel.fromJson(json),
    );
  }
}

/// Strongly typed wrapper for `log:submitted` socket broadcasts.
class SocketLogEvent {
  final DailyStatusLogModel log;
  final String? zoneId;

  const SocketLogEvent({
    required this.log,
    this.zoneId,
  });

  factory SocketLogEvent.fromJson(Map<String, dynamic> json) {
    return SocketLogEvent(
      log: DailyStatusLogModel.fromJson(json),
      zoneId: json['zoneId'] as String?,
    );
  }
}
