import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../daily_logs/daily_logs.dart';
import '../models/device_model.dart';
import '../repositories/device_repository.dart';
import '../../auth/auth.dart';

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

  final summary = await deviceRepo.getDashboardSummary(
    zoneId: zoneId,
    clientId: clientId,
    includeSubzones: true,
  );

  // Cross-reference with live devices to ensure 100% accurate status breakdown matching the list
  final devicesAsync = ref.watch(staffDevicesProvider);
  if (devicesAsync.hasValue && devicesAsync.value != null && devicesAsync.value!.isNotEmpty) {
    final devices = devicesAsync.value!;
    final activeCount = devices.where((d) => d.status == DeviceStatus.active).length;
    final faultyCount = devices.where((d) => d.status == DeviceStatus.faulty).length;
    final underMaintCount = devices.where((d) => d.status == DeviceStatus.underMaintenance).length;
    final provCount = devices.where((d) => d.status == DeviceStatus.provisioned).length;
    final nonRetiredTotal = devices.where((d) => d.status != DeviceStatus.retired).length;

    return summary.copyWith(
      totalDevices: nonRetiredTotal > 0 ? nonRetiredTotal : summary.totalDevices,
      activeDevices: activeCount,
      faultyDevices: faultyCount > 0 ? faultyCount : summary.faultyDevices,
      underMaintenanceDevices: underMaintCount,
      provisionedDevices: provCount,
    );
  }

  return summary;
});

// 4. Available Spares Provider (Devices with status 'provisioned' in inventory)
final availableSparesProvider = FutureProvider.autoDispose<List<DeviceModel>>((ref) async {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  return deviceRepo.getDevices(status: 'provisioned');
});
