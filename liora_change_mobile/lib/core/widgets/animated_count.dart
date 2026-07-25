import 'package:flutter/material.dart';

/// Counts up to [value] and hands each step to [builder].
///
/// Every number that represents progress — streaks, XP, days — animates
/// through this, so earning something always looks like it happened.
class AnimatedCountBuilder extends StatelessWidget {
  const AnimatedCountBuilder({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 600),
  });

  final int value;
  final Widget Function(BuildContext context, int value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, int shown, _) => builder(context, shown),
    );
  }
}

/// [AnimatedCountBuilder] for the common case: the number as text.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 600),
  });

  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedCountBuilder(
      value: value,
      duration: duration,
      builder: (BuildContext context, int shown) =>
          Text('$prefix$shown$suffix', style: style),
    );
  }
}
