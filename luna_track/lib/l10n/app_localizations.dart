import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Luna Track'**
  String get appName;

  /// No description provided for @cycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get cycle;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @howAreYouToday.
  ///
  /// In en, this message translates to:
  /// **'How are you today?'**
  String get howAreYouToday;

  /// No description provided for @saveTodayLog.
  ///
  /// In en, this message translates to:
  /// **'Save today\'s log'**
  String get saveTodayLog;

  /// No description provided for @saveLog.
  ///
  /// In en, this message translates to:
  /// **'Save log'**
  String get saveLog;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get saved;

  /// No description provided for @savedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally'**
  String get savedLocally;

  /// No description provided for @flow.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get flow;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @symptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptoms;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @heavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get heavy;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @happy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get happy;

  /// No description provided for @calm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get calm;

  /// No description provided for @anxious.
  ///
  /// In en, this message translates to:
  /// **'Anxious'**
  String get anxious;

  /// No description provided for @sad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get sad;

  /// No description provided for @irritable.
  ///
  /// In en, this message translates to:
  /// **'Irritable'**
  String get irritable;

  /// No description provided for @tired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get tired;

  /// No description provided for @cramps.
  ///
  /// In en, this message translates to:
  /// **'Cramps'**
  String get cramps;

  /// No description provided for @headache.
  ///
  /// In en, this message translates to:
  /// **'Headache'**
  String get headache;

  /// No description provided for @bloating.
  ///
  /// In en, this message translates to:
  /// **'Bloating'**
  String get bloating;

  /// No description provided for @backPain.
  ///
  /// In en, this message translates to:
  /// **'Back pain'**
  String get backPain;

  /// No description provided for @nausea.
  ///
  /// In en, this message translates to:
  /// **'Nausea'**
  String get nausea;

  /// No description provided for @fatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get fatigue;

  /// No description provided for @dayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String dayOf(int day, int total);

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String daysLeft(int count);

  /// No description provided for @lastDayOfCycle.
  ///
  /// In en, this message translates to:
  /// **'Last day of cycle'**
  String get lastDayOfCycle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @logged.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get logged;

  /// No description provided for @noLogForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No log for this day'**
  String get noLogForThisDay;

  /// No description provided for @addLog.
  ///
  /// In en, this message translates to:
  /// **'Add log'**
  String get addLog;

  /// No description provided for @editLog.
  ///
  /// In en, this message translates to:
  /// **'Edit log'**
  String get editLog;

  /// No description provided for @onCycle.
  ///
  /// In en, this message translates to:
  /// **'On cycle'**
  String get onCycle;

  /// No description provided for @avgCycle.
  ///
  /// In en, this message translates to:
  /// **'avg cycle'**
  String get avgCycle;

  /// No description provided for @avgPeriod.
  ///
  /// In en, this message translates to:
  /// **'avg period'**
  String get avgPeriod;

  /// No description provided for @logsTotal.
  ///
  /// In en, this message translates to:
  /// **'logs total'**
  String get logsTotal;

  /// No description provided for @topSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Top symptoms'**
  String get topSymptoms;

  /// No description provided for @moodBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Mood breakdown'**
  String get moodBreakdown;

  /// No description provided for @cycleHistory.
  ///
  /// In en, this message translates to:
  /// **'Cycle length history'**
  String get cycleHistory;

  /// No description provided for @energySleep.
  ///
  /// In en, this message translates to:
  /// **'Energy & sleep (4 weeks)'**
  String get energySleep;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @startLogging.
  ///
  /// In en, this message translates to:
  /// **'Start logging your cycle to see insights'**
  String get startLogging;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get personalInfo;

  /// No description provided for @cycleSettings.
  ///
  /// In en, this message translates to:
  /// **'Cycle settings'**
  String get cycleSettings;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @avgCycleLength.
  ///
  /// In en, this message translates to:
  /// **'Average cycle length'**
  String get avgCycleLength;

  /// No description provided for @periodDuration.
  ///
  /// In en, this message translates to:
  /// **'Period duration'**
  String get periodDuration;

  /// No description provided for @lastPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'Last period start'**
  String get lastPeriodStart;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @periodBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Has your period started?'**
  String get periodBannerTitle;

  /// No description provided for @periodBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Predicted: {date}'**
  String periodBannerSubtitle(String date);

  /// No description provided for @yesStarted.
  ///
  /// In en, this message translates to:
  /// **'Yes, it started'**
  String get yesStarted;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet, remind later'**
  String get notYet;

  /// No description provided for @periodConfirmed.
  ///
  /// In en, this message translates to:
  /// **'New period recorded!'**
  String get periodConfirmed;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Luna Track'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your cycle smartly'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @cycleInfo.
  ///
  /// In en, this message translates to:
  /// **'Cycle information'**
  String get cycleInfo;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @lastPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Last period start date'**
  String get lastPeriodTitle;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @pleasePickDate.
  ///
  /// In en, this message translates to:
  /// **'Please select your last period start date'**
  String get pleasePickDate;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get register;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get haveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
