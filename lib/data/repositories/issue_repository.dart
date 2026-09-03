import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/hardware_type_model.dart';
import '../models/issue_model.dart';

class IssueRepository {
  final ApiClient apiClient;

  IssueRepository({required this.apiClient});

  /// Fetches issues with optional zone scoping, status, priority, and search filters.
  Future<List<IssueModel>> getIssues({
    String? zoneId,
    bool includeSubzones = true,
    String? status,
    String? priority,
    String? search,
    String? scope,
    String? assignedTechnicianId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (includeSubzones) 'includeSubzones': 'true',
        if (zoneId != null && zoneId.isNotEmpty) 'zoneId': zoneId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (priority != null && priority.isNotEmpty) 'priority': priority,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (scope != null && scope.isNotEmpty) 'scope': scope,
        if (assignedTechnicianId != null && assignedTechnicianId.isNotEmpty)
          'assignedTechnicianId': assignedTechnicianId,
      };

      AppLogger.d('📡 [IssueRepository] GET /issues with params: $queryParams');

      final response = await apiClient.dio.get(
        '/issues',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];

        final issues = items
            .map((e) => IssueModel.fromJson(e as Map<String, dynamic>))
            .toList();

        AppLogger.i('🎫 [IssueRepository] Fetched ${issues.length} issues successfully');
        return issues;
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to load issues';
        AppLogger.w('⚠️ [IssueRepository] Error response: $msg');
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error fetching issues';
      AppLogger.e('❌ [IssueRepository] DioException: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [IssueRepository] Unexpected error in getIssues: $e', e, st);
      throw Exception('Failed to load issues: $e');
    }
  }

  /// Fetches issue details.
  Future<IssueModel> getIssueById(String issueId) async {
    try {
      AppLogger.d('📡 [IssueRepository] GET /issues/$issueId');

      final response = await apiClient.dio.get('/issues/$issueId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return IssueModel.fromJson(data);
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to load issue detail';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error';
      AppLogger.e('❌ [IssueRepository] DioException in getIssueById: $message', e);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to load issue: $e');
    }
  }

  /// Fetches chronological status timeline history for an issue.
  Future<List<IssueStatusHistoryModel>> getIssueHistory(String issueId) async {
    try {
      AppLogger.d('📡 [IssueRepository] GET /issues/$issueId/history');

      final response = await apiClient.dio.get('/issues/$issueId/history');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> items = data is List
            ? data
            : (data is Map<String, dynamic> ? (data['items'] as List<dynamic>? ?? []) : []);

        final historyList = items
            .map((e) => IssueStatusHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList();

        AppLogger.i('📜 [IssueRepository] Fetched ${historyList.length} timeline events for issue $issueId');
        return historyList;
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to load issue history';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error';
      AppLogger.e('❌ [IssueRepository] DioException in getIssueHistory: $message', e);
      return [];
    } catch (e) {
      AppLogger.w('⚠️ [IssueRepository] Error fetching history: $e');
      return [];
    }
  }

  /// Creates a new maintenance issue ticket.
  Future<IssueModel> createIssue({
    required String deviceId,
    required String categoryId,
    required IssuePriority priority,
    required String description,
  }) async {
    try {
      final payload = {
        'deviceId': deviceId,
        'categoryId': categoryId,
        'priority': priority.value,
        'description': description.trim(),
      };

      AppLogger.d('📡 [IssueRepository] POST /issues with: $payload');

      final response = await apiClient.dio.post(
        '/issues',
        data: payload,
      );

      if (response.statusCode == 201 || (response.statusCode == 200 && response.data['success'] == true)) {
        final data = response.data['data'] as Map<String, dynamic>;
        final newIssue = IssueModel.fromJson(data);
        AppLogger.i('🚨 [IssueRepository] Issue created successfully: ${newIssue.id}');
        return newIssue;
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to raise issue';
        AppLogger.w('⚠️ [IssueRepository] Error: $msg');
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error creating issue';
      AppLogger.e('❌ [IssueRepository] DioException in createIssue: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [IssueRepository] Error creating issue: $e', e, st);
      throw Exception('Failed to raise issue: $e');
    }
  }

  /// Fetches issue categories for a given hardware type.
  Future<List<IssueCategoryModel>> getCategoriesForHardwareType(String? hardwareTypeId) async {
    try {
      if (hardwareTypeId == null || hardwareTypeId.isEmpty) {
        // Fetch all hardware types and collect categories
        final response = await apiClient.dio.get('/hardware-types');
        if (response.statusCode == 200 && response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          final items = (data['items'] as List<dynamic>?) ?? [];
          final allCats = <IssueCategoryModel>[];
          for (final h in items) {
            final hw = HardwareTypeModel.fromJson(h as Map<String, dynamic>);
            allCats.addAll(hw.issueCategories);
          }
          return allCats;
        }
        return [];
      }

      final response = await apiClient.dio.get('/hardware-types/$hardwareTypeId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final hw = HardwareTypeModel.fromJson(data);
        return hw.issueCategories;
      }
      return [];
    } on DioException catch (e) {
      AppLogger.w('⚠️ [IssueRepository] Could not fetch categories: ${e.message}');
      return [];
    } catch (e) {
      AppLogger.w('⚠️ [IssueRepository] Error parsing categories: $e');
      return [];
    }
  }

  /// Updates the status of an issue (e.g. assigned -> in_progress -> on_hold -> resolved -> closed).
  Future<IssueModel> updateIssueStatus({
    required String issueId,
    required IssueStatus toStatus,
    String? notes,
  }) async {
    try {
      final payload = {
        'status': toStatus.value,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      AppLogger.d('📡 [IssueRepository] PATCH /issues/$issueId/status with: $payload');

      final response = await apiClient.dio.patch(
        '/issues/$issueId/status',
        data: payload,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final updatedIssue = IssueModel.fromJson(data);
        AppLogger.i('✅ [IssueRepository] Issue $issueId status changed to ${toStatus.label}');
        return updatedIssue;
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to update issue status';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error';
      AppLogger.e('❌ [IssueRepository] DioException in updateIssueStatus: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [IssueRepository] Error updating issue status: $e', e, st);
      throw Exception('Failed to update status: $e');
    }
  }
}
