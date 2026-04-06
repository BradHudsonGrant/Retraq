import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
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
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n? of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n);
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Retraq'**
  String get appName;

  /// No description provided for @appNameSince.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get appNameSince;

  /// No description provided for @appNameThen.
  ///
  /// In en, this message translates to:
  /// **'Then'**
  String get appNameThen;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navRecap.
  ///
  /// In en, this message translates to:
  /// **'Recap'**
  String get navRecap;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @heroPrompt0.
  ///
  /// In en, this message translates to:
  /// **'What\'s the\nTL;DR of '**
  String get heroPrompt0;

  /// No description provided for @heroPrompt1.
  ///
  /// In en, this message translates to:
  /// **'How was\n'**
  String get heroPrompt1;

  /// No description provided for @heroPrompt2.
  ///
  /// In en, this message translates to:
  /// **'What happened\n'**
  String get heroPrompt2;

  /// No description provided for @heroPrompt3.
  ///
  /// In en, this message translates to:
  /// **'Sum up\n'**
  String get heroPrompt3;

  /// No description provided for @heroPrompt4.
  ///
  /// In en, this message translates to:
  /// **'What stood\nout '**
  String get heroPrompt4;

  /// No description provided for @heroPrompt5.
  ///
  /// In en, this message translates to:
  /// **'Brain dump\nfor '**
  String get heroPrompt5;

  /// No description provided for @heroPrompt6.
  ///
  /// In en, this message translates to:
  /// **'One thing\nabout '**
  String get heroPrompt6;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Brain dump here. Full sentences optional.'**
  String get homeSubtitle;

  /// No description provided for @entryTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Traq title (optional)'**
  String get entryTitleHint;

  /// No description provided for @entryTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Traq title'**
  String get entryTitleLabel;

  /// No description provided for @amHint.
  ///
  /// In en, this message translates to:
  /// **'How did the morning go?'**
  String get amHint;

  /// No description provided for @pmHint.
  ///
  /// In en, this message translates to:
  /// **'How about the rest of the day?'**
  String get pmHint;

  /// No description provided for @saveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save Traq'**
  String get saveEntry;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @journalEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Traq'**
  String get journalEntryLabel;

  /// No description provided for @amLabel.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get amLabel;

  /// No description provided for @pmLabel.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pmLabel;

  /// No description provided for @progressFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Drop your first traq above.'**
  String get progressFirstEntry;

  /// No description provided for @progressWeekCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 traq} other{{count} traqs}} this week — keep going!'**
  String progressWeekCount(int count);

  /// No description provided for @recentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentLabel;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @entrySaved.
  ///
  /// In en, this message translates to:
  /// **'Traq saved'**
  String get entrySaved;

  /// No description provided for @undoLabel.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoLabel;

  /// No description provided for @saveAndSwitch.
  ///
  /// In en, this message translates to:
  /// **'Save and switch?'**
  String get saveAndSwitch;

  /// No description provided for @saveAndSwitchContent.
  ///
  /// In en, this message translates to:
  /// **'Your {period} traq will be saved before switching to {newPeriod}.'**
  String saveAndSwitchContent(String period, String newPeriod);

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @saveAndSwitchButton.
  ///
  /// In en, this message translates to:
  /// **'Save & Switch'**
  String get saveAndSwitchButton;

  /// No description provided for @saveFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get saveFailedMessage;

  /// No description provided for @milestone1.
  ///
  /// In en, this message translates to:
  /// **'Your very first traq!'**
  String get milestone1;

  /// No description provided for @milestone5.
  ///
  /// In en, this message translates to:
  /// **'5 traqs! You\'re off to a great start.'**
  String get milestone5;

  /// No description provided for @milestone10.
  ///
  /// In en, this message translates to:
  /// **'10 traqs! You\'re building a habit.'**
  String get milestone10;

  /// No description provided for @milestone25.
  ///
  /// In en, this message translates to:
  /// **'25 traqs! Look at you go.'**
  String get milestone25;

  /// No description provided for @milestone50.
  ///
  /// In en, this message translates to:
  /// **'50 traqs! That\'s genuinely impressive.'**
  String get milestone50;

  /// No description provided for @milestone100.
  ///
  /// In en, this message translates to:
  /// **'100 traqs! You\'re a pro.'**
  String get milestone100;

  /// No description provided for @milestone250.
  ///
  /// In en, this message translates to:
  /// **'250 traqs! A real treasure trove.'**
  String get milestone250;

  /// No description provided for @milestone500.
  ///
  /// In en, this message translates to:
  /// **'500 traqs! Half a thousand memories.'**
  String get milestone500;

  /// No description provided for @milestone1000.
  ///
  /// In en, this message translates to:
  /// **'1,000 traqs! Legendary status.'**
  String get milestone1000;

  /// No description provided for @entryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 traq} other{{count} traqs}}'**
  String entryCount(int count);

  /// No description provided for @moreEntries.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreEntries(int count);

  /// No description provided for @changeDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Change traq date, currently {date}'**
  String changeDateLabel(String date);

  /// No description provided for @recapTitle.
  ///
  /// In en, this message translates to:
  /// **'Recap'**
  String get recapTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search traqs...'**
  String get searchHint;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @searchEntries.
  ///
  /// In en, this message translates to:
  /// **'Search traqs'**
  String get searchEntries;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No traqs match your search.'**
  String get noSearchResults;

  /// No description provided for @weekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekLabel;

  /// No description provided for @monthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthLabel;

  /// No description provided for @weeklyRecap.
  ///
  /// In en, this message translates to:
  /// **'Weekly Recap'**
  String get weeklyRecap;

  /// No description provided for @weeklyRecapStats.
  ///
  /// In en, this message translates to:
  /// **'{totalEntries} traqs · {activeDays} days · {preferredTime}'**
  String weeklyRecapStats(
    int totalEntries,
    int activeDays,
    String preferredTime,
  );

  /// No description provided for @noEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No traqs yet'**
  String get noEntriesYet;

  /// No description provided for @noEntriesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Your traqs will appear here once you start writing.'**
  String get noEntriesYetMessage;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTitle;

  /// No description provided for @statsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your journey so far.'**
  String get statsSubtitle;

  /// No description provided for @noStatsYet.
  ///
  /// In en, this message translates to:
  /// **'No stats yet'**
  String get noStatsYet;

  /// No description provided for @noStatsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Start traqing to see your patterns and streaks.'**
  String get noStatsYetMessage;

  /// No description provided for @totalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total Traqs'**
  String get totalEntries;

  /// No description provided for @daysJournaled.
  ///
  /// In en, this message translates to:
  /// **'Days Traqed'**
  String get daysJournaled;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @daysSuffix.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysSuffix;

  /// No description provided for @mostActiveDay.
  ///
  /// In en, this message translates to:
  /// **'Most active day: {day}'**
  String mostActiveDay(String day);

  /// No description provided for @moodTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get moodTitle;

  /// No description provided for @moodDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get moodDistribution;

  /// No description provided for @moodAverage.
  ///
  /// In en, this message translates to:
  /// **'Average: {value}'**
  String moodAverage(String value);

  /// No description provided for @moodRough.
  ///
  /// In en, this message translates to:
  /// **'Rough'**
  String get moodRough;

  /// No description provided for @moodLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get moodLow;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodAmazing.
  ///
  /// In en, this message translates to:
  /// **'Amazing'**
  String get moodAmazing;

  /// No description provided for @moodSelectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Mood selector'**
  String get moodSelectorLabel;

  /// No description provided for @moodButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} mood'**
  String moodButtonLabel(String label);

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Your day,\nyour words.'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'No templates. No pressure.\nJust jot down the highlights.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Look back\nwithout stress.'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'A simple calendar shows\nwhat you captured each day.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Private\nby default.'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on your phone.\nNo account needed. Ever.'**
  String get onboardingBody3;

  /// No description provided for @onboardingPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String onboardingPageLabel(int current, int total);

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @getStartedButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedButton;

  /// No description provided for @ageGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Before we begin'**
  String get ageGateTitle;

  /// No description provided for @ageGateDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sorry!'**
  String get ageGateDeniedTitle;

  /// No description provided for @ageGateMessage.
  ///
  /// In en, this message translates to:
  /// **'Retraq is designed for users\naged 13 and older.'**
  String get ageGateMessage;

  /// No description provided for @ageGateDenied.
  ///
  /// In en, this message translates to:
  /// **'Retraq requires users to be 13 years or older.\nPlease come back when you\'re old enough!'**
  String get ageGateDenied;

  /// No description provided for @ageConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'I am 13 or older'**
  String get ageConfirmButton;

  /// No description provided for @ageDenyButton.
  ///
  /// In en, this message translates to:
  /// **'I am under 13'**
  String get ageDenyButton;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get almostThere;

  /// No description provided for @healthDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Retraq is a personal journaling app — not a medical or therapeutic tool. It does not provide health advice, diagnosis, or treatment. If you are in crisis, please contact a mental health professional or call 988 (Suicide & Crisis Lifeline).'**
  String get healthDisclaimer;

  /// No description provided for @healthDisclaimerCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I acknowledge the Health Disclaimer'**
  String get healthDisclaimerCheckbox;

  /// No description provided for @privacyPolicyCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Privacy Policy'**
  String get privacyPolicyCheckbox;

  /// No description provided for @termsCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Use'**
  String get termsCheckbox;

  /// No description provided for @notificationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on track'**
  String get notificationDialogTitle;

  /// No description provided for @notificationDialogContent.
  ///
  /// In en, this message translates to:
  /// **'A gentle daily reminder can help you build a traqing habit. You can change or turn this off anytime in Settings.'**
  String get notificationDialogContent;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @enableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get enableReminders;

  /// No description provided for @unlockBiometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock Retraq'**
  String get unlockBiometric;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get enterPin;

  /// No description provided for @wrongPinMessage.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. {remaining, plural, =1{1 attempt} other{{remaining} attempts}} remaining.'**
  String wrongPinMessage(int remaining);

  /// No description provided for @lockoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait {seconds}s.'**
  String lockoutMessage(int seconds);

  /// No description provided for @updatedPolicies.
  ///
  /// In en, this message translates to:
  /// **'Updated Policies'**
  String get updatedPolicies;

  /// No description provided for @reconsentMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve updated our Privacy Policy and/or Terms of Use. Please review and accept to continue.'**
  String get reconsentMessage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how Retraq feels to you.'**
  String get appearanceSubtitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get themeDay;

  /// No description provided for @themeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get themeNight;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @securitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your traqs private.'**
  String get securitySubtitle;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @appLockEnabled.
  ///
  /// In en, this message translates to:
  /// **'PIN required to open Retraq'**
  String get appLockEnabled;

  /// No description provided for @appLockDisabled.
  ///
  /// In en, this message translates to:
  /// **'No lock — anyone can open the app'**
  String get appLockDisabled;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @changePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new 4-digit PIN'**
  String get changePinSubtitle;

  /// No description provided for @biometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get biometricUnlock;

  /// No description provided for @biometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face to unlock'**
  String get biometricSubtitle;

  /// No description provided for @biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not available on this device'**
  String get biometricUnavailable;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock enabled — you\'ll be prompted next time you open Retraq'**
  String get biometricEnabled;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// No description provided for @allDayNotes.
  ///
  /// In en, this message translates to:
  /// **'All Day Notes'**
  String get allDayNotes;

  /// No description provided for @allDayNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One traq or split AM/PM'**
  String get allDayNotesSubtitle;

  /// No description provided for @allDayOption.
  ///
  /// In en, this message translates to:
  /// **'All Day'**
  String get allDayOption;

  /// No description provided for @openingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Opening Prompt'**
  String get openingPrompt;

  /// No description provided for @asksAboutToday.
  ///
  /// In en, this message translates to:
  /// **'Asks about today'**
  String get asksAboutToday;

  /// No description provided for @asksAboutYesterday.
  ///
  /// In en, this message translates to:
  /// **'Asks about yesterday'**
  String get asksAboutYesterday;

  /// No description provided for @journalEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Traq Title'**
  String get journalEntryTitle;

  /// No description provided for @journalEntryTitleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show or hide title fields in new traqs'**
  String get journalEntryTitleSubtitle;

  /// No description provided for @moodTracking.
  ///
  /// In en, this message translates to:
  /// **'Mood Tracking'**
  String get moodTracking;

  /// No description provided for @moodTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log how you feel with each traq'**
  String get moodTrackingSubtitle;

  /// No description provided for @requireMood.
  ///
  /// In en, this message translates to:
  /// **'Require Mood'**
  String get requireMood;

  /// No description provided for @requireMoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Must pick a mood before saving'**
  String get requireMoodSubtitle;

  /// No description provided for @moodOnlyEntries.
  ///
  /// In en, this message translates to:
  /// **'Mood-Only Traqs'**
  String get moodOnlyEntries;

  /// No description provided for @moodOnlyEntriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save traqs with just a mood, no text'**
  String get moodOnlyEntriesSubtitle;

  /// No description provided for @advancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedTitle;

  /// No description provided for @enterToSave.
  ///
  /// In en, this message translates to:
  /// **'Enter to Save'**
  String get enterToSave;

  /// No description provided for @enterToSaveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Press Enter to save traq instead of new line'**
  String get enterToSaveSubtitle;

  /// No description provided for @bulletPointsOnEnter.
  ///
  /// In en, this message translates to:
  /// **'Bullet Points on Enter'**
  String get bulletPointsOnEnter;

  /// No description provided for @bulletPointsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-insert • when pressing Enter'**
  String get bulletPointsSubtitle;

  /// No description provided for @weekStartsOn.
  ///
  /// In en, this message translates to:
  /// **'Week Starts On'**
  String get weekStartsOn;

  /// No description provided for @amPmSwitchesAt.
  ///
  /// In en, this message translates to:
  /// **'AM/PM Switches At'**
  String get amPmSwitchesAt;

  /// No description provided for @mondayName.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get mondayName;

  /// No description provided for @tuesdayName.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesdayName;

  /// No description provided for @wednesdayName.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesdayName;

  /// No description provided for @thursdayName.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursdayName;

  /// No description provided for @fridayName.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get fridayName;

  /// No description provided for @saturdayName.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturdayName;

  /// No description provided for @sundayName.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sundayName;

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your Data'**
  String get yourData;

  /// No description provided for @exportLabel.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportLabel;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJson;

  /// No description provided for @exportText.
  ///
  /// In en, this message translates to:
  /// **'Export Text'**
  String get exportText;

  /// No description provided for @importLabel.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importLabel;

  /// No description provided for @importFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Import from Backup'**
  String get importFromBackup;

  /// No description provided for @importAccepts.
  ///
  /// In en, this message translates to:
  /// **'Accepts Retraq JSON backup files only'**
  String get importAccepts;

  /// No description provided for @exportScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Export scope'**
  String get exportScopeTitle;

  /// No description provided for @exportScopeContent.
  ///
  /// In en, this message translates to:
  /// **'Export this week\'s traqs or all traqs?\n\nThe exported file will contain your personal traqs and settings. Keep it somewhere safe.'**
  String get exportScopeContent;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @allEntries.
  ///
  /// In en, this message translates to:
  /// **'All Traqs'**
  String get allEntries;

  /// No description provided for @importConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Import {filename}?'**
  String importConfirmTitle(String filename);

  /// No description provided for @importConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This will add traqs from this backup. Duplicates will be skipped.'**
  String get importConfirmContent;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {imported} traqs{skipped}{errors}'**
  String importSuccess(int imported, String skipped, String errors);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed. The file may be corrupted or in the wrong format.'**
  String get importFailed;

  /// No description provided for @filePickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open file picker. Please try again.'**
  String get filePickerFailed;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get exportFailed;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllDataTitle;

  /// No description provided for @deleteAllDataContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all traqs and reset your settings. This cannot be undone.\n\nConsider exporting your data first from the options above.'**
  String get deleteAllDataContent;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm:'**
  String get typeDeleteToConfirm;

  /// No description provided for @typeDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeleteError;

  /// No description provided for @deleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get deleteEverything;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data has been deleted.'**
  String get allDataDeleted;

  /// No description provided for @deleteDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete data. Please try again.'**
  String get deleteDataFailed;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Traq'**
  String get editEntry;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleHint;

  /// No description provided for @entryTextHint.
  ///
  /// In en, this message translates to:
  /// **'Traq text...'**
  String get entryTextHint;

  /// No description provided for @entryTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Traq text'**
  String get entryTextLabel;

  /// No description provided for @deleteEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete traq'**
  String get deleteEntryTooltip;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @entrySavedOverlay.
  ///
  /// In en, this message translates to:
  /// **'Traq saved'**
  String get entrySavedOverlay;

  /// No description provided for @niceOne.
  ///
  /// In en, this message translates to:
  /// **'Nice one ✓'**
  String get niceOne;

  /// No description provided for @dismissLabel.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissLabel;

  /// No description provided for @setPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get setPinTitle;

  /// No description provided for @confirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPinTitle;

  /// No description provided for @setPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN'**
  String get setPinSubtitle;

  /// No description provided for @confirmPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the same PIN again'**
  String get confirmPinSubtitle;

  /// No description provided for @pinTooEasy.
  ///
  /// In en, this message translates to:
  /// **'Too easy to guess. Choose a different PIN.'**
  String get pinTooEasy;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs did not match. Try again.'**
  String get pinMismatch;

  /// No description provided for @setPinButton.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPinButton;

  /// No description provided for @entryActions.
  ///
  /// In en, this message translates to:
  /// **'Traq actions'**
  String get entryActions;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete traq?'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This can\'t be undone.'**
  String get deleteEntryMessage;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @deleteFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete. Please try again.'**
  String get deleteFailedMessage;

  /// No description provided for @numberPadDisabled.
  ///
  /// In en, this message translates to:
  /// **'Number pad, disabled'**
  String get numberPadDisabled;

  /// No description provided for @deleteDigit.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteDigit;

  /// No description provided for @biometricButton.
  ///
  /// In en, this message translates to:
  /// **'Biometric'**
  String get biometricButton;

  /// No description provided for @pinDotsLabel.
  ///
  /// In en, this message translates to:
  /// **'{length} of {maxLength} digits entered{error}'**
  String pinDotsLabel(int length, int maxLength, String error);

  /// No description provided for @monthAtGlance.
  ///
  /// In en, this message translates to:
  /// **'Month at a glance'**
  String get monthAtGlance;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @dayMo.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get dayMo;

  /// No description provided for @dayTu.
  ///
  /// In en, this message translates to:
  /// **'Tu'**
  String get dayTu;

  /// No description provided for @dayWe.
  ///
  /// In en, this message translates to:
  /// **'We'**
  String get dayWe;

  /// No description provided for @dayTh.
  ///
  /// In en, this message translates to:
  /// **'Th'**
  String get dayTh;

  /// No description provided for @dayFr.
  ///
  /// In en, this message translates to:
  /// **'Fr'**
  String get dayFr;

  /// No description provided for @daySa.
  ///
  /// In en, this message translates to:
  /// **'Sa'**
  String get daySa;

  /// No description provided for @daySu.
  ///
  /// In en, this message translates to:
  /// **'Su'**
  String get daySu;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} theme'**
  String themeLabel(String label);

  /// No description provided for @prompt0.
  ///
  /// In en, this message translates to:
  /// **'Just the highlights...'**
  String get prompt0;

  /// No description provided for @prompt1.
  ///
  /// In en, this message translates to:
  /// **'What did you get up to today?'**
  String get prompt1;

  /// No description provided for @prompt2.
  ///
  /// In en, this message translates to:
  /// **'Anything worth remembering?'**
  String get prompt2;

  /// No description provided for @prompt3.
  ///
  /// In en, this message translates to:
  /// **'Drop a breadcrumb for future you.'**
  String get prompt3;

  /// No description provided for @prompt4.
  ///
  /// In en, this message translates to:
  /// **'Sum it up in a few words.'**
  String get prompt4;

  /// No description provided for @prompt5.
  ///
  /// In en, this message translates to:
  /// **'What was the vibe today?'**
  String get prompt5;

  /// No description provided for @prompt6.
  ///
  /// In en, this message translates to:
  /// **'One good thing that happened...'**
  String get prompt6;

  /// No description provided for @prompt7.
  ///
  /// In en, this message translates to:
  /// **'What took up most of your brain today?'**
  String get prompt7;

  /// No description provided for @prompt8.
  ///
  /// In en, this message translates to:
  /// **'If today were a headline, what would it be?'**
  String get prompt8;

  /// No description provided for @prompt9.
  ///
  /// In en, this message translates to:
  /// **'What would you tell a friend about today?'**
  String get prompt9;

  /// No description provided for @prompt10.
  ///
  /// In en, this message translates to:
  /// **'The most unexpected part of today was...'**
  String get prompt10;

  /// No description provided for @prompt11.
  ///
  /// In en, this message translates to:
  /// **'Three words to describe today.'**
  String get prompt11;

  /// No description provided for @prompt12.
  ///
  /// In en, this message translates to:
  /// **'What did you learn today?'**
  String get prompt12;

  /// No description provided for @prompt13.
  ///
  /// In en, this message translates to:
  /// **'What are you grateful for right now?'**
  String get prompt13;

  /// No description provided for @prompt14.
  ///
  /// In en, this message translates to:
  /// **'What drained your energy today?'**
  String get prompt14;

  /// No description provided for @prompt15.
  ///
  /// In en, this message translates to:
  /// **'What gave you energy today?'**
  String get prompt15;

  /// No description provided for @prompt16.
  ///
  /// In en, this message translates to:
  /// **'Describe today in one sentence.'**
  String get prompt16;

  /// No description provided for @prompt17.
  ///
  /// In en, this message translates to:
  /// **'Something you noticed today...'**
  String get prompt17;

  /// No description provided for @prompt18.
  ///
  /// In en, this message translates to:
  /// **'A thought that kept coming back...'**
  String get prompt18;

  /// No description provided for @prompt19.
  ///
  /// In en, this message translates to:
  /// **'The best part of today was...'**
  String get prompt19;

  /// No description provided for @prompt20.
  ///
  /// In en, this message translates to:
  /// **'Something you want to remember...'**
  String get prompt20;

  /// No description provided for @prompt21.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling right now?'**
  String get prompt21;

  /// No description provided for @prompt22.
  ///
  /// In en, this message translates to:
  /// **'What made you smile today?'**
  String get prompt22;

  /// No description provided for @prompt23.
  ///
  /// In en, this message translates to:
  /// **'A small win from today...'**
  String get prompt23;

  /// No description provided for @prompt24.
  ///
  /// In en, this message translates to:
  /// **'What would you do differently?'**
  String get prompt24;

  /// No description provided for @prompt25.
  ///
  /// In en, this message translates to:
  /// **'What are you looking forward to tomorrow?'**
  String get prompt25;

  /// No description provided for @prompt26.
  ///
  /// In en, this message translates to:
  /// **'Something that surprised you...'**
  String get prompt26;

  /// No description provided for @prompt27.
  ///
  /// In en, this message translates to:
  /// **'A moment of calm from today...'**
  String get prompt27;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Retraq'**
  String get notifTitle;

  /// No description provided for @notifMorning0.
  ///
  /// In en, this message translates to:
  /// **'Good morning! Set an intention for today — even one word counts.'**
  String get notifMorning0;

  /// No description provided for @notifMorning1.
  ///
  /// In en, this message translates to:
  /// **'Rise and write. What are you looking forward to today?'**
  String get notifMorning1;

  /// No description provided for @notifMorning2.
  ///
  /// In en, this message translates to:
  /// **'Morning check-in: how are you feeling right now?'**
  String get notifMorning2;

  /// No description provided for @notifMorning3.
  ///
  /// In en, this message translates to:
  /// **'Start your day with a thought. Retraq is ready.'**
  String get notifMorning3;

  /// No description provided for @notifMorning4.
  ///
  /// In en, this message translates to:
  /// **'A fresh page for a fresh day. What\'s on your mind?'**
  String get notifMorning4;

  /// No description provided for @notifEvening0.
  ///
  /// In en, this message translates to:
  /// **'What happened today? Even one sentence counts.'**
  String get notifEvening0;

  /// No description provided for @notifEvening1.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to capture today before it slips away.'**
  String get notifEvening1;

  /// No description provided for @notifEvening2.
  ///
  /// In en, this message translates to:
  /// **'How was your day? A few words is all it takes.'**
  String get notifEvening2;

  /// No description provided for @notifEvening3.
  ///
  /// In en, this message translates to:
  /// **'Hey, how did today go? Drop a quick traq.'**
  String get notifEvening3;

  /// No description provided for @notifEvening4.
  ///
  /// In en, this message translates to:
  /// **'What\'s the TL;DR of today?'**
  String get notifEvening4;

  /// No description provided for @notifEvening5.
  ///
  /// In en, this message translates to:
  /// **'Capture the vibe. Was today a 10 or a meh?'**
  String get notifEvening5;

  /// No description provided for @notifEvening6.
  ///
  /// In en, this message translates to:
  /// **'What made today different from yesterday?'**
  String get notifEvening6;

  /// No description provided for @notifEvening7.
  ///
  /// In en, this message translates to:
  /// **'The best time to traq was this morning. The second best time is now.'**
  String get notifEvening7;

  /// No description provided for @notifEvening8.
  ///
  /// In en, this message translates to:
  /// **'What surprised you today? Write it down before you forget.'**
  String get notifEvening8;

  /// No description provided for @notifGeneral0.
  ///
  /// In en, this message translates to:
  /// **'Retraq is waiting. No pressure, just jot something down.'**
  String get notifGeneral0;

  /// No description provided for @notifGeneral1.
  ///
  /// In en, this message translates to:
  /// **'Ready to write? Your future self will thank you.'**
  String get notifGeneral1;

  /// No description provided for @notifGeneral2.
  ///
  /// In en, this message translates to:
  /// **'Just checking in. What\'s on your mind today?'**
  String get notifGeneral2;

  /// No description provided for @notifGeneral3.
  ///
  /// In en, this message translates to:
  /// **'One small traq, one big habit. You\'ve got this.'**
  String get notifGeneral3;

  /// No description provided for @notifGeneral4.
  ///
  /// In en, this message translates to:
  /// **'Today deserves to be remembered. What stood out?'**
  String get notifGeneral4;

  /// No description provided for @notifGeneral5.
  ///
  /// In en, this message translates to:
  /// **'Your traqs, your pace. Write as much or as little as you\'d like.'**
  String get notifGeneral5;

  /// No description provided for @notifGeneral6.
  ///
  /// In en, this message translates to:
  /// **'Time for a brain dump? Open up and let it flow.'**
  String get notifGeneral6;

  /// No description provided for @notifGeneral7.
  ///
  /// In en, this message translates to:
  /// **'A quick note now saves a forgotten memory later.'**
  String get notifGeneral7;

  /// No description provided for @notifGeneral8.
  ///
  /// In en, this message translates to:
  /// **'Future you is curious about today. Leave a note.'**
  String get notifGeneral8;

  /// No description provided for @notifGeneral9.
  ///
  /// In en, this message translates to:
  /// **'Even busy days deserve a sentence or two.'**
  String get notifGeneral9;

  /// No description provided for @notifGeneral10.
  ///
  /// In en, this message translates to:
  /// **'You don\'t need perfect words. Just real ones.'**
  String get notifGeneral10;

  /// No description provided for @notifGeneral11.
  ///
  /// In en, this message translates to:
  /// **'Quick check: anything worth remembering today?'**
  String get notifGeneral11;

  /// No description provided for @notifGeneral12.
  ///
  /// In en, this message translates to:
  /// **'One minute, one traq. You can do this.'**
  String get notifGeneral12;

  /// No description provided for @notifGeneral13.
  ///
  /// In en, this message translates to:
  /// **'What would you tell a friend about today?'**
  String get notifGeneral13;

  /// No description provided for @notifGeneral14.
  ///
  /// In en, this message translates to:
  /// **'No rules, no word count. Just you and today.'**
  String get notifGeneral14;

  /// No description provided for @notifGeneral15.
  ///
  /// In en, this message translates to:
  /// **'A few taps now, a whole memory saved forever.'**
  String get notifGeneral15;

  /// No description provided for @notifGeneral16.
  ///
  /// In en, this message translates to:
  /// **'Retraq doesn\'t judge. It just listens.'**
  String get notifGeneral16;

  /// No description provided for @notifGeneral17.
  ///
  /// In en, this message translates to:
  /// **'Plot twist: you actually have time for this. Promise.'**
  String get notifGeneral17;

  /// No description provided for @notifWeekend0.
  ///
  /// In en, this message translates to:
  /// **'Lazy weekend? Perfect traqing weather.'**
  String get notifWeekend0;

  /// No description provided for @notifWeekend1.
  ///
  /// In en, this message translates to:
  /// **'Weekends fly by. Capture this one before it does.'**
  String get notifWeekend1;

  /// No description provided for @notifWeekend2.
  ///
  /// In en, this message translates to:
  /// **'No rush today. Take a moment to reflect.'**
  String get notifWeekend2;

  /// No description provided for @notifStreakRisk0.
  ///
  /// In en, this message translates to:
  /// **'Your streak called. It misses you.'**
  String get notifStreakRisk0;

  /// No description provided for @notifStreakRisk1.
  ///
  /// In en, this message translates to:
  /// **'Don\'t let today break your streak — one sentence is enough.'**
  String get notifStreakRisk1;

  /// No description provided for @notifStreakRisk2.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been consistent. Keep it going with a quick traq.'**
  String get notifStreakRisk2;

  /// No description provided for @settingsLegalFooter.
  ///
  /// In en, this message translates to:
  /// **'{appName} v{version}'**
  String settingsLegalFooter(String appName, String version);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @healthDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Disclaimer'**
  String get healthDisclaimerTitle;

  /// No description provided for @exportPiiNote.
  ///
  /// In en, this message translates to:
  /// **'The exported file will contain your personal traqs and settings. Keep it somewhere safe.'**
  String get exportPiiNote;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
