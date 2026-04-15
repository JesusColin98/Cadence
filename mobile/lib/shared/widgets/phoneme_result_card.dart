import 'package:flutter/material.dart';
import 'package:cadence/core/models/assessment_result.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/shared/widgets/cadence_card.dart';
import 'package:cadence/shared/widgets/progress_ring.dart';

class PhonemeResultCard extends StatelessWidget {
  const PhonemeResultCard({
    super.key,
    required this.result,
    required this.word,
  });

  final AssessmentResult result;
  final String word;

  @override
  Widget build(BuildContext context) {
    final score = result.overallScore;
    final isPassing = result.isPassing;

    return CadenceCard(
      color: isPassing
          ? AppColors.hunterGreen
          : AppColors.brightSnow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CadenceEyebrow(
                      'Your pronunciation',
                      color: isPassing
                          ? AppColors.yellowGreen
                          : AppColors.sageGreen,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word,
                      style: AppTypography.kicker(
                        fontSize: 22,
                        color: isPassing
                            ? AppColors.brightSnow
                            : AppColors.hunterGreen,
                      ),
                    ),
                    if (result.transcript.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '"${result.transcript}"',
                        style: AppTypography.bodySmall.copyWith(
                          color: isPassing
                              ? AppColors.onDarkMuted
                              : AppColors.slateGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ProgressRing(
                value: score,
                size: 56,
                color: isPassing
                    ? AppColors.yellowGreen
                    : AppColors.sageGreen,
                trackColor: isPassing
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.alabasterGrey,
              ),
            ],
          ),

          // Phoneme breakdown
          if (result.phonemes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.phonemes.map((p) {
                return _PhonemeChip(
                  phoneme: p,
                  dark: isPassing,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhonemeChip extends StatelessWidget {
  const _PhonemeChip({required this.phoneme, required this.dark});

  final PhonemeScore phoneme;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    Color textColor;

    if (phoneme.correct) {
      chipColor = dark
          ? Colors.white.withOpacity(0.15)
          : AppColors.sageGreen.withOpacity(0.12);
      textColor = dark ? AppColors.yellowGreen : AppColors.sageGreen;
    } else {
      chipColor = dark
          ? AppColors.blushedBrick.withOpacity(0.25)
          : AppColors.blushedBrick.withOpacity(0.1);
      textColor = AppColors.blushedBrick;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        phoneme.phoneme,
        style: AppTypography.labelSmall.copyWith(color: textColor),
      ),
    );
  }
}
