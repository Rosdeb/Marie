/// The progress page, as the server counts it.
///
/// Section 8: "for each office and domain, the number of questions answered
/// and the percentage correct by level and by theme. Highlight the weakest
/// themes with a 'Practise this theme' button."
class ProgressSlice {
  final String name;
  final int answered;
  final int correct;
  final int percentage;

  const ProgressSlice({
    required this.name,
    this.answered = 0,
    this.correct = 0,
    this.percentage = 0,
  });

  factory ProgressSlice.fromJson(Map<String, dynamic> json) {
    return ProgressSlice(
      name: json['name'] as String? ?? '',
      answered: (json['answered'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One office and discipline the reader has worked on.
class ProgressGroup {
  final String office;

  /// The stored key, used when starting a session from here.
  final String subject;

  /// The same discipline written for a reader.
  final String disciplineLabel;

  final int answered;
  final int correct;
  final int percentage;
  final List<ProgressSlice> byLevel;
  final List<ProgressSlice> byTheme;

  /// Up to three themes with the lowest score, each shown with a
  /// "Practise this theme" button. Empty until enough has been answered for
  /// a low score to mean anything.
  final List<String> weakestThemes;

  const ProgressGroup({
    required this.office,
    required this.subject,
    this.disciplineLabel = '',
    this.answered = 0,
    this.correct = 0,
    this.percentage = 0,
    this.byLevel = const [],
    this.byTheme = const [],
    this.weakestThemes = const [],
  });

  String get displayDiscipline =>
      disciplineLabel.isNotEmpty ? disciplineLabel : subject;

  factory ProgressGroup.fromJson(Map<String, dynamic> json) {
    List<ProgressSlice> slices(String key) =>
        (json[key] as List<dynamic>? ?? [])
            .map((s) => ProgressSlice.fromJson(s as Map<String, dynamic>))
            .toList();

    return ProgressGroup(
      office: json['office'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      disciplineLabel: json['disciplineLabel'] as String? ?? '',
      answered: (json['answered'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      byLevel: slices('byLevel'),
      byTheme: slices('byTheme'),
      weakestThemes: (json['weakestThemes'] as List<dynamic>? ?? [])
          .map((t) => t.toString())
          .toList(),
    );
  }
}
