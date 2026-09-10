import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:equipment_management_system/features/location/location_helper.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';
import 'update_status_state.dart';

typedef StatusUpdateCallback = Future<void> Function(
  IssueStatus newStatus,
  String comment,
  File? resolutionPhoto, [
  double? latitude,
  double? longitude,
]);

class UpdateStatusController {
  final IssueModel issue;
  final IssueStatus? initialTargetStatus;
  final LocationHelper locationHelper;
  final ImagePicker _picker;
  final void Function(UpdateStatusState state) onStateChanged;

  late UpdateStatusState _state;
  UpdateStatusState get state => _state;

  UpdateStatusController({
    required this.issue,
    this.initialTargetStatus,
    LocationHelper? locationHelper,
    ImagePicker? picker,
    required this.onStateChanged,
  })  : locationHelper = locationHelper ?? LocationHelper(),
        _picker = picker ?? ImagePicker() {
    final initialStatus = _resolveInitialStatus();
    _state = UpdateStatusState(
      selectedStatus: initialStatus,
      comment: _getDefaultComment(initialStatus),
    );
    fetchLocation();
  }

  void _update(UpdateStatusState newState) {
    _state = newState;
    onStateChanged(_state);
  }

  IssueStatus _resolveInitialStatus() {
    final allowed = getAllowedTransitions(issue.status);
    final requested = initialTargetStatus;
    if (requested != null && allowed.contains(requested)) {
      return requested;
    }
    final fallback = getDefaultNextStatus(issue.status);
    return allowed.contains(fallback) ? fallback : allowed.first;
  }

  static IssueStatus getDefaultNextStatus(IssueStatus current) {
    return switch (current) {
      IssueStatus.open || IssueStatus.assigned => IssueStatus.inProgress,
      IssueStatus.inProgress => IssueStatus.resolved,
      IssueStatus.onHold => IssueStatus.inProgress,
      IssueStatus.resolved => IssueStatus.closed,
      IssueStatus.closed || IssueStatus.reopened => IssueStatus.inProgress,
    };
  }

  static List<IssueStatus> getAllowedTransitions(IssueStatus current) {
    return switch (current) {
      IssueStatus.open || IssueStatus.assigned => [IssueStatus.inProgress, IssueStatus.onHold],
      IssueStatus.inProgress => [IssueStatus.resolved, IssueStatus.onHold],
      IssueStatus.onHold => [IssueStatus.inProgress],
      IssueStatus.resolved => [IssueStatus.closed, IssueStatus.reopened],
      IssueStatus.closed || IssueStatus.reopened => [IssueStatus.inProgress, IssueStatus.onHold],
    };
  }

  static String _getDefaultComment(IssueStatus status) {
    return switch (status) {
      IssueStatus.resolved => 'Repaired and tested equipment functionality.',
      IssueStatus.inProgress => 'Started diagnostic & on-site inspection.',
      IssueStatus.onHold => 'Waiting for replacement parts / access clearance.',
      _ => '',
    };
  }

  void setStatus(IssueStatus newStatus) {
    if (_state.selectedStatus == newStatus) return;
    _update(_state.copyWith(
      selectedStatus: newStatus,
      comment: _getDefaultComment(newStatus),
    ));
    if (newStatus == IssueStatus.resolved && !_state.hasValidGps) {
      fetchLocation();
    }
  }

  void setComment(String comment) {
    _update(_state.copyWith(comment: comment));
  }

  void clearImage() {
    _update(_state.copyWith(clearResolutionImage: true));
  }

  Future<void> fetchLocation() async {
    _update(_state.copyWith(isFetchingLocation: true));
    try {
      final res = await locationHelper.getLocation();
      _update(_state.copyWith(
        locationResult: res,
        isFetchingLocation: false,
      ));
    } catch (e) {
      _update(_state.copyWith(
        locationResult: LocationResult.failure(LocationErrorType.unknown, e.toString()),
        isFetchingLocation: false,
      ));
    }
  }

  Future<void> openLocationSettings() async {
    await locationHelper.openLocationSettings();
    fetchLocation();
  }

  Future<void> openAppSettings() async {
    await locationHelper.openAppSettings();
    fetchLocation();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      _update(_state.copyWith(isPickingImage: true));
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked != null) {
        _update(_state.copyWith(
          resolutionImage: File(picked.path),
          isPickingImage: false,
        ));
      } else {
        _update(_state.copyWith(isPickingImage: false));
      }
    } catch (e) {
      _update(_state.copyWith(
        isPickingImage: false,
        errorMessage: 'Failed to pick photo: $e',
      ));
    }
  }

  Future<bool> submit(StatusUpdateCallback onStatusUpdated) async {
    if (_state.isSubmitting) return false;

    _update(_state.copyWith(clearErrorMessage: true));

    // Mandatory GPS enforcement when resolving an issue
    if (_state.selectedStatus == IssueStatus.resolved) {
      if (!_state.hasValidGps) {
        _update(_state.copyWith(isFetchingLocation: true));
        final freshRes = await locationHelper.getLocation();
        _update(_state.copyWith(
          locationResult: freshRes,
          isFetchingLocation: false,
        ));

        if (!freshRes.isSuccess) {
          final explanation =
              freshRes.errorMessage ?? 'GPS coordinates are mandatory to mark an issue as Resolved.';
          _update(_state.copyWith(
            errorMessage: 'GPS Required: $explanation Please turn on GPS to proceed.',
          ));
          if (freshRes.error == LocationErrorType.serviceDisabled) {
            await locationHelper.openLocationSettings();
          } else if (freshRes.error == LocationErrorType.permissionDeniedForever) {
            await locationHelper.openAppSettings();
          }
          return false;
        }
      }
    }

    final comment = _state.comment.trim();

    _update(_state.copyWith(
      isSubmitting: true,
      clearErrorMessage: true,
    ));

    try {
      final lat = _state.locationResult?.latitude;
      final lng = _state.locationResult?.longitude;
      await onStatusUpdated(
        _state.selectedStatus,
        comment,
        _state.resolutionImage,
        lat,
        lng,
      );
      return true;
    } catch (e) {
      _update(_state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      ));
      return false;
    }
  }
}
