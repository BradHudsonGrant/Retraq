// ignore_for_file: prefer_single_quotes

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/services/ai/recap_ai_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TemplateRecapAiProvider', () {
    const provider = TemplateRecapAiProvider();

    test('reports available so callers never skip the template path',
        () async {
      expect(await provider.checkStatus(), RecapAiStatus.available);
    });

    test('returns the empty-week message when totalEntries is 0', () async {
      final result = await provider.summarize(
        totalEntries: 0,
        activeDays: 0,
        streak: 0,
        busiestDay: '',
        preferredTime: 'throughout the day',
        averageMood: null,
        entries: const [],
      );
      expect(result, contains('No entries this week'));
    });

    test('mentions the streak when >= 3 consecutive days', () async {
      final result = await provider.summarize(
        totalEntries: 5,
        activeDays: 5,
        streak: 5,
        busiestDay: 'Wednesday',
        preferredTime: 'morning',
        averageMood: null,
        entries: const [],
      );
      expect(result, contains('5-day streak'));
    });

    test('appends mood label when averageMood is provided', () async {
      final result = await provider.summarize(
        totalEntries: 2,
        activeDays: 2,
        streak: 0,
        busiestDay: 'Monday',
        preferredTime: 'throughout the day',
        averageMood: 4.7,
        entries: const [],
      );
      expect(result, contains('Amazing'));
    });
  });

  group('PlatformRecapAiProvider', () {
    // Unique channel name per-test so the mock handler reset between
    // tests is unambiguous — test fixture can't leak into production
    // channel traffic during the rest of the suite.
    const testChannelName = 'retraq_test/ondevice_ai';
    const testChannel = MethodChannel(testChannelName);

    tearDown(() {
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, null);
    });

    test('maps native status strings to RecapAiStatus enum', () async {
      final values = <String, RecapAiStatus>{
        'available': RecapAiStatus.available,
        'downloadable': RecapAiStatus.downloadable,
        'downloading': RecapAiStatus.downloading,
        'unavailable': RecapAiStatus.unavailable,
      };
      for (final entry in values.entries) {
        TestDefaultBinaryMessengerBinding
            .instance.defaultBinaryMessenger
            .setMockMethodCallHandler(testChannel, (call) async {
          expect(call.method, 'checkStatus');
          return entry.key;
        });
        final provider = PlatformRecapAiProvider(channel: testChannel);
        expect(
          await provider.checkStatus(),
          entry.value,
          reason: 'native "${entry.key}" should map to ${entry.value}',
        );
      }
    });

    test('treats missing channel implementation as unavailable', () async {
      // No handler registered — simulates running on a platform that
      // hasn't wired up the native bridge (e.g. desktop or web tests).
      final provider =
          PlatformRecapAiProvider(channel: const MethodChannel('retraq/unused'));
      expect(await provider.checkStatus(), RecapAiStatus.unavailable);
    });

    test('summarize forwards the prompt and returns the trimmed response',
        () async {
      String? capturedPrompt;
      int? capturedMaxTokens;
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (call) async {
        expect(call.method, 'summarize');
        final args = (call.arguments as Map).cast<String, dynamic>();
        capturedPrompt = args['prompt'] as String;
        capturedMaxTokens = args['maxOutputTokens'] as int;
        return '  A warm little recap.  \n';
      });

      final provider = PlatformRecapAiProvider(channel: testChannel);
      final result = await provider.summarize(
        totalEntries: 3,
        activeDays: 2,
        streak: 2,
        busiestDay: 'Friday',
        preferredTime: 'evening',
        averageMood: 3.5,
        entries: [
          JournalEntry(
            date: DateTime(2026, 4, 17),
            entry: 'Long Friday — shipped the migration.',
            createdAt: DateTime(2026, 4, 17),
          ),
        ],
      );

      expect(result, 'A warm little recap.');
      expect(capturedPrompt, isNotNull);
      expect(capturedPrompt, contains('Friday'));
      expect(capturedMaxTokens, 256);
    });

    test('summarize throws on empty response so RecapService can fallback',
        () async {
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (_) async => '   ');
      final provider = PlatformRecapAiProvider(channel: testChannel);
      await expectLater(
        provider.summarize(
          totalEntries: 1,
          activeDays: 1,
          streak: 1,
          busiestDay: 'Monday',
          preferredTime: 'morning',
          averageMood: null,
          entries: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('startDownload invokes the native method and tolerates no handler',
        () async {
      String? calledMethod;
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testChannel, (call) async {
        calledMethod = call.method;
        return null;
      });
      final provider = PlatformRecapAiProvider(channel: testChannel);
      await provider.startDownload();
      expect(calledMethod, 'startDownload');

      // Without a handler, startDownload should still complete silently
      // — the UI doesn't surface this error and falls back to template.
      final orphan =
          PlatformRecapAiProvider(channel: const MethodChannel('retraq/unused'));
      await expectLater(orphan.startDownload(), completes);
    });

    group('buildPrompt', () {
      test('includes all stats + strict bullet format + anti-praise rules',
          () {
        final prompt = PlatformRecapAiProvider.buildPrompt(
          totalEntries: 4,
          activeDays: 3,
          streak: 2,
          busiestDay: 'Thursday',
          preferredTime: 'evening',
          averageMood: 4.1,
          entries: const [],
        );
        // Stats are in the CONTEXT block.
        expect(prompt, contains('4 across 3 day'));
        expect(prompt, contains('Thursday'));
        expect(prompt, contains('evening'));
        expect(prompt, contains('4.1'));
        // Directive structure is present so the model knows to produce
        // bullets and avoid generic praise.
        expect(prompt, contains('OUTPUT FORMAT'));
        expect(prompt, contains('past tense'));
        expect(prompt, contains('Do NOT praise'));
      });

      test('omits busiest day + mood lines when unset', () {
        final prompt = PlatformRecapAiProvider.buildPrompt(
          totalEntries: 1,
          activeDays: 1,
          streak: 0,
          busiestDay: '',
          preferredTime: 'throughout the day',
          averageMood: null,
          entries: const [],
        );
        expect(prompt, isNot(contains('Most active day')));
        expect(prompt, isNot(contains('Average mood')));
      });

      test('formats entries chronologically with "[day]: [text]" lines', () {
        final prompt = PlatformRecapAiProvider.buildPrompt(
          totalEntries: 2,
          activeDays: 2,
          streak: 2,
          busiestDay: 'Wednesday',
          preferredTime: 'evening',
          averageMood: null,
          entries: [
            JournalEntry(
              date: DateTime(2026, 4, 15), // Wednesday
              entry: 'Shipped the migration after three rollbacks.',
              label: 'PM',
              createdAt: DateTime(2026, 4, 15, 18),
            ),
            JournalEntry(
              date: DateTime(2026, 4, 13), // Monday
              entry: 'Coffee with Sarah — she got the promotion.',
              createdAt: DateTime(2026, 4, 13, 9),
            ),
          ],
        );
        // Entries are labelled with the weekday so the AI can ground on
        // them when ordering bullets — but the bullets it emits should
        // NOT include the day prefix.
        expect(prompt, contains('Monday: Coffee with Sarah'));
        expect(
          prompt,
          contains('Wednesday PM: Shipped the migration'),
        );
        // Chronological order: Monday should appear before Wednesday in
        // the prompt so the model narrates the week forwards.
        final mondayIdx = prompt.indexOf('Monday: Coffee');
        final wednesdayIdx = prompt.indexOf('Wednesday PM: Shipped');
        expect(mondayIdx, lessThan(wednesdayIdx));
        // Output rules explicitly forbid day prefixes in the bullets,
        // so the model doesn't repeat what the UI already shows.
        expect(prompt, contains('Do NOT include the day name'));
        expect(prompt, contains('chronological order'));
      });

      test('caps entry text at 400 characters per entry', () {
        final longText = 'a' * 600;
        final prompt = PlatformRecapAiProvider.buildPrompt(
          totalEntries: 1,
          activeDays: 1,
          streak: 1,
          busiestDay: 'Monday',
          preferredTime: 'morning',
          averageMood: null,
          entries: [
            JournalEntry(
              date: DateTime(2026, 4, 13),
              entry: longText,
              createdAt: DateTime(2026, 4, 13),
            ),
          ],
        );
        expect(prompt.contains(longText), isFalse);
        expect(prompt, contains('…'));
      });
    });
  });

  group('parseRecapBullets', () {
    test('splits dash-prefixed lines into bullets', () {
      final bullets = parseRecapBullets(
        '- Coffee with Sarah\n- Ran on Tuesday\n- Shipped the migration',
      );
      expect(bullets, [
        'Coffee with Sarah',
        'Ran on Tuesday',
        'Shipped the migration',
      ]);
    });

    test('tolerates mixed bullet markers (*, \u2022, numbered)', () {
      final bullets = parseRecapBullets(
        '* Foo\n\u2022 Bar\n1. Baz\n2) Qux',
      );
      expect(bullets, ['Foo', 'Bar', 'Baz', 'Qux']);
    });

    test('strips preamble lines that end in a colon', () {
      final bullets = parseRecapBullets(
        "Here's your week:\n- Foo\n- Bar",
      );
      expect(bullets, ['Foo', 'Bar']);
    });

    test('returns single-element list for prose observation', () {
      final bullets = parseRecapBullets(
        "You captured one moment this week. Even a single entry matters.",
      );
      expect(bullets, hasLength(1));
      expect(bullets.first, contains('one moment'));
    });

    test('caps at 5 bullets even if the model runs long', () {
      final input = List.generate(8, (i) => '- item $i').join('\n');
      final bullets = parseRecapBullets(input);
      expect(bullets, hasLength(5));
    });

    test('empty / null input returns an empty list', () {
      expect(parseRecapBullets(null), isEmpty);
      expect(parseRecapBullets(''), isEmpty);
      expect(parseRecapBullets('   \n  \n'), isEmpty);
    });
  });
}
