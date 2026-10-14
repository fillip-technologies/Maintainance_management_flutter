import 'package:flutter_test/flutter_test.dart';
import '../lib/features/auth/models/user_model.dart';

void main() {
  test('parses multiple assigned zones and keeps the primary zone', () {
    final user = UserModel.fromJson({
      'id': 'u1',
      'email': 'a@b.c',
      'role': 'zone_staff',
      'zoneId': 'z1',
      'zoneName': 'North',
      'zones': [
        {'id': 'z1', 'name': 'North', 'logoUrl': null},
        {'id': 'z2', 'name': 'South', 'logoUrl': 'http://x/logo.png'},
      ],
    });

    expect(user.assignedZoneId, 'z1');
    expect(user.assignedZoneIds, ['z1', 'z2']);
    expect(user.assignedZonesLabel, 'North, South');
    expect(user.isInAssignedZones('z2'), isTrue);
    expect(user.isInAssignedZones('z3'), isFalse);

    final round = UserModel.fromJson(user.toJson());
    expect(round.assignedZoneIds, ['z1', 'z2']);
  });

  test('legacy single-zone payload still works', () {
    final user = UserModel.fromJson({
      'id': 'u1',
      'email': 'a@b.c',
      'role': 'zone_staff',
      'zoneId': 'z1',
    });
    expect(user.assignedZoneIds, ['z1']);
    expect(user.isInAssignedZones('z1'), isTrue);
    expect(user.isInAssignedZones('z2'), isFalse);
  });

  test('user with no zone is unrestricted', () {
    final user = UserModel.fromJson({'id': 'u', 'email': 'a@b.c', 'role': 'zone_staff'});
    expect(user.isInAssignedZones('anything'), isTrue);
  });
}
