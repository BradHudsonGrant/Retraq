// ignore_for_file: prefer_single_quotes

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/journal_entry.dart';
import '../app_log.dart';

/// Capability states for the device's built-in AI.
///
/// Mirrors the native side (Android: `FeatureStatus` from ML Kit GenAI;
/// iOS: Apple Foundation Models availability). The Dart side treats every
/// non-available state as "don't try inference" and falls back to the
/// template observation.
enum RecapAiStatus {
  /// Device does not support on-device inference at all (old hardware,
  /// no Apple Intelligence, etc.). Toggle is disabled in the UI.
  unavailable,

  /// Supported, but model weights are not yet on disk. Toggling the
  /// setting starts a background download the next time a recap runs.
  downloadable,

  /// Download in progress.
  downloading,

  /// Model is on device and ready to answer prompts immediately.
  available,
}

/// Event emitted by [RecapAiProvider.events] — status transitions and
/// download progress folded into a single stream so the UI only needs
/// one subscription.
///
/// ML Kit reports download progress as "total bytes downloaded so far"
/// with no denominator, so [bytesDownloaded] is monotonically increasing
/// but [totalBytes] is almost always `null`. Render as an indeterminate
/// bar + a "X MB downloaded" caption rather than a percentage.
class RecapAiEvent {
  const RecapAiEvent({
    required this.status,
    this.bytesDownloaded,
    this.totalBytes,
    this.errorMessage,
  });

  final RecapAiStatus status;
  final int? bytesDownloaded;
  final int? totalBytes;
  final String? errorMessage;

  @override
  String toString() =>
      'RecapAiEvent(status: $status, bytes: $bytesDownloaded/$totalBytes, '
      'err: $errorMessage)';
}

/// Produces the "observation" string that anchors the weekly recap card.
///
/// Two implementations ship:
///   * [TemplateRecapAiProvider] — deterministic, offline, zero deps.
///   * [PlatformRecapAiProvider] — bridges to the host OS's on-device AI
///     through a [MethodChannel]. Entries never leave the device; we
///     just hand them to the OS's sandboxed inference runtime.
abstract class RecapAiProvider {
  /// Cheap probe so the settings UI can disable the toggle when the
  /// device has no on-device AI at all. Safe to call every build.
  Future<RecapAiStatus> checkStatus();

  /// Broadcast stream of status + download-progress events. The settings
  /// card listens to render the progress bar; the recap screen listens
  /// so it can auto-refresh to the AI observation the moment the model
  /// finishes downloading. Always a broadcast stream so multiple
  /// subscribers don't fight over the underlying platform channel.
  Stream<RecapAiEvent> events();

  /// Idempotently ensure the model is downloading (if it isn't already on
  /// device). No-op on platforms without on-device AI or when the model
  /// is already `available`. Resolves as soon as the native side has
  /// dispatched the start call — actual completion arrives via [events].
  Future<void> startDownload();

  /// Generate the warm, two-sentence observation for this week. The
  /// provider receives the pre-computed stats so small models don't
  /// have to recompute them. `entries` are the raw user journal entries
  /// for the week — provider decides how much to feed into the prompt.
  Future<String> summarize({
    required int totalEntries,
    required int activeDays,
    required int streak,
    required String busiestDay,
    required String preferredTime,
    required double? averageMood,
    required List<JournalEntry> entries,
  });
}

/// Default fallback. Mirrors the template logic that has always lived
/// inline in `RecapService`; extracted so `RecapService` can delegate
/// to an AI provider without branching every code path.
class TemplateRecapAiProvider implements RecapAiProvider {
  const TemplateRecapAiProvider();

  @override
  Future<RecapAiStatus> checkStatus() async => RecapAiStatus.available;

  @override
  Stream<RecapAiEvent> events() => const Stream.empty();

  @override
  Future<void> startDownload() async {
    // Template provider has nothing to download — the "model" is inline.
  }

  @override
  Future<String> summarize({
    required int totalEntries,
    required int activeDays,
    required int streak,
    required String busiestDay,
    required String preferredTime,
    required double? averageMood,
    required List<JournalEntry> entries,
  }) async {
    String observation;
    if (totalEntries == 0) {
      observation =
          "No entries this week. That's okay \u2014 every week is different.";
    } else if (totalEntries == 1) {
      observation =
          "You captured one moment this week. Even a single entry matters.";
    } else if (activeDays == 7) {
      observation =
          "You journaled every day this week! Incredible consistency.";
    } else if (streak >= 3) {
      observation = "You're on a $streak-day streak. Nice momentum!";
    } else {
      observation =
          "You wrote $totalEntries entries across $activeDays days. $busiestDay was your most active day.";
    }

    if (averageMood != null) {
      observation += " Your average mood was ${_moodLabel(averageMood)}.";
    }
    return observation;
  }

  static String _moodLabel(double avg) {
    if (avg >= 4.5) return "Amazing";
    if (avg >= 3.5) return "Good";
    if (avg >= 2.5) return "Neutral";
    if (avg >= 1.5) return "Low";
    return "Rough";
  }
}

