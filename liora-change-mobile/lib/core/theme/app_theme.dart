import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = isLight
        ? const ColorScheme.light(
            primary: AppPalette.primary,
            onPrimary: AppPalette.onPrimary,
            primaryContainer: AppPalette.primaryContainer,
            onPrimaryContainer: AppPalette.onPrimaryContainer,
            secondary: AppPalette.secondary,
            surface: AppPalette.surface,
            onSurface: AppPalette.onBackground,
            error: AppPalette.error,
            outline: AppPalette.outline,
          )
        : ColorScheme.fromSeed(
            seedColor: AppPalette.primary,
            brightness: Brightness.dark,
            error: const Color(0xFFE57373),
          );

    final textTheme = GoogleFonts.nunitoTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).copyWith(
      displaySmall: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppPalette.background : colorScheme.surface,
      textTheme: textTheme,
      extensions: [
        isLight ? AppSemanticColors.light : AppSemanticColors.dark,
      ],
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}
