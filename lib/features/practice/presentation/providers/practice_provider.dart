import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/practice_setup_model.dart';
import '../../data/models/discipline_theme_models.dart';
import '../../data/repositories/practice_repository_impl.dart';
import '../../domain/repositories/practice_repository.dart';

class PracticeNotifier extends Notifier<PracticeSelection> {
  late final PracticeRepository _practiceRepository;

  @override
  PracticeSelection build() {
    _practiceRepository = ref.watch(practiceRepositoryProvider);
    Future.microtask(() => loadDisciplines(state.jurisdiction ?? 'IPI'));
    return PracticeSelection(
      topic: 'Patents',
      jurisdiction: 'IPI',
      level: 'Beginner',
      language: 'German',
    );
  }

  Future<void> loadDisciplines(String office) async {
    state = state.copyWith(isLoadingDisciplines: true, clearError: true);
    try {
      final disciplines = await _practiceRepository.getOfficeDisciplines(
        office,
      );
      String? updatedTopic = state.topic;
      if (disciplines.isNotEmpty) {
        final hasCurrentTopic = disciplines.any(
          (d) => d.name.toLowerCase() == (state.topic ?? '').toLowerCase(),
        );
        if (!hasCurrentTopic) {
          updatedTopic = disciplines.first.name;
        }
      }
      state = state.copyWith(
        disciplines: disciplines,
        topic: updatedTopic,
        isLoadingDisciplines: false,
      );
      if (updatedTopic != null) {
        loadThemes(office, updatedTopic);
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingDisciplines: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadThemes(String office, String subject) async {
    state = state.copyWith(isLoadingThemes: true);
    try {
      // "Theme across offices" compares one theme between offices, so its
      // menu is the themes that exist in more than one of them - not the
      // themes of the office the reader happens to have open.
      final themes = state.mode == 'theme_across_offices'
          ? await _practiceRepository.getCrossOfficeThemes(subject)
          : await _practiceRepository.getDisciplineThemes(office, subject);
      state = state.copyWith(themes: themes, isLoadingThemes: false);
    } catch (e) {
      state = state.copyWith(isLoadingThemes: false);
    }
  }

  /// The offices picked for "Theme across offices".
  void setCrossOffices(List<String> offices) {
    state = state.copyWith(offices: offices);
  }

  void setTopic(String topic) {
    // Called from a tap on Home or on the discipline screen, never from a
    // default, so this is where the choice is recorded.
    state = state.copyWith(topic: topic, topicChosen: true);
    final office = state.jurisdiction ?? 'IPI';
    loadThemes(office, topic);
  }

  void setJurisdiction(String jurisdiction) {
    state = state.copyWith(jurisdiction: jurisdiction);
    loadDisciplines(jurisdiction);
  }

  void setLevel(String level) {
    final discipline = state.disciplines.where(
      (item) => item.name.toLowerCase() == (state.topic ?? '').toLowerCase(),
    );
    final levels = discipline.isEmpty ? const [] : discipline.first.levels;
    final matches = levels.where(
      (item) => item.level.toLowerCase() == level.toLowerCase(),
    );
    final detail = matches.isEmpty ? null : matches.first;
    state = state.copyWith(
      level: level,
      mode: 'by_level',
      previewQuestions: detail?.questionsPerSession,
      previewMinutes: detail?.minutes,
    );
  }

  void setMode(String mode) {
    state = PracticeSelection(
      topic: state.topic,
      jurisdiction: state.jurisdiction,
      // A fresh mode choice must not carry a stale level/theme into its body.
      level: null,
      mode: mode,
      language: state.language,
      disciplines: state.disciplines,
      themes: state.themes,
      isLoadingDisciplines: state.isLoadingDisciplines,
      isLoadingThemes: state.isLoadingThemes,
    );

    // The two theme modes read from different menus, so the list has to be
    // fetched again when the reader moves between them.
    final office = state.jurisdiction;
    final topic = state.topic;
    if ((mode == 'by_theme' || mode == 'theme_across_offices') &&
        office != null &&
        topic != null) {
      loadThemes(office, topic);
    }
  }

  void setTheme(ThemeDetailModel theme) {
    state = PracticeSelection(
      topic: state.topic,
      jurisdiction: state.jurisdiction,
      // The mode is kept: this screen serves both "By theme" and "Theme
      // across offices", and hard-coding by_theme here sent every
      // cross-office session to the server as a single-office one.
      mode: state.mode == 'theme_across_offices'
          ? 'theme_across_offices'
          : 'by_theme',
      theme: theme.theme,
      offices: state.offices,
      previewQuestions: theme.sessionLength,
      language: state.language,
      disciplines: state.disciplines,
      themes: state.themes,
    );
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void reset() {
    state = PracticeSelection(
      topic: 'Patents',
      jurisdiction: 'IPI',
      level: 'Beginner',
      language: 'German',
    );
    loadDisciplines('IPI');
  }
}

final practiceProvider = NotifierProvider<PracticeNotifier, PracticeSelection>(
  PracticeNotifier.new,
);
