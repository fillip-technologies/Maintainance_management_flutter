import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/issue_model.dart';
import 'issue_providers.dart';

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

      // Invalidate queues, single detail, and history timeline
      ref.invalidate(staffIssuesProvider);
      ref.invalidate(technicianIssuesProvider);
      ref.invalidate(issueDetailProvider(issueId));
      ref.invalidate(issueHistoryProvider(issueId));

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

