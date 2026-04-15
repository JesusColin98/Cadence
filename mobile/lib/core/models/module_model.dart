/// Mirrors the `modules` table in Supabase.
class ModuleModel {
  final String id;
  final String title;
  final String? description;
  final int? lessonCount;
  final int completedCount;
  final double? avgScore;

  const ModuleModel({
    required this.id,
    required this.title,
    this.description,
    this.lessonCount,
    this.completedCount = 0,
    this.avgScore,
  });

  double get progressPercent =>
      lessonCount != null && lessonCount! > 0
          ? (completedCount / lessonCount!).clamp(0.0, 1.0)
          : 0.0;

  factory ModuleModel.fromJson(Map<String, dynamic> json) => ModuleModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        lessonCount: json['lesson_count'] as int?,
        completedCount: json['completed_count'] as int? ?? 0,
        avgScore: (json['avg_score'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'lesson_count': lessonCount,
        'completed_count': completedCount,
        'avg_score': avgScore,
      };
}
