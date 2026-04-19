import 'dart:async';

import '../services/database_service.dart';

/// Attaches the standard app-wide stream error logger. Every Drift
/// `watch*` stream that propagates to the UI should flow through
/// [logStreamErrors] so failures get one formatted message + Sentry
/// capture instead of silent dropped frames.
extension LogStreamErrors<T> on Stream<T> {
  Stream<T> logStreamErrors(String context) =>
      handleError((e) => DatabaseService.logStreamError(context, e));
}
