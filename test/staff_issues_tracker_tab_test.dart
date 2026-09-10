import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/features/issues/models/issue_model.dart';
import '../lib/features/staff/views/widgets/staff_issues_tracker_tab.dart';
import '../lib/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  final testIssues = <IssueModel>[
    IssueModel(
      id: 'i1',
      title: 'Camera 1 issue',
      description: 'Camera lens blurry',
      deviceId: 'd1',
      deviceName: 'Camera 1',
      zoneId: 'z1',
      zoneName: 'Entrance',
      categoryId: 'c1',
      categoryName: 'Hardware',
      createdByUserId: 'u1',
      createdByUserName: 'Staff User',
      status: IssueStatus.open,
      priority: IssuePriority.high,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    IssueModel(
      id: 'i2',
      title: 'Camera 2 issue',
      description: 'Power flicker',
      deviceId: 'd2',
      deviceName: 'Camera 2',
      zoneId: 'z1',
      zoneName: 'Entrance',
      categoryId: 'c1',
      categoryName: 'Hardware',
      createdByUserId: 'u1',
      createdByUserName: 'Staff User',
      status: IssueStatus.inProgress,
      priority: IssuePriority.medium,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    IssueModel(
      id: 'i3',
      title: 'Camera 3 issue',
      description: 'Wire reconnected',
      deviceId: 'd3',
      deviceName: 'Camera 3',
      zoneId: 'z1',
      zoneName: 'Entrance',
      categoryId: 'c1',
      categoryName: 'Hardware',
      createdByUserId: 'u1',
      createdByUserName: 'Staff User',
      status: IssueStatus.resolved,
      priority: IssuePriority.low,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    IssueModel(
      id: 'i4',
      title: 'Camera 4 issue',
      description: 'Replaced adapter',
      deviceId: 'd4',
      deviceName: 'Camera 4',
      zoneId: 'z1',
      zoneName: 'Entrance',
      categoryId: 'c1',
      categoryName: 'Hardware',
      createdByUserId: 'u1',
      createdByUserName: 'Staff User',
      status: IssueStatus.closed,
      priority: IssuePriority.low,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  testWidgets('renders Open, In Progress, and Done chips with correct counts and filtering',
      (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        StaffIssuesTrackerTab(
          issues: testIssues,
          isLoading: false,
          hasError: false,
          onRefresh: () async {},
          onOpenIssueDetail: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify filter chips exist with correct labels
    expect(find.text('Open (1)'), findsOneWidget);
    expect(find.text('In Progress (1)'), findsOneWidget);
    expect(find.text('Done (2)'), findsOneWidget);

    // Initial selected is Open (index 0) showing Camera 1
    expect(find.text('Camera 1 issue'), findsOneWidget);
    expect(find.text('Camera 2 issue'), findsNothing);
    expect(find.text('Camera 3 issue'), findsNothing);

    // Tap In Progress chip
    await tester.tap(find.text('In Progress (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Camera 1 issue'), findsNothing);
    expect(find.text('Camera 2 issue'), findsOneWidget);
    expect(find.text('Camera 3 issue'), findsNothing);

    // Tap Done chip (showing both resolved & closed)
    await tester.tap(find.text('Done (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Camera 1 issue'), findsNothing);
    expect(find.text('Camera 2 issue'), findsNothing);
    expect(find.text('Camera 3 issue'), findsOneWidget);
    expect(find.text('Camera 4 issue'), findsOneWidget);
  });
}
