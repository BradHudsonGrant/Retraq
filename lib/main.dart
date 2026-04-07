import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/user_settings.dart';
import 'theme/app_theme.dart';
import 'screens/app_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/screen_security_service.dart';
import 'services/widget_service.dart';
import 'l10n/app_localizations.dart';
import 'screens/reconsent_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler for framework errors (widget build failures, etc.)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Global handler for unhandled async errors (platform, isolate, etc.)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return true; // Prevents app crash — error is logged
  };

  // Allow all orientations for adaptive phone/tablet layouts
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);

  // Initialise Drift (SQLite) database before app starts — it's the only
  // service the splash screen / first real route depends on.
  // NotificationService and WidgetService are deferred to a post-first-frame
  // callback in RetraqApp.initState so they don't block the splash from
  // painting (they previously added flutter_local_notifications + home_widget
  // plugin handshakes to the critical path).
  await DatabaseService.instance.init();

  runApp(const RetraqApp());
}

class RetraqApp extends StatefulWidget {
  const RetraqApp({super.key});

  @override
  State<RetraqApp> createState() => _RetraqAppState();
}

class _RetraqAppState extends State<RetraqApp> with WidgetsBindingObserver {
  final _db = DatabaseService.instance;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLocked = true; // Start locked, unlock after settings check
  bool _appLockEnabled = false;
  bool _showOnboarding = false;
  bool _needsReconsent = false;
  bool _settingsLoaded = false;
  UserSettings _settings = UserSettings();
  StreamSubscription<UserSettings?>? _settingsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    // Watch for settings changes (e.g. theme toggled from settings screen)
    _settingsSub = _db.settings.watchSettings().listen((s) {
      if (!mounted || s == null) return;
      final newMode = _intToThemeMode(s.themeMode);
      final needsRebuild = newMode != _themeMode || s != _settings;
      _appLockEnabled = s.appLockEnabled;
      _settings = s;
      if (needsRebuild) {
        setState(() => _themeMode = newMode);
      }
      _updateFlagSecure(s.appLockEnabled);
    });

    // Defer non-critical service init until after the first frame so the
    // splash screen paints immediately. NotificationService.init() is also
    // called lazily inside _loadSettings before scheduleDaily, so the race
    // between this callback and _loadSettings is safe (init is idempotent).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initBackgroundServices());
    });
  }

  Future<void> _initBackgroundServices() async {
    try {
      await NotificationService.instance.init();
    } catch (e) {
      debugPrint('Notification init failed (non-fatal): $e');
    }
    try {
      await WidgetService.instance.init();
      await WidgetService.instance.update();
    } catch (e) {
      debugPrint('Widget init failed (non-fatal): $e');
    }
  }

  Future<void> _updateFlagSecure(bool enabled) =>
      ScreenSecurityService.instance.setSecure(enabled);

  @override
  void dispose() {
    _settingsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-lock when app goes to background (if lock is enabled).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _appLockEnabled) {
      setState(() => _isLocked = true);
    }
  }

  Future<void> _loadSettings() async {
    final settings = await _db.settings.getSettings();
    _settings = settings;
    // Check if returning user needs to re-consent to updated legal documents.
    bool reconsent = false;
    if (settings.onboardingComplete) {
      reconsent = await _db.userRepo.needsReconsent();
    }

    setState(() {
      _themeMode = _intToThemeMode(settings.themeMode);
      _appLockEnabled = settings.appLockEnabled;
      _isLocked = settings.appLockEnabled;
      _showOnboarding = !settings.onboardingComplete;
      _needsReconsent = reconsent;
      _settingsLoaded = true;
    });
    _updateFlagSecure(settings.appLockEnabled);
    try {
      // init() is idempotent — safe to call here even though the post-frame
      // callback in initState may have already run it.
      await NotificationService.instance.init();
      await NotificationService.instance.scheduleDaily(
        settings.nudgeHour,
        minute: settings.nudgeMinute,
      );
    } catch (e) {
      debugPrint('Notification schedule failed (non-fatal): $e');
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final settings = await _db.settings.getSettings();
      await _db.settings.saveSettings(
        settings.copyWith(onboardingComplete: true),
      );
    } catch (e) {
      debugPrint('Onboarding completion failed: $e');
      // Still transition past onboarding — user shouldn't get stuck.
      // On next launch, onboarding will show again if save truly failed.
    }
    if (mounted) setState(() => _showOnboarding = false);
  }

  static ThemeMode _intToThemeMode(int mode) {
    switch (mode) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(int mode) async {
    setState(() {
      _themeMode = _intToThemeMode(mode);
    });
    final settings = await _db.settings.getSettings();
    await _db.settings.saveSettings(settings.copyWith(themeMode: mode));
  }

  void _unlock() {
    setState(() => _isLocked = false);
  }

  Widget _buildCurrentScreen() {
    if (!_settingsLoaded) {
      return const SplashScreen(key: ValueKey('loading'));
    }
    if (_showOnboarding) {
      return OnboardingScreen(
        key: const ValueKey('onboarding'),
        onComplete: _completeOnboarding,
      );
    }
    if (_needsReconsent) {
      return ReconsentScreen(
        key: const ValueKey('reconsent'),
        onComplete: () {
          setState(() => _needsReconsent = false);
        },
      );
    }
    if (_isLocked) {
      return LockScreen(key: const ValueKey('lock'), onUnlocked: _unlock);
    }
    return AppShell(
      key: const ValueKey('app'),
      onThemeModeChanged: setThemeMode,
      themeMode: _themeMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsProvider(
      settings: _settings,
      child: MaterialApp(
        title: 'Retraq',
        debugShowCheckedModeBanner: false,
        showPerformanceOverlay: false,
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        home: Builder(
          builder: (ctx) {
            final reduceMotion = MediaQuery.of(ctx).disableAnimations;
            return AnimatedSwitcher(
              duration:
                  reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildCurrentScreen(),
            );
          },
        ),
      ),
    );
  }
}
