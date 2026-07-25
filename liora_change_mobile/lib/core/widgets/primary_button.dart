import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'press_scale.dart';

/// Filled, primary-coloured action button.
///
/// While [isLoading] the label is replaced by a spinner and the button stops
/// accepting taps, which is how every screen guards against double submits.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  /// Stretch to the available width. Primary actions are usually full-width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Widget button = PressScale(
      builder: (BuildContext context, WidgetStatesController controller) {
        return FilledButton(
          statesController: controller,
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimary,
                  ),
                )
              : _Label(label: label, icon: icon),
        );
      },
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Text(label, textAlign: TextAlign.center);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}
