// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SinceThen';

  @override
  String get appNameSince => 'Since';

  @override
  String get appNameThen => 'Then';

  @override
  String get navJournal => 'Journal';

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
  String get entryTitleHint => 'Entry title (optional)';

  @override
  String get entryTitleLabel => 'Entry title';

  @override
  String get amHint => 'How did the morning go?';

  @override
  String get pmHint => 'How about the rest of the day?';

  @override
  String get saveEntry => 'Save Entry';

  @override
  String get saving => 'Saving...';

  @override
  String get journalEntryLabel => 'Journal entry';

  @override
  String get amLabel => 'AM';

  @override
  String get pmLabel => 'PM';

  @override
  String get progressFirstEntry => 'Start your first entry above.';

  @override
  String progressWeekCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
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
  String get entrySaved => 'Entry saved';

  @override
  String get undoLabel => 'Undo';

  @override
  String get saveAndSwitch => 'Save and switch?';

  @override
  String saveAndSwitchContent(String period, String newPeriod) {
    return 'Your $period entry will be saved before switching to $newPeriod.';
  }

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get saveAndSwitchButton => 'Save & Switch';

  @override
  String get saveFailedMessage => 'Failed to save. Please try again.';

  @override
  String get milestone1 => 'Your very first entry!';

  @override
  String get milestone5 => '5 entries! You\'re off to a great start.';

  @override
  String get milestone10 => '10 entries! You\'re building a habit.';

  @override
  String get milestone25 => '25 entries! Look at you go.';

  @override
  String get milestone50 => '50 entries! That\'s genuinely impressive.';

  @override
  String get milestone100 => '100 entries! You\'re a journaling pro.';

  @override
  String get milestone250 => '250 entries! A real treasure trove.';

  @override
  String get milestone500 => '500 entries! Half a thousand memories.';

  @override
  String get milestone1000 => '1,000 entries! Legendary status.';

  @override
  String entryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String moreEntries(int count) {
    return '+$count more';
  }

  @override
  String changeDateLabel(String date) {
    return 'Change entry date, currently $date';
  }

  @override
  String get recapTitle => 'Recap';

  @override
  String get searchHint => 'Search entries...';

  @override
  String get closeSearch => 'Close search';

  @override
  String get searchEntries => 'Search entries';

  @override
  String get searching => 'Searching...';

  @override
  String get noSearchResults => 'No entries match your search.';

  @override
  String get weekLabel => 'Week';

  @override
  String get monthLabel => 'Month';

  @override
  String get weeklyRecap => 'Weekly Recap';

  @override
  String weeklyRecapStats(int totalEntries, int activeDays, String preferredTime) {
    return '$totalEntries entries · $activeDays days · $preferredTime';
  }

  @override
  String get noEntriesYet => 'No entries yet';

  @override
  String get noEntriesYetMessage => 'Your journal entries will appear here once you start writing.';

  @override
  String get statsTitle => 'Stats';

  @override
  String get statsSubtitle => 'Your journey so far.';

  @override
  String get noStatsYet => 'No stats yet';

  @override
  String get noStatsYetMessage => 'Start journaling to see your patterns and streaks.';

  @override
  String get totalEntries => 'Total Entries';

  @override
  String get daysJournaled => 'Days Journaled';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get daysSuffix => 'days';

  @override
  String mostActiveDay(String day) {
    return 'Most active day: $day';
  }

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
  String get onboardingTitle1 => 'Your day,\nyour words.';

  @override
  String get onboardingBody1 => 'No templates. No pressure.\nJust jot down the highlights.';

  @override
  String get onboardingTitle2 => 'Look back\nwithout stress.';

  @override
  String get onboardingBody2 => 'A simple calendar shows\nwhat you captured each day.';

  @override
  String get onboardingTitle3 => 'Private\nby default.';

  @override
  String get onboardingBody3 => 'Everything stays on your phone.\nNo account needed. Ever.';

  @override
  String onboardingPageLabel(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get nextButton => 'Next';

  @override
  String get getStartedButton => 'Get Started';

  @override
  String get ageGateTitle => 'Before we begin';

  @override
  String get ageGateDeniedTitle => 'Sorry!';

  @override
  String get ageGateMessage => 'SinceThen is designed for users\naged 13 and older.';

  @override
  String get ageGateDenied => 'SinceThen requires users to be 13 years or older.\nPlease come back when you\'re old enough!';

  @override
  String get ageConfirmButton => 'I am 13 or older';

  @override
  String get ageDenyButton => 'I am under 13';

  @override
  String get almostThere => 'Almost there!';

  @override
  String get healthDisclaimer => 'SinceThen is a personal journaling app — not a medical or therapeutic tool. It does not provide health advice, diagnosis, or treatment. If you are in crisis, please contact a mental health professional or call 988 (Suicide & Crisis Lifeline).';

  @override
  String get healthDisclaimerCheckbox => 'I acknowledge the Health Disclaimer';

  @override
  String get privacyPolicyCheckbox => 'I have read and agree to the Privacy Policy';

  @override
  String get termsCheckbox => 'I agree to the Terms of Use';

  @override
  String get notificationDialogTitle => 'Stay on track';

  @override
  String get notificationDialogContent => 'A gentle daily reminder can help you build a journaling habit. You can change or turn this off anytime in Settings.';

  @override
  String get notNow => 'Not now';

  @override
  String get enableReminders => 'Enable reminders';

  @override
  String get unlockBiometric => 'Unlock SinceThen';

  @override
  String get enterPin => 'Enter your PIN';

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
  String get reconsentMessage => 'We\'ve updated our Privacy Policy and/or Terms of Use. Please review and accept to continue.';

  @override
  String get continueButton => 'Continue';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle => 'Choose how SinceThen feels to you.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDay => 'Day';

  @override
  String get themeNight => 'Night';

  @override
  String get securityTitle => 'Security';

  @override
  String get securitySubtitle => 'Keep your journal private.';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockEnabled => 'PIN required to open SinceThen';

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
  String get biometricEnabled => 'Biometric unlock enabled — you\'ll be prompted next time you open SinceThen';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get allDayNotes => 'All Day Notes';

  @override
  String get allDayNotesSubtitle => 'One entry or split AM/PM';

  @override
  String get allDayOption => 'All Day';

  @override
  String get openingPrompt => 'Opening Prompt';

  @override
  String get asksAboutToday => 'Asks about today';

  @override
  String get asksAboutYesterday => 'Asks about yesterday';

  @override
  String get journalEntryTitle => 'Journal Entry Title';

  @override
  String get journalEntryTitleSubtitle => 'Show or hide title fields in new entries';

  @override
  String get moodTracking => 'Mood Tracking';

  @override
  String get moodTrackingSubtitle => 'Log how you feel with each entry';

  @override
  String get requireMood => 'Require Mood';

  @override
  String get requireMoodSubtitle => 'Must pick a mood before saving';

  @override
  String get moodOnlyEntries => 'Mood-Only Entries';

  @override
  String get moodOnlyEntriesSubtitle => 'Save entries with just a mood, no text';

  @override
  String get advancedTitle => 'Advanced';

  @override
  String get enterToSave => 'Enter to Save';

  @override
  String get enterToSaveSubtitle => 'Press Enter to save entry instead of new line';

  @override
  String get bulletPointsOnEnter => 'Bullet Points on Enter';

  @override
  String get bulletPointsSubtitle => 'Auto-insert • when pressing Enter';

  @override
  String get weekStartsOn => 'Week Starts On';

  @override
  String get amPmSwitchesAt => 'AM/PM Switches At';

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
  String get importAccepts => 'Accepts SinceThen JSON backup files only';

  @override
  String get exportScopeTitle => 'Export scope';

  @override
  String get exportScopeContent => 'Export this week\'s entries or all entries?\n\nThe exported file will contain your personal journal entries and settings. Keep it somewhere safe.';

  @override
  String get thisWeek => 'This Week';

  @override
  String get allEntries => 'All Entries';

  @override
  String importConfirmTitle(String filename) {
    return 'Import $filename?';
  }

  @override
  String get importConfirmContent => 'This will add entries from this backup to your journal. Duplicate entries will be skipped.';

  @override
  String get importButton => 'Import';

  @override
  String importSuccess(int imported, String skipped, String errors) {
    return 'Imported $imported entries$skipped$errors';
  }

  @override
  String get importFailed => 'Import failed. The file may be corrupted or in the wrong format.';

  @override
  String get filePickerFailed => 'Could not open file picker. Please try again.';

  @override
  String get exportFailed => 'Export failed. Please try again.';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteAllDataTitle => 'Delete all data?';

  @override
  String get deleteAllDataContent => 'This will permanently delete all journal entries and reset your settings. This cannot be undone.\n\nConsider exporting your data first from the options above.';

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
  String get editEntry => 'Edit Entry';

  @override
  String get titleHint => 'Title';

  @override
  String get entryTextHint => 'Entry text...';

  @override
  String get entryTextLabel => 'Entry text';

  @override
  String get deleteEntryTooltip => 'Delete entry';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get entrySavedOverlay => 'Entry saved';

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
  String get pinTooEasy => 'Too easy to guess. Choose a different PIN.';

  @override
  String get pinMismatch => 'PINs did not match. Try again.';

  @override
  String get setPinButton => 'Set PIN';

  @override
  String get entryActions => 'Entry actions';

  @override
  String get editAction => 'Edit';

  @override
  String get shareAction => 'Share';

  @override
  String get deleteAction => 'Delete';

  @override
  String get deleteEntryTitle => 'Delete entry?';

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
  String get notifTitle => 'SinceThen';

  @override
  String get notifMorning0 => 'Good morning! Set an intention for today — even one word counts.';

  @override
  String get notifMorning1 => 'Rise and write. What are you looking forward to today?';

  @override
  String get notifMorning2 => 'Morning check-in: how are you feeling right now?';

  @override
  String get notifMorning3 => 'Start your day with a thought. Your journal is ready.';

  @override
  String get notifMorning4 => 'A fresh page for a fresh day. What\'s on your mind?';

  @override
  String get notifEvening0 => 'What happened today? Even one sentence counts.';

  @override
  String get notifEvening1 => 'Take a moment to capture today before it slips away.';

  @override
  String get notifEvening2 => 'How was your day? A few words is all it takes.';

  @override
  String get notifEvening3 => 'Hey, how did today go? Your journal would love to know.';

  @override
  String get notifEvening4 => 'What\'s the TL;DR of today?';

  @override
  String get notifEvening5 => 'Capture the vibe. Was today a 10 or a meh?';

  @override
  String get notifEvening6 => 'What made today different from yesterday?';

  @override
  String get notifEvening7 => 'The best time to journal was this morning. The second best time is now.';

  @override
  String get notifEvening8 => 'What surprised you today? Write it down before you forget.';

  @override
  String get notifGeneral0 => 'Your journal is waiting. No pressure, just jot something down.';

  @override
  String get notifGeneral1 => 'Ready to write? Your future self will thank you.';

  @override
  String get notifGeneral2 => 'Just checking in. What\'s on your mind today?';

  @override
  String get notifGeneral3 => 'One small entry, one big habit. You\'ve got this.';

  @override
  String get notifGeneral4 => 'Today deserves to be remembered. What stood out?';

  @override
  String get notifGeneral5 => 'Your journal, your pace. Write as much or as little as you\'d like.';

  @override
  String get notifGeneral6 => 'Time for a brain dump? Open up and let it flow.';

  @override
  String get notifGeneral7 => 'A quick note now saves a forgotten memory later.';

  @override
  String get notifGeneral8 => 'Future you is curious about today. Leave a note.';

  @override
  String get notifGeneral9 => 'Even busy days deserve a sentence or two.';

  @override
  String get notifGeneral10 => 'You don\'t need perfect words. Just real ones.';

  @override
  String get notifGeneral11 => 'Quick check: anything worth remembering today?';

  @override
  String get notifGeneral12 => 'One minute, one entry. You can do this.';

  @override
  String get notifGeneral13 => 'What would you tell a friend about today?';

  @override
  String get notifGeneral14 => 'No rules, no word count. Just you and today.';

  @override
  String get notifGeneral15 => 'A few taps now, a whole memory saved forever.';

  @override
  String get notifGeneral16 => 'Your journal doesn\'t judge. It just listens.';

  @override
  String get notifGeneral17 => 'Plot twist: you actually have time for this. Promise.';

  @override
  String get notifWeekend0 => 'Lazy weekend? Perfect journaling weather.';

  @override
  String get notifWeekend1 => 'Weekends fly by. Capture this one before it does.';

  @override
  String get notifWeekend2 => 'No rush today. Take a moment to reflect.';

  @override
  String get notifStreakRisk0 => 'Your streak called. It misses you.';

  @override
  String get notifStreakRisk1 => 'Don\'t let today break your streak — one sentence is enough.';

  @override
  String get notifStreakRisk2 => 'You\'ve been consistent. Keep it going with a quick entry.';

  @override
  String settingsLegalFooter(String appName, String version) {
    return '$appName v$version';
  }

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get healthDisclaimerTitle => 'Health Disclaimer';

  @override
  String get exportPiiNote => 'The exported file will contain your personal journal entries and settings. Keep it somewhere safe.';
}
