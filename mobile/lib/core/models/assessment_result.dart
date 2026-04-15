/// Result from POST /api/assess — phoneme-level pronunciation scoring.
class AssessmentResult {
  final double overallScore;
  final String transcript;
  final List<PhonemeScore> phonemes;

  const AssessmentResult({
    required this.overallScore,
    required this.transcript,
    required this.phonemes,
  });

  bool get isPassing => overallScore >= 0.7;

  factory AssessmentResult.fromJson(Map<String, dynamic> json) =>
      AssessmentResult(
        overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
        transcript: json['transcript'] as String? ?? '',
        phonemes: (json['phonemes'] as List<dynamic>?)
                ?.map((p) => PhonemeScore.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class PhonemeScore {
  final String phoneme;
  final double score;
  final bool correct;

  const PhonemeScore({
    required this.phoneme,
    required this.score,
    required this.correct,
  });

  factory PhonemeScore.fromJson(Map<String, dynamic> json) => PhonemeScore(
        phoneme: json['phoneme'] as String,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        correct: json['correct'] as bool? ?? false,
      );
}
