import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadence/core/services/api_service.dart';
import 'package:cadence/features/learn/providers/learn_provider.dart';

class StatsState {
  final int totalSessions;
  final int completedLessons;
  final double avgScore;
  final int practiceStreak;
  final bool isLoading;
  final String? error;

  const StatsState({
    this.totalSessions = 0,
    this.completedLessons = 0,
    this.avgScore = 0.0,
    this.practiceStreak = 0,
    this.isLoading = false,
    this.error,
  });

  StatsState copyWith({
    int? totalSessions,
    int? completedLessons,
    double? avgScore,
    int? practiceStreak,
    bool? isLoading,
    String? error,
  }) =>
      StatsState(
        totalSessions: totalSessions ?? this.totalSessions,
        completedLessons: completedLessons ?? this.completedLessons,
        avgScore: avgScore ?? this.avgScore,
        practiceStreak: practiceStreak ?? this.practiceStreak,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier(this._api) : super(const StatsState()) {
    load();
  }

  final ApiService _api;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _api.getStats();
      state = StatsState(
        totalSessions: data['total_sessions'] as int? ?? 0,
        completedLessons: data['completed_lessons'] as int? ?? 0,
        avgScore: (data['avg_score'] as num?)?.toDouble() ?? 0.0,
        practiceStreak: data['streak'] as int? ?? 0,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>(
  (ref) => StatsNotifier(ref.watch(apiServiceProvider)),
);
