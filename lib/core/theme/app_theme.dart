import 'package:flutter/material.dart';
import 'app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Custom Theme Extension
// Carries every semantic color token for the app.
// Usage anywhere: context.appTheme.someToken
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.background,
    required this.surfaceHigh,
    required this.surfaceMedium,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textDisabled,
    required this.success,
    required this.successBg,
    required this.successBorder,
    required this.primaryShadow,
    required this.cardGradient,
    required this.iconColor,
  });

  final Color background;
  final Color surfaceHigh;
  final Color surfaceMedium;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textDisabled;
  final Color success;
  final Color successBg;
  final Color successBorder;
  final Color primaryShadow;
  final LinearGradient cardGradient;
  final Color iconColor;

  // ── Pre-built instances ────────────────────────────────────────────────────

  static const AppThemeExtension dark = AppThemeExtension(
    background: AppColors.darkBackground,
    surfaceHigh: AppColors.darkSurfaceHigh,
    surfaceMedium: AppColors.darkSurfaceMed,
    borderColor: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    textDisabled: AppColors.darkTextDisabled,
    success: AppColors.darkSuccess,
    successBg: AppColors.darkSuccessBg,
    successBorder: AppColors.darkSuccessBorder,
    primaryShadow: AppColors.darkPrimaryShadow,
    iconColor: AppColors.primary,
    cardGradient: LinearGradient(
      colors: [AppColors.primary, AppColors.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const AppThemeExtension light = AppThemeExtension(
    background: AppColors.lightBackground,
    surfaceHigh: AppColors.lightSurfaceHigh,
    surfaceMedium: AppColors.lightSurfaceMed,
    borderColor: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textHint: AppColors.lightTextHint,
    textDisabled: AppColors.lightTextDisabled,
    success: AppColors.lightSuccess,
    successBg: AppColors.lightSuccessBg,
    successBorder: AppColors.lightSuccessBorder,
    primaryShadow: AppColors.lightPrimaryShadow,
    iconColor: AppColors.primary,
    cardGradient: LinearGradient(
      colors: [AppColors.primary, AppColors.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ── ThemeExtension overrides ───────────────────────────────────────────────

  @override
  AppThemeExtension copyWith({
    Color? background,
    Color? surfaceHigh,
    Color? surfaceMedium,
    Color? borderColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? textDisabled,
    Color? success,
    Color? successBg,
    Color? successBorder,
    Color? primaryShadow,
    LinearGradient? cardGradient,
    Color? iconColor,
  }) {
    return AppThemeExtension(
      background: background ?? this.background,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceMedium: surfaceMedium ?? this.surfaceMedium,
      borderColor: borderColor ?? this.borderColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      textDisabled: textDisabled ?? this.textDisabled,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      successBorder: successBorder ?? this.successBorder,
      primaryShadow: primaryShadow ?? this.primaryShadow,
      cardGradient: cardGradient ?? this.cardGradient,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other == null) return this;
    return AppThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceMedium: Color.lerp(surfaceMedium, other.surfaceMedium, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      primaryShadow: Color.lerp(primaryShadow, other.primaryShadow, t)!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
      iconColor: Color.lerp(iconColor, other.iconColor, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience extension on BuildContext
// Usage: final t = context.appTheme;
// ─────────────────────────────────────────────────────────────────────────────
extension AppThemeContext on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;
}

// ─────────────────────────────────────────────────────────────────────────────
// ThemeData factories
// Named to match your MaterialApp: AppTheme.lightTheme / AppTheme.darkTheme
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // ── Light ──────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightBackground,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightTextPrimary,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 24,
          color: AppColors.lightTextPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceHigh,
        labelStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          shadowColor: AppColors.lightPrimaryShadow,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      extensions: const [AppThemeExtension.light],
    );
  }

  // ── Dark ───────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkBackground,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkTextPrimary,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 24,
          color: AppColors.darkTextPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        labelStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.darkTextPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          shadowColor: AppColors.darkPrimaryShadow,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      extensions: const [AppThemeExtension.dark],
    );
  }
}
