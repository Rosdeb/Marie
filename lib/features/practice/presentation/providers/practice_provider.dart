import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/practice_setup_model.dart';
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
      final disciplines = await _practiceRepository.getOfficeDisciplines(office);
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
      final themes = await _practiceRepository.getDisciplineThemes(office, subject);
      state = state.copyWith(
        themes: themes,
        isLoadingThemes: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingThemes: false,
      );
    }
  }

  void setTopic(String topic) {
    state = state.copyWith(topic: topic);
    final office = state.jurisdiction ?? 'IPI';
    loadThemes(office, topic);
  }

  void setJurisdiction(String jurisdiction) {
    state = state.copyWith(jurisdiction: jurisdiction);
    loadDisciplines(jurisdiction);
  }

  void setLevel(String level) {
    state = state.copyWith(level: level);
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

final practiceProvider =
    NotifierProvider<PracticeNotifier, PracticeSelection>(PracticeNotifier.new);
