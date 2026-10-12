enum ReplacementRequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const ReplacementRequestStatus(this.value);

  static ReplacementRequestStatus fromString(String? status) {
    return ReplacementRequestStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => ReplacementRequestStatus.pending,
    );
  }
}

/// A technician's request to replace/decommission a unit. Must be approved by
/// the organization head (client_admin) or super_admin before the technician
/// may carry the replacement out.
class ReplacementRequestModel {
  final String id;
  final String issueId;
  final ReplacementRequestStatus status;
  final String reason;
  final String replacementChoice;
  final String? spareDeviceName;
  final String? spareDeviceCode;
  final String? notes;
  final String? reviewNote;
  final String? reviewedByName;
  final DateTime? createdAt;

  const ReplacementRequestModel({
    required this.id,
    required this.issueId,
    required this.status,
    required this.reason,
    required this.replacementChoice,
    this.spareDeviceName,
    this.spareDeviceCode,
    this.notes,
    this.reviewNote,
    this.reviewedByName,
    this.createdAt,
  });

  bool get isPending => status == ReplacementRequestStatus.pending;
  bool get isApproved => status == ReplacementRequestStatus.approved;
  bool get isRejected => status == ReplacementRequestStatus.rejected;

  factory ReplacementRequestModel.fromJson(Map<String, dynamic> json) {
    final reviewedBy = json['reviewedBy'];
    return ReplacementRequestModel(
      id: (json['id'] as String?) ?? '',
      issueId: (json['issueId'] as String?) ?? '',
      status: ReplacementRequestStatus.fromString(json['status'] as String?),
      reason: (json['reason'] as String?) ?? '',
      replacementChoice: (json['replacementChoice'] as String?) ?? 'none',
      spareDeviceName: json['spareDeviceName'] as String?,
      spareDeviceCode: json['spareDeviceCode'] as String?,
      notes: json['notes'] as String?,
      reviewNote: json['reviewNote'] as String?,
      reviewedByName: reviewedBy is Map<String, dynamic> ? reviewedBy['name'] as String? : null,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
    );
  }
}
