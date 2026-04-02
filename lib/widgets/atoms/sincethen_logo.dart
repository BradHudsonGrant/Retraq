import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_text.dart';

/// Shared logo widget that adapts to the current theme.
/// Uses `cs.primary` colorFilter for visibility in both light and dark mode.
///
/// Supports optional entrance animation (fade + scale) and a gentle
/// breathing pulse — both designed to be calming for ADHD users.
///
/// Set [showText] to display "SinceThen" branded text below the icon.
class SinceThenLogo extends StatefulWidget {
  const SinceThenLogo({
    super.key,
    this.size = 28,
    this.animate = false,
    this.breathe = false,
    this.showText = false,
    this.delay = Duration.zero,
  });

  final double size;

  /// Fade-in + scale entrance animation on first render.
  final bool animate;

  /// Continuous gentle scale pulse (lock screen "alive" feel).
  final bool breathe;

  /// Show branded "SinceThen" text below the icon.
  final bool showText;

  /// Delay before starting the entrance animation.
  final Duration delay;

  @override
  State<SinceThenLogo> createState() => _SinceThenLogoState();
}

class _SinceThenLogoState extends State<SinceThenLogo>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  AnimationController? _breatheController;
  Animation<double>? _breatheScale;

  bool _reduceMotion = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();

    // Entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    // Breathing pulse (controller created unconditionally so didChangeDependencies can manage it)
    if (widget.breathe) {
      _breatheController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      );
      _breatheScale = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(
          parent: _breatheController!,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldReduce = MediaQuery.of(context).disableAnimations;
    if (shouldReduce != _reduceMotion) {
      _reduceMotion = shouldReduce;
      _applyMotionPreference();
    } else if (!_reduceMotion && !_entranceController.isAnimating && !_entranceController.isCompleted) {
      // First frame — kick off animations.
      _applyMotionPreference();
    }
  }

  void _applyMotionPreference() {
    if (_reduceMotion) {
      // Skip entrance animation — jump to end.
      _entranceController.value = 1.0;
      // Stop breathing at midpoint (scale = 1.0).
      _breatheController?.stop();
      _breatheController?.value = 0.0;
    } else {
      // Entrance
      if (widget.animate) {
        if (widget.delay > Duration.zero) {
          _delayTimer?.cancel();
          _delayTimer = Timer(widget.delay, () {
            if (mounted) _entranceController.forward();
          });
        } else {
          _entranceController.forward();
        }
      } else {
        _entranceController.value = 1.0;
      }
      // Breathing
      if (widget.breathe && _breatheController != null && !_breatheController!.isAnimating) {
        _breatheController!.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _entranceController.dispose();
    _breatheController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget icon = SvgPicture.asset(
      'assets/images/logo.svg',
      semanticsLabel: 'SinceThen logo',
      width: widget.size,
      height: widget.size,
      colorFilter: ColorFilter.mode(cs.primary, BlendMode.srcIn),
    );

    // Wrap in breathing animation if active
    if (_breatheScale != null) {
      icon = ScaleTransition(scale: _breatheScale!, child: icon);
    }

    // Build the full logo (icon + optional branded text)
    Widget content = icon;
    if (widget.showText) {
      // Text size scales with icon size — roughly 30% of icon height
      final textSize = widget.size * 0.30;
      final spacing = widget.size * 0.08;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(height: spacing),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: AppText.headlineFamily,
                fontSize: textSize,
                color: cs.primary,
              ),
              children: const [
                TextSpan(
                  text: 'Since',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: 'Then',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Wrap in entrance animation
    return FadeTransition(
      opacity: _fadeIn,
      child: ScaleTransition(
        scale: _scaleIn,
        child: content,
      ),
    );
  }
}
