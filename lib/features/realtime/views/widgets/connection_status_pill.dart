import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/socket_event_model.dart';
import '../../viewmodels/socket_viewmodel.dart';

/// Compact indicator showing real-time WebSocket connection state.
class ConnectionStatusPill extends ConsumerWidget {
  const ConnectionStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure socketSyncManager is active
    ref.watch(socketSyncManagerProvider);
    final stateAsync = ref.watch(socketConnectionStateProvider);
    final connectionState = stateAsync.value ?? SocketConnectionState.disconnected;
    final l10n = AppLocalizations.of(context);

    final (color, bgColor, label) = switch (connectionState) {
      SocketConnectionState.connected => (
          AppColors.success,
          AppColors.successLight,
          l10n?.realtimeLive ?? 'Live',
        ),
      SocketConnectionState.connecting => (
          AppColors.warning,
          AppColors.warningLight,
          l10n?.realtimeConnecting ?? 'Connecting...',
        ),
      SocketConnectionState.disconnected => (
          AppColors.neutralText,
          AppColors.neutralLight,
          l10n?.realtimeOffline ?? 'Offline',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
