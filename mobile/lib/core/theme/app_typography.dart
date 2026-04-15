import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cadence/core/theme/app_colors.dart';

/// Typography system matching the Cadence web design.
///
/// - Display font: Funnel Display (body, UI text)
/// - Kicker font:  Sour Gummy (headings, eyebrows, badges)
class AppTypography {
  const AppTypography._();

  // ── Display font (Funnel Display) ─────────────────────────────────────────

  static TextStyle display({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.nunitoSans(
        // Funnel Display fallback — swap to GoogleFonts.funnelDisplay() once available
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.42,
        letterSpacing: letterSpacing,
      );

  // ── Kicker font (Sour Gummy) ──────────────────────────────────────────────

  static TextStyle kicker({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.baloo2(
        // Sour Gummy fallback — swap to GoogleFonts.sourGummy() once available
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height ?? 1.16,
        letterSpacing: letterSpacing,
      );

  // ── Heading styles ────────────────────────────────────────────────────────

  static TextStyle get h1 => kicker(fontSize: 32, fontWeight: FontWeight.w700);
  static TextStyle get h2 => kicker(fontSize: 26, fontWeight: FontWeight.w700);
  static TextStyle get h3 => kicker(fontSize: 22, fontWeight: FontWeight.w700);
  static TextStyle get h4 => kicker(fontSize: 18, fontWeight: FontWeight.w600);

  // ── Body styles ───────────────────────────────────────────────────────────

  static TextStyle get bodyLarge =>
      display(fontSize: 16, height: 1.5);
  static TextStyle get body =>
      display(fontSize: 14, height: 1.5);
  static TextStyle get bodySmall =>
      display(fontSize: 12, height: 1.5);

  // ── Label / eyebrow ───────────────────────────────────────────────────────

  static TextStyle eyebrow({Color color = AppColors.sageGreen}) =>
      kicker(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.08,
        height: 1.1,
      );

  static TextStyle get labelMedium =>
      display(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2);
  static TextStyle get labelSmall =>
      display(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2);

  // ── Button ────────────────────────────────────────────────────────────────

  static TextStyle get buttonText =>
      display(fontSize: 14, fontWeight: FontWeight.w600, height: 1.0);
  static TextStyle get buttonTextLarge =>
      display(fontSize: 16, fontWeight: FontWeight.w700, height: 1.0);
}
