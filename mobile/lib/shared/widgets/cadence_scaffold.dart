import 'package:flutter/material.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/core/theme/app_typography.dart';

/// Standard scaffold with Cadence vanilla-cream background and styled AppBar.
class CadenceScaffold extends StatelessWidget {
  const CadenceScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor = AppColors.vanillaCream,
    this.resizeToAvoidBottomInset = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
  });

  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color backgroundColor;
  final bool resizeToAvoidBottomInset;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      appBar: title != null
          ? AppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: leading,
              automaticallyImplyLeading: leading == null,
              title: Text(
                title!,
                style: AppTypography.kicker(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: actions,
            )
          : null,
      body: SafeArea(
        child: padding == EdgeInsets.zero
            ? body
            : Padding(padding: padding, child: body),
      ),
    );
  }
}

/// Full-screen auth scaffold with no app bar — cream background.
class CadenceAuthScaffold extends StatelessWidget {
  const CadenceAuthScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vanillaCream,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: child,
        ),
      ),
    );
  }
}
