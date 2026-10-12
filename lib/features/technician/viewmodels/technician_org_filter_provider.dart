import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../issues/issues.dart';
import 'technician_zone_tree_viewmodel.dart';

/// An organization (client) a technician is assigned to.
class TechnicianOrg {
  final String id;
  final String name;

  const TechnicianOrg({required this.id, required this.name});
}

/// The organization the technician picked in the org chip row. `null` = all.
class TechnicianOrgFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? clientId) => state = clientId;
}

final technicianOrgFilterProvider =
    NotifierProvider<TechnicianOrgFilterNotifier, String?>(
  TechnicianOrgFilterNotifier.new,
);

/// Every organization visible to the technician, gathered from the zone map and
/// the ticket queue. Sorted by name. Has one entry or none for single-org
/// technicians, in which case the UI hides the org switcher entirely.
final technicianOrgsProvider = Provider.autoDispose<List<TechnicianOrg>>((ref) {
  final orgs = <String, String>{};

  void add(String? id, String? name) {
    if (id == null || id.isEmpty) return;
    orgs.putIfAbsent(id, () => (name == null || name.isEmpty) ? '—' : name);
  }

  final tree = ref.watch(technicianZoneTreeViewModelProvider).value;
  for (final sec in tree?.zoneSections ?? const []) {
    add(sec.zone.clientId, sec.zone.clientName);
  }
  for (final issue in ref.watch(technicianIssuesProvider).value ?? const []) {
    add(issue.clientId, issue.clientName);
  }

  return orgs.entries
      .map((e) => TechnicianOrg(id: e.key, name: e.value))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});

/// The selected organization id, or `null` when showing all (also `null` if the
/// previously selected org is no longer in the technician's coverage).
final technicianActiveOrgProvider = Provider.autoDispose<String?>((ref) {
  final selected = ref.watch(technicianOrgFilterProvider);
  if (selected == null) return null;
  final orgs = ref.watch(technicianOrgsProvider);
  return orgs.any((o) => o.id == selected) ? selected : null;
});
