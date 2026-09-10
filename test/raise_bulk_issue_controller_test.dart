import 'package:flutter_test/flutter_test.dart';
import 'package:equipment_management_system/features/devices/devices.dart';
import 'package:equipment_management_system/features/issues/controllers/raise_bulk_issue_controller.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';

void main() {
  group('RaiseBulkIssueController', () {
    late RaiseBulkIssueController controller;

    final dummyDevice1 = DeviceModel(
      id: 'dev-1',
      zoneId: 'z-1',
      zoneName: 'Main Zone',
      name: 'Camera Alpha',
      location: 'Gate 1',
      status: DeviceStatus.active,
      serialNumber: 'SN-001',
      hardwareTypeName: 'Security Camera',
    );

    final dummyDevice2 = DeviceModel(
      id: 'dev-2',
      zoneId: 'z-1',
      zoneName: 'Main Zone',
      name: 'Camera Beta',
      location: 'Gate 2',
      status: DeviceStatus.active,
      serialNumber: 'SN-002',
      hardwareTypeName: 'Security Camera',
    );

    final retiredDevice = DeviceModel(
      id: 'dev-retired',
      zoneId: 'z-1',
      zoneName: 'Main Zone',
      name: 'Old Camera',
      location: 'Scrapyard',
      status: DeviceStatus.retired,
      serialNumber: 'SN-003',
      hardwareTypeName: 'Security Camera',
    );

    setUp(() {
      controller = RaiseBulkIssueController(
        onStateChanged: (_) {},
      );
    });

    test('initial state defaults', () {
      expect(controller.state.selectedDeviceIds, isEmpty);
      expect(controller.state.selectedCategory, isNull);
      expect(controller.state.selectedPriority, IssuePriority.medium);
      expect(controller.state.description, '');
      expect(controller.state.isSubmitting, isFalse);
    });

    test('toggleDevice handles active, retired, and limit', () {
      // Toggle retired
      final retiredRes = controller.toggleDevice(retiredDevice);
      expect(retiredRes, DeviceToggleResult.retired);
      expect(controller.state.selectedCount, 0);

      // Toggle active
      final activeRes = controller.toggleDevice(dummyDevice1);
      expect(activeRes, DeviceToggleResult.toggled);
      expect(controller.state.selectedCount, 1);
      expect(controller.state.selectedDeviceIds.contains('dev-1'), isTrue);

      // Toggle off
      final offRes = controller.toggleDevice(dummyDevice1);
      expect(offRes, DeviceToggleResult.toggled);
      expect(controller.state.selectedCount, 0);

      // Add 50 dummy IDs to test limit
      controller.selectAllActive(List.generate(
        50,
        (i) => DeviceModel(
          id: 'dev-fill-$i',
          zoneId: 'z-1',
          zoneName: 'Main Zone',
          name: 'Device $i',
          location: 'Loc',
          status: DeviceStatus.active,
          serialNumber: 'SN-$i',
          hardwareTypeName: 'Test',
        ),
      ));
      expect(controller.state.selectedCount, 50);

      // Try adding 51st
      final limitRes = controller.toggleDevice(dummyDevice1);
      expect(limitRes, DeviceToggleResult.limitReached);
      expect(controller.state.selectedCount, 50);
    });

    test('group stepper functions correctly', () {
      final group = DeviceGroup(
        hardwareTypeName: 'Security Camera',
        devices: [dummyDevice1, dummyDevice2],
      );

      controller.increaseGroupQuantity(group);
      expect(controller.state.selectedCount, 1);
      expect(controller.state.selectedDeviceIds.contains('dev-1'), isTrue);

      controller.increaseGroupQuantity(group);
      expect(controller.state.selectedCount, 2);

      controller.decreaseGroupQuantity(group);
      expect(controller.state.selectedCount, 1);
    });

    test('filterDevices filters by hardware type and search', () {
      final list = [dummyDevice1, dummyDevice2];

      final filtered = RaiseBulkIssueController.filterDevices(
        allDevices: list,
        selectedHardwareType: 'Security Camera',
        searchQuery: 'Alpha',
      );
      expect(filtered.length, 1);
      expect(filtered.first.id, 'dev-1');
    });
  });
}
