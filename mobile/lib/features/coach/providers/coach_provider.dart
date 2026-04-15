import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cadence/core/models/coach_message.dart';
import 'package:cadence/core/services/api_service.dart';
import 'package:cadence/features/learn/providers/learn_provider.dart';

const _kSessionsKey = 'coach_sessions';
const _kMaxSessions = 12;

class CoachState {
  final List<CoachSession> sessions;
  final String? activeSessionId;
  final bool isSending;
  final String? error;

  const CoachState({
    this.sessions = const [],
    this.activeSessionId,
    this.isSending = false,
    this.error,
  });

  CoachSession? get activeSession =>
      sessions.where((s) => s.id == activeSessionId).firstOrNull;

  CoachState copyWith({
    List<CoachSession>? sessions,
    String? activeSessionId,
    bool? isSending,
    String? error,
    bool clearError = false,
    bool clearActiveSession = false,
  }) =>
      CoachState(
        sessions: sessions ?? this.sessions,
        activeSessionId: clearActiveSession
            ? null
            : (activeSessionId ?? this.activeSessionId),
        isSending: isSending ?? this.isSending,
        error: clearError ? null : (error ?? this.error),
      );
}

class CoachNotifier extends StateNotifier<CoachState> {
  CoachNotifier(this._api) : super(const CoachState()) {
    _loadSessions();
  }

  final ApiService _api;

  // ── Session management ────────────────────────────────────────────────────

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSessionsKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      final sessions = list.map((s) {
        final map = s as Map<String, dynamic>;
        return CoachSession(
          id: map['id'] as String,
          title: map['title'] as String,
          messages: (map['messages'] as List<dynamic>)
              .map((m) => CoachMessage.fromJson(m as Map<String, dynamic>))
              .toList(),
          createdAt: DateTime.parse(map['created_at'] as String),
          updatedAt: DateTime.parse(map['updated_at'] as String),
        );
      }).toList();
      state = state.copyWith(sessions: sessions);
    } catch (_) {}
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = state.sessions.map((s) => {
            'id': s.id,
            'title': s.title,
            'messages': s.messages.map((m) => m.toJson()).toList(),
            'created_at': s.createdAt.toIso8601String(),
            'updated_at': s.updatedAt.toIso8601String(),
          }).toList();
      await prefs.setString(_kSessionsKey, jsonEncode(list));
    } catch (_) {}
  }

  void createSession() {
    final session = CoachSession.empty();
    var sessions = [session, ...state.sessions];
    if (sessions.length > _kMaxSessions) {
      sessions = sessions.sublist(0, _kMaxSessions);
    }
    state = state.copyWith(sessions: sessions, activeSessionId: session.id);
    _saveSessions();
  }

  void selectSession(String id) {
    state = state.copyWith(activeSessionId: id);
  }

  void deleteSession(String id) {
    final sessions = state.sessions.where((s) => s.id != id).toList();
    state = state.copyWith(
      sessions: sessions,
      clearActiveSession: state.activeSessionId == id,
    );
    _saveSessions();
  }

  // ── Messaging ─────────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String content,
    String? audioPath,
    String? transcript,
  }) async {
    if (state.activeSession == null) createSession();

    final session = state.activeSession!;
    final userMsg = CoachMessage.user(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      audioPath: audioPath,
      transcript: transcript,
    );

    _updateActiveSession(
      session.copyWith(messages: [...session.messages, userMsg]),
    );

    state = state.copyWith(isSending: true, clearError: true);

    try {
      final history = session.messages
          .map((m) => {'role': m.role.name, 'content': m.content})
          .toList()
        ..add({'role': 'user', 'content': content});

      final res = await _api.sendCoachTurn(messages: history);
      final reply = res['response'] as String? ?? '';

      final coachMsg = CoachMessage.coach(
        id: '${DateTime.now().millisecondsSinceEpoch}_coach',
        content: reply,
      );

      final updated = state.activeSession!;
      _updateActiveSession(
        updated.copyWith(
          messages: [...updated.messages, coachMsg],
          updatedAt: DateTime.now(),
          title: updated.messages.isEmpty ? _titleFromMessage(content) : updated.title,
        ),
      );

      state = state.copyWith(isSending: false);
      _saveSessions();
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Could not reach the AI coach. Please try again.',
      );
    }
  }

  void _updateActiveSession(CoachSession updated) {
    final sessions = state.sessions
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    state = state.copyWith(sessions: sessions);
  }

  String _titleFromMessage(String msg) {
    if (msg.length <= 36) return msg;
    return '${msg.substring(0, 36)}...';
  }

  void clearError() => state = state.copyWith(clearError: true);
}

extension on CoachSession {
  CoachSession copyWith({
    String? title,
    List<CoachMessage>? messages,
    DateTime? updatedAt,
  }) =>
      CoachSession(
        id: id,
        title: title ?? this.title,
        messages: messages ?? this.messages,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

final coachProvider = StateNotifierProvider<CoachNotifier, CoachState>(
  (ref) => CoachNotifier(ref.watch(apiServiceProvider)),
);
