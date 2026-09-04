import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../devices/devices.dart';
import '../../../core/utils/app_logger.dart';
import '../models/issue_model.dart';
import 'issue_query_viewmodel.dart';

/// State for issue mutation operations (e.g. creating, updating status).
class IssueActionState {
  final bool isLoading;
  final String? errorMessage;
  final IssueModel? lastUpdatedIssue;

  const IssueActionState({
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdatedIssue,
  });

  IssueActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    IssueModel? lastUpdatedIssue,
  }) {
    return IssueActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastUpdatedIssue: lastUpdatedIssue ?? this.lastUpdatedIssue,
    );
  }
}

class IssueActionController extends Notifier<IssueActionState> {
  @override
  IssueActionState build() {
    return const IssueActionState();
  }

  /// Creates a new maintenance ticket and refreshes relevant providers.
  Future<IssueModel?> createIssue({
    required String deviceId,
    required String categoryId,
    required IssuePriority priority,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(issueRepositoryProvider);
      final newIssue = await repo.createIssue(
        deviceId: deviceId,
        categoryId: categoryId,
        priority: priority,
        description: description,
      );

      // Invalidate issue queues so UI reflects the new defect immediately
      ref.invalidate(staffIssuesProvider);
      ref.invalidate(technicianIssuesProvider);

      state = state.copyWith(isLoading: false, lastUpdatedIssue: newIssue);
      return newIssue;
    } catch (e, st) {
      AppLogger.e('❌ [IssueActionController] Failed to create issue: $e', e, st);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return null;
    }
  }

  /// Creates multiple maintenance tickets in bulk and refreshes relevant providers.
  Future<List<IssueModel>?> createBulkIssues({
    required List<String> deviceIds,
    required String categoryId,
    required IssuePriority priority,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(issueRepositoryProvider);
      final newIssues = await repo.createBulkIssues(
        deviceIds: deviceIds,
        categoryId: categoryId,
        priority: priority,
        description: description,
      );

      // Invalidate issue queues so UI reflects the new defects immediately
      ref.invalidate(staffIssuesProvider);
      ref.invalidate(technicianIssuesProvider);

      state = state.copyWith(
        isLoading: false,
        lastUpdatedIssue: newIssues.isNotEmpty ? newIssues.first : null,
      );
      return newIssues;
    } catch (e, st) {
      AppLogger.e('❌ [IssueActionController] Failed to create bulk issues: $e', e, st);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return null;
    }
  }

  /// Transitions status for multiple issues simultaneously and refreshes relevant providers.
  Future<({List<IssueModel> updated, List<Map<String, dynamic>> errors})?> bulkUpdateStatus({
    required List<String> issueIds,
    required IssueStatus status,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(issueRepositoryProvider);
      final result = await repo.bulkUpdateStatus(
        issueIds: issueIds,
        status: status,
        notes: notes,
      );

      // Invalidate relevant providers to update all views
      ref.invalidate(staffIssuesProvider);
      ref.invalidate(technicianIssuesProvider);
      ref.invalidate(staffDevicesProvider);
      ref.invalidate(staffDashboardSummaryProvider);

      state = state.copyWith(
        isLoading: false,
        lastUpdatedIssue: result.updated.isNotEmpty ? result.updated.first : null,
      );
      return result;
    } catch (e, st) {
      AppLogger.e('❌ [IssueActionController] Failed to bulk update status: $e', e, st);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return null;
    }
  }

  /// Transitions issue status (e.g., open -> in_progress -> on_hold -> resolved -> closed).
  Future<IssueModel?> updateStatus({
    required String issueId,
    required IssueStatus toStatus,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(issueRepositoryProvider);
      final updatedIssue = await repo.updateIssueStatus(
        issueId: issueId,
        toStatus: toStatus,
        notes: notes,
      );

      // Invalidate queues, single detail, device inventory, and history timeline
      ref.invalidate(staffIssuesProvider);
      ref.invalidate(technicianIssuesProvider);
      ref.invalidate(issueDetailProvider(issueId));
      ref.invalidate(issueHistoryProvider(issueId));
      ref.invalidate(staffDevicesProvider);
      ref.invalidate(staffDashboardSummaryProvider);

      state = state.copyWith(isLoading: false, lastUpdatedIssue: updatedIssue);
      return updatedIssue;
    } catch (e, st) {
      AppLogger.e('❌ [IssueActionController] Failed to update status: $e', e, st);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final issueActionControllerProvider =
    NotifierProvider<IssueActionController, IssueActionState>(IssueActionController.new);

