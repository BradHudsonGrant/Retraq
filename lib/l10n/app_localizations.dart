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

  /// No description provided for @navJot.
  ///
  /// In en, this message translates to:
  /// **'Traq'**
  String get navJot;

  /// No description provided for @navRecap.
  ///
  /// In en, this message translates to:
  /// **'Retraq'**
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
  /// **'Tap to traq'**
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

  /// No description provided for @noRecentEntries.
  ///
  /// In en, this message translates to:
  /// **'No traqs yet. Drop a traq?'**
  String get noRecentEntries;

  /// No description provided for @recentEntriesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your recent traqs will appear here.'**
  String get recentEntriesPlaceholder;

  /// Task 2.13 — Empty-recent state headline on Home. Warm/low-pressure tone; reinforces the 'no pressure' brand voice.
  ///
  /// In en, this message translates to:
  /// **'A fresh page'**
  String get emptyRecentHeadline;

  /// Task 2.13 — Empty-recent state body copy on Home. One sentence, supportive, not imperative.
  ///
  /// In en, this message translates to:
  /// **'No traqs from the last two days. Nothing to catch up on — just drop a breadcrumb whenever you\'re ready.'**
  String get emptyRecentBody;

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

  /// No description provided for @writeSomethingFirst.
  ///
  /// In en, this message translates to:
  /// **'Write something first!'**
  String get writeSomethingFirst;

  /// No description provided for @pickMoodToSave.
  ///
  /// In en, this message translates to:
  /// **'Pick a mood to save'**
  String get pickMoodToSave;

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
  /// **'Retraq'**
  String get recapTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your traqs...'**
  String get searchHint;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @searchEntries.
  ///
  /// In en, this message translates to:
  /// **'Search your traqs'**
  String get searchEntries;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No traqs found. Try different words.'**
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

  /// Task 2.5 — left label on the top-level Entries/Insights pill on the Recap screen. Swaps the body between the browse view (Week/Month entries) and the embedded Stats content.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get entriesLabel;

  /// Task 2.5 — right label on the Entries/Insights pill, shows the collapsed Stats content inside Recap.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsLabel;

  /// No description provided for @weeklyRecap.
  ///
  /// In en, this message translates to:
  /// **'Week Retraqd'**
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

  /// No description provided for @noEntriesForWeek.
  ///
  /// In en, this message translates to:
  /// **'No traqs for this week.'**
  String get noEntriesForWeek;

  /// No description provided for @previousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeek;

  /// No description provided for @currentWeek.
  ///
  /// In en, this message translates to:
  /// **'Current week'**
  String get currentWeek;

  /// No description provided for @thisWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeekLabel;

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

  /// No description provided for @streaksSection.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get streaksSection;

  /// No description provided for @longestThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Longest This Month'**
  String get longestThisMonth;

  /// No description provided for @entriesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Entries per week'**
  String get entriesPerWeek;

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

  /// No description provided for @onThisDayLastYear.
  ///
  /// In en, this message translates to:
  /// **'On this day last year...'**
  String get onThisDayLastYear;

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
  /// **'How\'ve you been?\nWhat have you\nbeen up to?'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'If those questions make your\nmind go blank, you\'re in the right place.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Retraq is your\nmemory backup.'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Jot down anything about your day —\na word, a sentence, whatever.\nAnything is a start.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Start simple.\nThat\'s the whole point.'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Want more features later?\nThey\'re all in settings,\nwaiting for when you\'re ready.'**
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
  /// **'Drop your first traq'**
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

  /// Task 12.3 — country-aware age threshold. {minAge} is resolved from the device locale (13 / 14 / 16 per COPPA + GDPR Art. 8 + Quebec Law 25). See locale_age_threshold.dart for the full table.
  ///
  /// In en, this message translates to:
  /// **'Retraq is designed for users\naged {minAge} and older.'**
  String ageGateMessage(int minAge);

  /// Task 12.3 — country-aware denial message matching ageGateMessage threshold.
  ///
  /// In en, this message translates to:
  /// **'Retraq requires users to be {minAge} years or older.\nPlease come back when you\'re old enough!'**
  String ageGateDenied(int minAge);

  /// Task 12.3 — country-aware confirm label reflecting the regional threshold.
  ///
  /// In en, this message translates to:
  /// **'I am {minAge} or older'**
  String ageConfirmButton(int minAge);

  /// Task 12.3 — country-aware deny label.
  ///
  /// In en, this message translates to:
  /// **'I am under {minAge}'**
  String ageDenyButton(int minAge);

  /// No description provided for @ageGateContactGuardian.
  ///
  /// In en, this message translates to:
  /// **'If this was entered in error, please contact a parent or guardian.'**
  String get ageGateContactGuardian;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get almostThere;

  /// Task 2.6 — Shown on the consent page when the user has prior consent on record (cross-install marker present). Replaces 'Almost there!' so reinstall users feel recognised. Consent itself is still required on every install.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBackTitle;

  /// Task 2.6 — Subtitle on the consent page for the returning-user path explaining why consent is still required.
  ///
  /// In en, this message translates to:
  /// **'We still need you to re-accept these, but we won\'t walk you through the intros again.'**
  String get welcomeBackSubtitle;

  /// Health-disclaimer body. {crisisContact} is injected from CrisisContacts.formatInline for the user's locale. Task 12.16 — never hardcode the US/Canada 988 number; the helper resolves per-region.
  ///
  /// In en, this message translates to:
  /// **'Retraq is a personal journaling app — not a medical or therapeutic tool. It does not provide health advice, diagnosis, or treatment. If you are in crisis, please contact a mental health professional or call {crisisContact}.'**
  String healthDisclaimer(String crisisContact);

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

  /// No description provided for @consentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save consent. Please try again.'**
  String get consentSaveFailed;

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

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPin;

  /// No description provided for @forgotPinMessage.
  ///
  /// In en, this message translates to:
  /// **'If you\'ve forgotten your PIN, you can reset the app. This will permanently delete all your traqs and data. You can export first to save them.'**
  String get forgotPinMessage;

  /// No description provided for @resetApp.
  ///
  /// In en, this message translates to:
  /// **'Reset App'**
  String get resetApp;

  /// Button on the Forgot PIN dialog that lets the user export their data before the destructive reset.
  ///
  /// In en, this message translates to:
  /// **'Export first'**
  String get exportBeforeReset;

  /// Biometric prompt shown before the destructive reset-app action fires.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you before resetting Retraq'**
  String get resetAppBiometricReason;

  /// No description provided for @resetAppBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric check failed. Try again or cancel.'**
  String get resetAppBiometricFailed;

  /// Task 10.1 — Settings → Data section heading for the Sentry opt-in toggle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsLabel;

  /// Task 10.1 — Settings row title for the crash-reporting opt-in toggle.
  ///
  /// In en, this message translates to:
  /// **'Help improve Retraq'**
  String get helpImproveRetraq;

  /// Task 10.1 — Settings row subtitle explaining the opt-in scope. Keep it short and truthful; the full details live in the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Send anonymous crash reports so we can fix bugs. No traq content, mood, or timestamps are ever included.'**
  String get helpImproveRetraqBody;

  /// Task 11.13 — Settings row title for the local-counter kill switch. Controls whether feature counters / session stamps are written to the local DB. Never sent anywhere.
  ///
  /// In en, this message translates to:
  /// **'Keep usage stats on this device'**
  String get keepUsageStats;

  /// Task 11.13 — Settings row subtitle for the usage-stats kill switch. Emphasises the local-only nature to avoid confusion with Diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Local counters only. Never sent anywhere. Off = your taps aren\'t counted.'**
  String get keepUsageStatsBody;

  /// Task 3.2 — non-dismissible SnackBar shown for 10 seconds after the user confirms a Forgot-PIN reset. Tapping the action cancels the timer and leaves all data intact.
  ///
  /// In en, this message translates to:
  /// **'Erasing in {seconds}s — tap to cancel'**
  String resetAppUndoToast(int seconds);

  /// SnackBar action label on the reset-countdown toast. Task 3.2.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get resetAppUndoCancel;

  /// Confirmation toast after the user cancels the reset within the 10-second undo window. Task 3.2.
  ///
  /// In en, this message translates to:
  /// **'Reset cancelled. Your data is safe.'**
  String get resetAppCancelled;

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
  /// **'We\'ve updated our Privacy Policy, Terms of Use, and/or Health Disclaimer. Please review and accept to continue.'**
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

  /// No description provided for @biometricEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock enabled — you\'ll be prompted next time you open Retraq'**
  String get biometricEnabledMessage;

  /// No description provided for @appLockA11y.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockA11y;

  /// No description provided for @biometricUnlockA11y.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get biometricUnlockA11y;

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

  /// No description provided for @bionicReading.
  ///
  /// In en, this message translates to:
  /// **'Bionic Reading'**
  String get bionicReading;

  /// No description provided for @bionicReadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bolds the start of each word for faster reading'**
  String get bionicReadingSubtitle;

  /// No description provided for @onDeviceAiRecap.
  ///
  /// In en, this message translates to:
  /// **'On-Device AI Recap'**
  String get onDeviceAiRecap;

  /// No description provided for @onDeviceAiRecapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your phone\'s built-in AI to write weekly recaps. Entries never leave your device.'**
  String get onDeviceAiRecapSubtitle;

  /// No description provided for @onDeviceAiRecapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not supported on this device'**
  String get onDeviceAiRecapUnavailable;

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

  /// No description provided for @weekStartsOnA11y.
  ///
  /// In en, this message translates to:
  /// **'Week starts on {day}'**
  String weekStartsOnA11y(String day);

  /// No description provided for @amPmSwitchesAtA11y.
  ///
  /// In en, this message translates to:
  /// **'AM/PM switches at {time}'**
  String amPmSwitchesAtA11y(String time);

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

  /// Summary shown after a successful import. Uses ICU plurals for each counter; skipped/errors collapse to empty when zero.
  ///
  /// In en, this message translates to:
  /// **'{imported, plural, =1{Imported 1 traq} other{Imported {imported} traqs}}{skipped, plural, =0{} =1{, 1 duplicate skipped} other{, {skipped} duplicates skipped}}{errors, plural, =0{} =1{, 1 error} other{, {errors} errors}}'**
  String importSuccess(int imported, int skipped, int errors);

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

  /// No description provided for @allDataDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get allDataDeletedTitle;

  /// No description provided for @allDataDeletedBody.
  ///
  /// In en, this message translates to:
  /// **'Your traqs, settings and consent records have been cleared. Retraq will close now — reopen it to start fresh.'**
  String get allDataDeletedBody;

  /// No description provided for @closeAppButton.
  ///
  /// In en, this message translates to:
  /// **'Close Retraq'**
  String get closeAppButton;

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

  /// No description provided for @entryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Traq is empty. Add some text, a title, or a mood.'**
  String get entryEmptyMessage;

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

  /// No description provided for @choosePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a {length}-digit PIN'**
  String choosePinSubtitle(int length);

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

  /// No description provided for @fourDigits.
  ///
  /// In en, this message translates to:
  /// **'4 digits'**
  String get fourDigits;

  /// No description provided for @sixDigits.
  ///
  /// In en, this message translates to:
  /// **'6 digits'**
  String get sixDigits;

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

  /// Task 7.4 — shown in WeekDayList when a day has zero journal entries.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get noEntriesForDay;

  /// Task 7.9 — NudgeCard reminder-time summary, e.g. 'Daily at 8:30 PM'. {time} is pre-formatted to user locale.
  ///
  /// In en, this message translates to:
  /// **'Daily at {time}'**
  String dailyAtTime(String time);

  /// Task 2.8 — Middle action in the AM/PM switch dialog shown when the user has typed entry text. Drops the typed text and flips the day period without saving.
  ///
  /// In en, this message translates to:
  /// **'Discard & Switch'**
  String get discardAndSwitchButton;

  /// Task 3.9 — Title of the warning dialog shown before invoking the share sheet for a plaintext export.
  ///
  /// In en, this message translates to:
  /// **'Share this file?'**
  String get plaintextExportWarningTitle;

  /// Task 3.9 — Body copy of the plaintext-export warning dialog. Reads in the brand voice: plain, non-alarmist, informative.
  ///
  /// In en, this message translates to:
  /// **'This file contains your journal in a readable format. The app you pick will receive everything you\'ve written. Only share with apps you trust, like your own file manager or cloud drive.'**
  String get plaintextExportWarningBody;

  /// Task 3.9 — Confirm button on the plaintext-export warning dialog.
  ///
  /// In en, this message translates to:
  /// **'Share anyway'**
  String get plaintextExportShareAnyway;

  /// Task 2.7 — Trailing button on the onboarding consent row that opens the legal document. Separated from the checkbox label tap target to avoid accidental navigation when toggling consent.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewLabel;

  /// Task 2.9 — Semantics + delete-icon tooltip on the date-override chip when an alternate day has been picked for the entry.
  ///
  /// In en, this message translates to:
  /// **'Reset to today'**
  String get resetToTodayLabel;

  /// Task 2.14 — Subtitle under the nudge time-picker explaining that the reminder is suppressed on days the user already journaled.
  ///
  /// In en, this message translates to:
  /// **'We\'ll only remind you if you haven\'t journaled yet.'**
  String get nudgeSkipIfJournaledHint;

  /// Task 2.14 — Label on the Change Time button in the NudgeCard.
  ///
  /// In en, this message translates to:
  /// **'Change Time'**
  String get nudgeChangeTime;

  /// Task 2.14 — Body copy inside the Settings NudgeCard explaining the purpose of the daily reminder.
  ///
  /// In en, this message translates to:
  /// **'Get a quick nudge to drop a breadcrumb before you forget your day.'**
  String get nudgeCardBody;

  /// Task 2.3 — Shown when tapping a bar on the weekly-trend chart. {range} is a date-range string (e.g. 'Mar 3 – Mar 9'); {count} is the number of entries in that week.
  ///
  /// In en, this message translates to:
  /// **'{range}: {count, plural, =0{no entries} =1{1 entry} other{{count} entries}}'**
  String weekEntryCountSnackbar(String range, int count);

  /// Task 2.11 — Screen-reader label for the aggregated stats card grid.
  ///
  /// In en, this message translates to:
  /// **'Statistics overview'**
  String get statisticsOverview;

  /// Task 2.11 — Screen-reader label for a recent-day card showing a snippet of its entry. {dayLabel} is a formatted day name (e.g. 'Monday'); {preview} is the first few words of the entry.
  ///
  /// In en, this message translates to:
  /// **'Entry for {dayLabel}: {preview}'**
  String entryForDayPreview(String dayLabel, String preview);

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

  /// No description provided for @calendarDayA11y.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String calendarDayA11y(int day);

  /// No description provided for @calendarDayTodaySuffix.
  ///
  /// In en, this message translates to:
  /// **', today'**
  String get calendarDayTodaySuffix;

  /// No description provided for @calendarDayHasEntriesSuffix.
  ///
  /// In en, this message translates to:
  /// **', has entries'**
  String get calendarDayHasEntriesSuffix;

  /// No description provided for @calendarDaySelectedSuffix.
  ///
  /// In en, this message translates to:
  /// **', selected'**
  String get calendarDaySelectedSuffix;

  /// No description provided for @entryCardA11y.
  ///
  /// In en, this message translates to:
  /// **'Journal traq for {dateLabel}'**
  String entryCardA11y(String dateLabel);

  /// No description provided for @entryOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Traq options'**
  String get entryOptionsTooltip;

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

  /// No description provided for @nudgeDescription.
  ///
  /// In en, this message translates to:
  /// **'Get a quick nudge to drop a breadcrumb before you forget your day.'**
  String get nudgeDescription;

  /// No description provided for @changeTime.
  ///
  /// In en, this message translates to:
  /// **'Change Time'**
  String get changeTime;

  /// No description provided for @shareDay.
  ///
  /// In en, this message translates to:
  /// **'Share Day'**
  String get shareDay;

  /// No description provided for @noEntryForDay.
  ///
  /// In en, this message translates to:
  /// **'No traqs for this day'**
  String get noEntryForDay;

  /// No description provided for @noEntriesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No traqs this month.'**
  String get noEntriesThisMonth;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Retraq'**
  String get notifTitle;

  /// No description provided for @notifDaily0.
  ///
  /// In en, this message translates to:
  /// **'Quick — what happened today? Even one word counts.'**
  String get notifDaily0;

  /// No description provided for @notifDaily1.
  ///
  /// In en, this message translates to:
  /// **'30 seconds. One traq. You\'ll thank yourself later.'**
  String get notifDaily1;

  /// No description provided for @notifDaily2.
  ///
  /// In en, this message translates to:
  /// **'Jot something down before today disappears.'**
  String get notifDaily2;

  /// No description provided for @notifDaily3.
  ///
  /// In en, this message translates to:
  /// **'Future you wants to know what happened today.'**
  String get notifDaily3;

  /// No description provided for @notifDaily4.
  ///
  /// In en, this message translates to:
  /// **'Don\'t let today vanish. Drop a traq.'**
  String get notifDaily4;

  /// No description provided for @notifWeekly0.
  ///
  /// In en, this message translates to:
  /// **'Your week\'s been retraqd. Take a look back.'**
  String get notifWeekly0;

  /// No description provided for @notifWeekly1.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what you got up to this week.'**
  String get notifWeekly1;

  /// No description provided for @notifReengage0.
  ///
  /// In en, this message translates to:
  /// **'It\'s been a few days. Drop a quick traq so you don\'t lose the week.'**
  String get notifReengage0;

  /// No description provided for @notifReengage1.
  ///
  /// In en, this message translates to:
  /// **'Your week is disappearing. Takes 10 seconds to save it.'**
  String get notifReengage1;

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

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @healthDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Disclaimer'**
  String get healthDisclaimerTitle;

  /// No description provided for @legalFooterTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get legalFooterTerms;

  /// No description provided for @legalFooterHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get legalFooterHealth;

  /// No description provided for @legalFooterLicenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get legalFooterLicenses;

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
