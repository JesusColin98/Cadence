import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/theme/app_spacing.dart';
import 'package:cadence/core/models/coach_message.dart';
import 'package:cadence/core/services/api_service.dart';
import 'package:cadence/features/coach/providers/coach_provider.dart';
import 'package:cadence/features/learn/providers/learn_provider.dart';
import 'package:cadence/shared/widgets/cadence_card.dart';
import 'package:cadence/shared/widgets/cadence_button.dart';
import 'package:cadence/shared/widgets/audio_recorder_widget.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _scrollController = ScrollController();
  bool _showHistory = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onRecordingComplete(File audioFile) async {
    final api = ref.read(apiServiceProvider);

    // Transcribe first
    String transcript;
    try {
      transcript = await api.transcribe(audioFile);
    } catch (_) {
      transcript = '(voice message)';
    }

    await ref.read(coachProvider.notifier).sendMessage(
          content: transcript,
          audioPath: audioFile.path,
          transcript: transcript,
        );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachProvider);
    final session = state.activeSession;

    return Scaffold(
      backgroundColor: AppColors.vanillaCream,
      body: Column(
        children: [
          // Top bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  // History toggle
                  IconButton(
                    icon: Icon(
                      _showHistory
                          ? LucideIcons.panelLeftClose
                          : LucideIcons.panelLeft,
                      color: AppColors.hunterGreen,
                    ),
                    onPressed: () =>
                        setState(() => _showHistory = !_showHistory),
                  ),
                  Expanded(
                    child: Text(
                      session?.title ?? 'AI Coach',
                      style: AppTypography.kicker(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // New session
                  IconButton(
                    icon: const Icon(LucideIcons.squarePen,
                        color: AppColors.hunterGreen),
                    onPressed: () {
                      ref.read(coachProvider.notifier).createSession();
                      setState(() => _showHistory = false);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Row(
              children: [
                // Side history panel
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: _showHistory
                      ? SizedBox(
                          width: 240,
                          child: _HistoryPanel(
                            sessions: state.sessions,
                            activeId: state.activeSessionId,
                            onSelect: (id) {
                              ref
                                  .read(coachProvider.notifier)
                                  .selectSession(id);
                              setState(() => _showHistory = false);
                            },
                            onDelete: (id) =>
                                ref.read(coachProvider.notifier).deleteSession(id),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Chat area
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: session == null || session.messages.isEmpty
                            ? _EmptyCoachState(
                                onStart: () => ref
                                    .read(coachProvider.notifier)
                                    .createSession(),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.pagePadding,
                                    vertical: AppSpacing.md),
                                itemCount: session.messages.length +
                                    (state.isSending ? 1 : 0),
                                itemBuilder: (context, i) {
                                  if (i == session.messages.length) {
                                    return const _TypingIndicator();
                                  }
                                  return _MessageBubble(
                                    message: session.messages[i],
                                  )
                                      .animate()
                                      .fadeIn(duration: 250.ms)
                                      .slideY(
                                        begin: 0.04,
                                        curve: Curves.easeOutCubic,
                                      );
                                },
                              ),
                      ),

                      // Error
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.pagePadding,
                              vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.blushedBrick.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              state.error!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.blushedBrick,
                              ),
                            ),
                          ),
                        ),

                      // Recorder
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.pagePadding),
                        child: AudioRecorderWidget(
                          onRecordingComplete: _onRecordingComplete,
                          onError: (e) {},
                          isProcessing: state.isSending,
                          label: session == null
                              ? 'Start a new session first'
                              : 'Hold to speak to coach',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.sessions,
    required this.activeId,
    required this.onSelect,
    required this.onDelete,
  });

  final List<CoachSession> sessions;
  final String? activeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.brightSnow,
        border: Border(
          right: BorderSide(color: AppColors.alabasterGrey),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Sessions',
              style: AppTypography.kicker(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.sageGreen,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, i) {
                final s = sessions[i];
                final isActive = s.id == activeId;
                return ListTile(
                  dense: true,
                  selected: isActive,
                  selectedTileColor:
                      AppColors.yellowGreen.withOpacity(0.15),
                  title: Text(
                    s.title,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: AppColors.hunterGreen,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onSelect(s.id),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.trash2,
                        size: 14, color: AppColors.paleSlateMedium),
                    onPressed: () => onDelete(s.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                color: AppColors.hunterGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bot,
                  size: 14, color: AppColors.yellowGreen),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.hunterGreen
                    : AppColors.brightSnow,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(
                      isUser ? AppRadius.lg : AppRadius.xs),
                  bottomRight: Radius.circular(
                      isUser ? AppRadius.xs : AppRadius.lg),
                ),
              ),
              child: Text(
                message.content,
                style: AppTypography.body.copyWith(
                  color: isUser
                      ? AppColors.brightSnow
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

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: AppColors.hunterGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.bot,
                size: 14, color: AppColors.yellowGreen),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.brightSnow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const SizedBox(
              width: 32,
              height: 8,
              child: _ThreeDots(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeDots extends StatefulWidget {
  const _ThreeDots();

  @override
  State<_ThreeDots> createState() => _ThreeDotsState();
}

class _ThreeDotsState extends State<_ThreeDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) {
            final offset = ((_ctrl.value - i * 0.2) % 1.0);
            final opacity = offset < 0.5
                ? offset * 2
                : (1.0 - offset) * 2;
            return Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.sageGreen
                    .withOpacity(0.3 + opacity * 0.7),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _EmptyCoachState extends StatelessWidget {
  const _EmptyCoachState({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.hunterGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bot,
                  size: 32, color: AppColors.yellowGreen),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'AI Coach',
              style: AppTypography.kicker(
                  fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Practice pronunciation, get instant feedback, and improve your accent with your personal AI coach.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            CadenceButton(
              label: 'Start conversation',
              onPressed: onStart,
              variant: CadenceButtonVariant.secondary,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
