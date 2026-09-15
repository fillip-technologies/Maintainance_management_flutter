import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equipment_management_system/core/network/api_client.dart';
import 'package:equipment_management_system/core/storage/storage_service.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/features/devices/devices.dart';
import 'package:equipment_management_system/features/issues/issues.dart';
import 'package:equipment_management_system/features/technician/models/technician_queue_state.dart';
import 'package:equipment_management_system/features/technician/models/technician_zone_map_data.dart';
import 'package:equipment_management_system/features/technician/models/technician_zone_tree_state.dart';
import 'package:equipment_management_system/features/technician/viewmodels/technician_view_mode_provider.dart';
import 'package:equipment_management_system/features/technician/views/widgets/subzone_grid_card.dart';
import 'package:equipment_management_system/features/technician/views/widgets/technician_device_block.dart';
import 'package:equipment_management_system/features/technician/views/widgets/technician_health_ring.dart';
import 'package:equipment_management_system/features/technician/views/widgets/technician_search_filter_bar.dart';
import 'package:equipment_management_system/features/technician/views/widgets/technician_subzone_card.dart';
import 'package:equipment_management_system/features/technician/views/widgets/technician_top_level_zone_card.dart';
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

    test('view mode defaults to zone status table and toggles between modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(technicianViewModeProvider),
        TechnicianViewMode.zoneStatusTable,
      );

      container
          .read(technicianViewModeProvider.notifier)
          .setMode(TechnicianViewMode.spatialExplorer);
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

      // Verify visual defect strip rendered (priority is shown by colour, not text)
      expect(find.text('Lens cracked'), findsOneWidget);
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

    testWidgets('device whose only issue is resolved shows the ALL OK safety strip, no red callout', (tester) async {
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
      expect(find.text('ALL OK'), findsOneWidget);
      // No red defect callout for a device with no unresolved issue
      expect(find.text('Sensor misaligned'), findsNothing);
    });

    testWidgets('working device taps onInspectDevice callback', (tester) async {
      const device = DeviceModel(
        id: 'dev-ok',
        zoneId: 'zone-1',
        zoneName: 'South Zone',
        name: 'Gate Scanner',
        serialNumber: 'GAT-001',
        hardwareTypeName: 'Scanner',
        status: DeviceStatus.active,
      );

      DeviceModel? inspectedDevice;

      await tester.pumpWidget(
        _localized(
          ZoneDeviceCard(
            device: device,
            activeIssues: const [],
            onInspectDevice: (d) => inspectedDevice = d,
          ),
        ),
      );

      expect(find.text('Gate Scanner'), findsOneWidget);
      expect(find.text('ALL OK'), findsOneWidget);

      await tester.tap(find.text('Gate Scanner'));
      expect(inspectedDevice?.id, 'dev-ok');
    });

    testWidgets('device with faulty status without open issues shows defective styling and callout', (tester) async {
      const device = DeviceModel(
        id: 'dev-faulty',
        zoneId: 'zone-1',
        zoneName: 'South Zone',
        name: 'Defective Sensor',
        serialNumber: 'SEN-001',
        hardwareTypeName: 'Sensor',
        status: DeviceStatus.faulty,
      );

      bool inspected = false;

      await tester.pumpWidget(
        _localized(
          ZoneDeviceCard(
            device: device,
            activeIssues: const [],
            onInspectDevice: (_) => inspected = true,
          ),
        ),
      );

      expect(find.text('Defective Sensor'), findsOneWidget);
      expect(find.text('Faulty Unit • Needs Action'), findsOneWidget);
      expect(find.text('ALL OK'), findsNothing);

      await tester.tap(find.text('Faulty Unit • Needs Action'));
      expect(inspected, isTrue);
    });

    test('separates devices into defective (sorted first) and operational in spatial view, showing all devices', () {
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

      bool isDefective(DeviceModel d) =>
          activeIssues.any((iss) => iss.deviceId == d.id) ||
          d.status == DeviceStatus.faulty ||
          d.status == DeviceStatus.underMaintenance;

      final defective = allDevices.where(isDefective).toList();
      final operational = allDevices.where((d) => !isDefective(d)).toList();
      final displayedDevices = [...defective, ...operational];

      expect(displayedDevices.length, 4);
      expect(defective.map((d) => d.id).toList(), ['d1', 'd2']);
      expect(operational.map((d) => d.id).toList(), ['d3', 'd4']);
      expect(displayedDevices.map((d) => d.id).toList(), ['d1', 'd2', 'd3', 'd4']);
    });

    testWidgets('SubzoneGridCard shows yellow border on partial issue (some devices defective)', (tester) async {
      const zone = TechnicianZoneNode(
        id: 'z-nested',
        name: 'Surgical Wing',
        deviceCount: 10,
        workingCount: 8, // 2 units need a fix (partial issue -> YELLOW border)
        subzoneCount: 3,
      );

      await tester.pumpWidget(
        _localized(SubzoneGridCard(zone: zone, onTap: () {})),
      );

      expect(find.text('Surgical Wing'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // badge = units needing fix
      expect(find.text('3'), findsOneWidget); // nested sub-zone count

      final inkWell = tester.widget<InkWell>(find.byType(InkWell).first);
      final container = inkWell.child as Container;
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.color, AppColors.warning);
    });

    testWidgets('SubzoneGridCard shows red border only when ALL devices in zone are under issue', (tester) async {
      const zone = TechnicianZoneNode(
        id: 'z-critical',
        name: 'ICU Ward',
        deviceCount: 4,
        workingCount: 0, // All 4 units broken -> RED border
        subzoneCount: 0,
      );

      await tester.pumpWidget(
        _localized(SubzoneGridCard(zone: zone, onTap: () {})),
      );

      expect(find.text('ICU Ward'), findsOneWidget);
      expect(find.text('4'), findsNWidgets(2)); // badge = 4 broken & inventory = 4 total

      final inkWell = tester.widget<InkWell>(find.byType(InkWell).first);
      final container = inkWell.child as Container;
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.color, AppColors.error);
    });

    testWidgets('SubzoneGridCard shows green border and OK badge when every unit is working', (tester) async {
      const zone = TechnicianZoneNode(
        id: 'z-clean',
        name: 'Radiology Area',
        deviceCount: 8,
        workingCount: 8,
        subzoneCount: 1,
      );

      await tester.pumpWidget(
        _localized(SubzoneGridCard(zone: zone, onTap: () {})),
      );

      expect(find.text('Radiology Area'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // nested sub-zone count

      final inkWell = tester.widget<InkWell>(find.byType(InkWell).first);
      final container = inkWell.child as Container;
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.color, AppColors.success);
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

    test('extractErrorMessage safely handles 429 string payload without type error', () {
      final dioException429 = DioException(
        requestOptions: RequestOptions(path: '/zones'),
        response: Response(
          requestOptions: RequestOptions(path: '/zones'),
          statusCode: 429,
          data: 'Too many requests, please try again later.',
        ),
      );

      final msg = dioException429.extractErrorMessage('Failed to load subzones');
      expect(msg, contains('Too many requests'));
      // Verifies that extracting error does NOT throw "String is not a subtype of int of index"
      expect(msg, isA<String>());
    });

    test('extractErrorMessage safely extracts JSON Map error messages', () {
      final dioExceptionMap = DioException(
        requestOptions: RequestOptions(path: '/zones'),
        response: Response(
          requestOptions: RequestOptions(path: '/zones'),
          statusCode: 400,
          data: {'message': 'Invalid zone id parameter'},
        ),
      );

      final msg = dioExceptionMap.extractErrorMessage('Fallback error');
      expect(msg, 'Invalid zone id parameter');
    });

    test('IssueRepository.getIssues clamps limit to max 100 to prevent backend 400 validation error', () async {
      final storage = _FakeStorageService();
      final apiClient = ApiClient(storage: storage);
      RequestOptions? capturedOptions;
      apiClient.dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedOptions = options;
          handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {'items': []},
            },
          ));
        },
      ));

      final issueRepo = IssueRepository(apiClient: apiClient);

      await issueRepo.getIssues(limit: 200);
      expect(capturedOptions?.queryParameters['limit'], 100);

    });
  });

  group('Technician Web-Parity Zone Map Tests', () {
    testWidgets('TechnicianHealthRing renders percentage text and color accurately', (tester) async {
      await tester.pumpWidget(
        _localized(
          const Row(
            children: [
              TechnicianHealthRing(percentage: 100, size: 44),
              TechnicianHealthRing(percentage: 80, size: 44),
              TechnicianHealthRing(percentage: 50, size: 44),
            ],
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('TechnicianDeviceBlock renders green for active and red for defective', (tester) async {
      const activeDev = DeviceModel(
        id: 'dev-active',
        zoneId: 'z1',
        zoneName: 'Zone 1',
        name: 'Cam 1',
        serialNumber: 'CAM-001',
        hardwareTypeName: 'CCTV Camera',
        status: DeviceStatus.active,
      );

      const defectiveDev = DeviceModel(
        id: 'dev-defective',
        zoneId: 'z1',
        zoneName: 'Zone 1',
        name: 'Cam 2',
        serialNumber: 'CAM-002',
        hardwareTypeName: 'CCTV Camera',
        status: DeviceStatus.faulty,
      );

      await tester.pumpWidget(
        _localized(
          const Row(
            children: [
              TechnicianDeviceBlock(device: activeDev, isDefective: false),
              TechnicianDeviceBlock(device: defectiveDev, isDefective: true),
            ],
          ),
        ),
      );

      // Verify materials render
      final materials = tester.widgetList<Material>(find.byType(Material)).toList();
      final activeMaterial = materials.firstWhere((m) => m.color == AppColors.success);
      final defectiveMaterial = materials.firstWhere((m) => m.color == AppColors.error);

      expect(activeMaterial.color, AppColors.success);
      expect(defectiveMaterial.color, AppColors.error);
    });

    testWidgets('TechnicianSubzoneCard renders header, counts, and status footer', (tester) async {
      const subzoneNode = TechnicianZoneNode(
        id: 'sz-1',
        name: 'North Gate',
      );

      const d1 = DeviceModel(
        id: 'd1',
        zoneId: 'sz-1',
        zoneName: 'North Gate',
        name: 'Gate Cam',
        serialNumber: 'CAM-01',
        hardwareTypeName: 'CCTV Camera',
        status: DeviceStatus.active,
      );

      const d2 = DeviceModel(
        id: 'd2',
        zoneId: 'sz-1',
        zoneName: 'North Gate',
        name: 'Perimeter Cam',
        serialNumber: 'CAM-02',
        hardwareTypeName: 'CCTV Camera',
        status: DeviceStatus.faulty,
      );

      final item = TechnicianSubzoneItem(
        zone: subzoneNode,
        devices: const [d1, d2],
        issues: const [],
      );

      await tester.pumpWidget(
        _localized(
          TechnicianSubzoneCard(subzoneItem: item),
        ),
      );

      expect(find.text('North Gate'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('1 Defective / Issues'), findsOneWidget);
      expect(find.textContaining('1 offline: CAM-02'), findsOneWidget);
    });

    testWidgets('TechnicianTopLevelZoneCard renders uppercase name, stats, and collapses without circular health ring', (tester) async {
      const topZone = TechnicianZoneNode(
        id: 'root-1',
        name: 'Lion Safari Zone',
      );

      const subzoneNode = TechnicianZoneNode(
        id: 'sz-1',
        name: 'North Ridge',
        parentZoneId: 'root-1',
      );

      const d1 = DeviceModel(
        id: 'd1',
        zoneId: 'root-1',
        zoneName: 'Lion Safari Zone',
        name: 'Main Direct Cam',
        serialNumber: 'DIR-01',
        hardwareTypeName: 'CCTV Camera',
        status: DeviceStatus.active,
      );

      const d2 = DeviceModel(
        id: 'd2',
        zoneId: 'sz-1',
        zoneName: 'North Ridge',
        name: 'Ridge Cam',
        serialNumber: 'RDG-01',
        hardwareTypeName: 'CCTV Camera',
        status: DeviceStatus.faulty,
      );

      final subItem = TechnicianSubzoneItem(
        zone: subzoneNode,
        devices: const [d2],
      );

      final topItem = TechnicianTopLevelZoneItem(
        zone: topZone,
        directDevices: const [d1],
        subzones: [subItem],
      );

      await tester.pumpWidget(
        _localized(
          TechnicianTopLevelZoneCard(zoneItem: topItem),
        ),
      );

      // Verify uppercase name
      expect(find.text('LION SAFARI ZONE'), findsOneWidget);
      // Verify stats
      expect(find.text('2 products'), findsOneWidget);
      expect(find.text('1 subzone'), findsOneWidget);
      expect(find.text('● 1'), findsOneWidget);
      expect(find.text('○ 1'), findsOneWidget);
      // Verify circular health ring is NOT present in card
      expect(find.text('50%'), findsNothing);

      // Direct products title rendered when expanded
      expect(find.text('DIRECT PRODUCTS'), findsOneWidget);
      expect(find.text('North Ridge'), findsOneWidget);

      // Tap header to collapse
      await tester.tap(find.text('LION SAFARI ZONE'));
      await tester.pumpAndSettle();

      // Body elements hidden when collapsed
      expect(find.text('DIRECT PRODUCTS'), findsNothing);
      expect(find.text('North Ridge'), findsNothing);
    });

    test('Issue-First Sorting puts problem zones and problem subzones at the top first', () {
      const zNominal = TechnicianZoneNode(id: 'z-clean', name: 'Zebra Enclosure');
      const zWarning = TechnicianZoneNode(id: 'z-warn', name: 'Aviary Wing');
      const zCritical = TechnicianZoneNode(id: 'z-crit', name: 'Aquarium Pavilion');

      const szNominal = TechnicianZoneNode(id: 'sz-clean', name: 'Freshwater Tanks');
      const szProblem = TechnicianZoneNode(id: 'sz-prob', name: 'Reef Tanks');

      final itemNominal = TechnicianTopLevelZoneItem(
        zone: zNominal,
        directDevices: const [
          DeviceModel(id: 'd-ok1', zoneId: 'z-clean', zoneName: 'Z', name: 'Cam 1', hardwareTypeName: 'CCTV'),
          DeviceModel(id: 'd-ok2', zoneId: 'z-clean', zoneName: 'Z', name: 'Cam 2', hardwareTypeName: 'CCTV'),
        ],
      );

      final itemWarning = TechnicianTopLevelZoneItem(
        zone: zWarning,
        directDevices: const [
          DeviceModel(id: 'd-f1', zoneId: 'z-warn', zoneName: 'A', name: 'Cam 3', status: DeviceStatus.faulty, hardwareTypeName: 'CCTV'),
        ],
      );

      final itemCritical = TechnicianTopLevelZoneItem(
        zone: zCritical,
        subzones: [
          TechnicianSubzoneItem(
            zone: szNominal,
            devices: const [
              DeviceModel(id: 'd-ok3', zoneId: 'sz-clean', zoneName: 'F', name: 'Cam 4', hardwareTypeName: 'CCTV'),
            ],
          ),
          TechnicianSubzoneItem(
            zone: szProblem,
            devices: const [
              DeviceModel(id: 'd-f2', zoneId: 'sz-prob', zoneName: 'R', name: 'Cam 5', status: DeviceStatus.faulty, hardwareTypeName: 'CCTV'),
            ],
            issues: [
              IssueModel(
                id: 'iss-1',
                title: 'Sensor Failure',
                description: '',
                deviceId: 'd-f2',
                deviceName: 'Cam 5',
                zoneId: 'sz-prob',
                zoneName: 'R',
                categoryId: '',
                categoryName: '',
                priority: IssuePriority.critical,
                status: IssueStatus.open,
                createdByUserId: 'u1',
                createdByUserName: 'U',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ],
          ),
        ],
      );

      final items = [itemNominal, itemWarning, itemCritical];

      // Sort issue-first
      TechnicianTopLevelZoneItem.sortIssueFirst(items);

      // Aquarium Pavilion has problemScore = 1 (issue) + 1 (faulty) = 2 -> Should be index 0
      // Aviary Wing has problemScore = 1 (faulty) = 1 -> Should be index 1
      // Zebra Enclosure has problemScore = 0 -> Should be index 2
      expect(items[0].zone.id, 'z-crit');
      expect(items[1].zone.id, 'z-warn');
      expect(items[2].zone.id, 'z-clean');

      // Inside Aquarium Pavilion, Reef Tanks (has defect) must be sorted BEFORE Freshwater Tanks (nominal)
      expect(items[0].subzones[0].zone.id, 'sz-prob');
      expect(items[0].subzones[1].zone.id, 'sz-clean');
    });

    testWidgets('Zone 1 renders Big Card containing Sub 1 and Sub 2 small cards with device icons, without duplicate standalone cards', (tester) async {
      const parentZone = TechnicianZoneNode(
        id: 'zone-1',
        name: 'Zone 1',
      );

      const sub1 = TechnicianZoneNode(
        id: 'sub-1',
        name: 'Sub 1',
        parentZoneId: 'zone-1',
      );

      const sub2 = TechnicianZoneNode(
        id: 'sub-2',
        name: 'Sub 2',
        parentZoneId: 'zone-1',
      );

      const devSub1 = DeviceModel(
        id: 'd-sub1',
        zoneId: 'sub-1',
        zoneName: 'Sub 1',
        name: 'Camera S1',
        serialNumber: 'SN-01',
        hardwareTypeName: 'CCTV Camera',
        status: DeviceStatus.active,
      );

      const devSub2 = DeviceModel(
        id: 'd-sub2',
        zoneId: 'sub-2',
        zoneName: 'Sub 2',
        name: 'Camera S2',
        serialNumber: 'SN-02',
        hardwareTypeName: 'CCTV Camera',
        status: DeviceStatus.faulty,
      );

      // Section for Zone 1 containing Sub 1 and Sub 2
      final zone1Section = TechnicianTopLevelZoneItem(
        zone: parentZone,
        directDevices: const [],
        subzones: [
          TechnicianSubzoneItem(
            zone: sub1,
            devices: const [devSub1],
          ),
          TechnicianSubzoneItem(
            zone: sub2,
            devices: const [devSub2],
          ),
        ],
      );

      // Simulate a list of top-level sections
      final sections = [zone1Section];

      await tester.pumpWidget(
        _localized(
          ListView.builder(
            itemCount: sections.length,
            itemBuilder: (context, index) => TechnicianTopLevelZoneCard(
              zoneItem: sections[index],
            ),
          ),
        ),
      );

      // Verify single Big Card header for ZONE 1
      expect(find.text('ZONE 1'), findsOneWidget);

      // Verify subzone count in stats
      expect(find.text('2 subzones'), findsOneWidget);

      // Verify nested small cards for Sub 1 and Sub 2 are both present inside
      expect(find.text('Sub 1'), findsOneWidget);
      expect(find.text('Sub 2'), findsOneWidget);

      // Verify device blocks exist inside the nested cards
      expect(find.byType(TechnicianDeviceBlock), findsNWidgets(2));

      // Verify exactly ONE TechnicianTopLevelZoneCard exists (no duplicate standalone Big Cards for Sub 1 or Sub 2)
      expect(find.byType(TechnicianTopLevelZoneCard), findsOneWidget);
    });

    test('rootsToProcess suppresses child subzones when parent zone is present', () {
      const parentZone = TechnicianZoneNode(
        id: 'zone-1',
        name: 'Zone 1',
        parentZoneId: null,
      );

      const sub1 = TechnicianZoneNode(
        id: 'sub-1',
        name: 'Sub 1',
        parentZoneId: 'zone-1',
      );

      const sub2 = TechnicianZoneNode(
        id: 'sub-2',
        name: 'Sub 2',
        parentZoneId: 'zone-1',
      );

      final allZones = [parentZone, sub1, sub2];
      final loadedZoneIds = allZones.map((z) => z.id).toSet();

      // Track all zone IDs that are children of another loaded zone
      final childZoneIds = <String>{};
      for (final z in allZones) {
        if (z.parentZoneId != null &&
            z.parentZoneId!.isNotEmpty &&
            loadedZoneIds.contains(z.parentZoneId)) {
          childZoneIds.add(z.id);
        }
      }

      final rootsToProcess = allZones.where((z) => !childZoneIds.contains(z.id)).toList();

      // Only Zone 1 should be a root; Sub 1 and Sub 2 are suppressed from roots
      expect(rootsToProcess.length, 1);
      expect(rootsToProcess.first.id, 'zone-1');
      expect(childZoneIds, containsAll(['sub-1', 'sub-2']));
    });

    test('All 6 issues across 4 parent zones correctly map to their respective zone sections', () {
      // 4 parent zones
      const rootTiger = TechnicianZoneNode(id: 'root-tiger', name: 'Tiger Retiring room');
      const rootAdmin = TechnicianZoneNode(id: 'root-admin', name: 'Admin Block');
      const rootHerb = TechnicianZoneNode(id: 'root-herb', name: 'Herbivore Retiring Room');
      const rootHosp = TechnicianZoneNode(id: 'root-hosp', name: 'Hospital');

      // 4 subzones
      const subBehind = TechnicianZoneNode(id: 'sub-behind', name: 'Behind of Retiring room', parentZoneId: 'root-tiger');
      const subForester = TechnicianZoneNode(id: 'sub-forester', name: 'Forester Zone', parentZoneId: 'root-admin');
      const subBlockC = TechnicianZoneNode(id: 'sub-blockc', name: 'Block-C', parentZoneId: 'root-herb');
      const subGallery = TechnicianZoneNode(id: 'sub-gallery', name: 'Right Side Gallery', parentZoneId: 'root-hosp');

      // 4 devices
      const devTiger = DeviceModel(id: 'dev-1', zoneId: 'sub-behind', zoneName: 'Behind of Retiring room', name: 'PTZ Camera', hardwareTypeName: 'CCTV Camera');
      const devAdmin = DeviceModel(id: 'dev-2', zoneId: 'sub-forester', zoneName: 'Forester Zone', name: 'Dome Camera', hardwareTypeName: 'CCTV Camera');
      const devHerb = DeviceModel(id: 'dev-3', zoneId: 'sub-blockc', zoneName: 'Block-C', name: 'Dome Camera', hardwareTypeName: 'CCTV Camera');
      const devHosp = DeviceModel(id: 'dev-4', zoneId: 'sub-gallery', zoneName: 'Right Side Gallery', name: 'Dome Camera', hardwareTypeName: 'CCTV Camera');

      // 6 issues (3 on Tiger, 1 on Admin, 1 on Herbivore, 1 on Hospital)
      final allIssues = [
        IssueModel(id: 'iss-1', title: 'Issue 1', description: '', deviceId: 'dev-1', deviceName: 'PTZ', zoneId: 'sub-behind', zoneName: '', categoryId: '', categoryName: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), createdByUserId: 'u', createdByUserName: 'U'),
        IssueModel(id: 'iss-2', title: 'Issue 2', description: '', deviceId: 'dev-1', deviceName: 'PTZ', zoneId: 'sub-behind', zoneName: '', categoryId: '', categoryName: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), createdByUserId: 'u', createdByUserName: 'U'),
        IssueModel(id: 'iss-3', title: 'Issue 3', description: '', deviceId: 'dev-1', deviceName: 'PTZ', zoneId: 'sub-behind', zoneName: '', categoryId: '', categoryName: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), createdByUserId: 'u', createdByUserName: 'U'),
        IssueModel(id: 'iss-4', title: 'Issue 4', description: '', deviceId: 'dev-2', deviceName: 'Dome', zoneId: 'sub-forester', zoneName: '', categoryId: '', categoryName: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), createdByUserId: 'u', createdByUserName: 'U'),
        IssueModel(id: 'iss-5', title: 'Issue 5', description: '', deviceId: 'dev-3', deviceName: 'Dome', zoneId: 'sub-blockc', zoneName: '', categoryId: '', categoryName: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), createdByUserId: 'u', createdByUserName: 'U'),
        IssueModel(id: 'iss-6', title: 'Issue 6', description: '', deviceId: 'dev-4', deviceName: 'Dome', zoneId: 'sub-gallery', zoneName: '', categoryId: '', categoryName: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), createdByUserId: 'u', createdByUserName: 'U'),
      ];

      final roots = [rootTiger, rootAdmin, rootHerb, rootHosp];
      final allZones = [rootTiger, rootAdmin, rootHerb, rootHosp, subBehind, subForester, subBlockC, subGallery];
      final allDevices = [devTiger, devAdmin, devHerb, devHosp];

      final sections = <TechnicianTopLevelZoneItem>[];
      for (final root in roots) {
        final subzones = allZones.where((z) => z.parentZoneId == root.id).toList();
        final subzoneIds = subzones.map((s) => s.id).toSet();

        final subzoneItems = subzones.map((sz) {
          final szDevices = allDevices.where((d) => d.zoneId == sz.id).toList();
          final szDeviceIds = szDevices.map((d) => d.id).toSet();
          final szIssues = allIssues.where((iss) => iss.zoneId == sz.id || szDeviceIds.contains(iss.deviceId)).toList();
          return TechnicianSubzoneItem(zone: sz, devices: szDevices, issues: szIssues);
        }).toList();

        final allRootDeviceIds = {
          for (final sz in subzoneItems) ...sz.devices.map((d) => d.id),
        };

        final rootIssues = allIssues.where((iss) =>
          iss.zoneId == root.id || subzoneIds.contains(iss.zoneId) || allRootDeviceIds.contains(iss.deviceId)
        ).toList();

        sections.add(TechnicianTopLevelZoneItem(
          zone: root,
          subzones: subzoneItems,
          issues: rootIssues,
        ));
      }

      // Assert that all 4 sections have active issues
      expect(sections.length, 4);
      for (final sec in sections) {
        expect(sec.hasIssues, isTrue, reason: '${sec.zone.name} should have issues');
      }

      // Assert issue distribution: Tiger has 3, the others have 1 each
      expect(sections.firstWhere((s) => s.zone.id == 'root-tiger').issues.length, 3);
      expect(sections.firstWhere((s) => s.zone.id == 'root-admin').issues.length, 1);
      expect(sections.firstWhere((s) => s.zone.id == 'root-herb').issues.length, 1);
      expect(sections.firstWhere((s) => s.zone.id == 'root-hosp').issues.length, 1);
    });
  });
}

class _FakeStorageService extends Fake implements StorageService {
  @override
  String? getBaseUrl() => 'https://mock.api';
  @override
  String? getAccessToken() => 'fake-token';
  @override
  String? getRefreshToken() => 'fake-refresh';
}


