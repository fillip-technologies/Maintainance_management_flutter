import 'device_model.dart';

/// Represents a collection of equipment units grouped by their hardware type name.
class DeviceGroup {
  final String hardwareTypeName;
  final List<DeviceModel> devices;

  const DeviceGroup({
    required this.hardwareTypeName,
    required this.devices,
  });

  int get totalCount => devices.length;
  int get activeCount => devices.where((d) => d.status == DeviceStatus.active).length;
  int get faultyCount => devices.where((d) => d.status == DeviceStatus.faulty).length;
  int get maintenanceCount => devices.where((d) => d.status == DeviceStatus.underMaintenance).length;
  int get inStockCount => devices.where((d) => d.status == DeviceStatus.provisioned).length;
  int get retiredCount => devices.where((d) => d.status == DeviceStatus.retired).length;

  /// Groups a flat list of devices by their [DeviceModel.hardwareTypeName].
  static List<DeviceGroup> fromDevices(List<DeviceModel> devices) {
    final Map<String, List<DeviceModel>> grouped = {};
    for (final dev in devices) {
      final key = dev.hardwareTypeName.trim().isNotEmpty
          ? dev.hardwareTypeName.trim()
          : 'Other Equipment';
      grouped.putIfAbsent(key, () => []).add(dev);
    }
    return grouped.entries
        .map((e) => DeviceGroup(hardwareTypeName: e.key, devices: e.value))
        .toList()
      ..sort((a, b) => a.hardwareTypeName.toLowerCase().compareTo(b.hardwareTypeName.toLowerCase()));
  }
}
