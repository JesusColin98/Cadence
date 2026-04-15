import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadence/core/services/api_service.dart';
import 'package:cadence/features/learn/providers/learn_provider.dart';

class ConversationState {
  final List<Map<String, dynamic>> modules;
  final bool isLoading;
  final String? error;

  const ConversationState({
    this.modules = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationState copyWith({
    List<Map<String, dynamic>>? modules,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      ConversationState(
        modules: modules ?? this.modules,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ConversationNotifier extends StateNotifier<ConversationState> {
  ConversationNotifier(this._api) : super(const ConversationState()) {
    load();
  }

  final ApiService _api;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final progress = await _api.getConversationProgress();
      state = state.copyWith(modules: progress, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load conversation modules.',
      );
    }
  }
}

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>(
  (ref) => ConversationNotifier(ref.watch(apiServiceProvider)),
);
