import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_summary_model.dart';
import '../../data/models/device_model.dart';
import '../../data/repositories/device_repository.dart';
import 'auth_provider.dart';

// 1. Device Repository Provider
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeviceRepository(apiClient: apiClient);
});

// 2. Staff Devices List Provider (Scoped to the authenticated user's zone)
final staffDevicesProvider = FutureProvider.autoDispose<List<DeviceModel>>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  final deviceRepo = ref.watch(deviceRepositoryProvider);

  final zoneId = authUser?.assignedZoneId;
  return deviceRepo.getDevices(
    zoneId: zoneId,
    includeSubzones: true,
  );
});

// 3. Staff Dashboard Summary Provider (KPI metrics)
final staffDashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummaryModel>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  final deviceRepo = ref.watch(deviceRepositoryProvider);

  final zoneId = authUser?.assignedZoneId;
  final clientId = authUser?.clientId;

  return deviceRepo.getDashboardSummary(
    zoneId: zoneId,
    clientId: clientId,
    includeSubzones: true,
  );
});

// 4. Available Spares Provider (Devices with status 'provisioned' in inventory)
final availableSparesProvider = FutureProvider.autoDispose<List<DeviceModel>>((ref) async {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  return deviceRepo.getDevices(status: 'provisioned');
});
