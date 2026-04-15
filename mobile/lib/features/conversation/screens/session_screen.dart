import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/shared/widgets/cadence_button.dart';
import 'package:cadence/shared/widgets/cadence_card.dart';
import 'package:cadence/shared/widgets/audio_recorder_widget.dart';

class ConversationSessionScreen extends StatefulWidget {
  const ConversationSessionScreen({
    super.key,
    required this.moduleId,
    required this.title,
  });

  final String moduleId;
  final String title;

  @override
  State<ConversationSessionScreen> createState() =>
      _ConversationSessionScreenState();
}

class _ConversationSessionScreenState
    extends State<ConversationSessionScreen> {
  final List<_Turn> _turns = [];
  bool _isProcessing = false;
  int _currentTurnIndex = 0;

  // Placeholder prompt — real data comes from the API
  static const _promptText =
      'Introduce yourself and share one thing you enjoy doing.';

  void _onRecordingComplete(dynamic audioFile) {
    setState(() {
      _isProcessing = true;
      _turns.add(_Turn(
        type: _TurnType.user,
        text: 'Processing your response...',
        isLoading: true,
      ));
    });

    // Simulate coach reply — replace with real API call
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _turns.last = _Turn(
          type: _TurnType.user,
          text: '(Your recorded response)',
        );
        _turns.add(_Turn(
          type: _TurnType.coach,
          text:
              'Great effort! Your pronunciation was clear. Let\'s continue — can you tell me more about that?',
        ));
        _currentTurnIndex++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
          widget.title,
          style: AppTypography.display(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Prompt card at top
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding, 0, AppSpacing.pagePadding, 0),
            child: CadenceCard(
              color: AppColors.hunterGreen,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(LucideIcons.messageSquare,
                      size: 16, color: AppColors.yellowGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _promptText,
                      style: AppTypography.body.copyWith(
                        color: AppColors.brightSnow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Turn history
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              itemCount: _turns.length,
              itemBuilder: (context, i) => _TurnBubble(turn: _turns[i]),
            ),
          ),

          // Recorder
          Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              children: [
                AudioRecorderWidget(
                  onRecordingComplete: _onRecordingComplete,
                  isProcessing: _isProcessing,
                  label: 'Record your response',
                ),
                const SizedBox(height: AppSpacing.lg),
                CadenceButton(
                  label: 'Finish session',
                  onPressed: () => context.pop(),
                  variant: CadenceButtonVariant.ghost,
                  fullWidth: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _TurnType { user, coach }

class _Turn {
  final _TurnType type;
  final String text;
  final bool isLoading;

  _Turn({
    required this.type,
    required this.text,
    this.isLoading = false,
  });
}

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({required this.turn});
  final _Turn turn;

  @override
  Widget build(BuildContext context) {
    final isUser = turn.type == _TurnType.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppColors.hunterGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bot,
                  size: 16, color: AppColors.yellowGreen),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.yellowGreen
                    : AppColors.brightSnow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: turn.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.hunterGreen,
                      ),
                    )
                  : Text(
                      turn.text,
                      style: AppTypography.body.copyWith(
                        color: isUser
                            ? AppColors.hunterGreen
                            : AppColors.hunterGreen,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
