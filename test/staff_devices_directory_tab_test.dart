import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/theme/colors.dart';
import '../lib/features/devices/devices.dart';
import '../lib/features/staff/views/widgets/staff_devices_directory_tab.dart';
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

  final sampleDevices = [
    const DeviceModel(
      id: 'd1',
      name: 'Fixed Cam 1',
      hardwareTypeId: 'hw1',
      hardwareTypeName: 'Fixed Cameras',
      status: DeviceStatus.active,
      serialNumber: 'FC-01',
      zoneId: 'z1',
      zoneName: 'Main Entrance',
      location: 'Gate 1',
    ),
    const DeviceModel(
      id: 'd2',
      name: 'Fixed Cam 2',
      hardwareTypeId: 'hw1',
      hardwareTypeName: 'Fixed Cameras',
      status: DeviceStatus.faulty,
      serialNumber: 'FC-02',
      zoneId: 'z1',
      zoneName: 'Main Entrance',
      location: 'Gate 2',
    ),
    const DeviceModel(
      id: 'd3',
      name: 'PTZ Cam 1',
      hardwareTypeId: 'hw2',
      hardwareTypeName: 'PTZ Cameras',
      status: DeviceStatus.active,
      serialNumber: 'PTZ-01',
      zoneId: 'z2',
      zoneName: 'Perimeter',
      location: 'Tower A',
    ),
    const DeviceModel(
      id: 'd4',
      name: 'Switch Core 1',
      hardwareTypeId: 'hw3',
      hardwareTypeName: 'Network Switches',
      status: DeviceStatus.underMaintenance,
      serialNumber: 'SW-01',
      zoneId: 'z3',
      zoneName: 'Server Room',
      location: 'Rack A',
    ),
  ];

  group('StaffDevicesDirectoryTab Widget Tests', () {
    testWidgets('renders 2-column GridView of EquipmentCategoryCard in grouped mode', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          StaffDevicesDirectoryTab(
            devices: sampleDevices,
            isLoading: false,
            hasError: false,
            onRefresh: () async {},
            onOpenRaiseIssue: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should display category cards for Fixed Cameras, PTZ Cameras, Network Switches
      expect(find.byType(EquipmentCategoryCard), findsNWidgets(3));
      expect(find.text('Fixed Cameras'), findsOneWidget);
      expect(find.text('PTZ Cameras'), findsOneWidget);
      expect(find.text('Network Switches'), findsOneWidget);

      // Verify header category count text
      expect(find.text('3 Categories'), findsOneWidget);
      expect(find.text('4 Units'), findsOneWidget);
    });

    testWidgets('tapping a category card opens CategoryDevicesSheet', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          StaffDevicesDirectoryTab(
            devices: sampleDevices,
            isLoading: false,
            hasError: false,
            onRefresh: () async {},
            onOpenRaiseIssue: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the Fixed Cameras category card
      await tester.tap(find.text('Fixed Cameras'));
      await tester.pumpAndSettle();

      // Bottom sheet should open
      expect(find.byType(CategoryDevicesSheet), findsOneWidget);
      expect(find.text('Fixed Cam 1'), findsOneWidget);
      expect(find.text('Fixed Cam 2'), findsOneWidget);
    });

    testWidgets('toggling view switches between Catalog Grid and Flat List view', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          StaffDevicesDirectoryTab(
            devices: sampleDevices,
            isLoading: false,
            hasError: false,
            onRefresh: () async {},
            onOpenRaiseIssue: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially in Grid view: filter chips are hidden
      expect(find.byType(EquipmentCategoryCard), findsNWidgets(3));
      expect(find.text('All Hardware'), findsNothing);

      // Tap toggle button (grid icon) to switch to List view
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      // Now in Flat List view: filter chips are shown, individual device cards shown
      expect(find.byType(EquipmentCategoryCard), findsNothing);
      expect(find.text('All Hardware'), findsOneWidget);
      expect(find.text('Fixed Cam 1'), findsOneWidget);
      expect(find.text('Fixed Cam 2'), findsOneWidget);
      expect(find.text('PTZ Cam 1'), findsOneWidget);
      expect(find.text('Switch Core 1'), findsOneWidget);

      // Tap toggle button again to switch back to Grid view
      await tester.tap(find.byIcon(Icons.list_alt_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCategoryCard), findsNWidgets(3));
      expect(find.text('All Hardware'), findsNothing);
    });

    testWidgets('renders properly in dark mode without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      AppColors.isDark = true;

      await tester.pumpWidget(
        buildTestWidget(
          StaffDevicesDirectoryTab(
            devices: sampleDevices,
            isLoading: false,
            hasError: false,
            onRefresh: () async {},
            onOpenRaiseIssue: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(EquipmentCategoryCard), findsNWidgets(3));

      // Reset theme
      AppColors.isDark = false;
    });
  });
}
