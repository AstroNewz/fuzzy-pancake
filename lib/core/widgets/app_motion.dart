import 'package:flutter/material.dart';

/// Shared motion that respects the system accessibility preference.
class AppMotion {
  static const duration = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;
  static Duration durationOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// Pointer feedback without competing with the child's tap or semantics.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});
  final Widget child;
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
            scale:
                _pressed && !MediaQuery.disableAnimationsOf(context) ? .96 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: widget.child),
      );
}

class Reveal extends StatelessWidget {
  const Reveal(
      {super.key, required this.child, this.offset = 16, this.delay = 0});
  final Widget child;
  final double offset;
  final int delay;

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? child
      : TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 520 + delay),
          curve: Interval(delay / (520 + delay), 1, curve: AppMotion.curve),
          child: child,
          builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                  offset: Offset(0, offset * (1 - value)), child: child)),
        );
}

class AnimatedStat extends StatelessWidget {
  const AnimatedStat({super.key, required this.value, required this.style});
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
        label: value.toString(),
        child: ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 900),
          curve: Curves.easeOutQuart,
          builder: (_, number, __) =>
              Text(number.round().toString(), style: style),
        )),
      );
}

/// Avoid starting a zero-duration layout animation when reduced motion is on.
class MotionSize extends StatelessWidget {
  const MotionSize(
      {super.key,
      required this.child,
      required this.duration,
      this.alignment = Alignment.center});
  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;
  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSize(
          duration: duration,
          alignment: alignment,
          curve: AppMotion.curve,
          child: child);
}

class DeckPageTransitions extends PageTransitionsBuilder {
  const DeckPageTransitions();
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
        opacity: curved,
        child: SlideTransition(
            position: curved
                .drive(Tween(begin: const Offset(0.035, 0), end: Offset.zero)),
            child: child));
  }
}
