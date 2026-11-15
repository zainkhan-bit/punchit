import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final double offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _stepMs = 55;
  static const _runMs = 380;

  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    final delayMs = widget.index.clamp(0, 8) * _stepMs;
    final totalMs = delayMs + _runMs;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(delayMs / totalMs, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        child: widget.child,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

class AnimatedCount extends StatelessWidget {
  final double value;
  final String Function(double value) format;
  final TextStyle? style;

  const AnimatedCount({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(format(v), style: style),
    );
  }
}

class PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double scale;

  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed && widget.enabled ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  static const _base = AppColors.skeleton;
  static const _highlight = Color(0xFFF8F6F1);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (_, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-3 + 5 * t, 0),
            end: Alignment(-2 + 5 * t, 0),
            colors: const [_base, _highlight, _base],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final double spacing;

  const SkeletonList({
    super.key,
    this.count = 3,
    this.itemHeight = 92,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: SkeletonBox(height: itemHeight),
            ),
        ],
      ),
    );
  }
}

class Tilt3D extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final BorderRadius borderRadius;

  const Tilt3D({
    super.key,
    required this.child,
    this.maxTilt = 0.12,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  Offset _target = Offset.zero;
  bool _active = false;

  void _update(Offset local) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    final dx = (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0);
    final dy = (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0);
    setState(() {
      _target = Offset(dx, dy);
      _active = true;
    });
  }

  void _reset() {
    if (!_active && _target == Offset.zero) return;
    setState(() {
      _target = Offset.zero;
      _active = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) => _update(e.localPosition),
      onExit: (_) => _reset(),
      child: Listener(
        onPointerDown: (e) => _update(e.localPosition),
        onPointerMove: (e) => _update(e.localPosition),
        onPointerUp: (_) => _reset(),
        onPointerCancel: (_) => _reset(),
        child: TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(end: _target),
          duration: Duration(milliseconds: _active ? 140 : 520),
          curve: _active ? Curves.easeOut : Curves.easeOutBack,
          child: widget.child,
          builder: (_, tilt, child) {
            final strength = tilt.distance.clamp(0.0, 1.0);
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(-tilt.dy * widget.maxTilt)
                ..rotateY(tilt.dx * widget.maxTilt),
              child: Stack(
                children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: widget.borderRadius,
                          gradient: RadialGradient(
                            center: Alignment(tilt.dx, tilt.dy),
                            radius: 0.9,
                            colors: [
                              Colors.white.withValues(alpha: 0.16 * strength),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class FlipIn3D extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FlipIn3D({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 750),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: duration,
      curve: Curves.easeOutBack,
      child: child,
      builder: (_, t, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(t * math.pi / 2),
        child: child,
      ),
    );
  }
}

class PressDepth extends StatelessWidget {
  final Widget child;
  final bool pressed;
  final Color edgeColor;
  final double depth;
  final BorderRadius borderRadius;

  const PressDepth({
    super.key,
    required this.child,
    required this.pressed,
    required this.edgeColor,
    this.depth = 5,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: pressed ? 1 : 0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: child,
      builder: (_, t, child) {
        final lift = depth * (1 - t);
        return Padding(
          padding: EdgeInsets.only(bottom: depth),
          child: Transform.translate(
            offset: Offset(0, depth - lift),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(color: edgeColor, offset: Offset(0, lift)),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10 * (1 - t)),
                    blurRadius: 14,
                    offset: Offset(0, lift + 6),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
