import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/core/models/lesson_model.dart';
import 'package:cadence/core/models/assessment_result.dart';
import 'package:cadence/core/services/api_service.dart';
import 'package:cadence/features/learn/providers/learn_provider.dart';
import 'package:cadence/shared/widgets/cadence_button.dart';
import 'package:cadence/shared/widgets/audio_recorder_widget.dart';
import 'package:cadence/shared/widgets/phoneme_result_card.dart';
import 'package:cadence/shared/widgets/cadence_card.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key, required this.lesson});

  final LessonModel lesson;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  final _player = AudioPlayer();
  AssessmentResult? _lastResult;
  bool _isAssessing = false;
  String? _error;
  bool _showResult = false;

  int _currentIndex = 0;

  LessonWord get _currentWord => widget.lesson.words[_currentIndex];
  bool get _isLastWord => _currentIndex >= widget.lesson.words.length - 1;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playReference() async {
    try {
      final url =
          '${ref.read(apiServiceProvider).getReferenceAudioUrl(_currentWord.word)}';
      await _player.setUrl(await ref
          .read(apiServiceProvider)
          .getReferenceAudioUrl(_currentWord.word));
      await _player.play();
    } catch (_) {}
  }

  Future<void> _onRecordingComplete(dynamic audioFile) async {
    setState(() {
      _isAssessing = true;
      _showResult = false;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.assess(
        audioFile: audioFile,
        targetWord: _currentWord.word,
      );
      setState(() {
        _lastResult = result;
        _isAssessing = false;
        _showResult = true;
      });
    } catch (e) {
      setState(() {
        _isAssessing = false;
        _error = 'Assessment failed. Please try again.';
      });
    }
  }

  void _nextWord() {
    if (_isLastWord) {
      _showCompletion();
    } else {
      setState(() {
        _currentIndex++;
        _lastResult = null;
        _showResult = false;
        _error = null;
      });
    }
  }

  void _showCompletion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(
        score: _lastResult?.overallScore ?? 0,
        onContinue: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / widget.lesson.words.length;

    return Scaffold(
      backgroundColor: AppColors.vanillaCream,
      appBar: AppBar(
        backgroundColor: AppColors.vanillaCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: AppColors.hunterGreen),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.lesson.title,
          style: AppTypography.display(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.alabasterGrey,
            valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.sageGreen),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            children: [
              const Spacer(),

              // Word card
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _WordCard(
                  key: ValueKey(_currentIndex),
                  word: _currentWord,
                  onPlayReference: _playReference,
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // Result card
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showResult && _lastResult != null
                    ? PhonemeResultCard(
                        key: ValueKey('result_$_currentIndex'),
                        result: _lastResult!,
                        word: _currentWord.word,
                      )
                    : _error != null
                        ? _ErrorMessage(_error!)
                        : const SizedBox.shrink(),
              ),

              const Spacer(),

              // Recorder / Next
              if (!_showResult)
                AudioRecorderWidget(
                  onRecordingComplete: _onRecordingComplete,
                  onError: (e) => setState(() => _error = e),
                  isProcessing: _isAssessing,
                  label: 'Tap to record "${_currentWord.word}"',
                ).animate().fadeIn(duration: 300.ms)
              else
                CadenceButton(
                  label: _isLastWord ? 'Complete lesson' : 'Next word',
                  onPressed: _nextWord,
                  variant: _lastResult!.isPassing
                      ? CadenceButtonVariant.secondary
                      : CadenceButtonVariant.ghost,
                ).animate().fadeIn(duration: 250.ms),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    super.key,
    required this.word,
    required this.onPlayReference,
  });

  final LessonWord word;
  final VoidCallback onPlayReference;

  @override
  Widget build(BuildContext context) {
    return CadenceCard(
      color: AppColors.hunterGreen,
      child: Column(
        children: [
          CadenceEyebrow(
            'Pronounce this word',
            color: AppColors.yellowGreen,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            word.word,
            style: AppTypography.kicker(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.brightSnow,
            ),
          ),
          if (word.ipa != null) ...[
            const SizedBox(height: 6),
            Text(
              '/${word.ipa}/',
              style: AppTypography.display(
                fontSize: 16,
                color: AppColors.onDarkMuted,
              ),
            ),
          ],
          if (word.hint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                word.hint!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onDarkMuted,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          // Listen button
          TextButton.icon(
            onPressed: onPlayReference,
            icon: const Icon(LucideIcons.volume2,
                size: 16, color: AppColors.yellowGreen),
            label: Text(
              'Hear reference',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.yellowGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blushedBrick.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle,
              size: 16, color: AppColors.blushedBrick),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.blushedBrick,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionDialog extends StatelessWidget {
  const _CompletionDialog({
    required this.score,
    required this.onContinue,
  });

  final double score;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isPassing = score >= 0.7;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isPassing ? AppColors.hunterGreen : AppColors.brightSnow,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPassing ? '🎉' : '💪',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isPassing ? 'Great work!' : 'Keep practicing!',
              style: AppTypography.kicker(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isPassing
                    ? AppColors.yellowGreen
                    : AppColors.hunterGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${(score * 100).round()}%',
              style: AppTypography.body.copyWith(
                color: isPassing
                    ? AppColors.onDarkMuted
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            CadenceButton(
              label: 'Continue',
              onPressed: onContinue,
              variant: isPassing
                  ? CadenceButtonVariant.secondary
                  : CadenceButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
