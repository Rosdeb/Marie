import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../practice/data/models/quiz_models.dart';

class MarkedQuestionsState {
  final List<Question> items;
  final bool isLoading;

  const MarkedQuestionsState({
    this.items = const [],
    this.isLoading = false,
  });

  MarkedQuestionsState copyWith({
    List<Question>? items,
    bool? isLoading,
  }) {
    return MarkedQuestionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MarkedQuestionsNotifier extends Notifier<MarkedQuestionsState> {
  static const String _storageKey = 'marked_questions_storage_v1';

  @override
  MarkedQuestionsState build() {
    Future.microtask(() => loadMarkedQuestions());
    return const MarkedQuestionsState(isLoading: true);
  }

  Future<void> loadMarkedQuestions() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final questions = decoded
            .map((item) => Question.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        state = state.copyWith(items: questions, isLoading: false);
        return;
      }
    } catch (e) {
      debugPrint('Error loading marked questions: $e');
    }
    state = state.copyWith(items: [], isLoading: false);
  }

  bool isMarked(String questionId) {
    if (questionId.isEmpty) return false;
    return state.items.any((q) => q.id == questionId);
  }

  Future<void> toggleMark(Question question) async {
    if (question.id.isEmpty) return;

    final existingIndex = state.items.indexWhere((q) => q.id == question.id);
    List<Question> updatedList;
    if (existingIndex >= 0) {
      updatedList = List<Question>.from(state.items)..removeAt(existingIndex);
    } else {
      updatedList = [question, ...state.items];
    }

    state = state.copyWith(items: updatedList);
    await _saveToStorage(updatedList);
  }

  Future<void> unmark(String questionId) async {
    if (questionId.isEmpty) return;
    final updatedList = state.items.where((q) => q.id != questionId).toList();
    state = state.copyWith(items: updatedList);
    await _saveToStorage(updatedList);
  }

  Future<void> _saveToStorage(List<Question> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((q) => q.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving marked questions: $e');
    }
  }
}

final markedQuestionsProvider =
    NotifierProvider<MarkedQuestionsNotifier, MarkedQuestionsState>(
  MarkedQuestionsNotifier.new,
);
