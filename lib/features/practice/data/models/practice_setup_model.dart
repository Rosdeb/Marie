import 'discipline_theme_models.dart';

class PracticeSelection {
  final String? topic;
  final String? jurisdiction;
  final String? level;
  final String language;
  final List<DisciplineDetailModel> disciplines;
  final List<ThemeDetailModel> themes;
  final bool isLoadingDisciplines;
  final bool isLoadingThemes;
  final String? errorMessage;

  PracticeSelection({
    this.topic,
    this.jurisdiction,
    this.level,
    this.language = 'German',
    this.disciplines = const [],
    this.themes = const [],
    this.isLoadingDisciplines = false,
    this.isLoadingThemes = false,
    this.errorMessage,
  });

  PracticeSelection copyWith({
    String? topic,
    String? jurisdiction,
    String? level,
    String? language,
    List<DisciplineDetailModel>? disciplines,
    List<ThemeDetailModel>? themes,
    bool? isLoadingDisciplines,
    bool? isLoadingThemes,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PracticeSelection(
      topic: topic ?? this.topic,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      level: level ?? this.level,
      language: language ?? this.language,
      disciplines: disciplines ?? this.disciplines,
      themes: themes ?? this.themes,
      isLoadingDisciplines: isLoadingDisciplines ?? this.isLoadingDisciplines,
      isLoadingThemes: isLoadingThemes ?? this.isLoadingThemes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
