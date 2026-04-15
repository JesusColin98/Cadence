/// A single message in the AI Coach conversation thread.
class CoachMessage {
  final String id;
  final CoachMessageRole role;
  final String content;
  final String? audioPath; // local path to recorded audio (user messages)
  final String? transcript; // transcription of user audio
  final DateTime createdAt;

  const CoachMessage({
    required this.id,
    required this.role,
    required this.content,
    this.audioPath,
    this.transcript,
    required this.createdAt,
  });

  bool get isUser => role == CoachMessageRole.user;
  bool get isCoach => role == CoachMessageRole.coach;

  factory CoachMessage.user({
    required String id,
    required String content,
    String? audioPath,
    String? transcript,
  }) =>
      CoachMessage(
        id: id,
        role: CoachMessageRole.user,
        content: content,
        audioPath: audioPath,
        transcript: transcript,
        createdAt: DateTime.now(),
      );

  factory CoachMessage.coach({
    required String id,
    required String content,
  }) =>
      CoachMessage(
        id: id,
        role: CoachMessageRole.coach,
        content: content,
        createdAt: DateTime.now(),
      );

  factory CoachMessage.fromJson(Map<String, dynamic> json) => CoachMessage(
        id: json['id'] as String,
        role: CoachMessageRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => CoachMessageRole.coach,
        ),
        content: json['content'] as String,
        audioPath: json['audio_path'] as String?,
        transcript: json['transcript'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'audio_path': audioPath,
        'transcript': transcript,
        'created_at': createdAt.toIso8601String(),
      };
}

enum CoachMessageRole { user, coach }

/// A saved coach session (mirrors ai-coach-storage.ts)
class CoachSession {
  final String id;
  final String title;
  final List<CoachMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoachSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoachSession.empty() => CoachSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New conversation',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
