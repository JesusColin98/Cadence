import 'package:flutter/material.dart';

/// Full Cadence color palette — mirrors globals.css CSS variables exactly.
class AppColors {
  const AppColors._();

  // ── Brand palette ─────────────────────────────────────────────────────────
  static const Color hunterGreen = Color(0xFF386641);
  static const Color sageGreen = Color(0xFF6A994E);
  static const Color yellowGreen = Color(0xFFA7C957);
  static const Color blushedBrick = Color(0xFFBC4749);

  // ── Neutrals ──────────────────────────────────────────────────────────────
  static const Color vanillaCream = Color(0xFFF2E8CF);
  static const Color brightSnow = Color(0xFFF8F9FA);
  static const Color platinum = Color(0xFFE9ECEF);
  static const Color alabasterGrey = Color(0xFFDEE2E6);
  static const Color paleSlateDark = Color(0xFFCED4DA);
  static const Color paleSlateMedium = Color(0xFFADB5BD);
  static const Color slateGrey = Color(0xFF6C757D);
  static const Color ironGrey = Color(0xFF495057);
  static const Color gunmetal = Color(0xFF343A40);
  static const Color carbonBlack = Color(0xFF212529);

  // ── Semantic aliases ───────────────────────────────────────────────────────
  static const Color background = vanillaCream;
  static const Color surface = brightSnow;
  static const Color primary = hunterGreen;
  static const Color secondary = sageGreen;
  static const Color accent = yellowGreen;
  static const Color error = blushedBrick;

  static const Color textPrimary = hunterGreen;
  static const Color textSecondary = ironGrey;
  static const Color textMuted = slateGrey;
  static const Color textDisabled = paleSlateMedium;

  static const Color borderLight = alabasterGrey;
  static const Color borderMedium = paleSlateDark;

  // ── Dark-surface variants (used on hunterGreen backgrounds) ───────────────
  static const Color onDark = brightSnow;
  static const Color onDarkMuted = Color(0xCCF8F9FA); // 80% opacity
  static const Color onDarkFaint = Color(0x99F8F9FA); // 60% opacity
  static const Color accentOnDark = yellowGreen;
  static const Color sageOnDark = sageGreen;

  // ── Hover states ──────────────────────────────────────────────────────────
  static const Color hunterGreenHover = Color(0xFF44784F);
  static const Color yellowGreenHover = Color(0xFFB5D567);
  static const Color vanillaCreamHover = Color(0xFFEADFBE);
  static const Color blushedBrickHover = Color(0xFFA84042);
  static const Color sageGreenHover = Color(0xFF5D8A43);
}
