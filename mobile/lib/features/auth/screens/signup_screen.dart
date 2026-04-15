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
import 'package:cadence/features/auth/screens/login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  Map<String, String?> _errors = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final errors = <String, String?>{};
    if (_nameCtrl.text.trim().isEmpty) {
      errors['name'] = 'Your name is required';
    }
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      errors['email'] = 'Enter a valid email address';
    }
    if (_passwordCtrl.text.length < 8) {
      errors['password'] = 'Password must be at least 8 characters';
    }
    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).signUp(
          _emailCtrl.text,
          _passwordCtrl.text,
          _nameCtrl.text,
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
              const SizedBox(height: AppSpacing.xxl),

              _LogoHeader()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.xxxl),

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
                      'Start your journey',
                      style: AppTypography.kicker(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create your free Cadence account',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    CadenceTextField(
                      controller: _nameCtrl,
                      label: 'Your name',
                      hint: 'Alex Johnson',
                      errorText: _errors['name'],
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CadenceTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'you@example.com',
                      errorText: _errors['email'],
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CadenceTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      hint: 'Min. 8 characters',
                      errorText: _errors['password'],
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.newPassword],
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
                    if (authState.error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ErrorBanner(authState.error!),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    CadenceButton(
                      label: 'Create account',
                      onPressed: _submit,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'By creating an account you agree to our Terms of Service and Privacy Policy.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.06, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.xxl),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTypography.body.copyWith(
                        color: AppColors.textMuted),
                  ),
                  GestureDetector(
                    onTap: () => context.go(Routes.login),
                    child: Text(
                      'Sign in',
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
