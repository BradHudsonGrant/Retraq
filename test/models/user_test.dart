// ignore_for_file: prefer_single_quotes
import 'package:flutter_test/flutter_test.dart';
import 'package:sincethen/models/user.dart';

void main() {
  group('User', () {
    test('constructor sets default values', () {
      final user = User();

      expect(user.id, isNull);
      expect(user.displayName, isNull);
      expect(user.email, isNull);
      expect(user.subscriptionTier, 'free');
      expect(user.createdAt, isNotNull);
    });

    test('createdAt defaults to now when omitted', () {
      final before = DateTime.now();
      final user = User();
      final after = DateTime.now();

      expect(
        user.createdAt.isAfter(before) || user.createdAt == before,
        true,
      );
      expect(
        user.createdAt.isBefore(after) || user.createdAt == after,
        true,
      );
    });

    test('createdAt uses provided value when given', () {
      final custom = DateTime(2025, 6, 15, 10, 30);
      final user = User(createdAt: custom);
      expect(user.createdAt, custom);
    });

    test('constructor accepts all fields', () {
      final created = DateTime(2026, 1, 1);
      final user = User(
        id: 42,
        displayName: 'Alice',
        email: 'alice@example.com',
        subscriptionTier: 'premium',
        createdAt: created,
      );

      expect(user.id, 42);
      expect(user.displayName, 'Alice');
      expect(user.email, 'alice@example.com');
      expect(user.subscriptionTier, 'premium');
      expect(user.createdAt, created);
    });

    test('all fields are settable via copyWith', () {
      final user = User();

      final updated = user.copyWith(
        id: 7,
        displayName: 'Bob',
        email: 'bob@example.com',
        subscriptionTier: 'premium',
      );

      expect(updated.id, 7);
      expect(updated.displayName, 'Bob');
      expect(updated.email, 'bob@example.com');
      expect(updated.subscriptionTier, 'premium');
    });

    test('subscriptionTier defaults to free', () {
      final user = User();
      expect(user.subscriptionTier, 'free');
    });
  });
}
