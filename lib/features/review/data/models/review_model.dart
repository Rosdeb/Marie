class ReviewSession {
  final String id;
  final String title;
  final String topic;
  final String jurisdiction;
  final String level;
  final int totalQuestions;
  final int correctCount;
  final int flaggedCount;
  final String completedDate;
  final bool isFlagged;

  const ReviewSession({
    required this.id,
    required this.title,
    required this.topic,
    required this.jurisdiction,
    required this.level,
    required this.totalQuestions,
    required this.correctCount,
    required this.flaggedCount,
    required this.completedDate,
    this.isFlagged = false,
  });

  double get accuracy =>
      totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;
}
