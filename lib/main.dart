import 'dart:async';
import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_settings.dart';
import 'services/analytics_service.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'screens/app_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';
import 'widgets/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/screen_security_service.dart';
import 'services/widget_service.dart';
import 'l10n/app_localizations.dart';
import 'screens/reconsent_screen.dart';
import 'screens/splash_screen.dart';

/// Sentry DSN read at compile time via `--dart-define=
/// SENTRY_DSN=...`. Empty string means "do not wire crash reporting"
/// which is the safe default for local `flutter run` sessions and
/// any build where the secret isn't provisioned.
///
/// The hardcoded fallback keeps parity with the pre-hardening state
/// so the user's local debug builds still phone home. CI should
/// override with `--dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}`.
/// DSNs are embedded in every APK regardless (they are public by
/// design; the security gate is the auth token used for dSYM uploads).
const _sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue:
      'https://844023f9d58cc7de383a324b205ba9aa@o4511236634443776.ingest.us.sentry.io/4511236638572544',
);

/// Sentry environment tag. Overridable via
/// `--dart-define=SENTRY_ENVIRONMENT=...` so CI can split events by
/// release track (e.g. `beta`, `testflight-internal`, `prod`). Empty
/// default routes to the kReleaseMode-based fallback inside init,
/// which uses `'beta'` for release builds until the public launch.
/// Flip the fallback to `'prod'` in the same commit that submits to
/// App Store / Play Store — that way pre-launch events stay out of
/// the production bucket.
const _sentryEnvironmentOverride = String.fromEnvironment(
  'SENTRY_ENVIRONMENT',
  defaultValue: '',
);

/// Sentry opt-in gate. The privacy policy promises "no analytics,
/// no telemetry, no tracking of any kind" — Sentry events are therefore
/// blocked in `beforeSend` unless this SharedPreferences flag is `true`.
/// Default false; the Settings → Data → Diagnostics toggle flips it.
/// Reading it synchronously keeps the hot-path on `beforeSend` fast;
/// the flag is primed on app start and refreshed on any toggle.
const _sentryOptInKey = 'sentry_opt_in';
bool _sentryOptedIn = false;

Future<void> _loadSentryOptIn() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    _sentryOptedIn = prefs.getBool(_sentryOptInKey) ?? false;
  } catch (_) {
    // SharedPreferences may be unavailable in some test envs — fall
    // back to opted-out, which is the privacy-preserving default.
    _sentryOptedIn = false;
  }
}

/// Public hook so a Settings toggle (follow-up commit) can update the
/// cached flag without requiring an app restart. Call after writing
/// the SharedPreferences key.
void setSentryOptIn(bool value) {
  _sentryOptedIn = value;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prime opt-in flag BEFORE Sentry.init so the very first beforeSend
  // already observes the correct state. If the user opted in on the
  // previous session, we honour that immediately on the next launch.
  await _loadSentryOptIn();

  // Prime the Analytics kill-switch cache so the very
  // first `bump(...)` call (e.g., a counter fired during onboarding)
  // observes the user's persisted preference. Default true when
  // SharedPreferences is unreachable — no telemetry leaves device
  // regardless of local write state, so permissive default is safe.
  await AnalyticsService.instance.refreshFromPrefs();

  // Sentry is optional — if no DSN is configured we skip init entirely
  // and just keep a vanilla FlutterError handler. This keeps `flutter
  // test` + `flutter run` without a DSN working as before.
  if (_sentryDsn.isEmpty) {
    _bootPlain();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      // Env + release tags so events bucket correctly in
      // Sentry's UI. Free-tier 5k-event/mo quota burns fast at 1.0
      // sample rates; drop to 10% in release mode and keep 100% in
      // debug so local dev still sees full telemetry.
      //
      // Environment fallback: explicit --dart-define override wins;
      // otherwise release builds tag as 'beta' (pre-launch) and
      // debug builds as 'dev'. When the public launch ships, flip
      // the 'beta' here to 'prod' in the same commit that submits
      // to App Store / Play Store.
      options.environment = _sentryEnvironmentOverride.isNotEmpty
          ? _sentryEnvironmentOverride
          : (kReleaseMode ? 'beta' : 'dev');
      options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
      // ignore: experimental_member_use
      options.profilesSampleRate = kReleaseMode ? 0.1 : 1.0;

      // PII scrub + opt-in gate. beforeSend runs on every
      // event BEFORE it leaves the device. Returning null drops the
      // event entirely — the SDK never phones home.
      options.beforeSend = (event, hint) {
        if (!_sentryOptedIn) return null;
        // Strip device.name (can leak "Brad's iPhone" on iOS).
        // Other PII-adjacent fields (user.id, user.email) are not set
        // by our code; if Sentry auto-collects anything new in future
        // SDK versions, add the matching scrub here.
        final device = event.contexts.device;
        if (device != null) {
          event = event.copyWith(
            contexts: event.contexts.copyWith(
              device: device.copyWith(name: null),
            ),
          );
        }
        return event;
      };
    },
    appRunner: _bootPlain,
  );
}

/// The actual app-boot sequence, extracted so we can call it both
/// from inside Sentry's init callback AND directly when no DSN is
/// configured (no-Sentry fallback).
Future<void> _bootPlain() async {
  // Global error handler for framework errors (widget build failures, etc.)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Sentry.captureException(details.exception, stackTrace: details.stack);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Global handler for unhandled async errors (platform, isolate, etc.)
  PlatformDispatcher.instance.onError = (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
    debugPrint('Unhandled error: $error\n$stack');
    return true; // Prevents app crash — error is logged
  };

  // Route DatabaseService stream errors through Sentry so
  // background Drift watcher failures are captured alongside widget
  // crashes.
  DatabaseService.onStreamError = (message) {
    Sentry.captureMessage(message, level: SentryLevel.warning);
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
  UserSettings _settings = const UserSettings();
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
      // FLAG_SECURE is applied unconditionally, not gated on
      // appLockEnabled. Journal content is sensitive even without a PIN:
      // blocking screenshots + Recents thumbnails protects users who
      // have not set up app lock.
      setFlagSecure(true);
    });

    // Defer non-critical service init until after the first frame so the
    // splash screen paints immediately. NotificationService.init() is also
    // called lazily inside _loadSettings before scheduleDaily, so the race
    // between this callback and _loadSettings is safe (init is idempotent).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initBackgroundServices());
    });

    // Tell the widget service how to check lock state so
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


  @override
  void dispose() {
    _settingsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-lock when app goes to background (if lock is enabled).
  ///
  /// Lock on `inactive` as well as `paused`. `inactive` fires
  /// the instant the user swipes up into the app switcher or receives a
  /// phone call; `paused` fires later, once the OS has already snapshot
  /// the UI for the Recents thumbnail (or allowed another app to peek
  /// at the screen). Locking on `inactive` closes that window and moves
  /// the lock overlay in place BEFORE any OS-level snapshot is taken.
  ///
  /// FLAG_SECURE is now unconditional, so the thumbnail is
  /// blocked on Android regardless of this path. The iOS equivalent is
  /// handled separately by the iOS `applicationWillResignActive`
  /// blur overlay; this change is still useful on iOS because it means
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
    // Unconditional (see above).
    setFlagSecure(true);
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
