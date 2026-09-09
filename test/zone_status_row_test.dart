import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equipment_management_system/features/technician/technician.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';

void main() {
  group('Technician ZoneStatusRow Unit & Aggregation Tests', () {
    test('1. overallStatus reads online unless hardware > 0 and online == 0', () {
      // Normal online zone with mixed statuses (matches mock row 4)
      const normalZone = ZoneStatusRow(
        id: 'z-1',
        name: 'Tiger Safari',
        hardwareCount: 52,
        onlineCount: 48,
        offlineCount: 2,
        maintenanceCount: 2,
      );
      expect(normalZone.overallStatus, ZoneOverallStatus.online);
      expect(normalZone.overallStatus.isOnline, isTrue);
      expect(normalZone.overallStatus.isOffline, isFalse);

      // Total failure zone: has hardware but 0 are online
      const downZone = ZoneStatusRow(
        id: 'z-2',
        name: 'Dark Cave',
        hardwareCount: 10,
        onlineCount: 0,
        offlineCount: 8,
        maintenanceCount: 2,
      );
      expect(downZone.overallStatus, ZoneOverallStatus.offline);
      expect(downZone.overallStatus.isOffline, isTrue);

      // Empty zone with 0 hardware
      const emptyZone = ZoneStatusRow(
        id: 'z-3',
        name: 'Future Expansion',
        hardwareCount: 0,
        onlineCount: 0,
      );
      expect(emptyZone.overallStatus, ZoneOverallStatus.online);
    });

    test('2. fromBreakdown accurately aggregates counts across sub-zones', () {
      final sampleBreakdown = {
        'z-root': {
          'total': 20,
          'working': 18,
          'faulty': 1,
          'underMaintenance': 1,
        },
        'z-sub-1': {
          'total': 15,
          'working': 14,
          'faulty': 1,
          'underMaintenance': 0,
        },
        'z-sub-2': {
          'total': 17,
          'working': 16,
          'faulty': 0,
          'underMaintenance': 1,
        },
      };

      final row = ZoneStatusRow.fromBreakdown(
        id: 'z-root',
        name: 'Entry / Exit',
        imageUrl: 'https://res.cloudinary.com/demo/image/upload/entry.jpg',
        breakdownMap: sampleBreakdown,
      );

      expect(row.id, 'z-root');
      expect(row.name, 'Entry / Exit');
      expect(row.imageUrl, 'https://res.cloudinary.com/demo/image/upload/entry.jpg');
      expect(row.hardwareCount, 52); // 20 + 15 + 17
      expect(row.onlineCount, 48);   // 18 + 14 + 16
      expect(row.offlineCount, 2);   // 1 + 1 + 0
      expect(row.maintenanceCount, 2); // 1 + 0 + 1
      expect(row.overallStatus, ZoneOverallStatus.online);
      expect(row.dataLoadFailed, isFalse);
    });

    test('2b. displayName formats zone names in Title Case (first letter capitalized, rest small)', () {
      const rowUpper = ZoneStatusRow(id: '1', name: 'TIGER ZONE');
      expect(rowUpper.displayName, 'Tiger Zone');

      const rowLower = ZoneStatusRow(id: '2', name: 'primate sanctuary');
      expect(rowLower.displayName, 'Primate Sanctuary');

      const rowSlash = ZoneStatusRow(id: '3', name: 'ENTRY / EXIT');
      expect(rowSlash.displayName, 'Entry / Exit');

      const rowHyphen = ZoneStatusRow(id: '4', name: 'NORTH-WEST WING');
      expect(rowHyphen.displayName, 'North-West Wing');

      const rowMixed = ZoneStatusRow(id: '5', name: 'vIsItOr ArEa');
      expect(rowMixed.displayName, 'Visitor Area');
    });

    test('3. Localization keys parity between English and Hindi', () async {
      final en = lookupAppLocalizations(const Locale('en'));
      final hi = lookupAppLocalizations(const Locale('hi'));

      expect(en.techViewStatus, 'Zone Status');
      expect(hi.techViewStatus, 'ज़ोन स्थिति');

      expect(en.zoneStatusTitle, 'Zone Status');
      expect(hi.zoneStatusTitle, 'ज़ोन स्थिति');

      expect(en.zoneStatusColZone, 'Zone / Area');
      expect(hi.zoneStatusColZone, 'ज़ोन / क्षेत्र');

      expect(en.zoneStatusColHardware, 'Total');
      expect(hi.zoneStatusColHardware, 'कुल');

      expect(en.zoneStatusColOnline, 'Online');
      expect(hi.zoneStatusColOnline, 'चालू');

      expect(en.zoneStatusColOffline, 'Offline');
      expect(hi.zoneStatusColOffline, 'बंद');

      expect(en.zoneStatusColMaint, 'Maint.');
      expect(hi.zoneStatusColMaint, 'मरम्मत');

      expect(en.zoneStatusColStatus, 'Status');
      expect(hi.zoneStatusColStatus, 'स्थिति');

      expect(en.zoneStatusOnline, 'Online');
      expect(hi.zoneStatusOnline, 'चालू');

      expect(en.zoneStatusOffline, 'Offline');
      expect(hi.zoneStatusOffline, 'बंद');

      expect(en.zoneStatusEmpty, 'No zones assigned');
      expect(hi.zoneStatusEmpty, 'कोई ज़ोन असाइन नहीं');

      expect(en.zoneStatusLoadFailed, "Couldn't load zone status");
      expect(hi.zoneStatusLoadFailed, 'ज़ोन स्थिति लोड नहीं हो सकी');
    });

    testWidgets('4. TechnicianZoneStatusView renders table headers, rows, and counts', (tester) async {
      final testRows = [
        const ZoneStatusRow(
          id: 'z-1',
          name: 'Entry / Exit',
          hardwareCount: 36,
          onlineCount: 33,
          offlineCount: 2,
          maintenanceCount: 1,
        ),
        const ZoneStatusRow(
          id: 'z-2',
          name: 'Visitor Area',
          hardwareCount: 54,
          onlineCount: 50,
          offlineCount: 3,
          maintenanceCount: 1,
        ),
        const ZoneStatusRow(
          id: 'z-3',
          name: 'Power Substation',
          hardwareCount: 8,
          onlineCount: 0,
          offlineCount: 8,
          maintenanceCount: 0,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            technicianZoneStatusViewModelProvider.overrideWith(
              () => _FakeZoneStatusViewModel(testRows),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TechnicianZoneStatusView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title and count
      expect(find.text('Zone Status'), findsWidgets); // Header title & column header
      expect(find.text('3'), findsNWidgets(3)); // Count pill (3), row 2 offline (3), and row 3 index (3)

      // Check table column headers
      expect(find.text('#'), findsOneWidget);
      expect(find.text('Zone / Area'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Maint.'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);

      // Check row items
      expect(find.text('Entry / Exit'), findsOneWidget);
      expect(find.text('36'), findsOneWidget);
      expect(find.text('33'), findsOneWidget);

      expect(find.text('Visitor Area'), findsOneWidget);
      expect(find.text('54'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);

      expect(find.text('Power Substation'), findsOneWidget);

      // 'Online' appears 3 times: 1 header + 2 row status indicators
      expect(find.text('Online'), findsNWidgets(3));
      // 'Offline' appears 2 times: 1 header + 1 row status indicator
      expect(find.text('Offline'), findsNWidgets(2));
    });

    testWidgets('5. TechnicianZoneStatusView renders without overflow on compact mobile viewport (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRows = [
        const ZoneStatusRow(
          id: 'z-1',
          name: 'Entry / Exit',
          hardwareCount: 36,
          onlineCount: 33,
          offlineCount: 2,
          maintenanceCount: 1,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            technicianZoneStatusViewModelProvider.overrideWith(
              () => _FakeZoneStatusViewModel(testRows),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TechnicianZoneStatusView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Entry / Exit'), findsOneWidget);
    });
  });
}

class _FakeZoneStatusViewModel extends TechnicianZoneStatusViewModel {
  final List<ZoneStatusRow> rows;

  _FakeZoneStatusViewModel(this.rows);

  @override
  Future<List<ZoneStatusRow>> build() async => rows;
}
