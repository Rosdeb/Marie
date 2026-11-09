import 'discipline_theme_models.dart';

class PracticeSelection {
  final String? topic;
  final String? jurisdiction;
  final String? level;
  final String mode;
  final String? theme;

  /// The offices chosen for "Theme across offices" — two or more. Empty for
  /// every other mode, which works on one office at a time.
  final List<String> offices;
  final int? previewQuestions;
  final int? previewMinutes;
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
    this.mode = 'by_level',
    this.theme,
    this.offices = const [],
    this.previewQuestions,
    this.previewMinutes,
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
    String? mode,
    String? theme,
    List<String>? offices,
    int? previewQuestions,
    int? previewMinutes,
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
      mode: mode ?? this.mode,
      theme: theme ?? this.theme,
      offices: offices ?? this.offices,
      previewQuestions: previewQuestions ?? this.previewQuestions,
      previewMinutes: previewMinutes ?? this.previewMinutes,
      language: language ?? this.language,
      disciplines: disciplines ?? this.disciplines,
      themes: themes ?? this.themes,
      isLoadingDisciplines: isLoadingDisciplines ?? this.isLoadingDisciplines,
      isLoadingThemes: isLoadingThemes ?? this.isLoadingThemes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
