import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/features/auth/providers/auth_provider.dart';
import 'package:cadence/shared/widgets/cadence_button.dart';
import 'package:cadence/shared/widgets/cadence_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  String? _emailError;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Enter a valid email address');
      return;
    }
    setState(() => _emailError = null);

    await ref
        .read(authProvider.notifier)
        .sendPasswordReset(email);

    if (mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.vanillaCream,
      appBar: AppBar(
        backgroundColor: AppColors.vanillaCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.hunterGreen),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: _sent ? _SuccessView() : _FormView(
            emailCtrl: _emailCtrl,
            emailError: _emailError,
            isLoading: authState.isLoading,
            error: authState.error,
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.emailCtrl,
    required this.emailError,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController emailCtrl;
  final String? emailError;
  final bool isLoading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset password',
          style: AppTypography.kicker(
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your email and we'll send you a reset link.",
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        CadenceTextField(
          controller: emailCtrl,
          label: 'Email address',
          hint: 'you@example.com',
          errorText: emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.blushedBrick,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              error!,
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.brightSnow),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        CadenceButton(
          label: 'Send reset link',
          onPressed: onSubmit,
          isLoading: isLoading,
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.yellowGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.mail,
            color: AppColors.hunterGreen,
            size: 32,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Check your email',
          style: AppTypography.kicker(
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We've sent a password reset link to your inbox.",
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        CadenceButton(
          label: 'Back to sign in',
          onPressed: () => context.pop(),
          variant: CadenceButtonVariant.ghost,
        ),
      ],
    );
  }
}
