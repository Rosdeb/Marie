class DemoItem {
  final String id;
  final String title;
  final int questions;
  final int minutes;
  final String subdiscipline;
  final String level;

  const DemoItem({
    required this.id,
    required this.title,
    required this.questions,
    required this.minutes,
    this.subdiscipline = 'General Knowledge',
    this.level = 'Beginner',
  });
}
