import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/app_log.dart';

/// AppLog captures records through its sink so future
/// Sentry/Crashlytics adapters can subscribe without touching callers,
/// and so unit tests can assert on emitted diagnostics.
void main() {
  group('AppLog', () {
    final captured = <LogRecord>[];

    setUp(() {
      captured.clear();
      AppLog.sink = captured.add;
    });

    tearDown(() {
      AppLog.sink = null;
    });

    test('info emits one record with info level and given scope', () {
      AppLog.info('DatabaseService', 'migrated to v14');
      expect(captured, hasLength(1));
      expect(captured.first.level, 'info');
      expect(captured.first.scope, 'DatabaseService');
      expect(captured.first.message, 'migrated to v14');
      expect(captured.first.error, isNull);
    });

    test('warn emits warn-level record and accepts an optional stack', () {
      final st = StackTrace.current;
      AppLog.warn('EntryRepository', 'unexpected null userId', st);
      expect(captured, hasLength(1));
      expect(captured.first.level, 'warn');
      expect(captured.first.stackTrace, same(st));
    });

    test('error records include the thrown object and its string form', () {
      final err = StateError('db closed mid-write');
      AppLog.error('ExportService', err);
      expect(captured, hasLength(1));
      expect(captured.first.level, 'error');
      expect(captured.first.error, same(err));
      expect(captured.first.message, contains('db closed mid-write'));
    });

    test('LogRecord.toString renders level, scope, message', () {
      const r = LogRecord(
        level: 'warn',
        scope: 'Foo',
        message: 'bar',
      );
      expect(r.toString(), '[warn] Foo: bar');
    });

    test('sink set to null stops capture — no records leak after tearDown', () {
      AppLog.info('scope', 'before');
      AppLog.sink = null;
      AppLog.info('scope', 'after');
      expect(captured, hasLength(1));
      expect(captured.single.message, 'before');
    });
  });
}
