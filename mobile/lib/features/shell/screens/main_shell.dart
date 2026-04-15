import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/router/app_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vanillaCream,
      body: child,
      bottomNavigationBar: const _CadenceBottomNav(),
    );
  }
}

class _CadenceBottomNav extends StatelessWidget {
  const _CadenceBottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.brightSnow,
        boxShadow: [
          BoxShadow(
            color: AppColors.hunterGreen.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: LucideIcons.home,
                label: 'Home',
                route: Routes.home,
                isActive: location == Routes.home,
              ),
              _NavItem(
                icon: LucideIcons.bookOpen,
                label: 'Learn',
                route: Routes.learn,
                isActive: location.startsWith(Routes.learn),
              ),
              _NavItem(
                icon: LucideIcons.messageCircle,
                label: 'Talk',
                route: Routes.conversation,
                isActive: location.startsWith(Routes.conversation),
              ),
              _NavItem(
                icon: LucideIcons.bot,
                label: 'Coach',
                route: Routes.coach,
                isActive: location.startsWith(Routes.coach),
              ),
              _NavItem(
                icon: LucideIcons.user,
                label: 'Profile',
                route: Routes.profile,
                isActive: location.startsWith(Routes.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(route),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.yellowGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? AppColors.hunterGreen
                    : AppColors.ironGrey,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.display(
                  fontSize: 10,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.hunterGreen
                      : AppColors.ironGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
