// ignore_for_file: prefer_single_quotes

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/l10n/app_localizations.dart';
import 'package:retraq/utils/milestones.dart';

/// Task 1.2 — tests for `milestoneMessageFor` + `isMilestoneCount`,
/// the pure-function milestone gate extracted from home_screen.dart.
///
/// Milestone count thresholds are load-bearing for the save-success
/// overlay hold duration (1000ms on milestones + first ten saves,
/// 400ms otherwise — Task 2.15). If a threshold disappears silently,
/// users lose a celebration cue. Pin every current one here so a
/// future refactor has to update this file too.
void main() {
  late L10n l10n;

  setUpAll(() async {
    l10n = await L10n.delegate.load(const Locale('en'));
  });

  group('milestoneMessageFor', () {
    test('returns copy for the first traq', () {
      expect(milestoneMessageFor(1, l10n), l10n.milestone1);
    });

    test('returns copy for every documented threshold', () {
      // One assertion per threshold — a silent drop of any would be
      // a real UX regression (lost celebration cue).
      expect(milestoneMessageFor(5, l10n), l10n.milestone5);
      expect(milestoneMessageFor(10, l10n), l10n.milestone10);
      expect(milestoneMessageFor(25, l10n), l10n.milestone25);
      expect(milestoneMessageFor(50, l10n), l10n.milestone50);
      expect(milestoneMessageFor(100, l10n), l10n.milestone100);
      expect(milestoneMessageFor(250, l10n), l10n.milestone250);
      expect(milestoneMessageFor(500, l10n), l10n.milestone500);
      expect(milestoneMessageFor(1000, l10n), l10n.milestone1000);
    });

    test('returns null on non-milestone counts', () {
      expect(milestoneMessageFor(0, l10n), isNull);
      expect(milestoneMessageFor(2, l10n), isNull);
      expect(milestoneMessageFor(11, l10n), isNull);
      expect(milestoneMessageFor(99, l10n), isNull);
      expect(milestoneMessageFor(101, l10n), isNull);
      expect(milestoneMessageFor(999, l10n), isNull);
      expect(milestoneMessageFor(1001, l10n), isNull);
      expect(milestoneMessageFor(10000, l10n), isNull,
          reason:
              'Far-future count must return null — no silent new '
              'milestone creep. To add one, update milestoneThresholds '
              'and the ARB (see the doc comment).');
    });

    test('negative counts return null', () {
      // Shouldn't happen in practice, but belt-and-suspenders: no
      // underflow weirdness producing a negative-indexed milestone.
      expect(milestoneMessageFor(-1, l10n), isNull);
      expect(milestoneMessageFor(-1000, l10n), isNull);
    });
  });

  group('isMilestoneCount', () {
    test('matches milestoneMessageFor domain exactly', () {
      // If these ever disagree, the UI branching (overlay hold
      // duration vs message display) would split. Pin them
      // equivalent.
      for (final n in [0, 1, 2, 5, 10, 11, 100, 500, 999, 1000, 1001]) {
        expect(
          isMilestoneCount(n),
          milestoneMessageFor(n, l10n) != null,
          reason: 'isMilestoneCount($n) must match '
              'milestoneMessageFor($n) != null',
        );
      }
    });

    test('threshold list is exactly the 9 documented counts', () {
      // Guards against silent threshold drops — the save-success
      // overlay hold-duration math relies on this list.
      expect(milestoneThresholds, [1, 5, 10, 25, 50, 100, 250, 500, 1000]);
    });
  });
}
