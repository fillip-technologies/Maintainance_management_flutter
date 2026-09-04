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
  final int devicesMissingTodayLog;
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
    this.devicesMissingTodayLog = 0,
    this.todayLogsCompleted = 0,
    this.todayLogsPending = 0,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final total = (json['totalDevices'] ?? json['total_devices'] as num?)?.toInt() ?? 0;
    final missing = (json['devicesMissingTodayLog'] ?? json['devices_missing_today_log'] ?? json['today_logs_pending'] as num?)?.toInt() ?? 0;
    final completed = (json['todayLogsCompleted'] ?? json['today_logs_completed'] as num?)?.toInt() ?? (total > missing ? total - missing : 0);
    final faulty = (json['faultyDevices'] ?? json['faulty_devices'] as num?)?.toInt() ?? 0;
    final underMaint = (json['underMaintenance'] ??
            json['under_maintenance'] ??
            json['underMaintenanceDevices'] ??
            json['under_maintenance_devices'] as num?)
        ?.toInt() ??
        0;
    final prov = (json['provisionedDevices'] ?? json['provisioned_devices'] as num?)?.toInt() ?? 0;

    final rawActive = (json['activeDevices'] ?? json['active_devices'] as num?)?.toInt();
    // When the backend does not explicitly return activeDevices, derive it from
    // non-retired total minus any faulty, under-maintenance, and provisioned devices.
    final calculatedActive = rawActive ?? (total - faulty - underMaint - prov).clamp(0, total);

    return DashboardSummaryModel(
      totalDevices: total,
      activeDevices: calculatedActive,
      underMaintenanceDevices: underMaint,
      faultyDevices: faulty,
      provisionedDevices: prov,
      openIssues: (json['openIssues'] ?? json['open_issues'] as num?)?.toInt() ?? 0,
      inProgressIssues: (json['inProgressIssues'] ?? json['in_progress_issues'] as num?)?.toInt() ?? 0,
      resolvedIssues: (json['resolvedIssues'] ?? json['resolved_issues'] as num?)?.toInt() ?? 0,
      criticalIssues: (json['criticalIssues'] ?? json['critical_issues'] as num?)?.toInt() ?? 0,
      devicesMissingTodayLog: missing,
      todayLogsCompleted: completed,
      todayLogsPending: missing,
    );
  }

  DashboardSummaryModel copyWith({
    int? totalDevices,
    int? activeDevices,
    int? underMaintenanceDevices,
    int? faultyDevices,
    int? provisionedDevices,
    int? openIssues,
    int? inProgressIssues,
    int? resolvedIssues,
    int? criticalIssues,
    int? devicesMissingTodayLog,
    int? todayLogsCompleted,
    int? todayLogsPending,
  }) {
    return DashboardSummaryModel(
      totalDevices: totalDevices ?? this.totalDevices,
      activeDevices: activeDevices ?? this.activeDevices,
      underMaintenanceDevices: underMaintenanceDevices ?? this.underMaintenanceDevices,
      faultyDevices: faultyDevices ?? this.faultyDevices,
      provisionedDevices: provisionedDevices ?? this.provisionedDevices,
      openIssues: openIssues ?? this.openIssues,
      inProgressIssues: inProgressIssues ?? this.inProgressIssues,
      resolvedIssues: resolvedIssues ?? this.resolvedIssues,
      criticalIssues: criticalIssues ?? this.criticalIssues,
      devicesMissingTodayLog: devicesMissingTodayLog ?? this.devicesMissingTodayLog,
      todayLogsCompleted: todayLogsCompleted ?? this.todayLogsCompleted,
      todayLogsPending: todayLogsPending ?? this.todayLogsPending,
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
      'devices_missing_today_log': devicesMissingTodayLog,
      'today_logs_completed': todayLogsCompleted,
      'today_logs_pending': todayLogsPending,
    };
  }
}
