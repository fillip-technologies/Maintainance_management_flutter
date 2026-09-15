import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/theme/colors.dart';
import '../lib/features/devices/devices.dart';
import '../lib/features/issues/models/issue_model.dart';
import '../lib/features/staff/views/widgets/staff_devices_directory_tab.dart';
import '../lib/features/staff/views/widgets/staff_device_grid_card.dart';
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
      status: DeviceStatus.faulty, // problem (faulty)
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
      status: DeviceStatus.active, // will have an active issue
      serialNumber: 'SW-01',
      zoneId: 'z3',
      zoneName: 'Server Room',
      location: 'Rack A',
    ),
  ];

  final sampleIssues = [
    IssueModel(
      id: 'iss1',
      title: 'Port failure',
      description: 'Switch port 3 down',
      deviceId: 'd4',
      deviceName: 'Switch Core 1',
      zoneId: 'z3',
      zoneName: 'Server Room',
      categoryId: 'cat1',
      categoryName: 'Port Defect',
      status: IssueStatus.open, // Unresolved issue on d4
      priority: IssuePriority.high,
      createdByUserId: 'u1',
      createdByUserName: 'Staff',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  group('StaffDevicesDirectoryTab Visual Grid & Multi-Select Tests', () {
    testWidgets('renders all devices as visual StaffDeviceGridCards directly with NO camera names on card face', (tester) async {
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
            issues: sampleIssues,
            isLoading: false,
            hasError: false,
            onRefresh: () async {},
            onOpenRaiseIssue: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All 4 devices should be rendered directly as StaffDeviceGridCard
      expect(find.byType(StaffDeviceGridCard), findsNWidgets(4));

      // No camera/device names should be printed on the card face
      expect(find.text('Fixed Cam 1'), findsNothing);
      expect(find.text('Fixed Cam 2'), findsNothing);
      expect(find.text('PTZ Cam 1'), findsNothing);
      expect(find.text('Switch Core 1'), findsNothing);
    });

    testWidgets('correctly marks green active vs red problem status', (tester) async {
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
            issues: sampleIssues,
            isLoading: false,
            hasError: false,
            onRefresh: () async {},
            onOpenRaiseIssue: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // d1: Active with no issues -> isProblem = false (Green)
      final d1Card = tester.widget<StaffDeviceGridCard>(
        find.byKey(const ValueKey('device_grid_d1')),
      );
      expect(d1Card.isProblem, isFalse);

      // d2: Faulty status -> isProblem = true (Red)
      final d2Card = tester.widget<StaffDeviceGridCard>(
        find.byKey(const ValueKey('device_grid_d2')),
      );
      expect(d2Card.isProblem, isTrue);

      // d3: Active with no issues -> isProblem = false (Green)
      final d3Card = tester.widget<StaffDeviceGridCard>(
        find.byKey(const ValueKey('device_grid_d3')),
      );
      expect(d3Card.isProblem, isFalse);

      // d4: Has unresolved issue iss1 -> isProblem = true (Red)
      final d4Card = tester.widget<StaffDeviceGridCard>(
        find.byKey(const ValueKey('device_grid_d4')),
      );
      expect(d4Card.isProblem, isTrue);
    });

    testWidgets('renders top Zone Tabs when multiple zones exist and filters on tap', (tester) async {
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
            issues: sampleIssues,
            isLoading: false,
            hasError: false,
            onRefresh: () async {},
            onOpenRaiseIssue: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show All Zones, Main Entrance, Perimeter, Server Room
      expect(find.text('All Zones'), findsOneWidget);
      expect(find.text('Main Entrance'), findsOneWidget);
      expect(find.text('Perimeter'), findsOneWidget);
      expect(find.text('Server Room'), findsOneWidget);

      // Tap 'Main Entrance' zone tab
      await tester.tap(find.text('Main Entrance'));
      await tester.pumpAndSettle();

      // 2 devices (Fixed Cam 1 and Fixed Cam 2 in Main Entrance) should be visible
      expect(find.byType(StaffDeviceGridCard), findsNWidgets(2));
      expect(find.byKey(const ValueKey('device_grid_d1')), findsOneWidget);
      expect(find.byKey(const ValueKey('device_grid_d2')), findsOneWidget);

      // Tap 'All Zones' to reset
      await tester.tap(find.text('All Zones'));
      await tester.pumpAndSettle();
      expect(find.byType(StaffDeviceGridCard), findsNWidgets(4));
    });

    testWidgets('multi-select allows selecting units, shows bottom bar, and selects all', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      List<DeviceModel>? raisedBulkDevices;

      await tester.pumpWidget(
        buildTestWidget(
          StaffDevicesDirectoryTab(
            devices: sampleDevices,
            issues: sampleIssues,
            isLoading: false,
            hasError: false,
            onRefresh: () async {},
            onOpenRaiseIssue: (_) {},
            onOpenRaiseBulkIssue: (devs) {
              raisedBulkDevices = devs;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no bottom bar
      expect(find.text('1 Selected'), findsNothing);
      expect(find.text('Select All'), findsNothing);

      // Long-press or tap tick on d1
      final d1Finder = find.byKey(const ValueKey('device_grid_d1'));
      await tester.longPress(d1Finder);
      await tester.pumpAndSettle();

      // Bottom bar appears
      expect(find.text('1 Selected'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Tap on d2 card in selection mode
      final d2Finder = find.byKey(const ValueKey('device_grid_d2'));
      await tester.tap(d2Finder);
      await tester.pumpAndSettle();

      expect(find.text('2 Selected'), findsOneWidget);

      // Tap 'Select All'
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      expect(find.text('4 Selected'), findsOneWidget);

      // Tap 'Raise Defect Ticket (4 units)'
      await tester.tap(find.text('Raise Defect Ticket (4 units)'));
      await tester.pumpAndSettle();

      expect(raisedBulkDevices, isNotNull);
      expect(raisedBulkDevices!.length, equals(4));

      // After raising, selection clears
      expect(find.text('4 Selected'), findsNothing);
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
            issues: sampleIssues,
            isLoading: false,
            hasError: false,
            onRefresh: () async {},
            onOpenRaiseIssue: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StaffDeviceGridCard), findsNWidgets(4));

      // Reset theme
      AppColors.isDark = false;
    });
  });
}
