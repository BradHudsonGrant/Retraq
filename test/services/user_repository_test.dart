import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/database_service.dart';
import 'package:retraq/services/user_repository.dart';

/// Repository-level coverage for consent records — the GDPR / UK-GDPR audit
/// trail. Auditors need proof that accepting Privacy / Terms / Health actually
/// lands in the DB with the right version string. Previously only verified
/// at the widget level by asserting the Accept button fired its callback.
void main() {
  late UserRepository repo;

  setUp(() async {
    // Fresh in-memory DB per test so consent rows don't leak across cases.
    await DatabaseService.instance.initInMemory();
    repo = DatabaseService.instance.userRepo;
  });

  group('UserRepository consent records', () {
    test('fresh install needs reconsent (no records yet)', () async {
      expect(await repo.needsReconsent(), isTrue);
      expect(await repo.getConsentRecords(), isEmpty);
    });

    test('saveConsentRecord persists a row with the supplied fields', () async {
      final now = DateTime(2026, 4, 6, 10, 15);
      final id = await repo.saveConsentRecord(
        consentType: 'privacy_policy',
        documentVersion: currentPrivacyPolicyVersion,
        acceptedAt: now,
        appVersion: '0.9.0',
      );

      expect(id, greaterThan(0));

      final rows = await repo.getConsentRecords();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.consentType, 'privacy_policy');
      expect(row.documentVersion, currentPrivacyPolicyVersion);
      expect(row.acceptedAt.toLocal(), now);
      expect(row.appVersion, '0.9.0');
    });

    test(
      'needsReconsent is false only after all three current versions are saved',
      () async {
        final now = DateTime.now();

        await repo.saveConsentRecord(
          consentType: 'privacy_policy',
          documentVersion: currentPrivacyPolicyVersion,
          acceptedAt: now,
        );
        expect(await repo.needsReconsent(), isTrue,
            reason: 'terms + health still missing');

        await repo.saveConsentRecord(
          consentType: 'terms_of_service',
          documentVersion: currentTermsOfServiceVersion,
          acceptedAt: now,
        );
        expect(await repo.needsReconsent(), isTrue,
            reason: 'health disclaimer still missing');

        await repo.saveConsentRecord(
          consentType: 'health_disclaimer',
          documentVersion: currentHealthDisclaimerVersion,
          acceptedAt: now,
        );
        expect(await repo.needsReconsent(), isFalse);
      },
    );

    test('stale document version still triggers reconsent', () async {
      final now = DateTime.now();
      // Pretend the user accepted an older version of privacy policy.
      await repo.saveConsentRecord(
        consentType: 'privacy_policy',
        documentVersion: '2025-01-01',
        acceptedAt: now,
      );
      await repo.saveConsentRecord(
        consentType: 'terms_of_service',
        documentVersion: currentTermsOfServiceVersion,
        acceptedAt: now,
      );
      await repo.saveConsentRecord(
        consentType: 'health_disclaimer',
        documentVersion: currentHealthDisclaimerVersion,
        acceptedAt: now,
      );

      expect(
        await repo.needsReconsent(),
        isTrue,
        reason: 'old privacy_policy version must force reconsent',
      );
    });

    test('getConsentRecords returns rows newest first', () async {
      await repo.saveConsentRecord(
        consentType: 'privacy_policy',
        documentVersion: currentPrivacyPolicyVersion,
        acceptedAt: DateTime(2026, 1, 1),
      );
      await repo.saveConsentRecord(
        consentType: 'terms_of_service',
        documentVersion: currentTermsOfServiceVersion,
        acceptedAt: DateTime(2026, 3, 1),
      );
      await repo.saveConsentRecord(
        consentType: 'health_disclaimer',
        documentVersion: currentHealthDisclaimerVersion,
        acceptedAt: DateTime(2026, 2, 1),
      );

      final rows = await repo.getConsentRecords();
      expect(rows, hasLength(3));
      expect(rows.map((r) => r.consentType), [
        'terms_of_service',
        'health_disclaimer',
        'privacy_policy',
      ]);
    });
  });
}
