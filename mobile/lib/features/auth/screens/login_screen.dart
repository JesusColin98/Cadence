import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cadence/core/router/app_router.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/features/auth/providers/auth_provider.dart';
import 'package:cadence/shared/widgets/cadence_button.dart';
import 'package:cadence/shared/widgets/cadence_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = _emailCtrl.text.trim().isEmpty ||
              !_emailCtrl.text.contains('@')
          ? 'Enter a valid email address'
          : null;
      _passwordError = _passwordCtrl.text.isEmpty
          ? 'Password is required'
          : null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).signIn(
          _emailCtrl.text,
          _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.vanillaCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxxl),

              // Logo + headline
              _LogoHeader()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.xxxl),

              // Form card
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.hunterGreen.withOpacity(0.06),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: AppTypography.kicker(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to continue your practice',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    CadenceTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'you@example.com',
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CadenceTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      hint: '••••••••',
                      errorText: _passwordError,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.password],
                      suffix: GestureDetector(
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        child: Text(
                          _obscurePassword ? 'Show' : 'Hide',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.sageGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.push(Routes.forgotPassword),
                        child: Text(
                          'Forgot password?',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.sageGreen,
                          ),
                        ),
                      ),
                    ),
                    if (authState.error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ErrorBanner(authState.error!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    CadenceButton(
                      label: 'Sign in',
                      onPressed: _submit,
                      isLoading: authState.isLoading,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.06, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.xxl),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(Routes.signup),
                    child: Text(
                      'Sign up',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.hunterGreen,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cadence wordmark (text fallback since we may not have SVG in assets yet)
        Text(
          'Cadence',
          style: AppTypography.kicker(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.hunterGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI Pronunciation Training',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.sageGreen,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blushedBrick,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.brightSnow,
        ),
      ),
    );
  }
}
