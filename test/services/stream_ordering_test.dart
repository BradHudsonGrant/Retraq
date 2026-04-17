// ignore_for_file: prefer_single_quotes

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/services/database_service.dart';

import '../test_helpers.dart';

/// Task 6.4 (partial, 3 of 3) — stream-ordering race coverage.
///
/// The previous two partials of Task 6.4 covered:
/// - entry_repository_concurrency_test.dart — concurrent write atomicity
/// - lockout_controller_concurrency_test.dart — rapid-PIN guard
///
/// This file pins stream-subscriber ordering. HomeScreen and StatsScreen
/// both assume Drift's `watch*` streams emit in a monotonically
/// consistent order: each emission reflects a DB state that is EITHER
/// equal to OR newer than the previous one. Out-of-order emissions
/// cause visible UI glitches (a deleted entry briefly reappearing, a
/// higher streak number momentarily flashing to a lower one) and, worse,
/// widget-state invariants can corrupt (a setState branching on a stale
/// snapshot that the next emission will contradict).
///
/// Drift's internal stream implementation is already ordered, but this
/// test pins the contract so a future migration off Drift — or a
/// well-meaning refactor that introduces a `Stream.asyncMap` or an
/// extra `.debounceTime` — doesn't silently weaken it.
///
/// What "ordered" means here:
/// - Each emission has `entries.length >= previous.length - 1`
///   (at most one delete between emissions if the writes are
///   sequenced correctly; a monotonically advancing `max(createdAt)`
///   is the canonical marker).
/// - The FINAL emission matches a fresh SELECT — no buffered stale
///   snapshot slips out after the last DB write.
void main() {
  setUpAll(() async {
    await initTestDatabase();
  });
  tearDownAll(resetTestDatabase);

  tearDown(() async {
    await DatabaseService.instance.userRepo.deleteAllData();
  });

  group('watchWeekEntriesFrom stream ordering', () {
    test(
      '20 interleaved writes produce a strictly non-decreasing max(createdAt)',
      () async {
        // Week of 2026-06-01 (Monday) through 2026-06-07 (Sunday).
        final weekStart = DateTime(2026, 6, 1);
        final emissions = <List<JournalEntry>>[];
        final sub = DatabaseService.instance.entries
            .watchWeekEntriesFrom(weekStart)
            .listen(emissions.add);

        // Fire 20 inserts, a handful of updates via saveEntry
        // (upsert-by-id), and 5 deletes. Sequence the writes with
        // tiny microtask yields so the stream subscription has a
        // chance to emit between batches. This models what a
        // real-world save + auto-save + widget-triggered invalidate
        // look like on HomeScreen.
        final ids = <int>[];
        for (var i = 0; i < 20; i++) {
          final id = await DatabaseService.instance.entries.saveEntry(
            JournalEntry(
              date: weekStart.add(Duration(days: i % 7)),
              entry: 'stream-seed $i',
              createdAt: weekStart
                  .add(Duration(hours: i, minutes: (i * 7) % 60)),
            ),
          );
          ids.add(id);
          await Future<void>.delayed(Duration.zero);
        }

        // 5 deletes (every 4th row).
        for (var i = 0; i < ids.length; i += 4) {
          await DatabaseService.instance.entries.deleteEntry(ids[i]);
          await Future<void>.delayed(Duration.zero);
        }

        // Settle any trailing emissions.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        expect(emissions.isNotEmpty, isTrue,
            reason: 'stream must emit at least an initial snapshot');

        // Walk the emissions; each snapshot's max(createdAt) must be
        // greater than or equal to its predecessor's (allowing for
        // a delete-only emission that shortens the list but keeps
        // max(createdAt) the same).
        DateTime? prevMax;
        for (final snap in emissions) {
          if (snap.isEmpty) {
            prevMax = null;
            continue;
          }
          final snapMax = snap
              .map((e) => e.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
          if (prevMax != null) {
            expect(!snapMax.isBefore(prevMax),
                isTrue,
                reason: 'watchWeekEntriesFrom emitted an older snapshot '
                    'than its predecessor ($snapMax < $prevMax). Out-of-'
                    'order emissions cause UI glitches where a deleted '
                    'entry briefly reappears.');
          }
          prevMax = snapMax;
        }

        // Final state must match a fresh read — no buffered stale
        // snapshot lingers past the last write.
        final freshRead = await DatabaseService.instance.entries
            .watchWeekEntriesFrom(weekStart)
            .first;
        expect(freshRead, hasLength(15),
            reason: '20 inserts - 5 deletes = 15 entries in week');

        final lastEmission = emissions.last;
        expect(lastEmission.length, equals(freshRead.length),
            reason:
                'last stream emission must observe the final DB state, '
                'not a stale pre-delete snapshot');
      },
    );

    test(
      'deleting every entry emits a final empty list — no ghost rows',
      () async {
        final weekStart = DateTime(2026, 7, 6);
        final emissions = <int>[];
        final sub = DatabaseService.instance.entries
            .watchWeekEntriesFrom(weekStart)
            .listen((snap) => emissions.add(snap.length));

        final ids = <int>[];
        for (var i = 0; i < 10; i++) {
          final id = await DatabaseService.instance.entries.saveEntry(
            JournalEntry(
              date: weekStart,
              entry: 'soon-gone $i',
              createdAt: weekStart.add(Duration(minutes: i)),
            ),
          );
          ids.add(id);
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Concurrent deletes.
        await Future.wait(
          ids.map(DatabaseService.instance.entries.deleteEntry),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        // The final emission must be 0.
        expect(emissions.last, 0,
            reason: 'after 10 concurrent deletes the stream must settle '
                'on an empty snapshot; a ghost row here would surface '
                'as a deleted entry staying on screen');
        // Counts across emissions must be monotonically non-increasing
        // within the "delete phase" — once we start deleting, no
        // emission should jump back up.
        var sawFirstDrop = false;
        int? prev;
        for (final n in emissions) {
          if (!sawFirstDrop && prev != null && n < prev) {
            sawFirstDrop = true;
          }
          if (sawFirstDrop && prev != null) {
            expect(n, lessThanOrEqualTo(prev),
                reason:
                    'during the delete phase, list length must not grow');
          }
          prev = n;
        }
      },
    );

    test(
      'watchTotalEntryCount stream matches getTotalEntryCount at steady state',
      () async {
        // Count stream must agree with the imperative count after each
        // write settles. The cached count (Task 8.10) could drift if
        // the stream buffer and the SELECT see different transaction
        // snapshots.
        final counts = <int>[];
        final sub = DatabaseService.instance.entries
            .watchTotalEntryCount()
            .listen(counts.add);

        for (var i = 0; i < 5; i++) {
          await DatabaseService.instance.entries.saveEntry(
            JournalEntry(
              date: DateTime(2026, 8, 1 + i),
              entry: 'count $i',
              createdAt: DateTime(2026, 8, 1 + i, 9),
            ),
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        // Drift sometimes coalesces emissions; we don't assert the
        // exact count of emissions, only that the final one is 5.
        expect(counts.last, 5);
        expect(
          await DatabaseService.instance.entries.getTotalEntryCount(),
          equals(counts.last),
          reason: 'stream-derived count must match imperative count at '
              'steady state',
        );
      },
    );
  });
}
