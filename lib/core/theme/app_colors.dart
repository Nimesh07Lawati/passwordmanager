import 'package:flutter/material.dart';

/// Central color palette for the app.
/// Organized into dark and light namespaces.
/// Access semantic tokens via [AppThemeExtension] through context.appTheme.
class AppColors {
  AppColors._();

  // ── Shared brand colors (same in both themes) ──────────────────────────────
  static const Color primary = Color(0xFF1565C0); // blue.shade700
  static const Color secondary = Color(0xFF6A1B9A); // purple.shade700

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0a001c);
  static const Color darkSurfaceHigh = Color(0x1AFFFFFF); // 10 % white
  static const Color darkSurfaceMed = Color(0x0DFFFFFF); // 5  % white
  static const Color darkBorder = Color(0x33FFFFFF); // 20 % white

  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xB3FFFFFF); // 70 % white
  static const Color darkTextHint = Color(0x99FFFFFF); // 60 % white
  static const Color darkTextDisabled = Color(0x66FFFFFF); // 40 % white

  static const Color darkSuccess = Color(0xFF66BB6A); // green.shade400
  static const Color darkSuccessBg = Color(0x3366BB6A); // 20 % green
  static const Color darkSuccessBorder = Color(0x4D66BB6A); // 30 % green
  static const Color darkPrimaryShadow = Color(0x4D1565C0); // 30 % primary

  // ── Light theme ────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurfaceHigh = Color(0xFFFFFFFF);
  static const Color lightSurfaceMed = Color(0xFFF0F0F0);
  static const Color lightBorder = Color(0xFFDDDDDD);

  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF555577);
  static const Color lightTextHint = Color(0xFF888899);
  static const Color lightTextDisabled = Color(0xFFBBBBCC);

  static const Color lightSuccess = Color(0xFF2E7D32); // green.shade800
  static const Color lightSuccessBg = Color(0xFFE8F5E9); // green.50
  static const Color lightSuccessBorder = Color(0xFFA5D6A7); // green.200
  static const Color lightPrimaryShadow = Color(0x261565C0); // 15 % primary
}
