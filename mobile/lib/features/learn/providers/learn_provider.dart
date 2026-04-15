import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadence/core/models/module_model.dart';
import 'package:cadence/core/models/lesson_model.dart';
import 'package:cadence/core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final modulesProvider = FutureProvider<List<ModuleModel>>((ref) async {
  return ref.watch(apiServiceProvider).getModules();
});

final lessonsProvider =
    FutureProvider.family<List<LessonModel>, String>((ref, moduleId) async {
  return ref.watch(apiServiceProvider).getLessons(moduleId);
});

// ── Practice session state ────────────────────────────────────────────────────

class PracticeState {
  final List<LessonWord> words;
  final int currentIndex;
  final Map<String, dynamic> results; // wordId -> AssessmentResult
  final bool isComplete;
  final bool isAssessing;
  final String? error;

  const PracticeState({
    this.words = const [],
    this.currentIndex = 0,
    this.results = const {},
    this.isComplete = false,
    this.isAssessing = false,
    this.error,
  });

  LessonWord? get currentWord =>
      currentIndex < words.length ? words[currentIndex] : null;

  bool get isLastWord => currentIndex >= words.length - 1;

  double get overallScore {
    if (results.isEmpty) return 0;
    final scores = results.values
        .map((r) => (r['overall_score'] as num?)?.toDouble() ?? 0.0)
        .toList();
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  PracticeState copyWith({
    List<LessonWord>? words,
    int? currentIndex,
    Map<String, dynamic>? results,
    bool? isComplete,
    bool? isAssessing,
    String? error,
    bool clearError = false,
  }) =>
      PracticeState(
        words: words ?? this.words,
        currentIndex: currentIndex ?? this.currentIndex,
        results: results ?? this.results,
        isComplete: isComplete ?? this.isComplete,
        isAssessing: isAssessing ?? this.isAssessing,
        error: clearError ? null : (error ?? this.error),
      );
}

class PracticeNotifier extends StateNotifier<PracticeState> {
  PracticeNotifier(this._api) : super(const PracticeState());

  final ApiService _api;
  String? _sessionId;

  Future<void> startSession(LessonModel lesson) async {
    try {
      _sessionId = await _api.startSession(
        lessonId: lesson.id,
        moduleId: lesson.moduleId,
      );
    } catch (_) {
      // Continue without session tracking
    }
    state = PracticeState(words: lesson.words);
  }

  Future<void> assess({
    required dynamic audioFile,
    required String targetWord,
    required String wordId,
  }) async {
    state = state.copyWith(isAssessing: true, clearError: true);
    try {
      final result = await _api.assess(
        audioFile: audioFile,
        targetWord: targetWord,
        sessionId: _sessionId,
      );
      final updated = Map<String, dynamic>.from(state.results);
      updated[wordId] = result.toJson();
      state = state.copyWith(isAssessing: false, results: updated);
    } catch (e) {
      state = state.copyWith(
        isAssessing: false,
        error: 'Assessment failed. Please try again.',
      );
    }
  }

  void nextWord() {
    if (state.isLastWord) {
      state = state.copyWith(isComplete: true);
      _endSession();
    } else {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;
    try {
      await _api.endSession(
        sessionId: _sessionId!,
        score: state.overallScore,
        duration: 0,
      );
    } catch (_) {}
  }

  void reset() {
    _sessionId = null;
    state = const PracticeState();
  }
}

final practiceProvider =
    StateNotifierProvider.autoDispose<PracticeNotifier, PracticeState>(
  (ref) => PracticeNotifier(ref.watch(apiServiceProvider)),
);
