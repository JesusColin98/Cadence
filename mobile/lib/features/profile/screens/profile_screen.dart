import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cadence/core/router/app_router.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/features/auth/providers/auth_provider.dart';
import 'package:cadence/features/home/providers/stats_provider.dart';
import 'package:cadence/shared/widgets/cadence_button.dart';
import 'package:cadence/shared/widgets/cadence_card.dart';
import 'package:cadence/shared/widgets/progress_ring.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(statsProvider);
    final name = user?.userMetadata?['display_name'] as String? ?? 'User';
    final email = user?.email ?? '';
    final isPro = user?.userMetadata?['subscription_status'] == 'active';

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
              'Profile',
              style: AppTypography.kicker(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // User card
                CadenceCard(
                  color: AppColors.hunterGreen,
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.yellowGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : 'U',
                            style: AppTypography.kicker(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.hunterGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: AppTypography.kicker(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brightSnow,
                                  ),
                                ),
                                if (isPro) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.yellowGreen,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text(
                                      'PRO',
                                      style: AppTypography.eyebrow(
                                        color: AppColors.hunterGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              email,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onDarkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Stats
                CadenceEyebrow('Your progress'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Sessions',
                        value: '${stats.totalSessions}',
                        icon: LucideIcons.activity,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatTile(
                        label: 'Completed',
                        value: '${stats.completedLessons}',
                        icon: LucideIcons.checkCircle2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatTile(
                        label: 'Avg Score',
                        value: '${(stats.avgScore * 100).round()}%',
                        icon: LucideIcons.trendingUp,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Subscription
                if (!isPro) ...[
                  CadenceEyebrow('Subscription'),
                  const SizedBox(height: AppSpacing.md),
                  CadenceCard(
                    color: AppColors.yellowGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to Pro',
                          style: AppTypography.kicker(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.hunterGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unlock all modules, conversation practice, and AI coaching.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.hunterGreen.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        CadenceButton(
                          label: 'View plans — \$14.99/mo',
                          onPressed: () => _openCheckout(),
                          variant: CadenceButtonVariant.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // Settings
                CadenceEyebrow('Settings'),
                const SizedBox(height: AppSpacing.md),
                CadenceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.globe,
                        label: 'Help Center',
                        onTap: () => launchUrl(
                          Uri.parse('https://cadence.app/help'),
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: LucideIcons.shield,
                        label: 'Privacy Policy',
                        onTap: () => launchUrl(
                          Uri.parse('https://cadence.app/privacy'),
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: LucideIcons.fileText,
                        label: 'Terms of Service',
                        onTap: () => launchUrl(
                          Uri.parse('https://cadence.app/terms'),
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: LucideIcons.logOut,
                        label: 'Sign out',
                        textColor: AppColors.blushedBrick,
                        onTap: () => _confirmSignOut(context, ref),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openCheckout() {
    // Opens web checkout since Stripe payments happen on web
    launchUrl(
      Uri.parse('https://cadence.app/checkout'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.brightSnow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(
          'Sign out?',
          style: AppTypography.kicker(fontSize: 20),
        ),
        content: Text(
          'You will need to sign in again to continue your practice.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sign out',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.blushedBrick,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CadenceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.sageGreen),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.kicker(
                fontSize: 20, fontWeight: FontWeight.w700),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor = AppColors.hunterGreen,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 18, color: textColor),
      title: Text(
        label,
        style: AppTypography.labelMedium.copyWith(color: textColor),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: AppColors.paleSlateMedium,
      ),
      onTap: onTap,
    );
  }
}
