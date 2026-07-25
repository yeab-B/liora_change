import 'package:flutter/material.dart';

/// Semantic colors beyond Material ColorScheme (design system §1).
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.recovery,
  });

  final Color success;
  final Color recovery;

  static const light = AppSemanticColors(
    success: Color(0xFF2E7D32),
    recovery: Color(0xFFF5A623),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF66BB6A),
    recovery: Color(0xFFFFB84D),
  );

  @override
  AppSemanticColors copyWith({Color? success, Color? recovery}) {
    return AppSemanticColors(
      success: success ?? this.success,
      recovery: recovery ?? this.recovery,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      recovery: Color.lerp(recovery, other.recovery, t)!,
    );
  }
}

class AppPalette {
  AppPalette._();

  static const primary = Color(0xFF3F7D58);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFC2F1D3);
  static const onPrimaryContainer = Color(0xFF0B3B22);
  static const secondary = Color(0xFF6B9080);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEAF3ED);
  static const background = Color(0xFFFAFDF9);
  static const onBackground = Color(0xFF1B1F1C);
  static const outline = Color(0xFFC6D2CB);
  static const error = Color(0xFFD64545);
}
