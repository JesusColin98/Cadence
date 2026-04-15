import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/features/learn/providers/learn_provider.dart';
import 'package:cadence/core/models/lesson_model.dart';
import 'package:cadence/shared/widgets/cadence_card.dart';

class ModuleDetailScreen extends ConsumerWidget {
  const ModuleDetailScreen({
    super.key,
    required this.moduleId,
    required this.title,
  });

  final String moduleId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider(moduleId));

    return Scaffold(
      backgroundColor: AppColors.vanillaCream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.vanillaCream,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft,
                  color: AppColors.hunterGreen),
              onPressed: () => context.pop(),
            ),
            title: Text(
              title,
              style: AppTypography.kicker(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          lessonsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.sageGreen,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, __) => const SliverFillRemaining(
              child: Center(
                child: Text('Failed to load lessons'),
              ),
            ),
            data: (lessons) => SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final lesson = lessons[i];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _LessonTile(
                        lesson: lesson,
                        index: i,
                        onTap: () => context.push(
                          '/learn/$moduleId/practice/${lesson.id}',
                          extra: lesson,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (i * 40).ms, duration: 250.ms)
                          .slideX(begin: 0.03, curve: Curves.easeOutCubic),
                    );
                  },
                  childCount: lessons.length,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.index,
    required this.onTap,
  });

  final LessonModel lesson;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExam = lesson.type == 'exam';
    final isDone = lesson.isCompleted;

    return CadenceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: isDone ? AppColors.hunterGreen : AppColors.brightSnow,
      child: Row(
        children: [
          // Number badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.white.withOpacity(0.15)
                  : isExam
                      ? AppColors.yellowGreen
                      : AppColors.vanillaCream,
              shape: BoxShape.circle,
            ),
            child: isDone
                ? const Icon(LucideIcons.check,
                    size: 18, color: AppColors.yellowGreen)
                : Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.kicker(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isExam
                            ? AppColors.hunterGreen
                            : AppColors.sageGreen,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isExam)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: CadenceEyebrow(
                      'Assessment',
                      color: isDone
                          ? AppColors.yellowGreen
                          : AppColors.sageGreen,
                    ),
                  ),
                Text(
                  lesson.title,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDone
                        ? AppColors.brightSnow
                        : AppColors.hunterGreen,
                  ),
                ),
                Text(
                  '${lesson.words.length} words',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDone
                        ? AppColors.onDarkMuted
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (lesson.lastScore != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.yellowGreen
                    : AppColors.vanillaCream,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '${(lesson.lastScore! * 100).round()}%',
                style: AppTypography.kicker(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.hunterGreen,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: isDone
                ? AppColors.onDarkFaint
                : AppColors.paleSlateMedium,
          ),
        ],
      ),
    );
  }
}
