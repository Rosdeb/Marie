class PracticeSelection {
  final String? topic;
  final String? jurisdiction;
  final String? level;
  final String language;

  PracticeSelection({
    this.topic,
    this.jurisdiction,
    this.level,
    this.language = 'German',
  });

  PracticeSelection copyWith({
    String? topic,
    String? jurisdiction,
    String? level,
    String? language,
  }) {
    return PracticeSelection(
      topic: topic ?? this.topic,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      level: level ?? this.level,
      language: language ?? this.language,
    );
  }
}
