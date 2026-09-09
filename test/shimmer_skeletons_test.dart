import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equipment_management_system/core/theme/colors.dart';
import 'package:equipment_management_system/core/widgets/app_shimmer.dart';
import 'package:equipment_management_system/features/staff/models/staff_checklist_state.dart';
import 'package:equipment_management_system/features/staff/views/widgets/staff_daily_checklist_tab.dart';
import 'package:equipment_management_system/features/staff/views/widgets/staff_devices_directory_tab.dart';
import 'package:equipment_management_system/features/staff/views/widgets/staff_issues_tracker_tab.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget(Widget child, {bool isDark = false}) {
    AppColors.isDark = isDark;
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: child),
    );
  }

  group('Shimmer Skeletons Widget Tests', () {
    testWidgets('renders AppShimmer and ShimmerBox in light mode', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppShimmer(
            child: ShimmerBox(width: 100, height: 20),
          ),
          isDark: false,
        ),
      );
      expect(find.byType(AppShimmer), findsOneWidget);
      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('renders AppShimmer and ShimmerBox in dark mode', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppShimmer(
            child: ShimmerBox(width: 100, height: 20),
          ),
          isDark: true,
        ),
      );
      expect(find.byType(AppShimmer), findsOneWidget);
      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('EquipmentCategoryGridSkeleton renders grid items', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EquipmentCategoryGridSkeleton(itemCount: 4)),
      );
      expect(find.byType(EquipmentCategoryGridSkeleton), findsOneWidget);
      expect(find.byType(AppShimmer), findsOneWidget);
    });

    testWidgets('EquipmentListSkeleton renders list items', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EquipmentListSkeleton(itemCount: 3)),
      );
      expect(find.byType(EquipmentListSkeleton), findsOneWidget);
    });

    testWidgets('StaffChecklistSkeleton renders checklist placeholders', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const StaffChecklistSkeleton(itemCount: 3)),
      );
      expect(find.byType(StaffChecklistSkeleton), findsOneWidget);
    });

    testWidgets('IssuesListSkeleton renders issue placeholders', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const IssuesListSkeleton(itemCount: 3)),
      );
      expect(find.byType(IssuesListSkeleton), findsOneWidget);
    });

    testWidgets('ZoneTreeSkeleton and ZoneStatusTableSkeleton render', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const Column(
            children: [
              Expanded(child: ZoneTreeSkeleton()),
              Expanded(child: ZoneStatusTableSkeleton()),
            ],
          ),
        ),
      );
      expect(find.byType(ZoneTreeSkeleton), findsOneWidget);
      expect(find.byType(ZoneStatusTableSkeleton), findsOneWidget);
    });

    testWidgets('ProfileSkeleton renders avatar and sections', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ProfileSkeleton()),
      );
      expect(find.byType(ProfileSkeleton), findsOneWidget);
    });
  });

  group('Screen Loading State Integrations', () {
    testWidgets('StaffDevicesDirectoryTab renders EquipmentCategoryGridSkeleton when isLoading',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          StaffDevicesDirectoryTab(
            devices: const [],
            isLoading: true,
            hasError: false,
            onRefresh: () async {},
            onOpenRaiseIssue: (_) {},
          ),
        ),
      );
      expect(find.byType(EquipmentCategoryGridSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('StaffIssuesTrackerTab renders IssuesListSkeleton when isLoading',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          StaffIssuesTrackerTab(
            issues: const [],
            isLoading: true,
            hasError: false,
            onRefresh: () async {},
            onOpenIssueDetail: (_) {},
          ),
        ),
      );
      expect(find.byType(IssuesListSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('StaffDailyChecklistTab renders StaffChecklistSkeleton when isLoading',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          StaffDailyChecklistTab(
            allDevices: const [],
            todayLogsMap: const {},
            isLoading: true,
            hasError: false,
            checklistState: const StaffChecklistState(),
            onFilterChanged: (_) {},
            onNoteChanged: (_, _) {},
            onLogStatus: (_, _) {},
            onToggleEdit: (_, _) {},
            onCancelEdit: (_) {},
            onRefresh: () async {},
          ),
        ),
      );
      expect(find.byType(StaffChecklistSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
