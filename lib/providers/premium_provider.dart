import 'package:flutter/material.dart';

import '../services/purchase_service.dart';

/// Makes premium status available to the widget tree via [PremiumProvider.of].
class PremiumProvider extends StatefulWidget {
  final Widget child;

  const PremiumProvider({super.key, required this.child});

  /// Returns true if the user has an active premium subscription.
  static bool of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_PremiumInherited>()!
        .isPremium;
  }

  @override
  State<PremiumProvider> createState() => _PremiumProviderState();
}

class _PremiumProviderState extends State<PremiumProvider> {
  final _service = PurchaseService.instance;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _isPremium = _service.isPremium;
    _service.addListener(_onPremiumChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    final newValue = _service.isPremium;
    if (newValue != _isPremium) {
      setState(() => _isPremium = newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumInherited(
      isPremium: _isPremium,
      child: widget.child,
    );
  }
}

class _PremiumInherited extends InheritedWidget {
  final bool isPremium;

  const _PremiumInherited({
    required this.isPremium,
    required super.child,
  });

  @override
  bool updateShouldNotify(_PremiumInherited oldWidget) {
    return isPremium != oldWidget.isPremium;
  }
}
