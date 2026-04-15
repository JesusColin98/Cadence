import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cadence/core/config/app_config.dart';
import 'package:cadence/core/models/module_model.dart';
import 'package:cadence/core/models/lesson_model.dart';
import 'package:cadence/core/models/assessment_result.dart';

/// Centralised HTTP client that calls the Next.js API routes.
/// Automatically injects the Supabase JWT Bearer token.
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // ── Modules ───────────────────────────────────────────────────────────────

  Future<List<ModuleModel>> getModules() async {
    final res = await _dio.get('/api/modules');
    final list = res.data as List<dynamic>;
    return list
        .map((m) => ModuleModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<LessonModel>> getLessons(String moduleId) async {
    final res = await _dio.get('/api/modules/$moduleId/lessons');
    final list = res.data as List<dynamic>;
    return list
        .map((l) => LessonModel.fromJson(l as Map<String, dynamic>))
        .toList();
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProgress() async {
    final res = await _dio.get('/api/progress');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get('/api/stats');
    return res.data as Map<String, dynamic>;
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  Future<String> startSession({
    required String lessonId,
    required String moduleId,
  }) async {
    final res = await _dio.post('/api/sessions', data: {
      'lesson_id': lessonId,
      'module_id': moduleId,
    });
    return (res.data as Map<String, dynamic>)['session_id'] as String;
  }

  Future<void> endSession({
    required String sessionId,
    required double score,
    required int duration,
  }) async {
    await _dio.patch('/api/sessions/$sessionId', data: {
      'score': score,
      'duration_seconds': duration,
    });
  }

  // ── Pronunciation assessment ──────────────────────────────────────────────

  Future<AssessmentResult> assess({
    required File audioFile,
    required String targetWord,
    String? sessionId,
  }) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: 'recording.wav',
      ),
      'target': targetWord,
      if (sessionId != null) 'session_id': sessionId,
    });

    final res = await _dio.post('/api/assess', data: formData);
    return AssessmentResult.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Transcription ─────────────────────────────────────────────────────────

  Future<String> transcribe(File audioFile) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: 'recording.wav',
      ),
    });

    final res = await _dio.post('/api/transcribe', data: formData);
    return (res.data as Map<String, dynamic>)['transcript'] as String? ?? '';
  }

  // ── AI Coach ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendCoachTurn({
    required List<Map<String, dynamic>> messages,
    String mode = 'freedom',
    String? targetWord,
  }) async {
    final res = await _dio.post('/api/ai-coach', data: {
      'messages': messages,
      'mode': mode,
      if (targetWord != null) 'target_word': targetWord,
    });
    return res.data as Map<String, dynamic>;
  }

  // ── Reference audio ───────────────────────────────────────────────────────

  Future<String> getReferenceAudioUrl(String word) {
    return Future.value(
      '${AppConfig.apiBaseUrl}/api/reference-audio?word=${Uri.encodeComponent(word)}',
    );
  }

  // ── Conversation progress ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getConversationProgress() async {
    final res = await _dio.get('/api/conversation-progress');
    return (res.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
