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

  // Initialise Drift (SQLite) database before app starts
  await DatabaseService.instance.init();

  // Initialise local notifications (non-fatal if it fails)
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification init failed (non-fatal): $e');
  }

  // Initialise home screen widget data (non-fatal if it fails)
  try {
    await WidgetService.instance.init();
    await WidgetService.instance.update();
  } catch (e) {
    debugPrint('Widget init failed (non-fatal): $e');
  }

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
  }

  static const _flagSecureChannel = MethodChannel('com.retraq.app/flag_secure');

  Future<void> _updateFlagSecure(bool enabled) async {
    try {
      await _flagSecureChannel.invokeMethod(
        enabled ? 'addFlagSecure' : 'clearFlagSecure',
      );
    } catch (e) {
      debugPrint('FLAG_SECURE toggle failed: $e');
    }
  }

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
      await NotificationService.instance.scheduleDaily(settings.nudgeHour, minute: settings.nudgeMinute);
    } catch (e) {
      debugPrint('Notification schedule failed (non-fatal): $e');
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final settings = await _db.settings.getSettings();
      await _db.settings.saveSettings(settings.copyWith(onboardingComplete: true));
    } catch (e) {
      debugPrint('Onboarding completion failed: $e');
      // Still transition past onboarding — user shouldn't get stuck.
      // On next launch, onboarding will show again if save truly failed.
    }
    if (mounted) setState(() => _showOnboarding = false);
  }

  static ThemeMode _intToThemeMode(int mode) {
    switch (mode) {
      case 1: return ThemeMode.light;
      case 2: return ThemeMode.dark;
      default: return ThemeMode.system;
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
      return LockScreen(
        key: const ValueKey('lock'),
        onUnlocked: _unlock,
      );
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
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
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
