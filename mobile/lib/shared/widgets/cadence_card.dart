import 'package:flutter/material.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/core/theme/app_typography.dart';

/// A rounded card matching the Cadence `rounded-3xl` card style.
class CadenceCard extends StatelessWidget {
  const CadenceCard({
    super.key,
    required this.child,
    this.color = AppColors.brightSnow,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
    this.borderRadius = AppRadius.xl,
    this.shadow = true,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      elevation: shadow ? 0 : 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.hunterGreen.withOpacity(0.04),
        highlightColor: AppColors.hunterGreen.withOpacity(0.02),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Dark (hunter-green) card variant — used on feature sections.
class CadenceDarkCard extends StatelessWidget {
  const CadenceDarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CadenceCard(
      color: AppColors.hunterGreen,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

/// Card title styled with the kicker (Sour Gummy) font.
class CadenceCardTitle extends StatelessWidget {
  const CadenceCardTitle(
    this.text, {
    super.key,
    this.dark = false,
  });

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.kicker(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: dark ? AppColors.brightSnow : AppColors.hunterGreen,
      ),
    );
  }
}

/// Eyebrow label — small uppercase tracking text.
class CadenceEyebrow extends StatelessWidget {
  const CadenceEyebrow(
    this.text, {
    super.key,
    this.color = AppColors.sageGreen,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.eyebrow(color: color),
    );
  }
}

/// Pill/badge widget — matches the rounded-full badge pattern.
class CadenceBadge extends StatelessWidget {
  const CadenceBadge(
    this.text, {
    super.key,
    this.backgroundColor = AppColors.yellowGreen,
    this.textColor = AppColors.hunterGreen,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.eyebrow(color: textColor),
      ),
    );
  }
}
