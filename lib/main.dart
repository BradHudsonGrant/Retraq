import 'dart:async';
import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/user_settings.dart';
import 'theme/app_motion.dart';
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

  // Draw behind both the status bar and the gesture/3-button nav bar so the
  // top gradient tints and bottom NavigationBar surface flow seamlessly into
  // the system chrome. AnnotatedRegion in the home builder below handles the
  // per-theme tinting.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
      // Task 3.4 — FLAG_SECURE is applied unconditionally, not gated on
      // appLockEnabled. Journal content is sensitive even without a PIN:
      // blocking screenshots + Recents thumbnails protects users who
      // have not set up app lock.
      _updateFlagSecure(true);
    });

    // Defer non-critical service init until after the first frame so the
    // splash screen paints immediately. NotificationService.init() is also
    // called lazily inside _loadSettings before scheduleDaily, so the race
    // between this callback and _loadSettings is safe (init is idempotent).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initBackgroundServices());
    });

    // Task 3.8 — Tell the widget service how to check lock state so
    // home-widget updates skip the DB while the app is locked. The
    // widget displays mood + recent activity, which should not refresh
    // on the home-screen while a thief holds a locked device.
    WidgetService.instance.isLockedChecker =
        () => _appLockEnabled && _isLocked;
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
  ///
  /// Task 3.5 — Lock on `inactive` as well as `paused`. `inactive` fires
  /// the instant the user swipes up into the app switcher or receives a
  /// phone call; `paused` fires later, once the OS has already snapshot
  /// the UI for the Recents thumbnail (or allowed another app to peek
  /// at the screen). Locking on `inactive` closes that window and moves
  /// the lock overlay in place BEFORE any OS-level snapshot is taken.
  ///
  /// FLAG_SECURE (Task 3.4) is now unconditional, so the thumbnail is
  /// blocked on Android regardless of this path. The iOS equivalent is
  /// handled separately in Task 3.6 (native `applicationWillResignActive`
  /// blur overlay); this change is still useful on iOS because it means
  /// the in-Flutter lock screen appears before the OS snapshot, giving
  /// a consistent UX and a defense-in-depth layer.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_appLockEnabled) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (!_isLocked) {
          setState(() => _isLocked = true);
        }
      case AppLifecycleState.resumed:
      case AppLifecycleState.detached:
        // No-op on resume; unlock happens only through the lock screen's
        // PIN / biometric challenge (see lock_screen.dart).
        break;
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
    // Task 3.4 — unconditional (see above).
    _updateFlagSecure(true);
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
            final cs = Theme.of(ctx).colorScheme;
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            // Tint the Android status bar and 3-button / gesture nav bar so
            // the system chrome blends into Retraq's surface instead of the
            // OEM default slab. iOS ignores these uniforms.
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: cs.surface,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
              ),
              // Material 3 fade-through for top-level screen swaps.
              // Reduce-motion collapses the duration to zero so the swap is
              // instant for users with "Remove animations" enabled.
              child: PageTransitionSwitcher(
                duration: AppMotion.aware(ctx, AppMotion.slow),
                transitionBuilder: (child, primary, secondary) {
                  return FadeThroughTransition(
                    animation: primary,
                    secondaryAnimation: secondary,
                    fillColor: cs.surface,
                    child: child,
                  );
                },
                child: _buildCurrentScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
