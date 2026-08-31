class DashboardSummaryModel {
  final int totalDevices;
  final int activeDevices;
  final int underMaintenanceDevices;
  final int faultyDevices;
  final int provisionedDevices;
  final int openIssues;
  final int inProgressIssues;
  final int resolvedIssues;
  final int criticalIssues;
  final int todayLogsCompleted;
  final int todayLogsPending;

  const DashboardSummaryModel({
    this.totalDevices = 0,
    this.activeDevices = 0,
    this.underMaintenanceDevices = 0,
    this.faultyDevices = 0,
    this.provisionedDevices = 0,
    this.openIssues = 0,
    this.inProgressIssues = 0,
    this.resolvedIssues = 0,
    this.criticalIssues = 0,
    this.todayLogsCompleted = 0,
    this.todayLogsPending = 0,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalDevices: (json['total_devices'] as num?)?.toInt() ?? 0,
      activeDevices: (json['active_devices'] as num?)?.toInt() ?? 0,
      underMaintenanceDevices:
          (json['under_maintenance_devices'] as num?)?.toInt() ?? 0,
      faultyDevices: (json['faulty_devices'] as num?)?.toInt() ?? 0,
      provisionedDevices: (json['provisioned_devices'] as num?)?.toInt() ?? 0,
      openIssues: (json['open_issues'] as num?)?.toInt() ?? 0,
      inProgressIssues: (json['in_progress_issues'] as num?)?.toInt() ?? 0,
      resolvedIssues: (json['resolved_issues'] as num?)?.toInt() ?? 0,
      criticalIssues: (json['critical_issues'] as num?)?.toInt() ?? 0,
      todayLogsCompleted: (json['today_logs_completed'] as num?)?.toInt() ?? 0,
      todayLogsPending: (json['today_logs_pending'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_devices': totalDevices,
      'active_devices': activeDevices,
      'under_maintenance_devices': underMaintenanceDevices,
      'faulty_devices': faultyDevices,
      'provisioned_devices': provisionedDevices,
      'open_issues': openIssues,
      'in_progress_issues': inProgressIssues,
      'resolved_issues': resolvedIssues,
      'critical_issues': criticalIssues,
      'today_logs_completed': todayLogsCompleted,
      'today_logs_pending': todayLogsPending,
    };
  }
}
