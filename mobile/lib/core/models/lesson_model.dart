/// Mirrors the `lessons` table in Supabase.
class LessonModel {
  final String id;
  final String moduleId;
  final String title;
  final String type; // 'practice' | 'exam'
  final int orderIndex;
  final List<LessonWord> words;
  final bool isCompleted;
  final double? lastScore;

  const LessonModel({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.type,
    required this.orderIndex,
    this.words = const [],
    this.isCompleted = false,
    this.lastScore,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
        id: json['id'] as String,
        moduleId: json['module_id'] as String,
        title: json['title'] as String,
        type: json['type'] as String? ?? 'practice',
        orderIndex: json['order_index'] as int? ?? 0,
        words: (json['lesson_words'] as List<dynamic>?)
                ?.map((w) => LessonWord.fromJson(w as Map<String, dynamic>))
                .toList() ??
            [],
        isCompleted: json['is_completed'] as bool? ?? false,
        lastScore: (json['last_score'] as num?)?.toDouble(),
      );
}

class LessonWord {
  final String id;
  final String word;
  final String? ipa;
  final String? hint;

  const LessonWord({
    required this.id,
    required this.word,
    this.ipa,
    this.hint,
  });

  factory LessonWord.fromJson(Map<String, dynamic> json) => LessonWord(
        id: json['id'] as String,
        word: json['word'] as String,
        ipa: json['ipa'] as String?,
        hint: json['hint'] as String?,
      );
}
