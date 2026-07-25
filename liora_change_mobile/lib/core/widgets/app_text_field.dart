import 'package:flutter/material.dart';

/// Themed form input with the behaviour the auth screens require: validation
/// the moment a field loses focus, an optional show/hide toggle, and a slot for
/// server-side `422` messages.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.serverError,
    this.obscurable = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.autofillHints,
    this.prefixIcon,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  /// Message from the API's `errors` map, shown until the field is edited.
  final String? serverError;

  /// Renders the value hidden with a toggle to reveal it.
  final bool obscurable;

  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final GlobalKey<FormFieldState<String>> _fieldKey =
      GlobalKey<FormFieldState<String>>();
  bool _obscured = true;

  /// Errors stay quiet until the user has left the field once, then update
  /// live so a correction clears the message immediately.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  void _handleFocusChange(bool hasFocus) {
    if (hasFocus) return;
    if (widget.controller.text.isEmpty &&
        _autovalidateMode == AutovalidateMode.disabled) {
      return;
    }
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    _fieldKey.currentState?.validate();
  }

  String? _validate(String? value) {
    final String? local = widget.validator?.call(value);
    if (local != null) return local;
    return widget.serverError;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.serverError != oldWidget.serverError) {
      // Surface a freshly arrived server error without waiting for a blur.
      _fieldKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool obscure = widget.obscurable && _obscured;

    return Focus(
      onFocusChange: _handleFocusChange,
      child: TextFormField(
        key: _fieldKey,
        controller: widget.controller,
        validator: _validate,
        autovalidateMode: _autovalidateMode,
        obscureText: obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        autofillHints: widget.autofillHints,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: widget.prefixIcon == null
              ? null
              : Icon(widget.prefixIcon),
          suffixIcon: widget.obscurable
              ? IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: obscure ? 'Show password' : 'Hide password',
                )
              : null,
        ),
      ),
    );
  }
}
