/// User settings — singleton pattern.
/// Plain Dart class — Drift table definition lives in database_service.dart.
class UserSettings {
  // 0 = system (default), 1 = light, 2 = dark
  static const int themeModeSystem = 0;
  static const int themeModeLight = 1;
  static const int themeModeDark = 2;

  final int themeMode;
  final bool isAllDayMode;
  final bool askAboutToday;
  final bool showEntryTitle;
  final int weekStartDay; // 1 = Monday, 7 = Sunday
  final int nudgeHour; // 24h format, default 8 PM
  final int nudgeMinute; // 0-59, default 0
  final bool appLockEnabled;
  final String? pinHash; // Stored as "salt:hash" or "v2:salt:hash" (PBKDF2)
  final bool biometricEnabled;
  final bool onboardingComplete;
  final bool enterToSave;
  final bool bulletPointsOnEnter;
  final int amPmCutoffHour; // 24h format, default 14 (2 PM)
  final bool moodEnabled; // Show mood selector on home screen
  final bool moodRequired; // Require mood before saving entry
  final bool moodOnlyEntries; // Allow mood-only entries (no text)
  final bool bionicReadingEnabled; // Bold start of each word for faster reading

  UserSettings({
    this.themeMode = 0,
    this.isAllDayMode = true,
    this.askAboutToday = true,
    this.showEntryTitle = false,
    this.weekStartDay = 1,
    this.nudgeHour = 20,
    this.nudgeMinute = 0,
    this.appLockEnabled = false,
    this.pinHash,
    this.biometricEnabled = false,
    this.onboardingComplete = false,
    this.enterToSave = false,
    this.bulletPointsOnEnter = false,
    this.amPmCutoffHour = 14,
    this.moodEnabled = false,
    this.moodRequired = false,
    this.moodOnlyEntries = false,
    this.bionicReadingEnabled = false,
  });

  static const Object _sentinel = Object();

  UserSettings copyWith({
    int? themeMode,
    bool? isAllDayMode,
    bool? askAboutToday,
    bool? showEntryTitle,
    int? weekStartDay,
    int? nudgeHour,
    int? nudgeMinute,
    bool? appLockEnabled,
    Object? pinHash = _sentinel,
    bool? biometricEnabled,
    bool? onboardingComplete,
    bool? enterToSave,
    bool? bulletPointsOnEnter,
    int? amPmCutoffHour,
    bool? moodEnabled,
    bool? moodRequired,
    bool? moodOnlyEntries,
    bool? bionicReadingEnabled,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      isAllDayMode: isAllDayMode ?? this.isAllDayMode,
      askAboutToday: askAboutToday ?? this.askAboutToday,
      showEntryTitle: showEntryTitle ?? this.showEntryTitle,
      weekStartDay: weekStartDay ?? this.weekStartDay,
      nudgeHour: nudgeHour ?? this.nudgeHour,
      nudgeMinute: nudgeMinute ?? this.nudgeMinute,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      pinHash: pinHash == _sentinel ? this.pinHash : pinHash as String?,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      enterToSave: enterToSave ?? this.enterToSave,
      bulletPointsOnEnter: bulletPointsOnEnter ?? this.bulletPointsOnEnter,
      amPmCutoffHour: amPmCutoffHour ?? this.amPmCutoffHour,
      moodEnabled: moodEnabled ?? this.moodEnabled,
      moodRequired: moodRequired ?? this.moodRequired,
      moodOnlyEntries: moodOnlyEntries ?? this.moodOnlyEntries,
      bionicReadingEnabled: bionicReadingEnabled ?? this.bionicReadingEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettings &&
          themeMode == other.themeMode &&
          isAllDayMode == other.isAllDayMode &&
          askAboutToday == other.askAboutToday &&
          showEntryTitle == other.showEntryTitle &&
          weekStartDay == other.weekStartDay &&
          nudgeHour == other.nudgeHour &&
          nudgeMinute == other.nudgeMinute &&
          appLockEnabled == other.appLockEnabled &&
          pinHash == other.pinHash &&
          biometricEnabled == other.biometricEnabled &&
          onboardingComplete == other.onboardingComplete &&
          enterToSave == other.enterToSave &&
          bulletPointsOnEnter == other.bulletPointsOnEnter &&
          amPmCutoffHour == other.amPmCutoffHour &&
          moodEnabled == other.moodEnabled &&
          moodRequired == other.moodRequired &&
          moodOnlyEntries == other.moodOnlyEntries &&
          bionicReadingEnabled == other.bionicReadingEnabled;

  @override
  int get hashCode => Object.hash(
    themeMode,
    isAllDayMode,
    askAboutToday,
    showEntryTitle,
    weekStartDay,
    nudgeHour,
    nudgeMinute,
    appLockEnabled,
    pinHash,
    biometricEnabled,
    onboardingComplete,
    enterToSave,
    bulletPointsOnEnter,
    amPmCutoffHour,
    moodEnabled,
    moodRequired,
    moodOnlyEntries,
    bionicReadingEnabled,
  );
}
