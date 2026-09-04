/// Explicit state modeling for the Staff Daily Checklist tab.
class StaffChecklistState {
  final Set<String> submittingDeviceLogIds;
  final Set<String> editingDeviceLogIds;
  final Map<String, String> draftNotes;
  final int filterIndex; // 0: All, 1: Pending, 2: Checked Today
  final String? errorMessage;

  const StaffChecklistState({
    this.submittingDeviceLogIds = const {},
    this.editingDeviceLogIds = const {},
    this.draftNotes = const {},
    this.filterIndex = 0,
    this.errorMessage,
  });

  bool isSubmitting(String deviceId) => submittingDeviceLogIds.contains(deviceId);
  bool isEditing(String deviceId) => editingDeviceLogIds.contains(deviceId);
  String getDraftNote(String deviceId) => draftNotes[deviceId] ?? '';

  StaffChecklistState copyWith({
    Set<String>? submittingDeviceLogIds,
    Set<String>? editingDeviceLogIds,
    Map<String, String>? draftNotes,
    int? filterIndex,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StaffChecklistState(
      submittingDeviceLogIds: submittingDeviceLogIds ?? this.submittingDeviceLogIds,
      editingDeviceLogIds: editingDeviceLogIds ?? this.editingDeviceLogIds,
      draftNotes: draftNotes ?? this.draftNotes,
      filterIndex: filterIndex ?? this.filterIndex,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
