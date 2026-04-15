import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cadence/core/router/app_router.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/features/auth/providers/auth_provider.dart';
import 'package:cadence/features/home/providers/stats_provider.dart';
import 'package:cadence/features/learn/providers/learn_provider.dart';
import 'package:cadence/shared/widgets/cadence_card.dart';
import 'package:cadence/shared/widgets/progress_ring.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(statsProvider);
    final modulesAsync = ref.watch(modulesProvider);
    final firstName = (user?.userMetadata?['display_name'] as String?)
            ?.split(' ')
            .first ??
        'there';

    return Scaffold(
      backgroundColor: AppColors.vanillaCream,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding, 24, AppSpacing.pagePadding, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_greeting()},',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          firstName,
                          style: AppTypography.kicker(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    // Streak badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.yellowGreen,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥',
                              style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '${stats.practiceStreak}d',
                            style: AppTypography.kicker(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.hunterGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Sessions',
                      value: '${stats.totalSessions}',
                      icon: LucideIcons.activity,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      label: 'Completed',
                      value: '${stats.completedLessons}',
                      icon: LucideIcons.checkCircle2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      label: 'Avg Score',
                      value:
                          '${(stats.avgScore * 100).round()}%',
                      icon: LucideIcons.trendingUp,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CadenceEyebrow('Quick practice'),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _QuickActionCard(
                          title: 'Continue\nLearning',
                          subtitle: 'Pick up where\nyou left off',
                          color: AppColors.hunterGreen,
                          textColor: AppColors.brightSnow,
                          icon: LucideIcons.bookOpen,
                          onTap: () => context.go(Routes.learn),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _QuickActionCard(
                              title: 'AI Coach',
                              subtitle: 'Free talk',
                              color: AppColors.yellowGreen,
                              textColor: AppColors.hunterGreen,
                              icon: LucideIcons.bot,
                              onTap: () => context.go(Routes.coach),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _QuickActionCard(
                              title: 'Conversation',
                              subtitle: 'Practice',
                              color: AppColors.sageGreen.withOpacity(0.15),
                              textColor: AppColors.hunterGreen,
                              icon: LucideIcons.messageCircle,
                              onTap: () =>
                                  context.go(Routes.conversation),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

          // Recent modules
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CadenceEyebrow('Recent modules'),
                  TextButton(
                    onPressed: () => context.go(Routes.learn),
                    child: Text(
                      'See all',
                      style: AppTypography.labelSmall.copyWith(
                          color: AppColors.sageGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),

          modulesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: AppColors.sageGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            data: (modules) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i >= 3) return null;
                  final m = modules[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        0,
                        AppSpacing.pagePadding,
                        AppSpacing.md),
                    child: _ModuleListTile(
                      title: m.title,
                      progress: m.progressPercent,
                      lessonCount: m.lessonCount ?? 0,
                      onTap: () => context.push(
                        '/learn/${m.id}?title=${Uri.encodeComponent(m.title)}',
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (240 + i * 60).ms, duration: 300.ms)
                        .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                  );
                },
                childCount: modules.length.clamp(0, 3),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brightSnow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.sageGreen),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.kicker(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Color textColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.kicker(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleListTile extends StatelessWidget {
  const _ModuleListTile({
    required this.title,
    required this.progress,
    required this.lessonCount,
    required this.onTap,
  });

  final String title;
  final double progress;
  final int lessonCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CadenceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          ProgressRing(
            value: progress,
            size: 48,
            strokeWidth: 5,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelMedium),
                Text(
                  '$lessonCount lessons',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: AppColors.paleSlateMedium,
          ),
        ],
      ),
    );
  }
}
