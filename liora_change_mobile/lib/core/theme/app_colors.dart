import 'package:flutter/material.dart';

/// Design tokens from `docs/mvp/mobile-issues/00-design-system.md` §1.
///
/// Widgets must never reference these constants directly — they read colours
/// from `Theme.of(context).colorScheme` or [AppSemanticColors]. The raw values
/// live here so there is exactly one place to change them.
abstract final class AppColorTokens {
  // Light theme
  static const Color primary = Color(0xFF3F7D58);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFC2F1D3);
  static const Color onPrimaryContainer = Color(0xFF0B3B22);
  static const Color secondary = Color(0xFF6B9080);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEAF3ED);
  static const Color background = Color(0xFFFAFDF9);
  static const Color onSurface = Color(0xFF1B1F1C);
  static const Color outline = Color(0xFFC6D2CB);
  static const Color success = Color(0xFF2E7D32);
  static const Color recovery = Color(0xFFF5A623);
  static const Color error = Color(0xFFD64545);

  // Dark theme: the design system derives the scheme from the same seed and
  // only pins these three semantic values.
  static const Color successDark = Color(0xFF66BB6A);
  static const Color recoveryDark = Color(0xFFFFB84D);
  static const Color errorDark = Color(0xFFE57373);
}

/// Semantic colours Material 3's [ColorScheme] has no slot for.
///
/// `success` marks completed check-ins, streaks and XP gains. `recovery` marks
/// a missed or skipped day and is deliberately warm amber — the design system
/// forbids red for that state, which is reserved for genuine system errors.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.recovery,
    required this.onRecovery,
    required this.onRecoverySurface,
  });

  static const AppSemanticColors light = AppSemanticColors(
    success: AppColorTokens.success,
    onSuccess: Color(0xFFFFFFFF),
    recovery: AppColorTokens.recovery,
    onRecovery: Color(0xFF3D2A00),
    onRecoverySurface: Color(0xFF7A4E00),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: AppColorTokens.successDark,
    onSuccess: Color(0xFF07240B),
    recovery: AppColorTokens.recoveryDark,
    onRecovery: Color(0xFF3D2A00),
    onRecoverySurface: AppColorTokens.recoveryDark,
  );

  final Color success;
  final Color onSuccess;
  final Color recovery;

  /// Foreground on the solid [recovery] amber.
  final Color onRecovery;

  /// Foreground on [recoverySurface]. The amber itself is too pale to read
  /// against its own light tint, so light mode darkens it.
  final Color onRecoverySurface;

  /// The tinted card behind every comeback message.
  Color get recoverySurface => recovery.withValues(alpha: 0.14);

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? recovery,
    Color? onRecovery,
    Color? onRecoverySurface,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      recovery: recovery ?? this.recovery,
      onRecovery: onRecovery ?? this.onRecovery,
      onRecoverySurface: onRecoverySurface ?? this.onRecoverySurface,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      recovery: Color.lerp(recovery, other.recovery, t)!,
      onRecovery: Color.lerp(onRecovery, other.onRecovery, t)!,
      onRecoverySurface: Color.lerp(
        onRecoverySurface,
        other.onRecoverySurface,
        t,
      )!,
    );
  }
}

/// Shorthand for `Theme.of(context).extension<AppSemanticColors>()!`.
extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
