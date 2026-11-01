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
      language: 'English',
      disciplines: _getDefaultDisciplinesForOffice('IPI'),
    );
  }

  static List<DisciplineDetailModel> _getDefaultDisciplinesForOffice(String office) {
    final code = office.toUpperCase().trim();
    final names = switch (code) {
      'WIPO' => ['PCT', 'Madrid', 'Hague'],
      'UPC' => ['Court of First Instance', 'Court of Appeal', 'Mediation & Arbitration'],
      _ => ['Patents', 'Trademarks', 'Designs'],
    };

    return names.map((name) => DisciplineDetailModel(
      name: name,
      questions: 0,
      levels: const [
        LevelDetailModel(level: 'Beginner', isAvailable: true, minutes: 20),
        LevelDetailModel(level: 'Intermediate', isAvailable: true, minutes: 30),
        LevelDetailModel(level: 'Advanced', isAvailable: true, minutes: 40),
        LevelDetailModel(level: 'Expert', isAvailable: true, minutes: 50),
      ],
    )).toList();
  }

  static List<DisciplineDetailModel> _sortDisciplines(List<DisciplineDetailModel> list) {
    int getOrder(String name) {
      final n = name.toLowerCase().trim();
      if (n.contains('patent') || n == 'pct') return 1;
      if (n.contains('trademark') || n == 'madrid') return 2;
      if (n.contains('design') || n == 'hague') return 3;
      return 4;
    }

    final sorted = List<DisciplineDetailModel>.from(list);
    sorted.sort((a, b) => getOrder(a.name).compareTo(getOrder(b.name)));
    return sorted;
  }

  Future<void> loadDisciplines(String office) async {
    state = state.copyWith(isLoadingDisciplines: true, clearError: true);
    try {
      final fetched = await _practiceRepository.getOfficeDisciplines(
        office,
      );
      final rawList = fetched.isNotEmpty ? fetched : _getDefaultDisciplinesForOffice(office);
      final disciplines = _sortDisciplines(rawList);

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
      final fallback = _sortDisciplines(_getDefaultDisciplinesForOffice(office));
      state = state.copyWith(
        disciplines: state.disciplines.isNotEmpty ? state.disciplines : fallback,
        isLoadingDisciplines: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadThemes(String office, String subject) async {
    state = state.copyWith(isLoadingThemes: true);
    try {
      final themes = await _practiceRepository.getDisciplineThemes(
        office,
        subject,
      );
      state = state.copyWith(themes: themes, isLoadingThemes: false);
    } catch (e) {
      state = state.copyWith(isLoadingThemes: false);
    }
  }

  void setTopic(String topic) {
    state = state.copyWith(topic: topic);
    final office = state.jurisdiction ?? 'WIPO';
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
  }

  void setTheme(ThemeDetailModel theme) {
    state = PracticeSelection(
      topic: state.topic,
      jurisdiction: state.jurisdiction,
      mode: 'by_theme',
      theme: theme.theme,
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
      jurisdiction: 'WIPO',
      level: 'Beginner',
      language: 'German',
    );
    loadDisciplines('WIPO');
  }
}

final practiceProvider = NotifierProvider<PracticeNotifier, PracticeSelection>(
  PracticeNotifier.new,
);
