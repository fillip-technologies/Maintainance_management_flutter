import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_log_model.dart';
import '../../data/repositories/daily_log_repository.dart';
import 'auth_provider.dart';

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DailyLogRepository(apiClient: apiClient);
});

/// Fetches today's daily status logs for the user's assigned zone, keyed by deviceId for instant lookup.
final todayLogsProvider = FutureProvider.autoDispose<Map<String, DailyStatusLogModel>>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  final dailyLogRepo = ref.watch(dailyLogRepositoryProvider);

  final zoneId = authUser?.assignedZoneId;
  final now = DateTime.now().toUtc();
  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final logs = await dailyLogRepo.getDailyLogs(
    zoneId: zoneId,
    date: dateStr,
    includeSubzones: true,
  );

  final map = <String, DailyStatusLogModel>{};
  for (final l in logs) {
    map[l.deviceId] = l;
  }
  return map;
});