/// Bridges to the host OS's on-device AI.
///
/// Android: wraps ML Kit GenAI Prompt API (Gemini Nano via AICore).
/// iOS: wraps Apple Foundation Models (currently stubbed — always
/// returns [RecapAiStatus.unavailable] until we can test on device).
///
/// The channel contract is:
///   * `checkStatus`  -> String one of: unavailable|downloadable|downloading|available
///   * `summarize`    -> String (the final observation text)
///     args: { prompt: String, maxOutputTokens: int }
///
/// Errors bubble as [PlatformException]; callers should catch and fall
/// back to the template provider rather than surface the error.
class PlatformRecapAiProvider implements RecapAiProvider {
  PlatformRecapAiProvider({MethodChannel? channel, EventChannel? eventChannel})
      : _channel = channel ?? const MethodChannel(channelName),
        _eventChannel =
            eventChannel ?? const EventChannel(eventChannelName);

  static const String channelName = 'com.retraq.app/ondevice_ai';
  static const String eventChannelName = 'com.retraq.app/ondevice_ai/events';

  final MethodChannel _channel;
  final EventChannel _eventChannel;

  // Broadcast so multiple widgets (settings card + recap screen) can
  // subscribe at once without fighting over the platform stream. Cached
  // so re-subscribes don't re-open the underlying EventChannel.
  Stream<RecapAiEvent>? _eventsBroadcast;

  @override
  Future<RecapAiStatus> checkStatus() async {
    try {
      final result = await _channel.invokeMethod<String>('checkStatus');
      switch (result) {
        case 'available':
          return RecapAiStatus.available;
        case 'downloadable':
          return RecapAiStatus.downloadable;
        case 'downloading':
          return RecapAiStatus.downloading;
        case 'unavailable':
        default:
          return RecapAiStatus.unavailable;
      }
    } catch (e) {
      // Missing plugin / channel = platform doesn't implement it yet.
      if (kDebugMode) {
        AppLog.error('PlatformRecapAiProvider.checkStatus', e);
      }
      return RecapAiStatus.unavailable;
    }
  }

  @override
  Stream<RecapAiEvent> events() {
    return _eventsBroadcast ??=
        _eventChannel.receiveBroadcastStream().map(_decodeEvent).handleError((
      Object e,
    ) {
      // Platform channel missing = treat as unavailable rather than
      // blowing up the widget tree.
      if (kDebugMode) {
        AppLog.error('PlatformRecapAiProvider.events', e);
      }
    }).asBroadcastStream();
  }

  @override
  Future<void> startDownload() async {
    try {
      await _channel.invokeMethod<void>('startDownload');
    } catch (e) {
      if (kDebugMode) {
        AppLog.error('PlatformRecapAiProvider.startDownload', e);
      }
      // Silent fail — the events stream will report any failure state;
      // the UI shouldn't show an error for a missing channel.
    }
  }

  static RecapAiEvent _decodeEvent(dynamic raw) {
    final map = (raw as Map).cast<String, dynamic>();
    final statusStr = map['status'] as String?;
    final status = switch (statusStr) {
      'available' => RecapAiStatus.available,
      'downloadable' => RecapAiStatus.downloadable,
      'downloading' => RecapAiStatus.downloading,
      _ => RecapAiStatus.unavailable,
    };
    return RecapAiEvent(
      status: status,
      bytesDownloaded: (map['bytesDownloaded'] as num?)?.toInt(),
      totalBytes: (map['totalBytes'] as num?)?.toInt(),
      errorMessage: map['errorMessage'] as String?,
    );
  }

