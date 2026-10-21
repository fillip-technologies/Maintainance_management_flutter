import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/auth.dart';
import '../../devices/repositories/zone_repository.dart';

/// A staff member's assigned top-level zones, plus a lookup from any zone in
/// their scope (including sub-zones) to the top-level zone that contains it.
class StaffTopZones {
  /// Assigned top-level zones as (id, name), sorted by name.
  final List<({String id, String name})> zones;

  /// zoneId (top-level or any sub-zone) -> id of its top-level zone.
  final Map<String, String> topZoneOf;

  const StaffTopZones({required this.zones, required this.topZoneOf});

  const StaffTopZones.empty()
      : zones = const [],
        topZoneOf = const {};

  /// Builds the tree from the zones the backend scopes to the caller
  /// (`GET /zones`): the assigned subtrees. A zone whose parent is not in that
  /// set is an assigned top-level zone; every other zone climbs up to one.
  factory StaffTopZones.fromScopedZones(
    Iterable<({String id, String name, String? parentZoneId})> scoped,
  ) {
    final byId = {for (final z in scoped) z.id: z};
    final topZoneOf = <String, String>{};

    String topOf(String id) {
      final cached = topZoneOf[id];
      if (cached != null) return cached;
      var current = byId[id]!;
      final seen = <String>{current.id};
      while (current.parentZoneId != null && byId.containsKey(current.parentZoneId)) {
        if (!seen.add(current.parentZoneId!)) break; // defensive: cyclic data
        current = byId[current.parentZoneId]!;
      }
      return topZoneOf[id] = current.id;
    }

    for (final id in byId.keys) {
      topOf(id);
    }
    final zones = [
      for (final topId in topZoneOf.values.toSet()) (id: topId, name: byId[topId]!.name),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return StaffTopZones(zones: zones, topZoneOf: topZoneOf);
  }
}

/// Loads [StaffTopZones] for the signed-in zone officer. Re-runs on login change.
final staffTopZonesProvider = FutureProvider<StaffTopZones>((ref) async {
  final userId = ref.watch(authStateProvider.select((a) => a.value?.id));
  if (userId == null) return const StaffTopZones.empty();

  try {
    final nodes = await ref.read(zoneRepositoryProvider).getAllZones();
    return StaffTopZones.fromScopedZones(
      nodes.map((z) => (id: z.id, name: z.name, parentZoneId: z.parentZoneId)),
    );
  } catch (e) {
    AppLogger.w('⚠️ [StaffTopZones] Could not load assigned zones: $e');
    return const StaffTopZones.empty();
  }
});
