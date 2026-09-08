import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../repositories/device_repository.dart';
import '../../auth/auth.dart';

// 1. Device Repository Provider
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeviceRepository(apiClient: apiClient);
});

// 2. Staff Devices List Provider.
//
// No zoneId is sent: the backend already scopes the response to every zone the
// staff member is assigned to (subtree-expanded). Passing the login's single
// "primary" zone here used to hide the other zones a multi-zone staff member is
// responsible for.
final staffDevicesProvider = FutureProvider.autoDispose<List<DeviceModel>>((ref) async {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  return deviceRepo.getDevices(
    includeSubzones: true,
    limit: 100,
  );
});

// 3. Available Spares Provider (Devices with status 'provisioned' in inventory)
final availableSparesProvider = FutureProvider.autoDispose<List<DeviceModel>>((ref) async {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  return deviceRepo.getDevices(status: 'provisioned');
});
