import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  /// User completed onboarding when display_name is set.
  bool get hasOnboarded =>
      user?.userMetadata?['display_name'] != null &&
      (user!.userMetadata!['display_name'] as String).isNotEmpty;

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: clearUser ? null : (user ?? this.user),
        error: clearError ? null : (error ?? this.error),
        isInitialized: isInitialized ?? this.isInitialized,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _supabase = Supabase.instance.client;

  void _init() {
    // Set current user immediately
    final currentUser = _supabase.auth.currentUser;
    state = state.copyWith(
      user: currentUser,
      isInitialized: true,
    );

    // Listen for auth changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      state = state.copyWith(
        user: user,
        isInitialized: true,
        clearUser: user == null,
        clearError: true,
      );
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        user: res.user,
      );
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': name.trim()},
      );
      state = state.copyWith(
        isLoading: false,
        user: res.user,
      );
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> updateDisplayName(String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _supabase.auth.updateUser(
        UserAttributes(data: {'display_name': name.trim()}),
      );
      state = state.copyWith(isLoading: false, user: res.user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to save name.');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AuthState(isInitialized: true);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

/// Convenience: the current Supabase user (null when unauthenticated)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});