  @override
  Future<String> summarize({
    required int totalEntries,
    required int activeDays,
    required int streak,
    required String busiestDay,
    required String preferredTime,
    required double? averageMood,
    required List<JournalEntry> entries,
  }) async {
    final prompt = buildPrompt(
      totalEntries: totalEntries,
      activeDays: activeDays,
      streak: streak,
      busiestDay: busiestDay,
      preferredTime: preferredTime,
      averageMood: averageMood,
      entries: entries,
    );

    final result = await _channel.invokeMethod<String>('summarize', {
      'prompt': prompt,
      // 256 tokens = ~190 words. Enough for a two-sentence warm recap
      // without rambling, and matches the ML Kit Prompt API guidance
      // to keep outputs short for quality.
      'maxOutputTokens': 256,
    });
    final trimmed = result?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      throw const FormatException('On-device AI returned empty response');
    }
    return trimmed;
  }

  /// Exposed for tests — deterministic prompt construction.
  ///
  /// The prompt is aggressively directive because Gemini Nano is small
  /// enough that a looser instruction set produces generic output like
  /// "you have a nice habit". We force:
  ///   * exactly 3–5 bullets
  ///   * each bullet grounded in an actual entry (past tense)
  ///   * no meta praise ("great week", "keep it up"), no mention of
  ///     journaling
  ///   * strict "- " prefix so the Dart-side parser can split reliably
  @visibleForTesting
  static String buildPrompt({
    required int totalEntries,
    required int activeDays,
    required int streak,
    required String busiestDay,
    required String preferredTime,
    required double? averageMood,
    required List<JournalEntry> entries,
  }) {
    final buf = StringBuffer();
    buf.writeln(
      'You are writing a recap of someone\'s week from the notes they '
      'logged each day. Your job is to tell them back what they did — '
      'specific, concrete, concise.',
    );
    buf.writeln();
    buf.writeln('OUTPUT FORMAT (follow exactly):');
    buf.writeln('- <one thing they did, past tense, \u2264 12 words>');
    buf.writeln('- <one thing they did, past tense, \u2264 12 words>');
    buf.writeln('- <one thing they did, past tense, \u2264 12 words>');
    buf.writeln('(up to 5 bullets total)');
    buf.writeln();
    buf.writeln('RULES:');
    buf.writeln('1. Output ONLY bullet lines starting with "- ". No intro, no outro, no headings.');
    buf.writeln('2. Each bullet describes ONE specific thing from their notes below.');
    buf.writeln('3. Bullets MUST appear in the same chronological order as the notes below (earliest entry first). Do not reorder.');
    buf.writeln('4. Do NOT include the day name in the bullet text. Just describe what they did.');
    buf.writeln('5. Name the people, places, or activities they mentioned.');
    buf.writeln('6. Past tense. Start each bullet with a verb when possible.');
    buf.writeln('7. If the week was quiet, output fewer bullets — do not invent events.');
    buf.writeln('8. Do NOT praise them. Do NOT mention habits, streaks, consistency, or journaling.');
    buf.writeln('9. Do NOT use phrases like "you had a", "nice", "great", "wonderful", "keep it up".');
    buf.writeln();
    buf.writeln('CONTEXT (for your reference only, do not restate):');
    buf.writeln('Total entries: $totalEntries across $activeDays day(s).');
    if (busiestDay.isNotEmpty) buf.writeln('Most active day: $busiestDay.');
    buf.writeln('Writing pattern: $preferredTime.');
    if (averageMood != null) {
      buf.writeln('Average mood (1-5): ${averageMood.toStringAsFixed(1)}.');
    }
    buf.writeln();
    buf.writeln('THEIR NOTES (in chronological order, earliest first, one per line, "[day]: [what they wrote]"):');
    // Chronological so the model can narrate the week in the order the
    // user lived it — Monday → Sunday (or Sunday → Saturday, etc.,
    // depending on their configured week-start day). Keep payload well
    // under the 4K-token input ceiling; take the first 20 entries if a
    // week was unusually prolific.
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final weekdayNames = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };
    var included = 0;
    for (final e in sorted) {
      if (included >= 20) break;
      final text = (e.entry ?? '').trim();
      if (text.isEmpty) continue;
      final snippet =
          text.length > 400 ? '${text.substring(0, 400)}\u2026' : text;
      final dayName = weekdayNames[e.date.weekday] ?? '';
      final labelSuffix =
          (e.label == 'AM' || e.label == 'PM') ? ' ${e.label}' : '';
      buf.writeln('- $dayName$labelSuffix: $snippet');
      included++;
    }
    if (included == 0) {
      // Nothing usable — tell the model explicitly so it doesn't
      // hallucinate. RecapService already short-circuits to the template
      // when totalEntries < 2, so this branch only fires for edge cases
      // like all-empty entries (e.g. mood-only).
      buf.writeln('(no written notes this week)');
    }
    buf.writeln();
    buf.writeln('Now write the bullets:');
    return buf.toString();
  }
}

/// Parse an observation string into bullet lines. Tolerates Gemini
/// Nano's varied formatting:
///   * "- foo", "* foo", "\u2022 foo"
///   * "1. foo", "1) foo"
///   * stray intros like "Here's your week:" that precede the bullets
///   * prose with multiple sentences (returned as a single bullet)
///
/// Returns an empty list when [observation] is null/empty. Never throws.
List<String> parseRecapBullets(String? observation) {
  if (observation == null) return const [];
  final lines = observation.split(RegExp(r'\r?\n'));
  final bullets = <String>[];
  for (final raw in lines) {
    var line = raw.trim();
    if (line.isEmpty) continue;
    // Strip common bullet markers.
    line = line.replaceFirst(RegExp(r'^[-*\u2022\u2013]\s*'), '');
    // Strip "1. " / "1) " style numbering.
    line = line.replaceFirst(RegExp(r'^\d+[\.)]\s*'), '');
    // Drop obvious intro/outro lines that aren't part of the recap.
    final lower = line.toLowerCase();
    if (lower.endsWith(':') &&
        (lower.startsWith('here') ||
            lower.startsWith('your week') ||
            lower.startsWith('summary'))) {
      continue;
    }
    if (line.isEmpty) continue;
    bullets.add(line);
  }
  // Cap to 5 — the prompt asks for at most 5 but the model occasionally
  // runs long.
  if (bullets.length > 5) return bullets.sublist(0, 5);
  return bullets;
}
