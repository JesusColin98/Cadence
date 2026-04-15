import 'package:flutter/material.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';

enum CadenceButtonVariant { primary, secondary, ghost, danger, outline }

class CadenceButton extends StatelessWidget {
  const CadenceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CadenceButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 48,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final CadenceButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double height;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = _variantColors();
    return SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          disabledBackgroundColor: colors.background.withOpacity(0.6),
          disabledForegroundColor: colors.foreground.withOpacity(0.6),
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: height >= 52
              ? AppTypography.buttonTextLarge
              : AppTypography.buttonText,
          side: variant == CadenceButtonVariant.outline
              ? const BorderSide(color: AppColors.alabasterGrey, width: 1.5)
              : BorderSide.none,
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.foreground,
                ),
              )
            : Row(
                mainAxisSize:
                    fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }

  _ButtonColors _variantColors() {
    switch (variant) {
      case CadenceButtonVariant.primary:
        return const _ButtonColors(
          background: AppColors.hunterGreen,
          foreground: AppColors.brightSnow,
        );
      case CadenceButtonVariant.secondary:
        return const _ButtonColors(
          background: AppColors.yellowGreen,
          foreground: AppColors.hunterGreen,
        );
      case CadenceButtonVariant.ghost:
        return const _ButtonColors(
          background: AppColors.vanillaCream,
          foreground: AppColors.hunterGreen,
        );
      case CadenceButtonVariant.danger:
        return const _ButtonColors(
          background: AppColors.blushedBrick,
          foreground: AppColors.brightSnow,
        );
      case CadenceButtonVariant.outline:
        return const _ButtonColors(
          background: Colors.white,
          foreground: AppColors.hunterGreen,
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  const _ButtonColors({required this.background, required this.foreground});
}

/// Small icon-only circular button.
class CadenceIconButton extends StatelessWidget {
  const CadenceIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = AppColors.hunterGreen,
    this.iconColor = AppColors.brightSnow,
    this.size = 48,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: iconColor, size: size * 0.4),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
