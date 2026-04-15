import 'package:flutter/material.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';

class CadenceTextField extends StatelessWidget {
  const CadenceTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.enabled = true,
    this.suffix,
    this.prefix,
    this.autocorrect = true,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool enabled;
  final Widget? suffix;
  final Widget? prefix;
  final bool autocorrect;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.hunterGreen,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          autofocus: autofocus,
          enabled: enabled,
          autocorrect: autocorrect,
          autofillHints: autofillHints,
          style: AppTypography.body.copyWith(color: AppColors.hunterGreen),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: prefix,
                  )
                : null,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: suffix,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.platinum,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9999),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9999),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9999),
              borderSide: const BorderSide(
                color: AppColors.sageGreen,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9999),
              borderSide: const BorderSide(
                color: AppColors.blushedBrick,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9999),
              borderSide: const BorderSide(
                color: AppColors.blushedBrick,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.blushedBrick,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              errorText!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.brightSnow,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
