class LevelDetailModel {
  final String level;
  final int questions;
  final int minutes;
  final int questionsPerSession;
  final bool isAvailable;

  const LevelDetailModel({
    required this.level,
    this.questions = 0,
    this.minutes = 0,
    this.questionsPerSession = 0,
    this.isAvailable = true,
  });

  factory LevelDetailModel.fromJson(Map<String, dynamic> json) {
    return LevelDetailModel(
      level: json['level'] as String? ?? '',
      questions: (json['questions'] as num?)?.toInt() ?? 0,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      questionsPerSession: (json['questionsPerSession'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'questions': questions,
    'minutes': minutes,
    'questionsPerSession': questionsPerSession,
    'isAvailable': isAvailable,
  };
}

class DisciplineDetailModel {
  final String name;
  final int questions;
  final List<LevelDetailModel> levels;

  const DisciplineDetailModel({
    required this.name,
    this.questions = 0,
    this.levels = const [],
  });

  factory DisciplineDetailModel.fromJson(Map<String, dynamic> json) {
    final rawLevels = json['levels'] as List<dynamic>? ?? [];
    return DisciplineDetailModel(
      name: json['name'] as String? ?? '',
      questions: (json['questions'] as num?)?.toInt() ?? 0,
      levels: rawLevels
          .map((l) => LevelDetailModel.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'questions': questions,
    'levels': levels.map((l) => l.toJson()).toList(),
  };
}

class ThemeDetailModel {
  final String theme;
  final int questions;
  final int sessionLength;
  final bool isShortSession;
  final String? note;
  final List<String> offices;

  const ThemeDetailModel({
    required this.theme,
    this.questions = 0,
    this.sessionLength = 0,
    this.isShortSession = false,
    this.note,
    this.offices = const [],
  });

  factory ThemeDetailModel.fromJson(Map<String, dynamic> json) {
    final rawOffices = json['offices'] as List<dynamic>? ?? [];
    return ThemeDetailModel(
      theme: json['theme'] as String? ?? '',
      questions: (json['questions'] as num?)?.toInt() ?? 0,
      sessionLength: (json['sessionLength'] as num?)?.toInt() ?? 0,
      isShortSession: json['isShortSession'] as bool? ?? false,
      note: json['note'] as String?,
      offices: rawOffices.map((o) => o.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'questions': questions,
    'sessionLength': sessionLength,
    'isShortSession': isShortSession,
    'note': note,
    'offices': offices,
  };
}
