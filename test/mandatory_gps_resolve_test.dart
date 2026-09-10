import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';
import 'package:equipment_management_system/features/issues/views/update_status_sheet.dart';
import 'package:equipment_management_system/features/location/location_helper.dart';

class TestLocationHelper extends LocationHelper {
  final LocationResult result;
  bool openSettingsCalled = false;

  TestLocationHelper(this.result);

  @override
  Future<LocationResult> getLocation() async => result;

  @override
  Future<bool> openLocationSettings() async {
    openSettingsCalled = true;
    return true;
  }
}

void main() {
  final testIssue = IssueModel(
    id: 'iss-test-12345678',
    title: 'Motor Overheating',
    description: 'Motor overheating on conveyor belt',
    deviceId: 'dev-1',
    deviceName: 'Conveyor Alpha',
    zoneId: 'zone-1',
    zoneName: 'Assembly Line 1',
    categoryId: 'cat-1',
    categoryName: 'Overheating',
    createdByUserId: 'user-1',
    createdByUserName: 'John Doe',
    status: IssueStatus.inProgress,
    priority: IssuePriority.high,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  testWidgets('UpdateStatusSheet blocks submission and shows warning when resolving without GPS', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockLocation = TestLocationHelper(
      const LocationResult.failure(
        LocationErrorType.serviceDisabled,
        'Location (GPS) is turned off on this device.',
      ),
    );

    bool submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateStatusSheet(
            issue: testIssue,
            initialTargetStatus: IssueStatus.resolved,
            locationHelper: mockLocation,
            onStatusUpdated: (status, comment, photo, [lat, lng]) async {
              submitted = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify warning is displayed
    expect(find.text('GPS Location Required to Resolve'), findsOneWidget);
    expect(find.text('Open GPS Settings'), findsOneWidget);
    expect(find.text('Resolve Ticket (Turn On GPS)'), findsOneWidget);

    // Tap submit button
    await tester.ensureVisible(find.text('Resolve Ticket (Turn On GPS)'));
    await tester.tap(find.text('Resolve Ticket (Turn On GPS)'));
    await tester.pumpAndSettle();

    // Verify submission was blocked and settings was opened
    expect(submitted, isFalse);
    expect(mockLocation.openSettingsCalled, isTrue);
  });

  testWidgets('UpdateStatusSheet succeeds and passes coordinates when resolving with valid GPS', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockLocation = TestLocationHelper(
      const LocationResult.success(28.6139, 77.2090),
    );

    bool submitted = false;
    double? passedLat;
    double? passedLng;
    IssueStatus? passedStatus;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateStatusSheet(
            issue: testIssue,
            initialTargetStatus: IssueStatus.resolved,
            locationHelper: mockLocation,
            onStatusUpdated: (status, comment, photo, [lat, lng]) async {
              submitted = true;
              passedStatus = status;
              passedLat = lat;
              passedLng = lng;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify GPS coordinates display and verified badge
    expect(find.textContaining('GPS: 28.61390, 77.20900'), findsOneWidget);
    expect(find.text('Required ✓'), findsOneWidget);
    expect(find.text('Confirm & Transition to Resolved'), findsOneWidget);

    // Tap confirm button
    await tester.ensureVisible(find.text('Confirm & Transition to Resolved'));
    await tester.tap(find.text('Confirm & Transition to Resolved'));
    await tester.pumpAndSettle();

    // Verify submission succeeded with coordinates
    expect(submitted, isTrue);
    expect(passedStatus, IssueStatus.resolved);
    expect(passedLat, 28.6139);
    expect(passedLng, 77.2090);
  });

  testWidgets('UpdateStatusSheet allows transition to onHold even without GPS', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockLocation = TestLocationHelper(
      const LocationResult.failure(
        LocationErrorType.serviceDisabled,
        'GPS disabled',
      ),
    );

    bool submitted = false;
    IssueStatus? passedStatus;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateStatusSheet(
            issue: testIssue,
            initialTargetStatus: IssueStatus.onHold,
            locationHelper: mockLocation,
            onStatusUpdated: (status, comment, photo, [lat, lng]) async {
              submitted = true;
              passedStatus = status;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify optional notice
    expect(find.textContaining('optional'), findsOneWidget);
    expect(find.text('Confirm & Transition to On Hold'), findsOneWidget);

    // Tap confirm button
    await tester.ensureVisible(find.text('Confirm & Transition to On Hold'));
    await tester.tap(find.text('Confirm & Transition to On Hold'));
    await tester.pumpAndSettle();

    // Verify submission succeeded for onHold
    expect(submitted, isTrue);
    expect(passedStatus, IssueStatus.onHold);
  });
}
