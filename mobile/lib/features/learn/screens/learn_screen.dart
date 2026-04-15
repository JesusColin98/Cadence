import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/features/learn/providers/learn_provider.dart';
import 'package:cadence/shared/widgets/cadence_card.dart';
import 'package:cadence/shared/widgets/progress_ring.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(modulesProvider);

    return Scaffold(
      backgroundColor: AppColors.vanillaCream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.vanillaCream,
            floating: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Learn',
              style: AppTypography.kicker(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding),
            sliver: modulesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.sageGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: _ErrorView(onRetry: () => ref.invalidate(modulesProvider)),
              ),
              data: (modules) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final m = modules[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ModuleCard(
                        title: m.title,
                        description: m.description,
                        lessonCount: m.lessonCount ?? 0,
                        completedCount: m.completedCount,
                        progress: m.progressPercent,
                        onTap: () => context.push(
                          '/learn/${m.id}?title=${Uri.encodeComponent(m.title)}',
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (i * 50).ms, duration: 300.ms)
                          .slideX(begin: 0.03, curve: Curves.easeOutCubic),
                    );
                  },
                  childCount: modules.length,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.description,
    required this.lessonCount,
    required this.completedCount,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final String? description;
  final int lessonCount;
  final int completedCount;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isStarted = completedCount > 0;
    final isComplete = completedCount >= lessonCount && lessonCount > 0;

    return CadenceCard(
      onTap: onTap,
      color: isComplete
          ? AppColors.hunterGreen
          : AppColors.brightSnow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isStarted && !isComplete)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: CadenceEyebrow(
                          'In progress',
                          color: AppColors.sageGreen,
                        ),
                      ),
                    if (isComplete)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: CadenceEyebrow(
                          'Completed',
                          color: AppColors.yellowGreen,
                        ),
                      ),
                    CadenceCardTitle(title, dark: isComplete),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: AppTypography.body.copyWith(
                          color: isComplete
                              ? AppColors.onDarkMuted
                              : AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ProgressRing(
                value: progress,
                size: 52,
                color: isComplete
                    ? AppColors.yellowGreen
                    : AppColors.sageGreen,
                trackColor: isComplete
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.alabasterGrey,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CadenceProgressBar(
            value: progress,
            label: 'Progress',
            count: '$completedCount / $lessonCount lessons',
            dark: isComplete,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Could not load modules',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
