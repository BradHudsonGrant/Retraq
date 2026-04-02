/// Rotating ADHD-friendly journal prompts shown as hint text.
/// Rotates deterministically by day of year so the user sees variety
/// without randomness (consistent across app restarts on the same day).
const _prompts = [
  'Just the highlights...',
  'What did you get up to today?',
  'Anything worth remembering?',
  'Drop a breadcrumb for future you.',
  'Sum it up in a few words.',
  'What was the vibe today?',
  'One good thing that happened...',
  'What took up most of your brain today?',
  'If today were a headline, what would it be?',
  'What would you tell a friend about today?',
  'The most unexpected part of today was...',
  'Three words to describe today.',
  'What did you learn today?',
  'What are you grateful for right now?',
  'What drained your energy today?',
  'What gave you energy today?',
  'Describe today in one sentence.',
  'Something you noticed today...',
  'A thought that kept coming back...',
  'The best part of today was...',
  'Something you want to remember...',
  'How are you feeling right now?',
  'What made you smile today?',
  'A small win from today...',
  'What would you do differently?',
  'What are you looking forward to tomorrow?',
  'Something that surprised you...',
  'A moment of calm from today...',
];

/// Get today's rotating journal prompt.
/// Uses day-of-year for deterministic daily rotation.
String dailyJournalPrompt() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  return _prompts[dayOfYear % _prompts.length];
}
