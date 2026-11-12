class OfficeDisciplineEntity {
  /// The name stored with the questions: the key sent back when this
  /// discipline is chosen. Never shown as-is.
  final String name;

  /// How the server writes the same discipline for a reader, so a sheet
  /// called UnitaryPatent reads "Unitary Patent" without breaking the lookup.
  final String label;
  final int questions;

  /// How many of them the free demo can draw: the DEMO sheet only.
  ///
  /// Separate from [questions] because the two are genuinely different
  /// numbers. IPI holds 800 Patents questions and 7 demo ones, and the demo
  /// screens used to announce a written-in "20 questions" for every office.
  final int demoQuestions;

  const OfficeDisciplineEntity({
    required this.name,
    this.label = '',
    required this.questions,
    this.demoQuestions = 0,
  });

  /// What to put on screen. Older servers send no label.
  String get displayName => label.isNotEmpty ? label : name;
}

class OfficeEntity {
  final String code;
  final String name;

  /// The office's full name, from the server. The app used to carry its own
  /// copy of all fifteen, which took a release to correct.
  final String fullName;
  final String territory;
  final String type; // 'international', 'regional', 'national'
  final List<OfficeDisciplineEntity> disciplines;
  final int sheets;
  final int questions;
  final List<String> levels;
  final bool hasAccess;
  final bool isAvailable;

  /// Demo questions across all the disciplines of this office.
  final int demoQuestions;

  /// Whether the free demo can be played here at all. An office can hold
  /// thousands of questions and still have no DEMO sheet.
  final bool hasDemo;

  const OfficeEntity({
    required this.code,
    required this.name,
    this.fullName = '',
    required this.territory,
    required this.type,
    required this.disciplines,
    required this.sheets,
    required this.questions,
    required this.levels,
    required this.hasAccess,
    required this.isAvailable,
    this.demoQuestions = 0,
    this.hasDemo = false,
  });
}
