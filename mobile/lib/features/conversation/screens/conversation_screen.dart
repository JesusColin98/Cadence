import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/features/conversation/providers/conversation_provider.dart';
import 'package:cadence/shared/widgets/cadence_card.dart';
import 'package:cadence/shared/widgets/progress_ring.dart';

class ConversationScreen extends ConsumerWidget {
  const ConversationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationProvider);

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
              'Conversation',
              style: AppTypography.kicker(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.sageGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (state.error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.error!,
                        style: AppTypography.body.copyWith(
                            color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          ref.read(conversationProvider.notifier).load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (state.modules.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final module = state.modules[i];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ConversationModuleCard(
                        module: module,
                        onTap: () => context.push(
                          '/conversation/${module['id']}?title=${Uri.encodeComponent(module['title'] as String? ?? '')}',
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (i * 50).ms, duration: 300.ms)
                          .slideX(
                              begin: 0.03,
                              curve: Curves.easeOutCubic),
                    );
                  },
                  childCount: state.modules.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _ConversationModuleCard extends StatelessWidget {
  const _ConversationModuleCard({
    required this.module,
    required this.onTap,
  });

  final Map<String, dynamic> module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = module['title'] as String? ?? '';
    final completedTurns = module['completed_turns'] as int? ?? 0;
    final totalTurns = module['total_turns'] as int? ?? 1;
    final progress = completedTurns / totalTurns;
    final isDone = completedTurns >= totalTurns;

    return CadenceCard(
      onTap: onTap,
      color: isDone ? AppColors.hunterGreen : AppColors.brightSnow,
      child: Row(
        children: [
          ProgressRing(
            value: progress,
            size: 52,
            color: isDone ? AppColors.yellowGreen : AppColors.sageGreen,
            trackColor: isDone
                ? Colors.white.withOpacity(0.2)
                : AppColors.alabasterGrey,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDone)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: CadenceEyebrow(
                      'Completed',
                      color: AppColors.yellowGreen,
                    ),
                  ),
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDone
                        ? AppColors.brightSnow
                        : AppColors.hunterGreen,
                  ),
                ),
                Text(
                  '$completedTurns / $totalTurns turns',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDone
                        ? AppColors.onDarkMuted
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗣️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No conversation modules yet',
              style: AppTypography.kicker(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Conversation modules will appear here once available.',
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
