import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../practice/data/models/quiz_models.dart';

class MistakeEntry {
  final Question question;
  final DateTime recordedAt;

  const MistakeEntry({
    required this.question,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'question': question.toJson(),
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory MistakeEntry.fromJson(Map<String, dynamic> json) {
    return MistakeEntry(
      question: Question.fromJson(
        Map<String, dynamic>.from(json['question'] as Map),
      ),
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class MistakesReviewState {
  final List<MistakeEntry> entries;
  final String? selectedOffice;
  final String? selectedDiscipline;
  final String? selectedLevel;
  final String? selectedTheme;
  final bool isLoading;

  const MistakesReviewState({
    this.entries = const [],
    this.selectedOffice,
    this.selectedDiscipline,
    this.selectedLevel,
    this.selectedTheme,
    this.isLoading = false,
  });

  MistakesReviewState copyWith({
    List<MistakeEntry>? entries,
    String? selectedOffice,
    String? selectedDiscipline,
    String? selectedLevel,
    String? selectedTheme,
    bool? isLoading,
    bool clearOffice = false,
    bool clearDiscipline = false,
    bool clearLevel = false,
    bool clearTheme = false,
  }) {
    return MistakesReviewState(
      entries: entries ?? this.entries,
      selectedOffice: clearOffice ? null : (selectedOffice ?? this.selectedOffice),
      selectedDiscipline:
          clearDiscipline ? null : (selectedDiscipline ?? this.selectedDiscipline),
      selectedLevel: clearLevel ? null : (selectedLevel ?? this.selectedLevel),
      selectedTheme: clearTheme ? null : (selectedTheme ?? this.selectedTheme),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Oldest mistakes first (FIFO) per requirement:
  /// "The questions the user got wrong longest ago come first."
  List<MistakeEntry> get filteredEntries {
    final list = entries.where((entry) {
      final q = entry.question;
      if (selectedOffice != null &&
          selectedOffice!.isNotEmpty &&
          q.office.isNotEmpty &&
          q.office.toLowerCase() != selectedOffice!.toLowerCase()) {
        return false;
      }
      if (selectedDiscipline != null &&
          selectedDiscipline!.isNotEmpty &&
          q.discipline.isNotEmpty &&
          q.discipline.toLowerCase() != selectedDiscipline!.toLowerCase()) {
        return false;
      }
      if (selectedLevel != null &&
          selectedLevel!.isNotEmpty &&
          q.level.isNotEmpty &&
          q.level.toLowerCase() != selectedLevel!.toLowerCase()) {
        return false;
      }
      if (selectedTheme != null &&
          selectedTheme!.isNotEmpty &&
          q.theme.isNotEmpty &&
          q.theme.toLowerCase() != selectedTheme!.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    // FIFO: ascending order by recordedAt (longest ago comes first)
    list.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return list;
  }

  List<String> get availableOffices {
    final offices = <String>{};
    for (final e in entries) {
      if (e.question.office.isNotEmpty) offices.add(e.question.office);
    }
    return offices.toList()..sort();
  }

  List<String> get availableDisciplines {
    final disciplines = <String>{};
    for (final e in entries) {
      if (e.question.displayDiscipline.isNotEmpty) {
        disciplines.add(e.question.displayDiscipline);
      }
    }
    return disciplines.toList()..sort();
  }

  List<String> get availableLevels {
    final levels = <String>{};
    for (final e in entries) {
      if (e.question.level.isNotEmpty) levels.add(e.question.level);
    }
    return levels.toList()..sort();
  }

  List<String> get availableThemes {
    final themes = <String>{};
    for (final e in entries) {
      if (e.question.theme.isNotEmpty) themes.add(e.question.theme);
    }
    return themes.toList()..sort();
  }
}

class MistakesReviewNotifier extends Notifier<MistakesReviewState> {
  static const String _storageKey = 'mistakes_review_entries_v1';

  @override
  MistakesReviewState build() {
    Future.microtask(() => loadMistakes());
    return const MistakesReviewState(isLoading: true);
  }

  Future<void> loadMistakes() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final entries = decoded
            .map((item) => MistakeEntry.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        state = state.copyWith(entries: entries, isLoading: false);
        return;
      }
    } catch (e) {
      debugPrint('Error loading mistakes: $e');
    }
    state = state.copyWith(entries: [], isLoading: false);
  }

  /// Records wrong answers from a completed quiz or answer feedback.
  Future<void> recordMistakes(List<Question> wrongQuestions) async {
    if (wrongQuestions.isEmpty) return;

    final updated = List<MistakeEntry>.from(state.entries);
    final now = DateTime.now();

    for (final q in wrongQuestions) {
      // If already in mistakes, keep oldest timestamp
      final idx = updated.indexWhere((e) => e.question.id == q.id);
      if (idx < 0) {
        updated.add(MistakeEntry(question: q, recordedAt: now));
      }
    }

    state = state.copyWith(entries: updated);
    await _saveToStorage(updated);
  }

  /// When answered correctly in review session, it leaves the list.
  Future<void> removeCorrectMistakes(List<String> correctQuestionIds) async {
    if (correctQuestionIds.isEmpty) return;

    final updated = state.entries
        .where((e) => !correctQuestionIds.contains(e.question.id))
        .toList();

    state = state.copyWith(entries: updated);
    await _saveToStorage(updated);
  }

  void setOffice(String? office) {
    state = state.copyWith(selectedOffice: office, clearOffice: office == null);
  }

  void setDiscipline(String? discipline) {
    state = state.copyWith(
      selectedDiscipline: discipline,
      clearDiscipline: discipline == null,
    );
  }

  void setLevel(String? level) {
    state = state.copyWith(selectedLevel: level, clearLevel: level == null);
  }

  void setTheme(String? theme) {
    state = state.copyWith(selectedTheme: theme, clearTheme: theme == null);
  }

  void clearFilters() {
    state = state.copyWith(
      clearOffice: true,
      clearDiscipline: true,
      clearLevel: true,
      clearTheme: true,
    );
  }

  Future<void> _saveToStorage(List<MistakeEntry> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving mistakes: $e');
    }
  }
}

final mistakesReviewProvider =
    NotifierProvider<MistakesReviewNotifier, MistakesReviewState>(
  MistakesReviewNotifier.new,
);
