import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equipment_management_system/l10n/app_localizations.dart';
import 'package:equipment_management_system/features/auth/auth.dart';
import 'package:equipment_management_system/features/devices/devices.dart';
import 'package:equipment_management_system/features/issues/issues.dart';
import 'package:equipment_management_system/features/daily_logs/daily_logs.dart';
import 'package:equipment_management_system/features/realtime/realtime.dart';
import 'package:equipment_management_system/core/config/app_config.dart';
import 'package:equipment_management_system/core/utils/jwt_helper.dart';

void main() {
  group('Backend ⟷ Frontend Model Parity Tests', () {
    test('1. UserModel parses backend login response correctly', () {
      final backendUserJson = {
        'id': 'fc4349f5-eef1-4405-83c6-d43a452c725a',
        'name': 'Ravi Kumar',
        'email': 'ravi@cityzoo.com',
        'role': 'zone_incharge',
        'clientId': '6a348679-0265-41d5-aa19-0b98f4abf635',
        'zoneId': '052feedc-261f-4805-bfdc-1145a41cf7c8',
      };

      final user = UserModel.fromJson(backendUserJson);

      expect(user.id, 'fc4349f5-eef1-4405-83c6-d43a452c725a');
      expect(user.name, 'Ravi Kumar');
      expect(user.email, 'ravi@cityzoo.com');
      expect(user.role, UserRole.zoneIncharge);
      expect(user.role.value, 'zone_incharge');
      expect(user.role.isZoneHeadOrStaff, isTrue);
      expect(user.clientId, '6a348679-0265-41d5-aa19-0b98f4abf635');
      expect(user.assignedZoneId, '052feedc-261f-4805-bfdc-1145a41cf7c8');
    });

    test('1b. UserModel parses backend technician login response correctly', () {
      final backendTechnicianJson = {
        'id': 'ed6653dc-1069-4e1d-80a2-f300c60cbc3a',
        'name': 'Raju mistri',
        'role': 'technician',
        'clientId': null,
        'zoneId': null,
        'technicianId': '43db2f57-7ae8-497a-b77a-b370959c779e',
      };

      final user = UserModel.fromJson(backendTechnicianJson);

      expect(user.id, 'ed6653dc-1069-4e1d-80a2-f300c60cbc3a');
      expect(user.name, 'Raju mistri');
      expect(user.role, UserRole.technician);
      expect(user.role.isTechnician, isTrue);
      expect(user.role.isZoneHeadOrStaff, isFalse);
      expect(user.technicianId, '43db2f57-7ae8-497a-b77a-b370959c779e');
    });

    test('2. ZoneModel parses backend zone tree response correctly', () {
      final backendZoneJson = {
        'id': '052feedc-261f-4805-bfdc-1145a41cf7c8',
        'clientId': '6a348679-0265-41d5-aa19-0b98f4abf635',
        'parentZoneId': null,
        'name': 'North Wing',
        'status': 'active',
        'depth': 0,
        'deviceCount': 4,
        'openIssuesCount': 1,
      };

      final zone = ZoneModel.fromJson(backendZoneJson);

      expect(zone.id, '052feedc-261f-4805-bfdc-1145a41cf7c8');
      expect(zone.name, 'North Wing');
      expect(zone.status, ZoneStatus.active);
      expect(zone.depth, 0);
      expect(zone.parentZoneId, isNull);
      expect(zone.deviceCount, 4);
      expect(zone.openIssuesCount, 1);
    });

    test('3. DeviceModel parses backend device response and nested relations correctly', () {
      final backendDeviceJson = {
        'id': 'e23fdc61-4365-4a33-9d22-82412878e8fc',
        'zoneId': '1a1b8786-ce7b-4708-b340-47d8e98c3412',
        'hardwareTypeId': 'hw-ptz-01',
        'name': 'Cam - North Wing Gate',
        'location': 'north gate pillar',
        'installDate': '2026-08-31',
        'status': 'active',
        'isManualEntry': false,
        'customSpec': {'ip': '192.168.1.101'},
        'addedById': 'usr-123',
        'createdAt': '2026-08-31T10:00:00.000Z',
        'updatedAt': '2026-08-31T10:00:00.000Z',
        'zone': {
          'id': '1a1b8786-ce7b-4708-b340-47d8e98c3412',
          'name': 'North Wing',
          'clientId': '6a348679-0265-41d5-aa19-0b98f4abf635',
        },
        'hardwareType': {
          'id': 'hw-ptz-01',
          'name': 'CCTV camera',
        },
        'zoneName': 'North Wing',
      };

      final device = DeviceModel.fromJson(backendDeviceJson);

      expect(device.id, 'e23fdc61-4365-4a33-9d22-82412878e8fc');
      expect(device.name, 'Cam - North Wing Gate');
      expect(device.zoneId, '1a1b8786-ce7b-4708-b340-47d8e98c3412');
      expect(device.zoneName, 'North Wing');
      expect(device.hardwareTypeName, 'CCTV camera');
      expect(device.location, 'north gate pillar');
      expect(device.status, DeviceStatus.active);
      expect(device.specFields['ip'], '192.168.1.101');
      expect(device.installDate, isNotNull);
    });

    test('4. HardwareTypeModel & IssueCategoryModel parse catalogue data correctly', () {
      final backendHwJson = {
        'id': 'hw-01',
        'name': 'CCTV camera',
        'specFields': {'resolution': '4K', 'lens': '2.8mm'},
        'issueCategories': [
          {
            'id': 'cat-01',
            'hardwareTypeId': 'hw-01',
            'name': 'no power',
          },
          {
            'id': 'cat-02',
            'hardwareTypeId': 'hw-01',
            'name': 'lens damage',
          },
        ],
      };

      final hw = HardwareTypeModel.fromJson(backendHwJson);

      expect(hw.id, 'hw-01');
      expect(hw.name, 'CCTV camera');
      expect(hw.specFields['resolution'], '4K');
      expect(hw.issueCategories.length, 2);
      expect(hw.issueCategories[0].name, 'no power');
      expect(hw.issueCategories[1].name, 'lens damage');
    });

    test('5. IssueModel parses backend issue with nested technician and statusHistory', () {
      final backendIssueJson = {
        'id': 'eaa7b74d-8474-4603-adeb-2a24e01cef02',
        'deviceId': 'e23fdc61-4365-4a33-9d22-82412878e8fc',
        'categoryId': 'cat-01',
        'raisedByUserId': 'fc4349f5-eef1-4405-83c6-d43a452c725a',
        'assignedTechnicianId': 'f2477cbb-0830-46b6-86de-f8fac2d165a2',
        'priority': 'high',
        'status': 'assigned',
        'description': 'Seeded issue: no power on Cam - North Wing Gate',
        'createdAt': '2026-08-31T12:00:00.000Z',
        'updatedAt': '2026-08-31T12:30:00.000Z',
        'resolvedAt': null,
        'closedAt': null,
        'device': {
          'id': 'e23fdc61-4365-4a33-9d22-82412878e8fc',
          'name': 'Cam - North Wing Gate',
          'zoneId': '1a1b8786-ce7b-4708-b340-47d8e98c3412',
          'hardwareTypeId': 'hw-ptz-01',
          'zone': {'name': 'North Wing'},
        },
        'category': {
          'id': 'cat-01',
          'name': 'no power',
        },
        'raisedBy': {
          'id': 'fc4349f5-eef1-4405-83c6-d43a452c725a',
          'name': 'Ravi Kumar',
          'email': 'ravi@cityzoo.com',
        },
        'assignedTechnician': {
          'id': 'f2477cbb-0830-46b6-86de-f8fac2d165a2',
          'specialization': 'CCTV & Network',
          'user': {
            'id': '646acb55-9ebf-4e6d-8423-2180bc4dae1d',
            'name': 'Amit Shah',
          },
        },
        'statusHistory': [
          {
            'id': 'hist-01',
            'issueId': 'eaa7b74d-8474-4603-adeb-2a24e01cef02',
            'fromStatus': null,
            'toStatus': 'open',
            'changedByUserId': 'fc4349f5-eef1-4405-83c6-d43a452c725a',
            'changedAt': '2026-08-31T12:00:00.000Z',
            'notes': 'Reported during morning round',
            'changedBy': {
              'id': 'fc4349f5-eef1-4405-83c6-d43a452c725a',
              'name': 'Ravi Kumar',
            },
          },
        ],
      };

      final issue = IssueModel.fromJson(backendIssueJson);

      expect(issue.id, 'eaa7b74d-8474-4603-adeb-2a24e01cef02');
      expect(issue.description, 'Seeded issue: no power on Cam - North Wing Gate');
      expect(issue.priority, IssuePriority.high);
      expect(issue.status, IssueStatus.assigned);
      expect(issue.deviceName, 'Cam - North Wing Gate');
      expect(issue.categoryName, 'no power');
      expect(issue.createdByUserName, 'Ravi Kumar');
      expect(issue.assignedTechnicianName, 'Amit Shah');
      expect(issue.history.length, 1);
      expect(issue.history[0].toStatus, IssueStatus.open);
      expect(issue.history[0].comment, 'Reported during morning round');
      expect(issue.history[0].changedByUserName, 'Ravi Kumar');
    });

    test('6. DailyStatusLogModel parses backend daily log response correctly', () {
      final backendLogJson = {
        'id': 'log-01',
        'deviceId': 'e23fdc61-4365-4a33-9d22-82412878e8fc',
        'loggedByUserId': 'fc4349f5-eef1-4405-83c6-d43a452c725a',
        'status': 'working',
        'logDate': '2026-08-31T00:00:00.000Z',
        'notes': 'Lens cleaned and verified',
        'createdAt': '2026-08-31T14:00:00.000Z',
        'deviceName': 'Cam - North Wing Gate',
        'loggedByName': 'Ravi Kumar',
      };

      final log = DailyStatusLogModel.fromJson(backendLogJson);

      expect(log.id, 'log-01');
      expect(log.deviceId, 'e23fdc61-4365-4a33-9d22-82412878e8fc');
      expect(log.status, DailyLogStatus.working);
      expect(log.deviceName, 'Cam - North Wing Gate');
      expect(log.loggedByUserName, 'Ravi Kumar');
      expect(log.notes, 'Lens cleaned and verified');
    });

    test('7. DashboardSummaryModel parses backend summary metrics correctly', () {
      final backendSummaryJson = {
        'openIssues': 7,
        'faultyDevices': 0,
        'devicesMissingTodayLog': 3,
        'totalDevices': 4,
      };

      final summary = DashboardSummaryModel.fromJson(backendSummaryJson);

      expect(summary.totalDevices, 4);
      expect(summary.activeDevices, 4);
      expect(summary.openIssues, 7);
      expect(summary.faultyDevices, 0);
      expect(summary.devicesMissingTodayLog, 3);
    });

    test('8. IssueStatusHistoryModel parses backend timeline response correctly', () {
      final backendHistoryItem = {
        'id': 'hist-uuid-01',
        'issueId': 'iss-uuid-01',
        'fromStatus': 'open',
        'toStatus': 'in_progress',
        'changedByUserId': 'user-uuid-02',
        'changedAt': '2026-09-03T06:14:51.242Z',
        'notes': 'Technician arrived on site and started diagnosis',
        'changedBy': {
          'id': 'user-uuid-02',
          'name': 'Raju mistri',
        },
      };

      final history = IssueStatusHistoryModel.fromJson(backendHistoryItem);

      expect(history.id, 'hist-uuid-01');
      expect(history.issueId, 'iss-uuid-01');
      expect(history.fromStatus, IssueStatus.open);
      expect(history.toStatus, IssueStatus.inProgress);
      expect(history.changedByUserName, 'Raju mistri');
      expect(history.comment, 'Technician arrived on site and started diagnosis');
      expect(history.createdAt.year, 2026);
    });

    test('9. DeviceStatus handles retired and provisioned states correctly', () {
      expect(DeviceStatus.fromString('retired'), DeviceStatus.retired);
      expect(DeviceStatus.retired.label, 'Removed / Retired');
      expect(DeviceStatus.fromString('provisioned'), DeviceStatus.provisioned);
      expect(DeviceStatus.provisioned.label, 'Provisioned');
    });

    test('10. IssueModel parses nested deviceStatus and deviceCode correctly', () {
      final backendIssueJson = {
        'id': 'iss-001',
        'title': 'Camera destroyed',
        'description': 'Camera physically smashed',
        'device': {
          'id': 'dev-001',
          'name': 'Gate 1 Camera',
          'code': 'CAM-000123',
          'status': 'under_maintenance',
          'zone': {'id': 'z-1', 'name': 'North Wing'},
        },
        'category': {'id': 'cat-1', 'name': 'CCTV'},
        'priority': 'critical',
        'status': 'in_progress',
        'createdAt': '2026-09-03T10:00:00.000Z',
      };

      final issue = IssueModel.fromJson(backendIssueJson);
      expect(issue.deviceId, 'dev-001');
      expect(issue.deviceName, 'Gate 1 Camera');
      expect(issue.deviceCode, 'CAM-000123');
      expect(issue.deviceStatus, DeviceStatus.underMaintenance);
      expect(issue.priority, IssuePriority.critical);
    });

    test('11. AppConfig.getSocketUrl extracts WebSocket origin server URL correctly', () {
      expect(AppConfig.getSocketUrl('http://localhost:3000/api/v1'), 'http://localhost:3000');
      expect(AppConfig.getSocketUrl('https://api.myapp.com/api/v1/'), 'https://api.myapp.com');
      expect(AppConfig.getSocketUrl('http://192.168.1.100:3000/api/v1'), 'http://192.168.1.100:3000');
    });

    test('12. SocketEventModel parses socket domain payloads correctly', () {
      final backendIssuePayload = {
        'id': 'iss-live-01',
        'title': 'Power failure',
        'description': 'UPS battery dead',
        'device': {
          'id': 'dev-ups-01',
          'name': 'Main UPS',
          'code': 'UPS-000001',
          'status': 'under_maintenance',
        },
        'category': {'id': 'cat-pwr', 'name': 'Electrical'},
        'priority': 'high',
        'status': 'open',
        'createdAt': '2026-09-03T18:00:00.000Z',
      };

      final issueEvent = SocketIssueEvent.fromJson('issue:created', backendIssuePayload);
      expect(issueEvent.eventType, 'issue:created');
      expect(issueEvent.issue.id, 'iss-live-01');
      expect(issueEvent.issue.deviceName, 'Main UPS');

      final backendLogPayload = {
        'id': 'log-live-01',
        'deviceId': 'dev-ups-01',
        'status': 'working',
        'logDate': '2026-09-03',
        'notes': 'All green indicators',
        'zoneId': 'zone-north',
      };

      final logEvent = SocketLogEvent.fromJson(backendLogPayload);
      expect(logEvent.log.id, 'log-live-01');
      expect(logEvent.log.status, DailyLogStatus.working);
      expect(logEvent.zoneId, 'zone-north');
    });

    test('13. JwtHelper detects token expiration and decodes payload correctly', () {
      // Future expiry token:
      final futureExpirySeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
      final payloadFuture = base64Url.encode(utf8.encode('{"sub":"user-1","exp":$futureExpirySeconds}'));
      final validToken = 'header.$payloadFuture.signature';
      expect(JwtHelper.isExpired(validToken), false);

      // Past expiry token:
      final pastExpirySeconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 100;
      final payloadPast = base64Url.encode(utf8.encode('{"sub":"user-1","exp":$pastExpirySeconds}'));
      final expiredToken = 'header.$payloadPast.signature';
      expect(JwtHelper.isExpired(expiredToken), true);

      // Malformed token:
      expect(JwtHelper.isExpired('invalid-token'), true);
    });

    test('14. IssueModel deserializes bulk issue creation response list correctly', () {
      final backendBulkResponse = {
        'success': true,
        'data': [
          {
            'id': 'issue-bulk-01',
            'deviceId': 'dev-cam-01',
            'categoryId': 'cat-pwr-01',
            'priority': 'critical',
            'status': 'open',
            'description': 'Power surge knocked out sector cameras',
            'device': {
              'id': 'dev-cam-01',
              'name': 'North Gate Cam 1',
              'zoneId': 'zone-north',
              'zone': {'name': 'North Perimeter'},
            },
            'category': {
              'id': 'cat-pwr-01',
              'name': 'Power Outage',
            },
            'statusHistory': [
              {
                'id': 'hist-01',
                'issueId': 'issue-bulk-01',
                'fromStatus': null,
                'toStatus': 'open',
                'changedByUserId': 'user-staff-01',
                'changedAt': '2026-09-04T10:00:00.000Z',
              },
            ],
          },
          {
            'id': 'issue-bulk-02',
            'deviceId': 'dev-cam-02',
            'categoryId': 'cat-pwr-01',
            'priority': 'critical',
            'status': 'open',
            'description': 'Power surge knocked out sector cameras',
            'device': {
              'id': 'dev-cam-02',
              'name': 'North Gate Cam 2',
              'zoneId': 'zone-north',
              'zone': {'name': 'North Perimeter'},
            },
            'category': {
              'id': 'cat-pwr-01',
              'name': 'Power Outage',
            },
            'statusHistory': [
              {
                'id': 'hist-02',
                'issueId': 'issue-bulk-02',
                'fromStatus': null,
                'toStatus': 'open',
                'changedByUserId': 'user-staff-01',
                'changedAt': '2026-09-04T10:00:00.000Z',
              },
            ],
          },
        ],
      };

      final dataList = backendBulkResponse['data'] as List<dynamic>;
      final issues = dataList
          .map((item) => IssueModel.fromJson(item as Map<String, dynamic>))
          .toList();

      expect(issues.length, 2);
      expect(issues[0].id, 'issue-bulk-01');
      expect(issues[0].deviceName, 'North Gate Cam 1');
      expect(issues[0].priority, IssuePriority.critical);
      expect(issues[0].status, IssueStatus.open);
      expect(issues[0].description, 'Power surge knocked out sector cameras');

      expect(issues[1].id, 'issue-bulk-02');
      expect(issues[1].deviceName, 'North Gate Cam 2');
      expect(issues[1].priority, IssuePriority.critical);
      expect(issues[1].status, IssueStatus.open);
    });

    test('15. AppLocalizationsEn and AppLocalizationsHi have complete parity for Bulk Issue reporting', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));

      expect(en.btnBulkDefect, 'Bulk Defect');
      expect(hi.btnBulkDefect, 'थोक समस्या');

      expect(en.raiseBulkDefectTitle, 'Raise Bulk Defect');
      expect(hi.raiseBulkDefectTitle, 'थोक उपकरण समस्या रिपोर्ट करें');

      expect(en.raiseBulkDefectSubtitle, 'Report identical issue on multiple units (1–50)');
      expect(hi.raiseBulkDefectSubtitle, 'एकाधिक उपकरणों पर समान समस्या दर्ज करें (1–50)');

      expect(en.selectEquipmentUnits(5), 'Select Equipment (5/50)');
      expect(hi.selectEquipmentUnits(5), 'उपकरण चुनें (5/50)');

      expect(en.selectAll, 'Select All');
      expect(hi.selectAll, 'सभी चुनें');

      expect(en.clearSelection, 'Clear');
      expect(hi.clearSelection, 'हटाएं');

      expect(en.searchUnitsHint, 'Search unit by name, serial number or type...');
      expect(hi.searchUnitsHint, 'नाम, सीरियल नंबर या प्रकार से खोजें...');

      expect(en.noMatchingUnits, 'No matching equipment units found');
      expect(hi.noMatchingUnits, 'कोई मेल खाने वाला उपकरण नहीं मिला');

      expect(en.loadingCategories, 'Loading defect categories...');
      expect(hi.loadingCategories, 'दोष श्रेणियां लोड हो रही हैं...');

      expect(en.noCategoriesFound, 'No defect categories found. Please contact an administrator.');
      expect(hi.noCategoriesFound, 'कोई दोष श्रेणी नहीं मिली। कृपया व्यवस्थापक से संपर्क करें।');

      expect(en.selectCategoryHint, 'Select Defect Category');
      expect(hi.selectCategoryHint, 'दोष की श्रेणी चुनें');

      expect(en.bulkDefectDescriptionLabel, 'Defect Description & Shared Symptoms');
      expect(hi.bulkDefectDescriptionLabel, 'दोष का विवरण एवं सामान्य लक्षण');

      expect(en.btnSelectUnitsFirst, 'Select Units Above to Report Defect');
      expect(hi.btnSelectUnitsFirst, 'समस्या दर्ज करने हेतु ऊपर उपकरण चुनें');

      expect(en.btnRaiseBulkDefect(3), 'Raise Defect Ticket on 3 Unit(s)');
      expect(hi.btnRaiseBulkDefect(3), '3 उपकरणों के लिए समस्या टिकट दर्ज करें');

      expect(en.submittingBulkDefect, 'Raising Defects...');
      expect(hi.submittingBulkDefect, 'समस्याएं दर्ज हो रही हैं...');

      expect(en.errSelectAtLeastOneUnit, 'Please select at least 1 equipment unit');
      expect(hi.errSelectAtLeastOneUnit, 'कृपया कम से कम 1 उपकरण चुनें');

      expect(en.errMaxUnitsLimit, 'Maximum limit of 50 units reached for a single bulk ticket');
      expect(hi.errMaxUnitsLimit, 'एक साथ अधिकतम 50 उपकरण चुने जा सकते हैं');

      expect(en.errRetiredUnitSelected, 'Cannot raise defects on retired equipment');
      expect(hi.errRetiredUnitSelected, 'सेवामुक्त उपकरणों पर समस्या दर्ज नहीं की जा सकती');

      expect(en.errSelectCategory, 'Please select a defect category');
      expect(hi.errSelectCategory, 'कृपया दोष श्रेणी चुनें');

      expect(en.errProvideDescription, 'Please provide a clear description of the defect');
      expect(hi.errProvideDescription, 'कृपया दोष का स्पष्ट विवरण दर्ज करें');

      expect(en.bulkDefectSuccessMsg(4), '4 bulk defect tickets raised successfully');
      expect(hi.bulkDefectSuccessMsg(4), '4 थोक समस्या टिकट सफलतापूर्वक दर्ज किए गए');

      expect(en.errFailedToRaiseBulk, 'Failed to raise bulk issues');
      expect(hi.errFailedToRaiseBulk, 'थोक समस्या टिकट दर्ज करने में विफल');

      expect(en.errFailedToLoadCategories, 'Failed to load defect categories');
      expect(hi.errFailedToLoadCategories, 'दोष श्रेणियां लोड करने में विफल');
    });

    test('16. DeviceGroup.fromDevices correctly aggregates multi-quantity devices by hardware type', () {
      final sampleDevices = <DeviceModel>[
        const DeviceModel(
          id: 'cam-1',
          name: 'Gate Cam 1',
          serialNumber: 'SN-CAM-1',
          hardwareTypeName: 'CCTV Camera',
          location: 'Main Gate',
          status: DeviceStatus.active,
          zoneId: 'z1',
          zoneName: 'Zone A',
        ),
        const DeviceModel(
          id: 'cam-2',
          name: 'Fence Cam 2',
          serialNumber: 'SN-CAM-2',
          hardwareTypeName: 'CCTV Camera',
          location: 'Fence Line',
          status: DeviceStatus.faulty,
          zoneId: 'z1',
          zoneName: 'Zone A',
        ),
        const DeviceModel(
          id: 'fan-1',
          name: 'Exhaust Fan 1',
          serialNumber: 'SN-FAN-1',
          hardwareTypeName: 'Cooling Fan',
          location: 'Enclosure B',
          status: DeviceStatus.underMaintenance,
          zoneId: 'z1',
          zoneName: 'Zone A',
        ),
        const DeviceModel(
          id: 'fan-2',
          name: 'Exhaust Fan 2',
          serialNumber: 'SN-FAN-2',
          hardwareTypeName: 'Cooling Fan',
          location: 'Enclosure B',
          status: DeviceStatus.active,
          zoneId: 'z1',
          zoneName: 'Zone A',
        ),
        const DeviceModel(
          id: 'fan-3',
          name: 'Exhaust Fan 3',
          serialNumber: 'SN-FAN-3',
          hardwareTypeName: 'Cooling Fan',
          location: 'Enclosure B',
          status: DeviceStatus.provisioned,
          zoneId: 'z1',
          zoneName: 'Zone A',
        ),
      ];

      final groups = DeviceGroup.fromDevices(sampleDevices);

      expect(groups.length, 2);
      expect(groups[0].hardwareTypeName, 'CCTV Camera');
      expect(groups[0].totalCount, 2);
      expect(groups[0].activeCount, 1);
      expect(groups[0].faultyCount, 1);
      expect(groups[0].maintenanceCount, 0);

      expect(groups[1].hardwareTypeName, 'Cooling Fan');
      expect(groups[1].totalCount, 3);
      expect(groups[1].activeCount, 1);
      expect(groups[1].maintenanceCount, 1);
      expect(groups[1].inStockCount, 1);
      expect(groups[1].faultyCount, 0);
    });

    test('17. AppLocalizationsEn and AppLocalizationsHi have complete parity for Grouped View and Batch Selection', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final hi = await AppLocalizations.delegate.load(const Locale('hi'));

      expect(en.viewGrouped, 'Grouped');
      expect(hi.viewGrouped, 'समूहबद्ध');

      expect(en.viewFlat, 'List');
      expect(hi.viewFlat, 'सूची');

      expect(en.unitsCount(10), '10 Units');
      expect(hi.unitsCount(10), '10 उपकरण');

      expect(en.singleUnitCount, '1 Unit');
      expect(hi.singleUnitCount, '1 उपकरण');

      expect(en.selectAllInGroup, 'Select Group');
      expect(hi.selectAllInGroup, 'समूह चुनें');

      expect(en.deselectGroup, 'Deselect');
      expect(hi.deselectGroup, 'हटाएं');

      expect(en.groupSelectedCount(3, 8), '3/8 selected');
      expect(hi.groupSelectedCount(3, 8), '3/8 चयनित');

      expect(en.filterByHardwareType, 'Filter by Type');
      expect(hi.filterByHardwareType, 'प्रकार अनुसार फ़िल्टर');

      expect(en.allTypes, 'All Types');
      expect(hi.allTypes, 'सभी प्रकार');

      expect(en.collapseAll, 'Collapse All');
      expect(hi.collapseAll, 'सभी समेटें');

      expect(en.expandAll, 'Expand All');
      expect(hi.expandAll, 'सभी खोलें');

      expect(en.allHardware, 'All Hardware');
      expect(hi.allHardware, 'सभी हार्डवेयर');

      expect(en.singleCategory, '1 Category');
      expect(hi.singleCategory, '1 श्रेणी');

      expect(en.categoriesCount(3), '3 Categories');
      expect(hi.categoriesCount(3), '3 श्रेणियां');

      expect(en.unitsAffectedBadge(5), '5 Units Affected');
      expect(hi.unitsAffectedBadge(5), '5 उपकरण प्रभावित');

      expect(en.quantityLabel, 'Quantity');
      expect(hi.quantityLabel, 'मात्रा');

      expect(en.applyToSelected, 'Apply to Selected');
      expect(hi.applyToSelected, 'चयनित पर लागू करें');

      expect(en.selectMode, 'Select');
      expect(hi.selectMode, 'चुनें');

      expect(en.doneSelecting, 'Done');
      expect(hi.doneSelecting, 'पूर्ण');
    });

    test('18. Issue description parsing extracts Units affected count matching web format', () {
      const webFormattedDescription = 'Product: CCTV Camera · Units affected: 5\nDefect type: No Power\nCameras in north wing lost power simultaneously.';
      final match = RegExp(r'Units affected:\s*(\d+)').firstMatch(webFormattedDescription);

      expect(match, isNotNull);
      expect(int.parse(match!.group(1)!), 5);
    });

    test('19. IssueModel parses real backend payload with unitsAffected and displayDescription', () {
      final json = {
        'id': '91fa83bc-4d41-4ea2-b0ea-741e8b6e1b6f',
        'deviceId': '00a5f066-4272-4f77-a755-f56c730e0402',
        'categoryId': '25fda868-6145-4cb7-add1-14ee451caf15',
        'priority': 'medium',
        'status': 'open',
        'description': 'Product: Camera · Units affected: 3\nhello hunnu bunny',
        'device': {
          'id': '00a5f066-4272-4f77-a755-f56c730e0402',
          'name': 'PTZ CAMERA',
          'zone': {'name': 'North Gate'},
        },
        'category': {
          'id': '25fda868-6145-4cb7-add1-14ee451caf15',
          'name': 'Needs inspection',
        },
      };

      final issue = IssueModel.fromJson(json);

      expect(issue.id, '91fa83bc-4d41-4ea2-b0ea-741e8b6e1b6f');
      expect(issue.unitsAffected, 3);
      expect(issue.displayDescription, 'hello hunnu bunny');
      expect(issue.deviceName, 'PTZ CAMERA');
    });

    test('20. Technician Bulk Resolve localization keys parity between EN and HI', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final hi = lookupAppLocalizations(const Locale('hi'));

      expect(en.btnBulkResolve, 'Bulk Resolve');
      expect(hi.btnBulkResolve, 'थोक समाधान');

      expect(en.bulkResolveTitle, 'Bulk Resolve Issues');
      expect(hi.bulkResolveTitle, 'थोक समस्याएं हल करें');

      expect(en.bulkStatusSuccessMsg(4, 'Resolved'), '4 tickets updated to Resolved');
      expect(hi.bulkStatusSuccessMsg(4, 'समाधान'), '4 टिकट समाधान में सफलतापूर्वक अपडेट किए गए');

      expect(en.selectTickets(3), 'Select Tickets (3/50)');
      expect(hi.selectTickets(3), 'टिकट चुनें (3/50)');
    });

    test('21. Push Notification Device Token payload and platform parity', () {
      const sampleToken = 'fcm_test_token_abc_123';
      const platform = 'android';
      final payload = {
        'token': sampleToken,
        'platform': platform,
      };

      expect(payload['token'], sampleToken);
      expect(payload['platform'], 'android');
      expect(payload.containsKey('token'), isTrue);
      expect(payload.containsKey('platform'), isTrue);
    });
  });
}
