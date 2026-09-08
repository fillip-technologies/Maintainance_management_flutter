import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth.dart';
import '../models/daily_log_model.dart';
import '../repositories/daily_log_repository.dart';

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DailyLogRepository(apiClient: apiClient);
});

/// Fetches today's daily status logs across every zone the staff member is
/// assigned to (the backend scopes the response), keyed by deviceId for instant
/// lookup. No zoneId is sent — see [staffDevicesProvider] for why.
final todayLogsProvider = FutureProvider.autoDispose<Map<String, DailyStatusLogModel>>((ref) async {
  final dailyLogRepo = ref.watch(dailyLogRepositoryProvider);

  final now = DateTime.now().toUtc();
  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final logs = await dailyLogRepo.getDailyLogs(
    date: dateStr,
    includeSubzones: true,
    limit: 100,
  );

  final map = <String, DailyStatusLogModel>{};
  for (final l in logs) {
    map[l.deviceId] = l;
  }
  return map;
});
