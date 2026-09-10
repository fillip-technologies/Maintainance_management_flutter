import 'dart:io';
import 'package:equipment_management_system/features/location/location_helper.dart';
import 'package:equipment_management_system/features/issues/models/issue_model.dart';

class UpdateStatusState {
  final IssueStatus selectedStatus;
  final String comment;
  final File? resolutionImage;
  final bool isPickingImage;
  final LocationResult? locationResult;
  final bool isFetchingLocation;
  final bool isSubmitting;
  final String? errorMessage;

  const UpdateStatusState({
    required this.selectedStatus,
    this.comment = '',
    this.resolutionImage,
    this.isPickingImage = false,
    this.locationResult,
    this.isFetchingLocation = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get isGpsMandatory => selectedStatus == IssueStatus.resolved;
  bool get hasValidGps => locationResult?.isSuccess == true;

  UpdateStatusState copyWith({
    IssueStatus? selectedStatus,
    String? comment,
    File? resolutionImage,
    bool clearResolutionImage = false,
    bool? isPickingImage,
    LocationResult? locationResult,
    bool? isFetchingLocation,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return UpdateStatusState(
      selectedStatus: selectedStatus ?? this.selectedStatus,
      comment: comment ?? this.comment,
      resolutionImage: clearResolutionImage ? null : (resolutionImage ?? this.resolutionImage),
      isPickingImage: isPickingImage ?? this.isPickingImage,
      locationResult: locationResult ?? this.locationResult,
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
