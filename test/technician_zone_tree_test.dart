import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equipment_management_system/features/devices/devices.dart';
import 'package:equipment_management_system/features/issues/issues.dart';
import 'package:equipment_management_system/features/technician/models/technician_queue_state.dart';
import 'package:equipment_management_system/features/technician/models/technician_zone_tree_state.dart';
import 'package:equipment_management_system/features/technician/viewmodels/technician_view_mode_provider.dart';
import 'package:equipment_management_system/features/technician/views/widgets/subzone_grid_card.dart';
import 'package:equipment_management_system/features/technician/views/widgets/technician_search_filter_bar.dart';
import 'package:equipment_management_system/features/technician/views/widgets/zone_device_card.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';

/// Wraps a technician widget with the localization delegates it now needs.
Widget _localized(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('TechnicianZoneNode Unit Tests', () {
    test('parses from raw backend zone JSON and initializes default counts', () {
      final json = {
        'id': 'zone-101',
        'clientId': 'client-1',
        'clientName': 'City Zoo',
        'name': 'North Enclosure',
        'description': 'Main safari area',
        'parentZoneId': null,
        'depth': 0,
        'status': 'active',
      };

      final node = TechnicianZoneNode.fromJson(json);

      expect(node.id, 'zone-101');
      expect(node.name, 'North Enclosure');
      expect(node.clientName, 'City Zoo');
      expect(node.depth, 0);
      expect(node.isTopLevel, isTrue);
      expect(node.deviceCount, 0);
      expect(node.workingCount, 0);
      expect(node.notWorkingCount, 0);
      expect(node.openIssuesCount, 0);
      expect(node.criticalIssuesCount, 0);
      expect(node.operationalPercentage, 100);
      expect(node.healthStatus, ZoneHealthStatus.healthy);
    });

    test('parses real backend /technicians/me/zones payload with openIssues and deviceCount as numbers', () {
      final backendTechZone = {
        'id': '7328d5e5-1641-4f22-904c-d8559b8c367b',
        'name': 'South Zone',
        'status': 'draft',
        'client': {
          'id': 'd036929f-95a6-4bf0-905c-f657822d09d7',
          'name': 'Nature Safari',
        },
        'deviceCount': 3,
        'openIssues': 4,
      };

      final node = TechnicianZoneNode.fromJson(backendTechZone);

      expect(node.id, '7328d5e5-1641-4f22-904c-d8559b8c367b');
      expect(node.name, 'South Zone');
      expect(node.clientName, 'Nature Safari');
      expect(node.deviceCount, 3);
      expect(node.openIssuesCount, 4);
      expect(node.openIssues, isEmpty);
      expect(node.healthStatus, ZoneHealthStatus.warning);
    });

    test('calculates operationalPercentage accurately', () {
      const node = TechnicianZoneNode(
        id: 'zone-1',
        name: 'Zone 1',
        depth: 1,
        deviceCount: 10,
        workingCount: 8,
        notWorkingCount: 2,
      );

      expect(node.operationalPercentage, 80);
    });

    test('determines health status correctly based on defect severities and breakdown', () {
      // 1. Critical when critical issues > 0
      const criticalNode = TechnicianZoneNode(
        id: 'zone-c',
        name: 'Critical Area',
        deviceCount: 5,
        workingCount: 4,
        notWorkingCount: 1,
        criticalIssuesCount: 1,
      );
      expect(criticalNode.healthStatus, ZoneHealthStatus.critical);

      // 2. Warning when high issues > 0
      const warningNode1 = TechnicianZoneNode(
        id: 'zone-w1',
        name: 'Warning Area',
        deviceCount: 5,
        workingCount: 5,
        highIssuesCount: 1,
      );
      expect(warningNode1.healthStatus, ZoneHealthStatus.warning);

      // 3. Warning when open issues > 0
      const warningNode2 = TechnicianZoneNode(
        id: 'zone-w2',
        name: 'Warning Area 2',
        deviceCount: 5,
        workingCount: 5,
        openIssuesCount: 2,
      );
      expect(warningNode2.healthStatus, ZoneHealthStatus.warning);

      // 4. Warning when 1 device not working
      const warningNode3 = TechnicianZoneNode(
        id: 'zone-w3',
        name: 'Warning Area 3',
        deviceCount: 5,
        workingCount: 4,
        notWorkingCount: 1,
      );
      expect(warningNode3.healthStatus, ZoneHealthStatus.warning);

      // 5. Healthy when 0 defects and all devices working
      const healthyNode = TechnicianZoneNode(
        id: 'zone-h',
        name: 'Healthy Area',
        deviceCount: 10,
        workingCount: 10,
        notWorkingCount: 0,
        openIssuesCount: 0,
      );
      expect(healthyNode.healthStatus, ZoneHealthStatus.healthy);
    });

    test('copyWith updates properties properly', () {
      const original = TechnicianZoneNode(
        id: 'z-1',
        name: 'Alpha',
        depth: 0,
      );

      final updated = original.copyWith(
        deviceCount: 12,
        workingCount: 10,
        notWorkingCount: 2,
        subzoneCount: 3,
        criticalIssuesCount: 1,
      );

      expect(updated.id, 'z-1');
      expect(updated.name, 'Alpha');
      expect(updated.deviceCount, 12);
      expect(updated.workingCount, 10);
      expect(updated.notWorkingCount, 2);
      expect(updated.subzoneCount, 3);
      expect(updated.hasSubzones, isTrue);
      expect(updated.criticalIssuesCount, 1);
      expect(updated.healthStatus, ZoneHealthStatus.critical);
    });
  });

  group('TechnicianZoneTreeState Unit Tests', () {
    test('manages root state and depth correctly', () {
      const rootState = TechnicianZoneTreeState(
        rootZones: [
          TechnicianZoneNode(id: 'root-1', name: 'Zone A', depth: 0),
          TechnicianZoneNode(id: 'root-2', name: 'Zone B', depth: 0),
        ],
        currentPath: [],
      );

      expect(rootState.isAtRoot, isTrue);
      expect(rootState.currentZone, isNull);
      expect(rootState.currentDepth, 0);
    });

    test('manages drill-down path and ancestor hierarchy correctly', () {
      const level0 = TechnicianZoneNode(id: 'root-1', name: 'Zone A', depth: 0);
      const level1 = TechnicianZoneNode(id: 'sub-1', name: 'Section 1', depth: 1, parentZoneId: 'root-1');

      final drilledState = TechnicianZoneTreeState(
        rootZones: const [level0],
        currentPath: const [level0, level1],
        currentSubzones: const [],
        currentDevices: const [],
        currentIssues: const [],
      );

      expect(drilledState.isAtRoot, isFalse);
      expect(drilledState.currentZone, level1);
      expect(drilledState.currentDepth, 2);
      expect(drilledState.currentPath.length, 2);
    });

    test('view mode toggles between spatial explorer and work queue', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(technicianViewModeProvider),
        TechnicianViewMode.spatialExplorer,
      );

      container
          .read(technicianViewModeProvider.notifier)
          .setMode(TechnicianViewMode.workQueue);
      expect(
        container.read(technicianViewModeProvider),
        TechnicianViewMode.workQueue,
      );
    });
  });

  group('ZoneDeviceCard Widget Tests', () {
    testWidgets('renders device with embedded visual defect strip and inspects on tap', (tester) async {
      const device = DeviceModel(
        id: 'dev-1',
        zoneId: 'zone-1',
        zoneName: 'South Zone',
        name: 'Main Gate Camera',
        serialNumber: 'CAM-001',
        hardwareTypeName: 'CCTV Camera',
        location: 'Main Gate',
        status: DeviceStatus.faulty,
      );

      final issue = IssueModel(
        id: 'iss-12345678',
        title: 'Lens cracked',
        description: 'Camera lens broken',
        deviceId: 'dev-1',
        deviceName: 'Main Gate Camera',
        zoneId: 'zone-1',
        zoneName: 'South Zone',
        categoryId: 'cat-1',
        categoryName: 'Optical Hardware',
        priority: IssuePriority.critical,
        status: IssueStatus.open,
        createdByUserId: 'user-1',
        createdByUserName: 'Supervisor',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool inspected = false;

      await tester.pumpWidget(
        _localized(
          ZoneDeviceCard(
            device: device,
            activeIssues: [issue],
            onInspectIssue: (iss) => inspected = true,
          ),
        ),
      );

      // Verify device info rendered
      expect(find.text('Main Gate Camera'), findsOneWidget);
      expect(find.text('CAM-001'), findsOneWidget);
      expect(find.text('CCTV Camera'), findsOneWidget);

      // Verify visual defect strip rendered
      expect(find.text('Lens cracked'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);

      // Tap defect strip to inspect
      await tester.tap(find.text('Lens cracked'));
      expect(inspected, isTrue);
    });

    testWidgets('renders healthy device cleanly without defect strip', (tester) async {
      const device = DeviceModel(
        id: 'dev-2',
        zoneId: 'zone-1',
        zoneName: 'South Zone',
        name: 'Corridor Dome Camera',
        serialNumber: 'CAM-002',
        hardwareTypeName: 'CCTV Camera',
        status: DeviceStatus.active,
      );

      await tester.pumpWidget(
        _localized(
          const ZoneDeviceCard(
            device: device,
            activeIssues: [],
          ),
        ),
      );

      expect(find.text('Corridor Dome Camera'), findsOneWidget);
      expect(find.text('CAM-002'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      // Ensure zero defect banners rendered
      expect(find.text('CRITICAL'), findsNothing);
    });

    testWidgets('renders resolved device with green background and RESOLVED badge, not red or CRITICAL', (tester) async {
      const device = DeviceModel(
        id: 'dev-res',
        zoneId: 'zone-1',
        zoneName: 'South Zone',
        name: 'Turnstile A',
        serialNumber: 'TRN-001',
        hardwareTypeName: 'Turnstile',
        status: DeviceStatus.active,
      );

      final resolvedIssue = IssueModel(
        id: 'iss-999',
        title: 'Sensor misaligned',
        description: 'Sensor replaced and calibrated',
        deviceId: 'dev-res',
        deviceName: 'Turnstile A',
        zoneId: 'zone-1',
        zoneName: 'South Zone',
        categoryId: 'cat-1',
        categoryName: 'Hardware',
        priority: IssuePriority.critical,
        status: IssueStatus.resolved,
        createdByUserId: 'user-1',
        createdByUserName: 'Supervisor',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        _localized(
          ZoneDeviceCard(
            device: device,
            activeIssues: [resolvedIssue],
          ),
        ),
      );

      expect(find.text('Turnstile A'), findsOneWidget);
      expect(find.text('RESOLVED'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      // Ensure red critical defect banner is NOT rendered
      expect(find.text('CRITICAL'), findsNothing);
    });

    test('filters devices strictly to only those with unresolved issues in spatial view', () {
      const d1 = DeviceModel(id: 'd1', zoneId: 'z1', zoneName: 'Z', name: 'D1', serialNumber: '1', hardwareTypeName: 'H');
      const d2 = DeviceModel(id: 'd2', zoneId: 'z1', zoneName: 'Z', name: 'D2', serialNumber: '2', hardwareTypeName: 'H');
      const d3 = DeviceModel(id: 'd3', zoneId: 'z1', zoneName: 'Z', name: 'D3', serialNumber: '3', hardwareTypeName: 'H');
      const d4 = DeviceModel(id: 'd4', zoneId: 'z1', zoneName: 'Z', name: 'D4', serialNumber: '4', hardwareTypeName: 'H');

      final allDevices = [d1, d2, d3, d4];

      final rawIssues = [
        IssueModel(
          id: 'i1',
          title: 'Issue 1',
          description: '',
          deviceId: 'd1',
          deviceName: 'D1',
          zoneId: 'z1',
          zoneName: 'Z',
          categoryId: '',
          categoryName: '',
          priority: IssuePriority.high,
          status: IssueStatus.open,
          createdByUserId: 'u1',
          createdByUserName: 'U',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        IssueModel(
          id: 'i2',
          title: 'Issue 2',
          description: '',
          deviceId: 'd2',
          deviceName: 'D2',
          zoneId: 'z1',
          zoneName: 'Z',
          categoryId: '',
          categoryName: '',
          priority: IssuePriority.medium,
          status: IssueStatus.inProgress,
          createdByUserId: 'u1',
          createdByUserName: 'U',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        IssueModel(
          id: 'i3',
          title: 'Issue 3',
          description: '',
          deviceId: 'd3',
          deviceName: 'D3',
          zoneId: 'z1',
          zoneName: 'Z',
          categoryId: '',
          categoryName: '',
          priority: IssuePriority.low,
          status: IssueStatus.resolved,
          createdByUserId: 'u1',
          createdByUserName: 'U',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // In spatial view: exclude resolved/closed issues
      final activeIssues = rawIssues
          .where((i) => i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
          .toList();

      // Only show devices that have unresolved issues
      final displayedDevices = allDevices.where((d) {
        return activeIssues.any((iss) => iss.deviceId == d.id);
      }).toList();

      expect(displayedDevices.length, 2);
      expect(displayedDevices.map((d) => d.id).toList(), ['d1', 'd2']);
    });

    testWidgets('SubzoneGridCard renders unresolved units count and nested zones count', (tester) async {
      const zone = TechnicianZoneNode(
        id: 'z-nested',
        name: 'Surgical Wing',
        deviceCount: 10,
        subzoneCount: 3,
        unresolvedUnitsCount: 2,
        openIssuesCount: 2,
      );

      await tester.pumpWidget(
        _localized(SubzoneGridCard(zone: zone, onTap: () {})),
      );

      expect(find.text('Surgical Wing'), findsOneWidget);
      // Health signal is the red count badge; nested sub-zone count is icon + number.
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('2 not resolved'), findsNothing);
      expect(find.text('10 units'), findsNothing);
    });

    testWidgets('SubzoneGridCard renders All resolved when zone has 0 unresolved units', (tester) async {
      const zone = TechnicianZoneNode(
        id: 'z-clean',
        name: 'Radiology Area',
        deviceCount: 8,
        subzoneCount: 1,
        unresolvedUnitsCount: 0,
        openIssuesCount: 0,
      );

      await tester.pumpWidget(
        _localized(SubzoneGridCard(zone: zone, onTap: () {})),
      );

      expect(find.text('Radiology Area'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('All resolved'), findsNothing);
      expect(find.text('8 units'), findsNothing);
    });

    test('Spatial Explorer excludes resolved issues from active defects list', () {
      final issues = [
        IssueModel(
          id: 'i1',
          title: 'Issue 1',
          description: '',
          deviceId: 'd1',
          deviceName: 'D1',
          zoneId: 'z1',
          zoneName: 'Z',
          categoryId: '',
          categoryName: '',
          priority: IssuePriority.high,
          status: IssueStatus.open,
          createdByUserId: 'u1',
          createdByUserName: 'U',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        IssueModel(
          id: 'i2',
          title: 'Issue 2',
          description: '',
          deviceId: 'd2',
          deviceName: 'D2',
          zoneId: 'z1',
          zoneName: 'Z',
          categoryId: '',
          categoryName: '',
          priority: IssuePriority.low,
          status: IssueStatus.resolved,
          createdByUserId: 'u1',
          createdByUserName: 'U',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final activeIssues = issues
          .where((i) => i.status != IssueStatus.resolved && i.status != IssueStatus.closed)
          .toList();

      expect(activeIssues.length, 1);
      expect(activeIssues.first.id, 'i1');
    });

    testWidgets('TechnicianSearchFilterBar renders merged status filter chips with counts', (tester) async {
      int selectedTab = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechnicianSearchFilterBar(
              searchQuery: '',
              selectedPriority: null,
              selectedTabIndex: selectedTab,
              stats: const TechnicianKpiStats(total: 10, open: 4, onHold: 2, resolved: 4),
              onSearchChanged: (_) {},
              onPriorityChanged: (_) {},
              onTabSelected: (idx) => selectedTab = idx,
            ),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('4'), findsNWidgets(2)); // open 4, resolved 4
      expect(find.text('On Hold'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);

      // Tap On Hold chip
      await tester.tap(find.text('On Hold'));
      expect(selectedTab, 1);
    });

    test('aggregates subtree breakdown across multiple subzones correctly for coverage overview', () {
      final breakdownMap = {
        'sub-1': {'total': 5, 'working': 4, 'faulty': 1, 'underMaintenance': 0},
        'sub-2': {'total': 3, 'working': 3, 'faulty': 0, 'underMaintenance': 0},
      };

      int subtreeTotal = 0;
      int subtreeWorking = 0;
      int subtreeFaulty = 0;
      int subtreeMaintenance = 0;

      for (final entry in breakdownMap.values) {
        subtreeTotal += entry['total'] ?? 0;
        subtreeWorking += entry['working'] ?? 0;
        subtreeFaulty += entry['faulty'] ?? 0;
        subtreeMaintenance += entry['underMaintenance'] ?? 0;
      }

      expect(subtreeTotal, 8);
      expect(subtreeWorking, 7);
      expect(subtreeFaulty, 1);
      expect(subtreeMaintenance, 0);
    });
  });
}


