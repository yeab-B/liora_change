import 'package:flutter/material.dart';

/// Applies the design system's subtle press feedback (§5: scale to 0.97).
///
/// The child is built with a [WidgetStatesController] so the scale reacts to
/// the button's own pressed state rather than a competing gesture detector,
/// which would swallow taps.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.builder});

  final Widget Function(BuildContext context, WidgetStatesController controller)
  builder;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  final WidgetStatesController _controller = WidgetStatesController();
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStatesChanged);
  }

  void _onStatesChanged() {
    final bool pressed = _controller.value.contains(WidgetState.pressed);
    if (pressed != _pressed) {
      setState(() => _pressed = pressed);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStatesChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: widget.builder(context, _controller),
    );
  }
}
