import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Material 3 themes implementing `docs/mvp/mobile-issues/00-design-system.md`.
///
/// Light mode pins the exact hex values from §1. Dark mode is derived from the
/// same seed colour, as the design system specifies, with the documented
/// `success` / `recovery` / `error` overrides applied on top.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme, AppSemanticColors.light);

  static ThemeData get dark => _build(_darkScheme, AppSemanticColors.dark);

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(seedColor: AppColorTokens.primary).copyWith(
        primary: AppColorTokens.primary,
        onPrimary: AppColorTokens.onPrimary,
        primaryContainer: AppColorTokens.primaryContainer,
        onPrimaryContainer: AppColorTokens.onPrimaryContainer,
        secondary: AppColorTokens.secondary,
        onSecondary: AppColorTokens.onPrimary,
        surface: AppColorTokens.surface,
        onSurface: AppColorTokens.onSurface,
        // Material 3 replaced `surfaceVariant` with the surface container
        // roles; this is the design system's `surfaceVariant` token.
        surfaceContainerHighest: AppColorTokens.surfaceVariant,
        onSurfaceVariant: AppColorTokens.onSurface,
        outline: AppColorTokens.outline,
        error: AppColorTokens.error,
      );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColorTokens.primary,
    brightness: Brightness.dark,
  ).copyWith(error: AppColorTokens.errorDark);

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final TextTheme textTheme = _textTheme(scheme);
    final bool isLight = scheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[semantic],
      // The design system's `background` token: a warm off-white, not the
      // stark white used for cards.
      scaffoldBackgroundColor: isLight
          ? AppColorTokens.background
          : scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColorTokens.background : scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle(textTheme)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(textTheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(textTheme).copyWith(
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: scheme.outline),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.bodyLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: _inputBorder(scheme.outline),
        enabledBorder: _inputBorder(scheme.outline),
        focusedBorder: _inputBorder(scheme.primary, width: 2),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelSmall,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        contentTextStyle: textTheme.bodyLarge,
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }

  static ButtonStyle _buttonStyle(TextTheme textTheme) {
    return ButtonStyle(
      textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.bodyLarge),
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, AppSpacing.minTapTarget),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    );
  }

  /// Inputs use the card radius, per
  /// `docs/mvp/mobile-issues/02-auth-screens.md` §UI/UX.
  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Type scale from `docs/mvp/mobile-issues/00-design-system.md` §2, rendered
  /// in Nunito — rounded and friendly rather than corporate.
  static TextTheme _textTheme(ColorScheme scheme) {
    final TextTheme base = GoogleFonts.nunitoTextTheme(
      ThemeData(brightness: scheme.brightness).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
