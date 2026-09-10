import 'package:flutter_test/flutter_test.dart';
import 'package:equipment_management_system/features/issues/controllers/bulk_resolve_controller.dart';
import 'package:equipment_management_system/features/issues/controllers/bulk_resolve_state.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';

void main() {
  group('BulkResolveController', () {
    late BulkResolveController controller;
    BulkResolveState? lastState;

    setUp(() {
      controller = BulkResolveController(
        onStateChanged: (s) => lastState = s,
      );
    });

    test('initial state defaults', () {
      expect(controller.state.selectedIssueIds, isEmpty);
      expect(controller.state.targetStatus, IssueStatus.resolved);
      expect(controller.state.selectedTypeFilter, 'all');
      expect(controller.state.searchQuery, '');
      expect(controller.state.isSubmitting, isFalse);
    });

    test('toggleIssue adds, removes, and respects max limit of 50', () {
      expect(controller.toggleIssue('issue-1'), isTrue);
      expect(lastState?.selectedIssueIds.contains('issue-1'), isTrue);
      expect(controller.state.selectedCount, 1);

      // Toggle off
      expect(controller.toggleIssue('issue-1'), isTrue);
      expect(lastState?.selectedIssueIds.contains('issue-1'), isFalse);
      expect(controller.state.selectedCount, 0);

      // Fill up to 50
      for (int i = 0; i < 50; i++) {
        expect(controller.toggleIssue('issue-$i'), isTrue);
      }
      expect(controller.state.selectedCount, 50);
      expect(controller.state.isMaxLimitReached, isTrue);

      // 51st issue should fail to add
      expect(controller.toggleIssue('issue-overflow'), isFalse);
      expect(controller.state.selectedCount, 50);
    });

    test('setTargetStatus updates target status', () {
      controller.setTargetStatus(IssueStatus.inProgress);
      expect(lastState?.targetStatus, IssueStatus.inProgress);
      expect(controller.state.targetStatus, IssueStatus.inProgress);
    });

    test('filterIssues filters by search and category type', () {
      final issues = [
        IssueModel(
          id: 'ISS-001',
          title: 'Lens cracked',
          description: 'Needs replacement',
          deviceId: 'dev-1',
          deviceName: 'CCTV Camera Alpha',
          zoneId: 'z-1',
          zoneName: 'Main Gate',
          categoryId: 'cat-1',
          categoryName: 'Surveillance',
          createdByUserId: 'u-1',
          createdByUserName: 'Admin',
          status: IssueStatus.open,
          priority: IssuePriority.high,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
        IssueModel(
          id: 'ISS-002',
          title: 'Gate jammed',
          description: 'Motor failure',
          deviceId: 'dev-2',
          deviceName: 'Turnstile Beta',
          zoneId: 'z-2',
          zoneName: 'Lobby',
          categoryId: 'cat-2',
          categoryName: 'Access Control',
          createdByUserId: 'u-1',
          createdByUserName: 'Admin',
          status: IssueStatus.inProgress,
          priority: IssuePriority.critical,
          createdAt: DateTime(2026, 9, 2),
          updatedAt: DateTime(2026, 9, 2),
        ),
      ];

      // Filter by type
      final filteredType = BulkResolveController.filterIssues(
        candidateIssues: issues,
        selectedTypeFilter: 'Surveillance',
        searchQuery: '',
      );
      expect(filteredType.length, 1);
      expect(filteredType.first.id, 'ISS-001');

      // Filter by search query
      final filteredQuery = BulkResolveController.filterIssues(
        candidateIssues: issues,
        selectedTypeFilter: 'all',
        searchQuery: 'Lobby',
      );
      expect(filteredQuery.length, 1);
      expect(filteredQuery.first.id, 'ISS-002');
    });

    test('groupIssues groups correctly by category/device', () {
      final issues = [
        IssueModel(
          id: 'ISS-001',
          title: 'T1',
          description: 'D1',
          deviceId: 'd1',
          deviceName: 'CCTV 1',
          zoneId: 'z1',
          zoneName: 'Z1',
          categoryId: 'c1',
          categoryName: 'Surveillance',
          createdByUserId: 'u1',
          createdByUserName: 'Admin',
          status: IssueStatus.open,
          priority: IssuePriority.low,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
        IssueModel(
          id: 'ISS-002',
          title: 'T2',
          description: 'D2',
          deviceId: 'd2',
          deviceName: 'CCTV 2',
          zoneId: 'z2',
          zoneName: 'Z2',
          categoryId: 'c1',
          categoryName: 'Surveillance',
          createdByUserId: 'u1',
          createdByUserName: 'Admin',
          status: IssueStatus.open,
          priority: IssuePriority.low,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
      ];

      final grouped = BulkResolveController.groupIssues(issues);
      expect(grouped.containsKey('Surveillance'), isTrue);
      expect(grouped['Surveillance']!.length, 2);
    });
  });
}
