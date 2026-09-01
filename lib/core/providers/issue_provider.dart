import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/issue_model.dart';
import '../../data/repositories/issue_repository.dart';
import 'auth_provider.dart';

// 1. Issue Repository Provider
final issueRepositoryProvider = Provider<IssueRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return IssueRepository(apiClient: apiClient);
});

// 2. Staff Issues Provider (scoped to user's assigned zone tree)
final staffIssuesProvider = FutureProvider.autoDispose<List<IssueModel>>((ref) async {
  final authUser = ref.watch(authStateProvider).value;
  final issueRepo = ref.watch(issueRepositoryProvider);

  final zoneId = authUser?.assignedZoneId;
  return issueRepo.getIssues(
    zoneId: zoneId,
    includeSubzones: true,
  );
});

// 3. Technician Issues Provider (all assigned / open issues)
final technicianIssuesProvider = FutureProvider.autoDispose<List<IssueModel>>((ref) async {
  final issueRepo = ref.watch(issueRepositoryProvider);

  return issueRepo.getIssues(
    includeSubzones: true,
  );
});
