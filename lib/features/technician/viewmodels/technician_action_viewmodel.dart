import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../issues/issues.dart';

class TechnicianActionViewModel {
  final Ref _ref;

  TechnicianActionViewModel(this._ref);

  Future<void> updateStatus({
    required String issueId,
    required IssueStatus toStatus,
    String? notes,
  }) async {
    final issueRepo = _ref.read(issueRepositoryProvider);
    await issueRepo.updateIssueStatus(
      issueId: issueId,
      toStatus: toStatus,
      notes: notes,
    );

    _ref.invalidate(technicianIssuesProvider);
    _ref.invalidate(issueDetailProvider(issueId));
    _ref.invalidate(issueHistoryProvider(issueId));
  }

  void refreshQueue() {
    _ref.invalidate(technicianIssuesProvider);
  }
}

final technicianActionViewModelProvider = Provider<TechnicianActionViewModel>((ref) {
  return TechnicianActionViewModel(ref);
});
