import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/features/auth/providers/auth_provider.dart';
import 'package:cadence/shared/widgets/cadence_button.dart';
import 'package:cadence/shared/widgets/cadence_text_field.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  int _step = 0;
  String? _nameError;

  final _goals = [
    ('Professional communication', '💼'),
    ('Academic presentations', '🎓'),
    ('Social confidence', '💬'),
    ('Accent reduction', '🎯'),
    ('Clear speech at work', '📊'),
  ];
  final _selectedGoals = <int>{};

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        setState(() => _nameError = 'Please enter your name');
        return;
      }
      setState(() {
        _nameError = null;
        _step = 1;
      });
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    await ref
        .read(authProvider.notifier)
        .updateDisplayName(_nameCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.hunterGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // Step indicator
              Row(
                children: List.generate(2, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == _step ? 32 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: i == _step
                          ? AppColors.yellowGreen
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 0
                    ? _NameStep(
                        key: const ValueKey('name'),
                        controller: _nameCtrl,
                        error: _nameError,
                      )
                    : _GoalsStep(
                        key: const ValueKey('goals'),
                        goals: _goals,
                        selected: _selectedGoals,
                        onToggle: (i) =>
                            setState(() => _selectedGoals.contains(i)
                                ? _selectedGoals.remove(i)
                                : _selectedGoals.add(i)),
                      ),
              ),

              const Spacer(),

              CadenceButton(
                label: _step == 0 ? 'Continue' : 'Start practicing',
                onPressed: _nextStep,
                isLoading: authState.isLoading,
                variant: CadenceButtonVariant.secondary,
                height: 52,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    super.key,
    required this.controller,
    required this.error,
  });

  final TextEditingController controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to\nCadence',
          style: AppTypography.kicker(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.brightSnow,
            height: 1.1,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutCubic),
        const SizedBox(height: 12),
        Text(
          "Let's personalize your experience.",
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.onDarkMuted,
          ),
        ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'What should we call you?',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.yellowGreen,
          ),
        ).animate().fadeIn(delay: 120.ms),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: AppTypography.display(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.hunterGreen,
          ),
          decoration: InputDecoration(
            hintText: 'Your first name',
            hintStyle: AppTypography.body.copyWith(
              color: AppColors.slateGrey,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9999),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
          ),
        ).animate().fadeIn(delay: 150.ms),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.yellowGreen,
            ),
          ),
        ],
      ],
    );
  }
}

class _GoalsStep extends StatelessWidget {
  const _GoalsStep({
    super.key,
    required this.goals,
    required this.selected,
    required this.onToggle,
  });

  final List<(String, String)> goals;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are you\nworking on?',
          style: AppTypography.kicker(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.brightSnow,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply.',
          style: AppTypography.body.copyWith(
            color: AppColors.onDarkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ...List.generate(goals.length, (i) {
          final (label, emoji) = goals[i];
          final isSelected = selected.contains(i);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onToggle(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.yellowGreen
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? AppColors.hunterGreen
                            : AppColors.brightSnow,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (i * 60).ms, duration: 300.ms)
                .slideX(begin: 0.04, curve: Curves.easeOutCubic),
          );
        }),
      ],
    );
  }
}
