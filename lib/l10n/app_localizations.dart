import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Fixly'**
  String get appName;

  /// The subtitle or tagline of the application
  ///
  /// In en, this message translates to:
  /// **'Equipment & Maintenance Management'**
  String get appTagline;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmSignOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @switchToHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get switchToHindi;

  /// No description provided for @switchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get switchToEnglish;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your account password'**
  String get enterPassword;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Authentication Error'**
  String get authError;

  /// No description provided for @demoQuickLogin.
  ///
  /// In en, this message translates to:
  /// **'Demo Quick Login'**
  String get demoQuickLogin;

  /// No description provided for @demoLoginNotice.
  ///
  /// In en, this message translates to:
  /// **'One-tap role switching for rapid testing'**
  String get demoLoginNotice;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password'**
  String get emailRequired;

  /// No description provided for @roleHardwareTechnician.
  ///
  /// In en, this message translates to:
  /// **'Hardware Technician'**
  String get roleHardwareTechnician;

  /// No description provided for @roleZoneStaff.
  ///
  /// In en, this message translates to:
  /// **'Zone Staff'**
  String get roleZoneStaff;

  /// No description provided for @unassignedQueue.
  ///
  /// In en, this message translates to:
  /// **'Unassigned (Organization Queue)'**
  String get unassignedQueue;

  /// No description provided for @assignedQueue.
  ///
  /// In en, this message translates to:
  /// **'Assigned Queue'**
  String get assignedQueue;

  /// No description provided for @kpiTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get kpiTotal;

  /// No description provided for @kpiOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get kpiOpen;

  /// No description provided for @kpiOnHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get kpiOnHold;

  /// No description provided for @kpiResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get kpiResolved;

  /// No description provided for @tabActiveQueue.
  ///
  /// In en, this message translates to:
  /// **'Active Queue'**
  String get tabActiveQueue;

  /// No description provided for @tabOnHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get tabOnHold;

  /// No description provided for @tabResolvedHistory.
  ///
  /// In en, this message translates to:
  /// **'Resolved / History'**
  String get tabResolvedHistory;

  /// No description provided for @searchTickets.
  ///
  /// In en, this message translates to:
  /// **'Search ticket ID or device...'**
  String get searchTickets;

  /// No description provided for @filterPriority.
  ///
  /// In en, this message translates to:
  /// **'Filter Priority'**
  String get filterPriority;

  /// No description provided for @priorityAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get priorityAll;

  /// No description provided for @btnStartWork.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get btnStartWork;

  /// No description provided for @btnHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get btnHold;

  /// No description provided for @btnResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get btnResolve;

  /// No description provided for @noActiveTickets.
  ///
  /// In en, this message translates to:
  /// **'No tickets in active queue'**
  String get noActiveTickets;

  /// No description provided for @allTicketsDone.
  ///
  /// In en, this message translates to:
  /// **'Great job! All assigned tickets are resolved.'**
  String get allTicketsDone;

  /// No description provided for @kpiTotalDevices.
  ///
  /// In en, this message translates to:
  /// **'Total Equipment'**
  String get kpiTotalDevices;

  /// No description provided for @kpiActiveIssues.
  ///
  /// In en, this message translates to:
  /// **'Active Issues'**
  String get kpiActiveIssues;

  /// No description provided for @kpiMissingLogs.
  ///
  /// In en, this message translates to:
  /// **'Missing Today\'s Log'**
  String get kpiMissingLogs;

  /// No description provided for @kpiFaultyDevices.
  ///
  /// In en, this message translates to:
  /// **'Faulty Devices'**
  String get kpiFaultyDevices;

  /// No description provided for @tabDailyChecklist.
  ///
  /// In en, this message translates to:
  /// **'Daily Checklist'**
  String get tabDailyChecklist;

  /// No description provided for @tabIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get tabIssues;

  /// No description provided for @tabCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Equipment Catalogue'**
  String get tabCatalogue;

  /// No description provided for @btnSubmitDailyLog.
  ///
  /// In en, this message translates to:
  /// **'Submit Daily Log'**
  String get btnSubmitDailyLog;

  /// No description provided for @btnRaiseIssue.
  ///
  /// In en, this message translates to:
  /// **'Raise Defect'**
  String get btnRaiseIssue;

  /// No description provided for @logStatusWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get logStatusWorking;

  /// No description provided for @logStatusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get logStatusNeedsAttention;

  /// No description provided for @logStatusNotWorking.
  ///
  /// In en, this message translates to:
  /// **'Not Working'**
  String get logStatusNotWorking;

  /// No description provided for @logNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Observations, lens cleaned, cable status...'**
  String get logNotesHint;

  /// No description provided for @logSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Daily log submitted successfully'**
  String get logSubmittedSuccess;

  /// No description provided for @ticketDetails.
  ///
  /// In en, this message translates to:
  /// **'Ticket Details'**
  String get ticketDetails;

  /// No description provided for @defectDescription.
  ///
  /// In en, this message translates to:
  /// **'Defect Description'**
  String get defectDescription;

  /// No description provided for @timelineHistory.
  ///
  /// In en, this message translates to:
  /// **'Status History & Timeline'**
  String get timelineHistory;

  /// No description provided for @equipmentUnit.
  ///
  /// In en, this message translates to:
  /// **'Equipment Unit'**
  String get equipmentUnit;

  /// No description provided for @zoneLocation.
  ///
  /// In en, this message translates to:
  /// **'Zone Location'**
  String get zoneLocation;

  /// No description provided for @reportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported By'**
  String get reportedBy;

  /// No description provided for @assignedTech.
  ///
  /// In en, this message translates to:
  /// **'Assigned Tech'**
  String get assignedTech;

  /// No description provided for @btnUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Ticket Status / Add Work Log'**
  String get btnUpdateStatus;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No transitions logged yet. Issue is in initial state.'**
  String get noHistory;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @updateWorkStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Work Status'**
  String get updateWorkStatus;

  /// No description provided for @selectNextStatus.
  ///
  /// In en, this message translates to:
  /// **'Select Next Status'**
  String get selectNextStatus;

  /// No description provided for @workLogLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Log / Comments'**
  String get workLogLabel;

  /// No description provided for @workLogHint.
  ///
  /// In en, this message translates to:
  /// **'Enter details of work performed, parts used, or blockers...'**
  String get workLogHint;

  /// No description provided for @attachProofPhoto.
  ///
  /// In en, this message translates to:
  /// **'Proof / Verification Photo (Optional)'**
  String get attachProofPhoto;

  /// No description provided for @attachProofButton.
  ///
  /// In en, this message translates to:
  /// **'Attach Verification Photo (Camera / Gallery)'**
  String get attachProofButton;

  /// No description provided for @photoAdded.
  ///
  /// In en, this message translates to:
  /// **'Verification Photo Added'**
  String get photoAdded;

  /// No description provided for @photoAddedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Will be attached to update log'**
  String get photoAddedSubtitle;

  /// No description provided for @takePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take Photo (Camera)'**
  String get takePhotoCamera;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @confirmTransition.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Transition to {status}'**
  String confirmTransition(String status);

  /// No description provided for @raiseEquipmentDefect.
  ///
  /// In en, this message translates to:
  /// **'Raise Equipment Defect'**
  String get raiseEquipmentDefect;

  /// No description provided for @selectDevice.
  ///
  /// In en, this message translates to:
  /// **'Select Equipment Unit'**
  String get selectDevice;

  /// No description provided for @defectCategory.
  ///
  /// In en, this message translates to:
  /// **'Defect Category'**
  String get defectCategory;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Defect Type'**
  String get selectCategory;

  /// No description provided for @severityPriority.
  ///
  /// In en, this message translates to:
  /// **'Severity / Priority'**
  String get severityPriority;

  /// No description provided for @defectDetails.
  ///
  /// In en, this message translates to:
  /// **'Defect Details & Symptoms'**
  String get defectDetails;

  /// No description provided for @defectSymptomsHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the symptoms, error codes, physical damage...'**
  String get defectSymptomsHint;

  /// No description provided for @attachDefectPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach Defect Photo'**
  String get attachDefectPhoto;

  /// No description provided for @attachDefectPhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Attach Evidence Photo (Camera / Gallery)'**
  String get attachDefectPhotoButton;

  /// No description provided for @defectPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Defect Photo Added'**
  String get defectPhotoAdded;

  /// No description provided for @submitDefectTicket.
  ///
  /// In en, this message translates to:
  /// **'Submit & Raise Maintenance Ticket'**
  String get submitDefectTicket;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get statusOnHold;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get statusReopened;

  /// No description provided for @priorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get priorityCritical;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @deviceStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get deviceStatusActive;

  /// No description provided for @deviceStatusMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get deviceStatusMaintenance;

  /// No description provided for @deviceStatusFaulty.
  ///
  /// In en, this message translates to:
  /// **'Faulty'**
  String get deviceStatusFaulty;

  /// No description provided for @deviceStatusProvisioned.
  ///
  /// In en, this message translates to:
  /// **'Provisioned'**
  String get deviceStatusProvisioned;

  /// No description provided for @deviceStatusRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get deviceStatusRetired;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @workScope.
  ///
  /// In en, this message translates to:
  /// **'Work & Assignment Scope'**
  String get workScope;

  /// No description provided for @preferencesSystem.
  ///
  /// In en, this message translates to:
  /// **'Preferences & System'**
  String get preferencesSystem;

  /// No description provided for @securitySession.
  ///
  /// In en, this message translates to:
  /// **'Security & Session'**
  String get securitySession;

  /// No description provided for @organizationId.
  ///
  /// In en, this message translates to:
  /// **'Organization ID'**
  String get organizationId;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @assignedLocation.
  ///
  /// In en, this message translates to:
  /// **'Assigned Location'**
  String get assignedLocation;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @orgWideQueue.
  ///
  /// In en, this message translates to:
  /// **'Organization Wide Queue'**
  String get orgWideQueue;

  /// No description provided for @unassignedScope.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Scope'**
  String get unassignedScope;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
