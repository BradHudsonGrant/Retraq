// ignore_for_file: prefer_single_quotes
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/user.dart';

void main() {
  group('User.copyWith', () {
    test('every field is settable', () {
      // Guards against adding a field to User but forgetting to thread
      // it through copyWith. A silently-dropped field would cause
      // "my profile reverts on save" bugs.
      final user = User();
      final createdAt = DateTime(2026, 4, 20);
      final updated = user.copyWith(
        id: 7,
        displayName: 'Bob',
        email: 'bob@example.com',
        createdAt: createdAt,
      );

      expect(updated.id, 7);
      expect(updated.displayName, 'Bob');
      expect(updated.email, 'bob@example.com');
      expect(updated.createdAt, createdAt);
    });
  });
}
