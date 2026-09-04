import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
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

  /// Creates multiple maintenance issue tickets in bulk for several devices.
  Future<List<IssueModel>> createBulkIssues({
    required List<String> deviceIds,
    required String categoryId,
    required IssuePriority priority,
    required String description,
  }) async {
    try {
      final payload = {
        'deviceIds': deviceIds,
        'categoryId': categoryId,
        'priority': priority.value,
        'description': description.trim(),
      };

      AppLogger.d('📡 [IssueRepository] POST /issues/bulk with: $payload');

      final response = await apiClient.dio.post(
        '/issues/bulk',
        data: payload,
      );

      if (response.statusCode == 201 || (response.statusCode == 200 && response.data['success'] == true)) {
        final List<dynamic> dataList = response.data['data'] as List<dynamic>;
        final newIssues = dataList
            .map((item) => IssueModel.fromJson(item as Map<String, dynamic>))
            .toList();
        AppLogger.i('🚨 [IssueRepository] ${newIssues.length} bulk issues created successfully');
        return newIssues;
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to raise bulk issues';
        AppLogger.w('⚠️ [IssueRepository] Error: $msg');
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error creating bulk issues';
      AppLogger.e('❌ [IssueRepository] DioException in createBulkIssues: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [IssueRepository] Error creating bulk issues: $e', e, st);
      throw Exception('Failed to raise bulk issues: $e');
    }
  }

  /// Transitions status for multiple issues simultaneously via PATCH /issues/bulk-status.
  /// Returns a record with `updated` (`List<IssueModel>`) and `errors` (`List<Map<String, dynamic>>`).
  Future<({List<IssueModel> updated, List<Map<String, dynamic>> errors})> bulkUpdateStatus({
    required List<String> issueIds,
    required IssueStatus status,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'ids': issueIds,
        'status': status.value,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      AppLogger.d('📡 [IssueRepository] PATCH /issues/bulk-status with: $payload');

      final response = await apiClient.dio.patch(
        '/issues/bulk-status',
        data: payload,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final rawUpdated = data['updated'] as List<dynamic>? ?? [];
        final rawErrors = data['errors'] as List<dynamic>? ?? [];

        final updatedList = rawUpdated
            .map((item) => IssueModel.fromJson(item as Map<String, dynamic>))
            .toList();
        final errorsList = rawErrors
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        AppLogger.i('🚨 [IssueRepository] Bulk status updated: ${updatedList.length} success, ${errorsList.length} errors');
        return (updated: updatedList, errors: errorsList);
      } else {
        final msg = response.data['message'] as String? ?? 'Failed to bulk update issue status';
        AppLogger.w('⚠️ [IssueRepository] Bulk status error: $msg');
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? e.message ?? 'Network error updating bulk issues';
      AppLogger.e('❌ [IssueRepository] DioException in bulkUpdateStatus: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [IssueRepository] Error in bulkUpdateStatus: $e', e, st);
      throw Exception('Failed to bulk update status: $e');
    }
  }

  /// Fetches issue categories from the backend `/issue-categories` endpoint.
  /// If a [deviceId] is provided, returns global defect categories plus any categories
  /// specific to that device's product category.
  Future<List<IssueCategoryModel>> getCategoriesForHardwareType(
    String? hardwareTypeId, {
    String? deviceId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (deviceId != null && deviceId.isNotEmpty) {
        queryParams['deviceId'] = deviceId;
      }

      final response = await apiClient.dio.get(
        '/issue-categories',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        List<dynamic> items = [];
        if (data is Map<String, dynamic> && data['items'] is List) {
          items = data['items'] as List<dynamic>;
        } else if (data is List) {
          items = data;
        }

        return items
            .map((item) => IssueCategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
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

  /// Explicit helper to fetch defect categories for a specific device.
  Future<List<IssueCategoryModel>> getCategoriesForDevice(String deviceId) async {
    return getCategoriesForHardwareType(null, deviceId: deviceId);
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
      if (toStatus == IssueStatus.resolved && message.contains("Cannot move from 'open' to 'resolved'")) {
        AppLogger.w('⚠️ [IssueRepository] Auto-transitioning open -> in_progress before resolving issue $issueId');
        await apiClient.dio.patch('/issues/$issueId/status', data: {
          'status': 'in_progress',
          'notes': 'Auto-started work for hardware resolution',
        });
        return updateIssueStatus(issueId: issueId, toStatus: toStatus, notes: notes);
      }
      AppLogger.e('❌ [IssueRepository] DioException in updateIssueStatus: $message', e);
      throw Exception(message);
    } catch (e, st) {
      AppLogger.e('💥 [IssueRepository] Error updating issue status: $e', e, st);
      throw Exception('Failed to update status: $e');
    }
  }
}
