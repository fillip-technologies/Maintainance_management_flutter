import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../daily_logs/daily_logs.dart';
import '../../devices/devices.dart';
import '../models/staff_checklist_state.dart';

class StaffChecklistNotifier extends Notifier<StaffChecklistState> {
  @override
  StaffChecklistState build() => const StaffChecklistState();

  void setFilterIndex(int index) {
    state = state.copyWith(filterIndex: index);
  }

  void startEditing(String deviceId, String? initialNote) {
    final updatedEditing = Set<String>.from(state.editingDeviceLogIds)..add(deviceId);
    final updatedDrafts = Map<String, String>.from(state.draftNotes);
    if (initialNote != null && initialNote.isNotEmpty) {
      updatedDrafts[deviceId] = initialNote;
    }
    state = state.copyWith(
      editingDeviceLogIds: updatedEditing,
      draftNotes: updatedDrafts,
    );
  }

  void cancelEditing(String deviceId) {
    final updatedEditing = Set<String>.from(state.editingDeviceLogIds)..remove(deviceId);
    state = state.copyWith(editingDeviceLogIds: updatedEditing);
  }

  void setDraftNote(String deviceId, String note) {
    final updatedDrafts = Map<String, String>.from(state.draftNotes)..[deviceId] = note;
    state = state.copyWith(draftNotes: updatedDrafts);
  }

  Future<void> submitStatus({
    required DeviceModel device,
    required DailyLogStatus status,
  }) async {
    final deviceId = device.id;
    final note = state.draftNotes[deviceId]?.trim();

    // Mark device as submitting
    final updatedSubmitting = Set<String>.from(state.submittingDeviceLogIds)..add(deviceId);
    state = state.copyWith(
      submittingDeviceLogIds: updatedSubmitting,
      clearError: true,
    );

    try {
      final repo = ref.read(dailyLogRepositoryProvider);
      await repo.createOrUpdateLog(
        deviceId: deviceId,
        status: status,
        notes: (note != null && note.isNotEmpty) ? note : null,
      );

      // Invalidate relevant queries
      ref.invalidate(todayLogsProvider);
      ref.invalidate(staffDevicesProvider);
      ref.invalidate(staffDashboardSummaryProvider);

      // Clean up editing & submitting state for this device
      final finalSubmitting = Set<String>.from(state.submittingDeviceLogIds)..remove(deviceId);
      final finalEditing = Set<String>.from(state.editingDeviceLogIds)..remove(deviceId);
      final finalDrafts = Map<String, String>.from(state.draftNotes)..remove(deviceId);

      state = state.copyWith(
        submittingDeviceLogIds: finalSubmitting,
        editingDeviceLogIds: finalEditing,
        draftNotes: finalDrafts,
      );
    } catch (e) {
      final finalSubmitting = Set<String>.from(state.submittingDeviceLogIds)..remove(deviceId);
      state = state.copyWith(
        submittingDeviceLogIds: finalSubmitting,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

final staffChecklistViewModelProvider =
    NotifierProvider<StaffChecklistNotifier, StaffChecklistState>(
  StaffChecklistNotifier.new,
);
