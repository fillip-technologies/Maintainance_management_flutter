import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/issue_model.dart';
import '../../../data/repositories/issue_repository.dart';

/// 1. Issue Repository Provider
final issueRepositoryProvider = Provider<IssueRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return IssueRepository(apiClient: apiClient);
});

/// 2. Staff Issues Provider (scoped to user's assigned zone tree)
final staffIssuesProvider = FutureProvider.autoDispose<List<IssueModel>>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  final issueRepo = ref.watch(issueRepositoryProvider);

  final zoneId = authUser?.assignedZoneId;
  return issueRepo.getIssues(
    zoneId: zoneId,
    includeSubzones: true,
  );
});

/// 3. Technician Issues Provider (all organization issues / technician scope)
final technicianIssuesProvider = FutureProvider.autoDispose<List<IssueModel>>((ref) async {
  final issueRepo = ref.watch(issueRepositoryProvider);

  return issueRepo.getIssues(
    scope: 'technician',
    includeSubzones: true,
  );
});

/// 4. Dynamic Issue Detail Provider
final issueDetailProvider = FutureProvider.autoDispose.family<IssueModel, String>((ref, issueId) async {
  final issueRepo = ref.watch(issueRepositoryProvider);
  return issueRepo.getIssueById(issueId);
});

/// 5. Live Issue Status History Timeline Provider
final issueHistoryProvider = FutureProvider.autoDispose.family<List<IssueStatusHistoryModel>, String>((ref, issueId) async {
  final issueRepo = ref.watch(issueRepositoryProvider);
  return issueRepo.getIssueHistory(issueId);
});

/// 6. Dynamic Issue Categories Provider
final issueCategoriesProvider = FutureProvider.autoDispose.family<List<IssueCategoryModel>, String?>((ref, hardwareTypeId) async {
  final issueRepo = ref.watch(issueRepositoryProvider);
  return issueRepo.getCategoriesForHardwareType(hardwareTypeId);
});
