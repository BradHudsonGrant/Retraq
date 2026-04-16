// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Retraq';

  @override
  String get navJot => 'Jot';

  @override
  String get navRecap => 'Recap';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get heroPrompt0 => 'What\'s the\nTL;DR of ';

  @override
  String get heroPrompt1 => 'How was\n';

  @override
  String get heroPrompt2 => 'What happened\n';

  @override
  String get heroPrompt3 => 'Sum up\n';

  @override
  String get heroPrompt4 => 'What stood\nout ';

  @override
  String get heroPrompt5 => 'Brain dump\nfor ';

  @override
  String get heroPrompt6 => 'One thing\nabout ';

  @override
  String get homeSubtitle => 'Brain dump here. Full sentences optional.';

  @override
  String get entryTitleHint => 'Traq title (optional)';

  @override
  String get entryTitleLabel => 'Traq title';

  @override
  String get amHint => 'How did the morning go?';

  @override
  String get pmHint => 'How about the rest of the day?';

  @override
  String get saveEntry => 'Save Traq';

  @override
  String get saving => 'Saving...';

  @override
  String get journalEntryLabel => 'Traq';

  @override
  String get amLabel => 'AM';

  @override
  String get pmLabel => 'PM';

  @override
  String get progressFirstEntry => 'Drop your first traq above.';

  @override
  String progressWeekCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count traqs',
      one: '1 traq',
    );
    return '$_temp0 this week — keep going!';
  }

  @override
  String get recentLabel => 'Recent';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get noRecentEntries => 'No traqs yet. Drop a traq?';

  @override
  String get recentEntriesPlaceholder => 'Your recent traqs will appear here.';

  @override
  String get emptyRecentHeadline => 'A fresh page';

  @override
  String get emptyRecentBody =>
      'No traqs from the last two days. Nothing to catch up on — just drop a breadcrumb whenever you\'re ready.';

  @override
  String get entrySaved => 'Traq saved';

  @override
  String get undoLabel => 'Undo';

  @override
  String get saveAndSwitch => 'Save and switch?';

  @override
  String saveAndSwitchContent(String period, String newPeriod) {
    return 'Your $period traq will be saved before switching to $newPeriod.';
  }

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get saveAndSwitchButton => 'Save & Switch';

  @override
  String get saveFailedMessage => 'Failed to save. Please try again.';

  @override
  String get writeSomethingFirst => 'Write something first!';

  @override
  String get pickMoodToSave => 'Pick a mood to save';

  @override
  String get milestone1 => 'Your very first traq!';

  @override
  String get milestone5 => '5 traqs! You\'re off to a great start.';

  @override
  String get milestone10 => '10 traqs! You\'re building a habit.';

  @override
  String get milestone25 => '25 traqs! Look at you go.';

  @override
  String get milestone50 => '50 traqs! That\'s genuinely impressive.';

  @override
  String get milestone100 => '100 traqs! You\'re a pro.';

  @override
  String get milestone250 => '250 traqs! A real treasure trove.';

  @override
  String get milestone500 => '500 traqs! Half a thousand memories.';

  @override
  String get milestone1000 => '1,000 traqs! Legendary status.';

  @override
  String entryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count traqs',
      one: '1 traq',
    );
    return '$_temp0';
  }

  @override
  String moreEntries(int count) {
    return '+$count more';
  }

  @override
  String changeDateLabel(String date) {
    return 'Change traq date, currently $date';
  }

  @override
  String get recapTitle => 'Recap';

  @override
  String get searchHint => 'Search your traqs...';

  @override
  String get closeSearch => 'Close search';

  @override
  String get searchEntries => 'Search your traqs';

  @override
  String get searching => 'Searching...';

  @override
  String get noSearchResults => 'No traqs found. Try different words.';

  @override
  String get weekLabel => 'Week';

  @override
  String get monthLabel => 'Month';

  @override
  String get weeklyRecap => 'Week Retraqd';

  @override
  String weeklyRecapStats(
    int totalEntries,
    int activeDays,
    String preferredTime,
  ) {
    return '$totalEntries traqs · $activeDays days · $preferredTime';
  }

  @override
  String get noEntriesYet => 'No traqs yet';

  @override
  String get noEntriesYetMessage =>
      'Your traqs will appear here once you start writing.';

  @override
  String get noEntriesForWeek => 'No traqs for this week.';

  @override
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get currentWeek => 'Current week';

  @override
  String get thisWeekLabel => 'This week';

  @override
  String get statsTitle => 'Stats';

  @override
  String get statsSubtitle => 'Your journey so far.';

  @override
  String get noStatsYet => 'No stats yet';

  @override
  String get noStatsYetMessage =>
      'Start traqing to see your patterns and streaks.';

  @override
  String get totalEntries => 'Total Traqs';

  @override
  String get daysJournaled => 'Days Traqed';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get streaksSection => 'Streaks';

  @override
  String get longestThisMonth => 'Longest This Month';

  @override
  String get streakFreeze => 'Streak Freeze';

  @override
  String get streakFreezeAvailable => '1 available';

  @override
  String get streakFreezeUsed => 'Used this week';

  @override
  String get entriesPerWeek => 'Entries per week';

  @override
  String get daysSuffix => 'days';

  @override
  String mostActiveDay(String day) {
    return 'Most active day: $day';
  }

  @override
  String get onThisDayLastYear => 'On this day last year...';

  @override
  String get moodTitle => 'Mood';

  @override
  String get moodDistribution => 'Distribution';

  @override
  String moodAverage(String value) {
    return 'Average: $value';
  }

  @override
  String get moodRough => 'Rough';

  @override
  String get moodLow => 'Low';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodGood => 'Good';

  @override
  String get moodAmazing => 'Amazing';

  @override
  String get moodSelectorLabel => 'Mood selector';

  @override
  String moodButtonLabel(String label) {
    return '$label mood';
  }

  @override
  String get onboardingTitle1 =>
      'How\'ve you been?\nWhat have you\nbeen up to?';

  @override
  String get onboardingBody1 =>
      'If those questions make your\nmind go blank, you\'re in the right place.';

  @override
  String get onboardingTitle2 => 'Retraq is your\nmemory backup.';

  @override
  String get onboardingBody2 =>
      'Jot down anything about your day —\na word, a sentence, whatever.\nAnything is a start.';

  @override
  String get onboardingTitle3 => 'Start simple.\nThat\'s the whole point.';

  @override
  String get onboardingBody3 =>
      'Want more features later?\nThey\'re all in settings,\nwaiting for when you\'re ready.';

  @override
  String onboardingPageLabel(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get nextButton => 'Next';

  @override
  String get getStartedButton => 'Drop your first traq';

  @override
  String get ageGateTitle => 'Before we begin';

  @override
  String get ageGateDeniedTitle => 'Sorry!';

  @override
  String get ageGateMessage =>
      'Retraq is designed for users\naged 13 and older.';

  @override
  String get ageGateDenied =>
      'Retraq requires users to be 13 years or older.\nPlease come back when you\'re old enough!';

  @override
  String get ageConfirmButton => 'I am 13 or older';

  @override
  String get ageDenyButton => 'I am under 13';

  @override
  String get ageGateContactGuardian =>
      'If this was entered in error, please contact a parent or guardian.';

  @override
  String get almostThere => 'Almost there!';

  @override
  String healthDisclaimer(String crisisContact) {
    return 'Retraq is a personal journaling app — not a medical or therapeutic tool. It does not provide health advice, diagnosis, or treatment. If you are in crisis, please contact a mental health professional or call $crisisContact.';
  }

  @override
  String get healthDisclaimerCheckbox => 'I acknowledge the Health Disclaimer';

  @override
  String get privacyPolicyCheckbox =>
      'I have read and agree to the Privacy Policy';

  @override
  String get termsCheckbox => 'I agree to the Terms of Use';

  @override
  String get notificationDialogTitle => 'Stay on track';

  @override
  String get notificationDialogContent =>
      'A gentle daily reminder can help you build a traqing habit. You can change or turn this off anytime in Settings.';

  @override
  String get notNow => 'Not now';

  @override
  String get enableReminders => 'Enable reminders';

  @override
  String get consentSaveFailed => 'Failed to save consent. Please try again.';

  @override
  String get unlockBiometric => 'Unlock Retraq';

  @override
  String get enterPin => 'Enter your PIN';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get forgotPinMessage =>
      'If you\'ve forgotten your PIN, you can reset the app. This will permanently delete all your traqs and data. You can export first to save them.';

  @override
  String get resetApp => 'Reset App';

  @override
  String get exportBeforeReset => 'Export first';

  @override
  String get resetAppBiometricReason =>
      'Confirm it\'s you before resetting Retraq';

  @override
  String get resetAppBiometricFailed =>
      'Biometric check failed. Try again or cancel.';

  @override
  String wrongPinMessage(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining attempts',
      one: '1 attempt',
    );
    return 'Wrong PIN. $_temp0 remaining.';
  }

  @override
  String lockoutMessage(int seconds) {
    return 'Too many attempts. Wait ${seconds}s.';
  }

  @override
  String get updatedPolicies => 'Updated Policies';

  @override
  String get reconsentMessage =>
      'We\'ve updated our Privacy Policy, Terms of Use, and/or Health Disclaimer. Please review and accept to continue.';

  @override
  String get continueButton => 'Continue';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle => 'Choose how Retraq feels to you.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDay => 'Day';

  @override
  String get themeNight => 'Night';

  @override
  String get securityTitle => 'Security';

  @override
  String get securitySubtitle => 'Keep your traqs private.';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockEnabled => 'PIN required to open Retraq';

  @override
  String get appLockDisabled => 'No lock — anyone can open the app';

  @override
  String get changePin => 'Change PIN';

  @override
  String get changePinSubtitle => 'Set a new 4-digit PIN';

  @override
  String get biometricUnlock => 'Biometric Unlock';

  @override
  String get biometricSubtitle => 'Use fingerprint or face to unlock';

  @override
  String get biometricUnavailable => 'Biometrics not available on this device';

  @override
  String get biometricEnabledMessage =>
      'Biometric unlock enabled — you\'ll be prompted next time you open Retraq';

  @override
  String get appLockA11y => 'App lock';

  @override
  String get biometricUnlockA11y => 'Biometric unlock';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get allDayNotes => 'All Day Notes';

  @override
  String get allDayNotesSubtitle => 'One traq or split AM/PM';

  @override
  String get allDayOption => 'All Day';

  @override
  String get openingPrompt => 'Opening Prompt';

  @override
  String get asksAboutToday => 'Asks about today';

  @override
  String get asksAboutYesterday => 'Asks about yesterday';

  @override
  String get journalEntryTitle => 'Traq Title';

  @override
  String get journalEntryTitleSubtitle =>
      'Show or hide title fields in new traqs';

  @override
  String get moodTracking => 'Mood Tracking';

  @override
  String get moodTrackingSubtitle => 'Log how you feel with each traq';

  @override
  String get requireMood => 'Require Mood';

  @override
  String get requireMoodSubtitle => 'Must pick a mood before saving';

  @override
  String get moodOnlyEntries => 'Mood-Only Traqs';

  @override
  String get moodOnlyEntriesSubtitle => 'Save traqs with just a mood, no text';

  @override
  String get advancedTitle => 'Advanced';

  @override
  String get enterToSave => 'Enter to Save';

  @override
  String get enterToSaveSubtitle =>
      'Press Enter to save traq instead of new line';

  @override
  String get bulletPointsOnEnter => 'Bullet Points on Enter';

  @override
  String get bulletPointsSubtitle => 'Auto-insert • when pressing Enter';

  @override
  String get bionicReading => 'Bionic Reading';

  @override
  String get bionicReadingSubtitle =>
      'Bolds the start of each word for faster reading';

  @override
  String get weekStartsOn => 'Week Starts On';

  @override
  String get amPmSwitchesAt => 'AM/PM Switches At';

  @override
  String weekStartsOnA11y(String day) {
    return 'Week starts on $day';
  }

  @override
  String amPmSwitchesAtA11y(String time) {
    return 'AM/PM switches at $time';
  }

  @override
  String get mondayName => 'Monday';

  @override
  String get tuesdayName => 'Tuesday';

  @override
  String get wednesdayName => 'Wednesday';

  @override
  String get thursdayName => 'Thursday';

  @override
  String get fridayName => 'Friday';

  @override
  String get saturdayName => 'Saturday';

  @override
  String get sundayName => 'Sunday';

  @override
  String get yourData => 'Your Data';

  @override
  String get exportLabel => 'Export';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get exportText => 'Export Text';

  @override
  String get importLabel => 'Import';

  @override
  String get importFromBackup => 'Import from Backup';

  @override
  String get importAccepts => 'Accepts Retraq JSON backup files only';

  @override
  String get exportScopeTitle => 'Export scope';

  @override
  String get exportScopeContent =>
      'Export this week\'s traqs or all traqs?\n\nThe exported file will contain your personal traqs and settings. Keep it somewhere safe.';

  @override
  String get thisWeek => 'This Week';

  @override
  String get allEntries => 'All Traqs';

  @override
  String importConfirmTitle(String filename) {
    return 'Import $filename?';
  }

  @override
  String get importConfirmContent =>
      'This will add traqs from this backup. Duplicates will be skipped.';

  @override
  String get importButton => 'Import';

  @override
  String importSuccess(int imported, int skipped, int errors) {
    String _temp0 = intl.Intl.pluralLogic(
      imported,
      locale: localeName,
      other: 'Imported $imported traqs',
      one: 'Imported 1 traq',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: ', $skipped duplicates skipped',
      one: ', 1 duplicate skipped',
      zero: '',
    );
    String _temp2 = intl.Intl.pluralLogic(
      errors,
      locale: localeName,
      other: ', $errors errors',
      one: ', 1 error',
      zero: '',
    );
    return '$_temp0$_temp1$_temp2';
  }

  @override
  String get importFailed =>
      'Import failed. The file may be corrupted or in the wrong format.';

  @override
  String get filePickerFailed =>
      'Could not open file picker. Please try again.';

  @override
  String get exportFailed => 'Export failed. Please try again.';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteAllDataTitle => 'Delete all data?';

  @override
  String get deleteAllDataContent =>
      'This will permanently delete all traqs and reset your settings. This cannot be undone.\n\nConsider exporting your data first from the options above.';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm:';

  @override
  String get typeDeleteError => 'Type DELETE to confirm';

  @override
  String get deleteEverything => 'Delete Everything';

  @override
  String get allDataDeleted => 'All data has been deleted.';

  @override
  String get deleteDataFailed => 'Failed to delete data. Please try again.';

  @override
  String get editEntry => 'Edit Traq';

  @override
  String get titleHint => 'Title';

  @override
  String get entryTextHint => 'Traq text...';

  @override
  String get entryTextLabel => 'Traq text';

  @override
  String get deleteEntryTooltip => 'Delete traq';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get entryEmptyMessage =>
      'Traq is empty. Add some text, a title, or a mood.';

  @override
  String get entrySavedOverlay => 'Traq saved';

  @override
  String get niceOne => 'Nice one ✓';

  @override
  String get dismissLabel => 'Dismiss';

  @override
  String get setPinTitle => 'Set a PIN';

  @override
  String get confirmPinTitle => 'Confirm PIN';

  @override
  String get setPinSubtitle => 'Choose a 4-digit PIN';

  @override
  String get confirmPinSubtitle => 'Enter the same PIN again';

  @override
  String choosePinSubtitle(int length) {
    return 'Choose a $length-digit PIN';
  }

  @override
  String get pinTooEasy => 'Too easy to guess. Choose a different PIN.';

  @override
  String get pinMismatch => 'PINs did not match. Try again.';

  @override
  String get fourDigits => '4 digits';

  @override
  String get sixDigits => '6 digits';

  @override
  String get setPinButton => 'Set PIN';

  @override
  String get entryActions => 'Traq actions';

  @override
  String get editAction => 'Edit';

  @override
  String get shareAction => 'Share';

  @override
  String get deleteAction => 'Delete';

  @override
  String get deleteEntryTitle => 'Delete traq?';

  @override
  String get deleteEntryMessage => 'Are you sure? This can\'t be undone.';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get deleteFailedMessage => 'Failed to delete. Please try again.';

  @override
  String get numberPadDisabled => 'Number pad, disabled';

  @override
  String get deleteDigit => 'Delete';

  @override
  String get biometricButton => 'Biometric';

  @override
  String get noEntriesForDay => 'No entries';

  @override
  String dailyAtTime(String time) {
    return 'Daily at $time';
  }

  @override
  String get resetToTodayLabel => 'Reset to today';

  @override
  String get nudgeSkipIfJournaledHint =>
      'We\'ll only remind you if you haven\'t journaled yet.';

  @override
  String get nudgeChangeTime => 'Change Time';

  @override
  String get nudgeCardBody =>
      'Get a quick nudge to drop a breadcrumb before you forget your day.';

  @override
  String weekEntryCountSnackbar(String range, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'no entries',
    );
    return '$range: $_temp0';
  }

  @override
  String get statisticsOverview => 'Statistics overview';

  @override
  String entryForDayPreview(String dayLabel, String preview) {
    return 'Entry for $dayLabel: $preview';
  }

  @override
  String pinDotsLabel(int length, int maxLength, String error) {
    return '$length of $maxLength digits entered$error';
  }

  @override
  String get monthAtGlance => 'Month at a glance';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get dayMo => 'Mo';

  @override
  String get dayTu => 'Tu';

  @override
  String get dayWe => 'We';

  @override
  String get dayTh => 'Th';

  @override
  String get dayFr => 'Fr';

  @override
  String get daySa => 'Sa';

  @override
  String get daySu => 'Su';

  @override
  String calendarDayA11y(int day) {
    return 'Day $day';
  }

  @override
  String get calendarDayTodaySuffix => ', today';

  @override
  String get calendarDayHasEntriesSuffix => ', has entries';

  @override
  String get calendarDaySelectedSuffix => ', selected';

  @override
  String entryCardA11y(String dateLabel) {
    return 'Journal traq for $dateLabel';
  }

  @override
  String get entryOptionsTooltip => 'Traq options';

  @override
  String themeLabel(String label) {
    return '$label theme';
  }

  @override
  String get prompt0 => 'Just the highlights...';

  @override
  String get prompt1 => 'What did you get up to today?';

  @override
  String get prompt2 => 'Anything worth remembering?';

  @override
  String get prompt3 => 'Drop a breadcrumb for future you.';

  @override
  String get prompt4 => 'Sum it up in a few words.';

  @override
  String get prompt5 => 'What was the vibe today?';

  @override
  String get prompt6 => 'One good thing that happened...';

  @override
  String get prompt7 => 'What took up most of your brain today?';

  @override
  String get prompt8 => 'If today were a headline, what would it be?';

  @override
  String get prompt9 => 'What would you tell a friend about today?';

  @override
  String get prompt10 => 'The most unexpected part of today was...';

  @override
  String get prompt11 => 'Three words to describe today.';

  @override
  String get prompt12 => 'What did you learn today?';

  @override
  String get prompt13 => 'What are you grateful for right now?';

  @override
  String get prompt14 => 'What drained your energy today?';

  @override
  String get prompt15 => 'What gave you energy today?';

  @override
  String get prompt16 => 'Describe today in one sentence.';

  @override
  String get prompt17 => 'Something you noticed today...';

  @override
  String get prompt18 => 'A thought that kept coming back...';

  @override
  String get prompt19 => 'The best part of today was...';

  @override
  String get prompt20 => 'Something you want to remember...';

  @override
  String get prompt21 => 'How are you feeling right now?';

  @override
  String get prompt22 => 'What made you smile today?';

  @override
  String get prompt23 => 'A small win from today...';

  @override
  String get prompt24 => 'What would you do differently?';

  @override
  String get prompt25 => 'What are you looking forward to tomorrow?';

  @override
  String get prompt26 => 'Something that surprised you...';

  @override
  String get prompt27 => 'A moment of calm from today...';

  @override
  String get nudgeDescription =>
      'Get a quick nudge to drop a breadcrumb before you forget your day.';

  @override
  String get changeTime => 'Change Time';

  @override
  String get shareDay => 'Share Day';

  @override
  String get noEntryForDay => 'No traqs for this day';

  @override
  String get noEntriesThisMonth => 'No traqs this month.';

  @override
  String get notifTitle => 'Retraq';

  @override
  String get notifDaily0 =>
      'Quick — what happened today? Even one word counts.';

  @override
  String get notifDaily1 =>
      '30 seconds. One traq. You\'ll thank yourself later.';

  @override
  String get notifDaily2 => 'Jot something down before today disappears.';

  @override
  String get notifDaily3 => 'Future you wants to know what happened today.';

  @override
  String get notifDaily4 => 'Don\'t let today vanish. Drop a traq.';

  @override
  String get notifWeekly0 => 'Your week\'s been retraqd. Take a look back.';

  @override
  String get notifWeekly1 => 'Here\'s what you got up to this week.';

  @override
  String get notifReengage0 =>
      'It\'s been a few days. Drop a quick traq so you don\'t lose the week.';

  @override
  String get notifReengage1 =>
      'Your week is disappearing. Takes 10 seconds to save it.';

  @override
  String settingsLegalFooter(String appName, String version) {
    return '$appName v$version';
  }

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get healthDisclaimerTitle => 'Health Disclaimer';

  @override
  String get legalFooterTerms => 'Terms';

  @override
  String get legalFooterHealth => 'Health';

  @override
  String get legalFooterLicenses => 'Licenses';

  @override
  String get exportPiiNote =>
      'The exported file will contain your personal traqs and settings. Keep it somewhere safe.';
}
