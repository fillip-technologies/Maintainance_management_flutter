import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/technician_queue_state.dart';
import 'technician_queue_viewmodel.dart';

/// Exposes the real-time KPI metrics derived from the technician queue.
final technicianKpiStatsProvider = Provider.autoDispose<TechnicianKpiStats>((ref) {
  return ref.watch(technicianQueueStateProvider.select((s) => s.kpiStats));
});
