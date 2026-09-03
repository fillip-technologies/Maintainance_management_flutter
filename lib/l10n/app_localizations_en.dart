// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Fixly';

  @override
  String get appTagline => 'Equipment & Maintenance Management';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get submit => 'Submit';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get search => 'Search';

  @override
  String get close => 'Close';

  @override
  String get signOut => 'Sign Out';

  @override
  String get confirmSignOut => 'Are you sure you want to sign out?';

  @override
  String get language => 'Language';

  @override
  String get switchToHindi => 'हिन्दी';

  @override
  String get switchToEnglish => 'English';

  @override
  String get signIn => 'Sign In';

  @override
  String get email => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get enterEmail => 'Enter your registered email';

  @override
  String get enterPassword => 'Enter your account password';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get authError => 'Authentication Error';

  @override
  String get demoQuickLogin => 'Demo Quick Login';

  @override
  String get demoLoginNotice => 'One-tap role switching for rapid testing';

  @override
  String get emailRequired => 'Please enter both email and password';

  @override
  String get roleHardwareTechnician => 'Hardware Technician';

  @override
  String get roleZoneStaff => 'Zone Staff';

  @override
  String get unassignedQueue => 'Unassigned (Organization Queue)';

  @override
  String get assignedQueue => 'Assigned Queue';

  @override
  String get kpiTotal => 'Total';

  @override
  String get kpiOpen => 'Open';

  @override
  String get kpiOnHold => 'On Hold';

  @override
  String get kpiResolved => 'Resolved';

  @override
  String get tabActiveQueue => 'Active Queue';

  @override
  String get tabOnHold => 'On Hold';

  @override
  String get tabResolvedHistory => 'Resolved / History';

  @override
  String get searchTickets => 'Search ticket ID or device...';

  @override
  String get filterPriority => 'Filter Priority';

  @override
  String get priorityAll => 'All';

  @override
  String get btnStartWork => 'Start Work';

  @override
  String get btnHold => 'Hold';

  @override
  String get btnResolve => 'Resolve';

  @override
  String get noActiveTickets => 'No tickets in active queue';

  @override
  String get allTicketsDone => 'Great job! All assigned tickets are resolved.';

  @override
  String get kpiTotalDevices => 'Total Equipment';

  @override
  String get kpiActiveIssues => 'Active Issues';

  @override
  String get kpiMissingLogs => 'Missing Today\'s Log';

  @override
  String get kpiFaultyDevices => 'Faulty Devices';

  @override
  String get tabDailyChecklist => 'Daily Checklist';

  @override
  String get tabIssues => 'Issues';

  @override
  String get tabCatalogue => 'Equipment Catalogue';

  @override
  String get btnSubmitDailyLog => 'Submit Daily Log';

  @override
  String get btnRaiseIssue => 'Raise Defect';

  @override
  String get logStatusWorking => 'Working';

  @override
  String get logStatusNeedsAttention => 'Needs Attention';

  @override
  String get logStatusNotWorking => 'Not Working';

  @override
  String get logNotesHint => 'Observations, lens cleaned, cable status...';

  @override
  String get logSubmittedSuccess => 'Daily log submitted successfully';

  @override
  String get ticketDetails => 'Ticket Details';

  @override
  String get defectDescription => 'Defect Description';

  @override
  String get timelineHistory => 'Status History & Timeline';

  @override
  String get equipmentUnit => 'Equipment Unit';

  @override
  String get zoneLocation => 'Zone Location';

  @override
  String get reportedBy => 'Reported By';

  @override
  String get assignedTech => 'Assigned Tech';

  @override
  String get btnUpdateStatus => 'Update Ticket Status / Add Work Log';

  @override
  String get noHistory =>
      'No transitions logged yet. Issue is in initial state.';

  @override
  String get timeJustNow => 'Just now';

  @override
  String get updateWorkStatus => 'Update Work Status';

  @override
  String get selectNextStatus => 'Select Next Status';

  @override
  String get workLogLabel => 'Work Log / Comments';

  @override
  String get workLogHint =>
      'Enter details of work performed, parts used, or blockers...';

  @override
  String get attachProofPhoto => 'Proof / Verification Photo (Optional)';

  @override
  String get attachProofButton =>
      'Attach Verification Photo (Camera / Gallery)';

  @override
  String get photoAdded => 'Verification Photo Added';

  @override
  String get photoAddedSubtitle => 'Will be attached to update log';

  @override
  String get takePhotoCamera => 'Take Photo (Camera)';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String confirmTransition(String status) {
    return 'Confirm & Transition to $status';
  }

  @override
  String get raiseEquipmentDefect => 'Raise Equipment Defect';

  @override
  String get selectDevice => 'Select Equipment Unit';

  @override
  String get defectCategory => 'Defect Category';

  @override
  String get selectCategory => 'Select Defect Type';

  @override
  String get severityPriority => 'Severity / Priority';

  @override
  String get defectDetails => 'Defect Details & Symptoms';

  @override
  String get defectSymptomsHint =>
      'Describe the symptoms, error codes, physical damage...';

  @override
  String get attachDefectPhoto => 'Attach Defect Photo';

  @override
  String get attachDefectPhotoButton =>
      'Attach Evidence Photo (Camera / Gallery)';

  @override
  String get defectPhotoAdded => 'Defect Photo Added';

  @override
  String get submitDefectTicket => 'Submit & Raise Maintenance Ticket';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusOnHold => 'On Hold';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusReopened => 'Reopened';

  @override
  String get priorityCritical => 'Critical';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get deviceStatusActive => 'Active';

  @override
  String get deviceStatusMaintenance => 'Maintenance';

  @override
  String get deviceStatusFaulty => 'Faulty';

  @override
  String get deviceStatusProvisioned => 'Provisioned';

  @override
  String get deviceStatusRetired => 'Retired';
}
