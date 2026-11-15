import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive wrapper that provides subtle press-down tactile feedback
/// and micro-haptics following FORMA's motion design guidelines.
class FormaBounceable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final Duration duration;
  final bool enableHaptics;
  final HitTestBehavior behavior;

  const FormaBounceable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.enableHaptics = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<FormaBounceable> createState() => _FormaBounceableState();
}

class _FormaBounceableState extends State<FormaBounceable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration * 1.5,
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _controller.reverse();
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion || (widget.onTap == null && widget.onLongPress == null)) {
      return GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: widget.child,
      );
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: () {
        _controller.reverse();
        if (widget.enableHaptics) {
          HapticFeedback.mediumImpact();
        }
        widget.onLongPress?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
