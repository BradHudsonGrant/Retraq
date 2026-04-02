import 'package:flutter/widgets.dart';
import '../models/user_settings.dart';

/// Provides the current [UserSettings] down the widget tree.
/// Updated by the root [SinceThenApp] whenever settings change.
class SettingsProvider extends InheritedWidget {
  const SettingsProvider({
    super.key,
    required this.settings,
    required super.child,
  });

  final UserSettings settings;

  static UserSettings of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<SettingsProvider>();
    assert(provider != null, 'No SettingsProvider found in context');
    return provider!.settings;
  }

  static UserSettings? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SettingsProvider>()?.settings;
  }

  @override
  bool updateShouldNotify(SettingsProvider oldWidget) =>
      settings != oldWidget.settings;
}
