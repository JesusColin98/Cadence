import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cadence/core/theme/app_colors.dart';
import 'package:cadence/core/theme/app_typography.dart';
import 'package:cadence/core/services/audio_service.dart';

enum RecorderState { idle, recording, processing, done }

/// Mic button that handles recording lifecycle and exposes the recorded [File].
class AudioRecorderWidget extends StatefulWidget {
  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.onError,
    this.isProcessing = false,
    this.label = 'Hold to record',
  });

  final ValueChanged<File> onRecordingComplete;
  final ValueChanged<String>? onError;
  final bool isProcessing;
  final String label;

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  final _audio = AudioService();
  RecorderState _state = RecorderState.idle;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final permitted = await _audio.requestMicPermission();
    if (!permitted) {
      widget.onError?.call('Microphone permission denied.');
      return;
    }

    final started = await _audio.startRecording();
    if (!started) return;

    setState(() => _state = RecorderState.recording);
  }

  Future<void> _stopRecording() async {
    if (_state != RecorderState.recording) return;
    setState(() => _state = RecorderState.processing);

    final file = await _audio.stopRecording();
    if (file == null) {
      setState(() => _state = RecorderState.idle);
      widget.onError?.call('Recording was empty. Please try again.');
      return;
    }

    setState(() => _state = RecorderState.done);
    widget.onRecordingComplete(file);
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _state == RecorderState.recording;
    final isProcessing =
        _state == RecorderState.processing || widget.isProcessing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulse ring + mic button
        GestureDetector(
          onTapDown: (_) => _startRecording(),
          onTapUp: (_) => _stopRecording(),
          onTapCancel: () => _stopRecording(),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseRadius = isRecording
                  ? 8 + 8 * _pulseController.value
                  : 0.0;
              return Container(
                width: 80 + pulseRadius * 2,
                height: 80 + pulseRadius * 2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording
                      ? AppColors.blushedBrick.withOpacity(
                          0.12 + 0.06 * _pulseController.value)
                      : Colors.transparent,
                ),
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording
                    ? AppColors.blushedBrick
                    : isProcessing
                        ? AppColors.sageGreen
                        : AppColors.hunterGreen,
              ),
              child: isProcessing
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.brightSnow,
                        ),
                      ),
                    )
                  : Icon(
                      isRecording ? LucideIcons.micOff : LucideIcons.mic,
                      color: AppColors.brightSnow,
                      size: 28,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isRecording
                ? 'Recording...'
                : isProcessing
                    ? 'Analyzing...'
                    : widget.label,
            key: ValueKey(_state),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.slateGrey,
            ),
          ),
        ),
      ],
    );
  }
}

/// Waveform bar visualization (animated while recording).
class WaveformBar extends StatelessWidget {
  const WaveformBar({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(12, (i) {
        return _Bar(index: i, isActive: isActive);
      }),
    );
  }
}

class _Bar extends StatefulWidget {
  const _Bar({required this.index, required this.isActive});
  final int index;
  final bool isActive;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.index);
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + rng.nextInt(400)),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 4,
      end: 20 + rng.nextDouble() * 16,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_Bar old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isActive) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 3,
        height: widget.isActive ? _anim.value : 4,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppColors.sageGreen
              : AppColors.alabasterGrey,
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
    );
  }
}
