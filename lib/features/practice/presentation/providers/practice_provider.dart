import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/practice_setup_model.dart';

class PracticeNotifier extends Notifier<PracticeSelection> {
  @override
  PracticeSelection build() {
    return PracticeSelection(
      topic: 'Patents',
      jurisdiction: 'EPO',
      level: 'Beginner',
      language: 'German',
    );
  }

  void setTopic(String topic) {
    state = state.copyWith(topic: topic);
  }

  void setJurisdiction(String jurisdiction) {
    state = state.copyWith(jurisdiction: jurisdiction);
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
      jurisdiction: 'EPO',
      level: 'Beginner',
      language: 'German',
    );
  }
}

final practiceProvider =
    NotifierProvider<PracticeNotifier, PracticeSelection>(PracticeNotifier.new);
