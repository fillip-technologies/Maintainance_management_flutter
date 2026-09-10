import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/features/devices/devices.dart';
import '../lib/features/staff/views/widgets/equipment_category_card.dart';
import '../lib/features/staff/views/widgets/category_devices_sheet.dart';
import '../lib/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('EquipmentCategoryCard Widget Tests', () {
    testWidgets('renders total count, category name, and Online/Offline/Maintenance metrics', (tester) async {
      final List<DeviceModel> devices = [
        for (int i = 0; i < 130; i++)
          DeviceModel(
            id: 'dev_active_$i',
            name: 'Camera Unit $i',
            hardwareTypeId: 'hw_cam',
            hardwareTypeName: 'Fixed Cameras',
            status: DeviceStatus.active,
            serialNumber: 'FC-ACT-$i',
            zoneId: 'z1',
            zoneName: 'Main Entrance',
            location: 'Gate 1',
          ),
        for (int i = 0; i < 10; i++)
          DeviceModel(
            id: 'dev_faulty_$i',
            name: 'Faulty Unit $i',
            hardwareTypeId: 'hw_cam',
            hardwareTypeName: 'Fixed Cameras',
            status: DeviceStatus.faulty,
            serialNumber: 'FC-FLT-$i',
            zoneId: 'z1',
            zoneName: 'Main Entrance',
            location: 'Gate 1',
          ),
        for (int i = 0; i < 2; i++)
          DeviceModel(
            id: 'dev_maint_$i',
            name: 'Maint Unit $i',
            hardwareTypeId: 'hw_cam',
            hardwareTypeName: 'Fixed Cameras',
            status: DeviceStatus.underMaintenance,
            serialNumber: 'FC-MNT-$i',
            zoneId: 'z1',
            zoneName: 'Main Entrance',
            location: 'Gate 1',
          ),
      ];

      final group = DeviceGroup(hardwareTypeName: 'Fixed Cameras', devices: devices);
      bool tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          EquipmentCategoryCard(
            group: group,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Total count
      expect(find.text('142'), findsOneWidget);
      // Category Name
      expect(find.text('Fixed Cameras'), findsOneWidget);
      // Online metric
      expect(find.text('130'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      // Offline metric
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      // Maintenance metric
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);

      // Tap card
      await tester.tap(find.byType(EquipmentCategoryCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('uses Active and Down labels for optical/fiber links', (tester) async {
      final List<DeviceModel> devices = [
        const DeviceModel(
          id: 'dev_fib_1',
          name: 'Fiber Core A',
          hardwareTypeId: 'hw_fiber',
          hardwareTypeName: 'Fiber Links',
          status: DeviceStatus.active,
          serialNumber: 'FIB-01',
          zoneId: 'z1',
          zoneName: 'Server Room',
          location: 'Rack 1',
        ),
        const DeviceModel(
          id: 'dev_fib_2',
          name: 'Fiber Core B',
          hardwareTypeId: 'hw_fiber',
          hardwareTypeName: 'Fiber Links',
          status: DeviceStatus.faulty,
          serialNumber: 'FIB-02',
          zoneId: 'z1',
          zoneName: 'Server Room',
          location: 'Rack 1',
        ),
      ];

      final group = DeviceGroup(hardwareTypeName: 'Fiber Links', devices: devices);

      await tester.pumpWidget(
        buildTestWidget(
          EquipmentCategoryCard(
            group: group,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget); // total
      expect(find.text('Fiber Links'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Down'), findsOneWidget);
    });

    testWidgets('CategoryDevicesSheet displays devices and invokes onOpenRaiseIssue', (tester) async {
      const dev = DeviceModel(
        id: 'dev_ptz_1',
        name: 'Dome PTZ #1',
        hardwareTypeId: 'hw_ptz',
        hardwareTypeName: 'PTZ Cameras',
        status: DeviceStatus.active,
        serialNumber: 'PTZ-SN-999',
        zoneId: 'z2',
        zoneName: 'Perimeter West',
        location: 'Pole 12',
      );

      final group = const DeviceGroup(hardwareTypeName: 'PTZ Cameras', devices: [dev]);
      DeviceModel? selectedDevice;

      await tester.pumpWidget(
        buildTestWidget(
          CategoryDevicesSheet(
            group: group,
            onOpenRaiseIssue: (d) => selectedDevice = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PTZ Cameras'), findsOneWidget);
      expect(find.text('Dome PTZ #1'), findsOneWidget);
      expect(find.text('Perimeter West • PTZ-SN-999'), findsOneWidget);

      // Tap on unit card
      await tester.tap(find.text('Dome PTZ #1'));
      await tester.pumpAndSettle();

      expect(selectedDevice, isNotNull);
      expect(selectedDevice!.id, equals('dev_ptz_1'));
    });
  });
}
