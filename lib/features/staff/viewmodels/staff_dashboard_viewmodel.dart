import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../daily_logs/daily_logs.dart';
import '../../devices/devices.dart';
import '../../issues/issues.dart';

class StaffDashboardViewModel {
  final Ref _ref;

  StaffDashboardViewModel(this._ref);

  void refreshAll() {
    _ref.invalidate(staffDevicesProvider);
    _ref.invalidate(todayLogsProvider);
    _ref.invalidate(staffIssuesProvider);
  }

  void refreshDevices() {
    _ref.invalidate(staffDevicesProvider);
  }

  void refreshTodayLogs() {
    _ref.invalidate(todayLogsProvider);
  }

  void refreshIssues() {
    _ref.invalidate(staffIssuesProvider);
  }
}

final staffDashboardViewModelProvider = Provider<StaffDashboardViewModel>((ref) {
  return StaffDashboardViewModel(ref);
});
