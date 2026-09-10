import 'package:flutter_test/flutter_test.dart';
import '../lib/features/devices/devices.dart';
import '../lib/features/issues/controllers/replace_device_controller.dart';
import '../lib/features/issues/controllers/replace_device_state.dart';

void main() {
  group('ReplaceDeviceController', () {
    late ReplaceDeviceController controller;

    final dummySpare1 = DeviceModel(
      id: 'spare-1',
      zoneId: 'z-1',
      zoneName: 'Main Zone',
      name: 'Spare CCTV Alpha',
      location: 'Store Room',
      status: DeviceStatus.provisioned,
      serialNumber: 'SN-S001',
      hardwareTypeName: 'Security Camera',
    );

    final dummySpare2 = DeviceModel(
      id: 'spare-2',
      zoneId: 'z-1',
      zoneName: 'Main Zone',
      name: 'Spare Turnstile Beta',
      location: 'Warehouse',
      status: DeviceStatus.provisioned,
      serialNumber: 'SN-S002',
      hardwareTypeName: 'Access Control',
    );

    setUp(() {
      controller = ReplaceDeviceController(
        onStateChanged: (_) {},
      );
    });

    test('initial state defaults', () {
      expect(controller.state.selectedReason, DecommissionReason.physicalDamage);
      expect(controller.state.replacementChoice, ReplacementChoice.none);
      expect(controller.state.selectedSpareDevice, isNull);
      expect(controller.state.notes, '');
      expect(controller.state.searchQuery, '');
      expect(controller.state.isSubmitting, isFalse);
    });

    test('setting reason and replacement choice', () {
      controller.setReason(DecommissionReason.burntWater);
      expect(controller.state.selectedReason, DecommissionReason.burntWater);

      controller.setReplacementChoice(ReplacementChoice.inStock);
      expect(controller.state.replacementChoice, ReplacementChoice.inStock);

      controller.setSelectedSpareDevice(dummySpare1);
      expect(controller.state.selectedSpareDevice?.id, 'spare-1');

      // Resetting to none should clear spare device
      controller.setReplacementChoice(ReplacementChoice.none);
      expect(controller.state.replacementChoice, ReplacementChoice.none);
      expect(controller.state.selectedSpareDevice, isNull);
    });

    test('filterSpares filters by query matching name or hardware type', () {
      final spares = [dummySpare1, dummySpare2];

      final filtered1 = ReplaceDeviceController.filterSpares(
        spares: spares,
        searchQuery: 'Alpha',
      );
      expect(filtered1.length, 1);
      expect(filtered1.first.id, 'spare-1');

      final filtered2 = ReplaceDeviceController.filterSpares(
        spares: spares,
        searchQuery: 'Access',
      );
      expect(filtered2.length, 1);
      expect(filtered2.first.id, 'spare-2');

      final all = ReplaceDeviceController.filterSpares(
        spares: spares,
        searchQuery: '',
      );
      expect(all.length, 2);
    });
  });
}
