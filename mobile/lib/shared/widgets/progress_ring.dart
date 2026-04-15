import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';

/// Circular progress ring with centered percentage label.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value, // 0.0 - 1.0
    this.size = 64,
    this.strokeWidth = 6,
    this.color = AppColors.sageGreen,
    this.trackColor = AppColors.alabasterGrey,
    this.showLabel = true,
    this.label,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final bool showLabel;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              value: value.clamp(0.0, 1.0),
              color: color,
              trackColor: trackColor,
              strokeWidth: strokeWidth,
            ),
          ),
          if (showLabel)
            Text(
              label ?? '$pct%',
              style: AppTypography.display(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w700,
                color: AppColors.hunterGreen,
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

/// Horizontal progress bar with eyebrow label.
class CadenceProgressBar extends StatelessWidget {
  const CadenceProgressBar({
    super.key,
    required this.value,
    this.label,
    this.count,
    this.dark = false,
  });

  final double value;
  final String? label;
  final String? count;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || count != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!.toUpperCase(),
                  style: AppTypography.eyebrow(
                    color: dark ? AppColors.brightSnow : AppColors.sageGreen,
                  ),
                ),
              if (count != null)
                Text(
                  count!,
                  style: AppTypography.labelSmall.copyWith(
                    color: dark ? AppColors.brightSnow : AppColors.hunterGreen,
                  ),
                ),
            ],
          ),
        if (label != null || count != null) const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor:
                dark ? Colors.white.withOpacity(0.2) : AppColors.alabasterGrey,
            valueColor: AlwaysStoppedAnimation<Color>(
              dark ? AppColors.yellowGreen : AppColors.sageGreen,
            ),
          ),
        ),
      ],
    );
  }
}
