import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Task 1.13 — Thin, release-safe logging façade over `dart:developer`.
///
/// Previously the app used `debugPrint` everywhere, which Flutter
/// strips in release builds — meaning shipped apps lose every
/// diagnostic. `AppLog` wraps `developer.log` so records survive
/// release mode when a user opts in via `--dart-define=RETRAQ_LOG=true`,
/// and provides a test sink so widget/unit tests can assert on emitted
/// records without coupling to `developer.log` behaviour.
///
/// Wiring Sentry/Crashlytics is deferred (v1.1): `sink` is intentionally
/// generic so a future `SentryLogSink` can subscribe without touching
/// callers.
class AppLog {
  AppLog._();

  /// Compile-time gate: when true, `info`/`warn`/`error` emit records
  /// even in release builds. Set with `--dart-define=RETRAQ_LOG=true`
  /// at build time. Defaults to false so production users aren't
  /// paying for logging overhead by accident.
  static const bool _kEnableReleaseLogs = bool.fromEnvironment(
    'RETRAQ_LOG',
    defaultValue: false,
  );

  /// Optional sink for tests and future Sentry/Crashlytics wiring. When
  /// non-null, receives every record regardless of build mode. Set to
  /// null in teardown to avoid cross-test bleed.
  static LogSink? sink;

  /// Info-level diagnostic. Use for non-error paths worth tracing
  /// (migration applied, cache rebuilt, stream subscription started).
  static void info(String scope, String message) {
    _emit(_LogLevel.info, scope, message);
  }

  /// Warn-level diagnostic. Use for recoverable oddities that might
  /// indicate a bug but don't prevent the operation (unexpected-null
  /// fallback, retry-after-failure).
  static void warn(
    String scope,
    Object message, [
    StackTrace? stackTrace,
  ]) {
    _emit(_LogLevel.warn, scope, message.toString(), stackTrace: stackTrace);
  }

  /// Error-level diagnostic. Use in `catch` blocks. The [error] is
  /// included in the `developer.log` record so debuggers can surface
  /// the object graph.
  static void error(
    String scope,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    _emit(
      _LogLevel.error,
      scope,
      error.toString(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _emit(
    _LogLevel level,
    String scope,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final record = LogRecord(
      level: level.name,
      scope: scope,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    // Test sink first so unit tests don't depend on developer.log.
    sink?.call(record);

    // In release builds without the opt-in define, skip the native
    // call too — there's no point paying for VM service overhead if
    // nothing is listening.
    if (kReleaseMode && !_kEnableReleaseLogs) return;

    developer.log(
      message,
      name: scope,
      level: level.severity,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// A captured log record — passed to any registered [LogSink].
@immutable
class LogRecord {
  const LogRecord({
    required this.level,
    required this.scope,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final String level;
  final String scope;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() => '[$level] $scope: $message';
}

/// Callback signature for [AppLog.sink]. Usually set only in tests or
/// by a future Sentry/Crashlytics adapter.
typedef LogSink = void Function(LogRecord record);

enum _LogLevel {
  info(severity: 800, name: 'info'),
  warn(severity: 900, name: 'warn'),
  error(severity: 1000, name: 'error');

  const _LogLevel({required this.severity, required this.name});

  final int severity;
  final String name;
}
