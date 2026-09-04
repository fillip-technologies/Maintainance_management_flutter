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
  String get forgotPassword => 'Forgot Password?';

  @override
  String get secureConnectionNotice => 'Enterprise Maintenance Network';

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
  String get tabResolvedHistory => 'Resolved';

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
  String get deviceStatusProvisioned => 'In Stock';

  @override
  String get deviceStatusRetired => 'Removed / Retired';

  @override
  String get profile => 'Profile';

  @override
  String get workScope => 'Work & Assignment Scope';

  @override
  String get preferencesSystem => 'Preferences & System';

  @override
  String get securitySession => 'Security & Session';

  @override
  String get organizationId => 'Organization ID';

  @override
  String get userId => 'User ID';

  @override
  String get assignedLocation => 'Assigned Location';

  @override
  String get accountStatus => 'Account Status';

  @override
  String get activeStatus => 'Active';

  @override
  String get appVersion => 'App Version';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get role => 'Role';

  @override
  String get orgWideQueue => 'Organization Wide Queue';

  @override
  String get unassignedScope => 'Unassigned Scope';

  @override
  String get btnDecommissionReplace => 'Decommission & Replace';

  @override
  String get decommissionHeading => 'Decommission Equipment';

  @override
  String get decommissionReason => 'Reason for Removal';

  @override
  String get reasonPhysicalDamage => 'Physical Damage / Smashed';

  @override
  String get reasonBurntWater => 'Burnt / Water Damage';

  @override
  String get reasonUnrepairable => 'Unrepairable Defect';

  @override
  String get reasonObsolete => 'Obsolete / Scrapped';

  @override
  String get replacementOptions => 'Replacement Option';

  @override
  String get replacementOptionSpares => 'Select Spare from Stock';

  @override
  String get replacementOptionNew => 'Register New Hardware';

  @override
  String get replacementOptionNone => 'Decommission Only (No Replacement)';

  @override
  String get replacementSuccess =>
      'Hardware decommissioned & replacement logged';

  @override
  String get hardwareStatus => 'Hardware Status';

  @override
  String get filterRetired => 'Removed';

  @override
  String get hardwareCode => 'Hardware Code';

  @override
  String get deploySpareTitle => 'Available Spares in Stock';

  @override
  String get realtimeLive => 'Live';

  @override
  String get realtimeConnecting => 'Connecting...';

  @override
  String get realtimeOffline => 'Offline';

  @override
  String get newIssueAlertTitle => 'New Defect Reported';

  @override
  String get issueStartedAlert => 'Technician started work on equipment';

  @override
  String get issueResolvedAlert => 'Issue marked resolved by technician';

  @override
  String get deviceCheckedLive => 'Unit verified by colleague';

  @override
  String get viewTicket => 'View Ticket';

  @override
  String get stepWhatHappened => '1. What happened to the equipment?';

  @override
  String get stepWhatDidYouDo => '2. What action did you take?';

  @override
  String get actionRemovedOnly => 'Removed Only (Slot Left Empty)';

  @override
  String get actionRemovedOnlySub =>
      'Uninstalled from mounting; no spare available';

  @override
  String get actionReplacedFromStock => 'Replaced with Spare from Inventory';

  @override
  String get actionReplacedFromStockSub =>
      'Installed working spare unit from stockroom';

  @override
  String get availableSparesHeading => 'Available Spares in Stockroom';

  @override
  String get noSparesAvailable => 'No spare units available in stockroom';

  @override
  String get selectSparePrompt => 'Tap to select the spare unit installed:';

  @override
  String get selectSpareToProceed =>
      'Please select a spare unit from the list to continue';

  @override
  String get optionalNoteHint => 'Optional technician note...';

  @override
  String get btnSubmitAndClose => 'Done • Submit & Close Ticket';

  @override
  String get submittingDecommission => 'Submitting...';

  @override
  String get selectedSpareBadge => 'SELECTED';

  @override
  String get searchSparesHint => 'Search spare by name or code...';

  @override
  String get btnBulkDefect => 'Bulk Defect';

  @override
  String get raiseBulkDefectTitle => 'Raise Bulk Defect';

  @override
  String get raiseBulkDefectSubtitle =>
      'Report identical issue on multiple units (1–50)';

  @override
  String selectEquipmentUnits(int count) {
    return 'Select Equipment ($count/50)';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get clearSelection => 'Clear';

  @override
  String get searchUnitsHint => 'Search unit by name, serial number or type...';

  @override
  String get noMatchingUnits => 'No matching equipment units found';

  @override
  String get loadingCategories => 'Loading defect categories...';

  @override
  String get noCategoriesFound =>
      'No defect categories found. Please contact an administrator.';

  @override
  String get selectCategoryHint => 'Select Defect Category';

  @override
  String get bulkDefectDescriptionLabel =>
      'Defect Description & Shared Symptoms';

  @override
  String get bulkDefectDescriptionHint =>
      'Describe common symptoms, power failure, batch damage, network outage...';

  @override
  String get btnSelectUnitsFirst => 'Select Units Above to Report Defect';

  @override
  String btnRaiseBulkDefect(int count) {
    return 'Raise Defect Ticket on $count Unit(s)';
  }

  @override
  String get submittingBulkDefect => 'Raising Defects...';

  @override
  String get errSelectAtLeastOneUnit =>
      'Please select at least 1 equipment unit';

  @override
  String get errMaxUnitsLimit =>
      'Maximum limit of 50 units reached for a single bulk ticket';

  @override
  String get errRetiredUnitSelected =>
      'Cannot raise defects on retired equipment';

  @override
  String get errSelectCategory => 'Please select a defect category';

  @override
  String get errProvideDescription =>
      'Please provide a clear description of the defect';

  @override
  String bulkDefectSuccessMsg(int count) {
    return '$count bulk defect tickets raised successfully';
  }

  @override
  String get errFailedToRaiseBulk => 'Failed to raise bulk issues';

  @override
  String get errFailedToLoadCategories => 'Failed to load defect categories';

  @override
  String get viewGrouped => 'Grouped';

  @override
  String get viewFlat => 'List';

  @override
  String unitsCount(int count) {
    return '$count Units';
  }

  @override
  String get singleUnitCount => '1 Unit';

  @override
  String get selectAllInGroup => 'Select Group';

  @override
  String get deselectGroup => 'Deselect';

  @override
  String groupSelectedCount(int selected, int total) {
    return '$selected/$total selected';
  }

  @override
  String get filterByHardwareType => 'Filter by Type';

  @override
  String get allTypes => 'All Types';

  @override
  String get collapseAll => 'Collapse All';

  @override
  String get expandAll => 'Expand All';

  @override
  String get allHardware => 'All Hardware';

  @override
  String categoriesCount(int count) {
    return '$count Categories';
  }

  @override
  String get singleCategory => '1 Category';

  @override
  String unitsAffectedBadge(int count) {
    return '$count Units Affected';
  }

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get applyToSelected => 'Apply to Selected';

  @override
  String get actionMarkResolved => 'Mark Resolved';

  @override
  String get actionStartWork => 'Start Work';

  @override
  String get actionHold => 'Place on Hold';

  @override
  String get selectMode => 'Select';

  @override
  String get doneSelecting => 'Done';

  @override
  String get btnBulkResolve => 'Bulk Resolve';

  @override
  String get bulkResolveTitle => 'Bulk Resolve Issues';

  @override
  String get bulkResolveSubtitle =>
      'Batch update status for multiple tickets (1–50)';

  @override
  String selectTickets(int count) {
    return 'Select Tickets ($count/50)';
  }

  @override
  String get searchTicketsHint =>
      'Search ticket by ID, device, category or zone...';

  @override
  String get resolutionNotesLabel => 'Technician Resolution / Work Notes';

  @override
  String get resolutionNotesHint =>
      'Explain steps taken, repairs made, or reason for status update...';

  @override
  String btnApplyStatusToTickets(String status, int count) {
    return 'Apply $status to $count Ticket(s)';
  }

  @override
  String bulkStatusSuccessMsg(int count, String status) {
    return '$count tickets updated to $status';
  }

  @override
  String get errSelectAtLeastOneTicket => 'Please select at least 1 ticket';

  @override
  String get errMaxTicketsLimit =>
      'Maximum limit of 50 tickets can be updated at once';

  @override
  String get presetPowerRestored => 'Main power supply restored';

  @override
  String get presetBatchRepaired => 'Batch repair completed and verified';

  @override
  String get presetFirmwareUpdated => 'Firmware updated & rebooted';

  @override
  String get presetCablesTested => 'Cables re-seated & connectivity verified';
}
