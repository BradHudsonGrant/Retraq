import 'package:flutter/widgets.dart';

/// InheritedWidget that exposes the currently-active bottom nav
/// tab index to descendants.
///
/// AppShell's PageView keeps all children alive via
/// `AutomaticKeepAliveClientMixin` so stream subscriptions on
/// inactive tabs continue running and rebuilding off-screen. This
/// widget lets individual screens read which tab is active and
/// pause work they don't need (e.g., Drift watcher subscriptions)
/// when they're not visible.
///
/// Usage:
/// ```dart
/// @override
/// void didChangeDependencies() {
///   super.didChangeDependencies();
///   final isActive = ActiveTabScope.isActive(context, tabIndex: 0);
///   if (isActive) {
///     _subscriptions.forEach((s) => s.resume());
///   } else {
///     _subscriptions.forEach((s) => s.pause());
///   }
/// }
/// ```
///
/// AppShell provides exactly one of these at the root of its tree;
/// nested InheritedWidgets for the same type would confuse callers.
class ActiveTabScope extends InheritedWidget {
  const ActiveTabScope({
    super.key,
    required this.activeIndex,
    required super.child,
  });

  /// Current bottom-nav index (0 = Jot, 1 = Recap, 2 = Settings).
  final int activeIndex;

  /// Returns the current active index, or `null` if no ancestor
  /// ActiveTabScope exists (unit tests that pump a single screen
  /// without the shell).
  static int? maybeActiveIndexOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ActiveTabScope>();
    return scope?.activeIndex;
  }

  /// Convenience predicate: is the given tab the one currently
  /// being shown? Returns `true` when no ActiveTabScope ancestor
  /// exists, so unit tests pumping a screen in isolation behave
  /// as if the screen is active (no streams paused). Production
  /// code always has the ancestor because AppShell installs it.
  static bool isActive(BuildContext context, {required int tabIndex}) {
    final active = maybeActiveIndexOf(context);
    return active == null || active == tabIndex;
  }

  @override
  bool updateShouldNotify(ActiveTabScope old) => old.activeIndex != activeIndex;
}
