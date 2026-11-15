import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../practice/data/models/quiz_models.dart';
import '../../data/datasources/marked_remote_datasource.dart';

/// Marked questions: the ones the user starred by hand.
///
/// This used to be a list in the phone's own storage and nothing else. The
/// server had no idea a star existed, so the Review screen had one number to
/// fill two lines with - the mistakes total - and both read 151 when Marie
/// had starred nothing like 151 questions (build 11).
///
/// It is now the server's list. The star therefore survives a reinstall,
/// follows the account to a second device, and is counted in exactly one
/// place. The stars a phone was already keeping are handed over once, on the
/// first load after signing in, rather than thrown away.
///
/// Nothing in the quiz calls into this file, and nothing in this file knows
/// about mistakes. That separation is the fix, so it is kept visible: the two
/// lists cannot share a number if they do not share a line of code.
class MarkedQuestionsState {
  final List<Question> items;
  final bool isLoading;

  /// Every starred question, not just the page loaded. What the counter shows.
  final int total;

  /// What the four filter menus offer, counted from the user's own stars.
  final ReviewFilterOptions filters;

  final String? selectedOffice;
  final String? selectedDiscipline;
  final String? selectedLevel;
  final String? selectedTheme;

  final String? errorMessage;

  const MarkedQuestionsState({
    this.items = const [],
    this.isLoading = false,
    this.total = 0,
    this.filters = const ReviewFilterOptions(),
    this.selectedOffice,
    this.selectedDiscipline,
    this.selectedLevel,
    this.selectedTheme,
    this.errorMessage,
  });

  bool get hasFilter =>
      (selectedOffice ?? '').isNotEmpty ||
      (selectedDiscipline ?? '').isNotEmpty ||
      (selectedLevel ?? '').isNotEmpty ||
      (selectedTheme ?? '').isNotEmpty;

  MarkedQuestionsState copyWith({
    List<Question>? items,
    bool? isLoading,
    int? total,
    ReviewFilterOptions? filters,
    String? selectedOffice,
    String? selectedDiscipline,
    String? selectedLevel,
    String? selectedTheme,
    String? errorMessage,
    bool clearOffice = false,
    bool clearDiscipline = false,
    bool clearLevel = false,
    bool clearTheme = false,
    bool clearError = false,
  }) {
    return MarkedQuestionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      total: total ?? this.total,
      filters: filters ?? this.filters,
      selectedOffice: clearOffice
          ? null
          : (selectedOffice ?? this.selectedOffice),
      selectedDiscipline: clearDiscipline
          ? null
          : (selectedDiscipline ?? this.selectedDiscipline),
      selectedLevel: clearLevel ? null : (selectedLevel ?? this.selectedLevel),
      selectedTheme: clearTheme ? null : (selectedTheme ?? this.selectedTheme),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MarkedQuestionsNotifier extends Notifier<MarkedQuestionsState> {
  /// The key the stars used to live under, kept only so they can be adopted.
  static const String _storageKey = 'marked_questions_storage_v1';

  /// Set once the hand-over has happened, so it happens once per device.
  static const String _importedKey = 'marked_questions_imported_to_server_v1';

  /// A page big enough that the list rarely needs a second one, and the quiz
  /// never does - a session is twenty questions.
  static const int _pageSize = 100;

  late MarkedRemoteDataSource _remote;

  @override
  MarkedQuestionsState build() {
    _remote = ref.watch(markedRemoteDataSourceProvider);

    final isAuth = ref.watch(authProvider.select((s) => s.isAuthenticated));
    if (!isAuth) {
      // No account, no stars to show. The Review screen puts up its own sign-in
      // sheet, so this is not an error state.
      return const MarkedQuestionsState();
    }

    Future.microtask(() async {
      await _adoptLocalStars();
      await loadMarkedQuestions();
    });

    return const MarkedQuestionsState(isLoading: true);
  }

  // ------------------------------------------------------------- the hand-over

  /// Give the server the stars this phone was keeping on its own.
  ///
  /// Once per device. The local list is read, sent, and only then forgotten:
  /// if the call fails the key is left alone and the next load tries again,
  /// because losing somebody's starred questions quietly is worse than
  /// sending them twice. Sending them twice is harmless - the server keeps one
  /// star per question and leaves its original date alone.
  Future<void> _adoptLocalStars() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_importedKey) == true) return;

      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        await prefs.setBool(_importedKey, true);
        return;
      }

      final decoded = jsonDecode(raw) as List<dynamic>;
      final ids = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map((item) => (item['id'] ?? item['questionId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      if (ids.isEmpty) {
        await prefs.setBool(_importedKey, true);
        return;
      }

      await _remote.importLocal(ids);

      await prefs.setBool(_importedKey, true);
      // Only now, with the server holding them, is the local copy removed.
      await prefs.remove(_storageKey);

      debugPrint('[Marked] handed ${ids.length} local stars to the server');
    } catch (e) {
      // Left for the next load. Nothing is deleted on this path.
      debugPrint('[Marked] could not hand over the local stars: $e');
    }
  }

  // ------------------------------------------------------------------ reading

  Future<void> loadMarkedQuestions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _remote.list(
        office: state.selectedOffice,
        subject: state.selectedDiscipline,
        level: state.selectedLevel,
        theme: state.selectedTheme,
        limit: _pageSize,
      );

      // The unfiltered total, so choosing a filter does not change the number
      // on the Review screen - only what the list below it shows.
      final total = state.hasFilter ? await _remote.count() : page.total;

      final filters = await _remote.filters(
        // The office narrows the other three: IPI's disciplines, IPI's
        // themes. Asked with no office, every menu is the whole list.
        office: state.selectedOffice,
        subject: state.selectedDiscipline,
      );

      state = state.copyWith(
        items: page.rows.map((r) => r.question).toList(),
        total: total,
        filters: filters,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Marked] load failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load your marked questions.',
      );
    }
  }

  /// Just the number, for a screen that shows the count and not the list.
  Future<void> refreshCount() async {
    try {
      state = state.copyWith(total: await _remote.count());
    } catch (e) {
      debugPrint('[Marked] count failed: $e');
    }
  }

  bool isMarked(String questionId) {
    if (questionId.isEmpty) return false;
    return state.items.any((q) => q.id == questionId);
  }

  /// Light the stars for a set of questions the app is about to show.
  ///
  /// One call for a whole session: a quiz of twenty asks once, not twenty
  /// times. Used by the quiz and the answer-review screens, where the list
  /// itself has not been loaded.
  Future<void> syncStatusFor(List<Question> questions) async {
    final unknown = questions.where((q) => q.id.isNotEmpty).toList();
    if (unknown.isEmpty) return;

    try {
      final marked = await _remote.statusOf(unknown.map((q) => q.id).toList());
      if (marked.isEmpty) return;

      final known = {for (final q in state.items) q.id: q};
      for (final q in unknown) {
        if (marked.contains(q.id)) known[q.id] = q;
      }

      state = state.copyWith(items: known.values.toList());
    } catch (e) {
      debugPrint('[Marked] status check failed: $e');
    }
  }

  // ----------------------------------------------------------------- starring

  /// The star, as the one button on the question and explanation screens.
  ///
  /// The icon flips at once and the server is told afterwards, because a star
  /// that waits for the network feels broken. If the call fails the flip is
  /// undone, so the screen never keeps a star the server does not have.
  Future<void> toggleMark(Question question) async {
    if (question.id.isEmpty) return;

    final wasMarked = isMarked(question.id);
    final before = state;

    state = state.copyWith(
      items: wasMarked
          ? state.items.where((q) => q.id != question.id).toList()
          : [question, ...state.items],
      total: wasMarked ? (state.total - 1).clamp(0, 1 << 30) : state.total + 1,
      clearError: true,
    );

    try {
      final result = wasMarked
          ? await _remote.unmark(question.id)
          : await _remote.mark(question.id);

      // The server's own total, which is the one that counts.
      if (result.total >= 0) {
        state = state.copyWith(total: result.total);
      }
    } catch (e) {
      debugPrint('[Marked] toggle failed: $e');
      state = before.copyWith(
        errorMessage: wasMarked
            ? 'Could not remove the mark. Please try again.'
            : 'Could not mark the question. Please try again.',
      );
    }
  }

  /// Take the star off, from the list or from the question screen.
  ///
  /// Answering the question - rightly or wrongly - never calls this. A marked
  /// question stays marked until the user takes the star off.
  Future<void> unmark(String questionId) async {
    if (questionId.isEmpty) return;

    final before = state;
    state = state.copyWith(
      items: state.items.where((q) => q.id != questionId).toList(),
      total: (state.total - 1).clamp(0, 1 << 30),
      clearError: true,
    );

    try {
      final result = await _remote.unmark(questionId);
      if (result.total >= 0) {
        state = state.copyWith(total: result.total);
      }
    } catch (e) {
      debugPrint('[Marked] unmark failed: $e');
      state = before.copyWith(
        errorMessage: 'Could not remove the mark. Please try again.',
      );
    }
  }

  // ------------------------------------------------------------------ filters

  void setOffice(String? office) {
    state = state.copyWith(
      selectedOffice: office,
      clearOffice: office == null || office.isEmpty,
      // The office decides which disciplines and themes exist, so a change of
      // office drops the three below it rather than leaving an impossible
      // combination on screen.
      clearDiscipline: true,
      clearTheme: true,
    );
    loadMarkedQuestions();
  }

  void setDiscipline(String? discipline) {
    state = state.copyWith(
      selectedDiscipline: discipline,
      clearDiscipline: discipline == null || discipline.isEmpty,
      clearTheme: true,
    );
    loadMarkedQuestions();
  }

  void setLevel(String? level) {
    state = state.copyWith(
      selectedLevel: level,
      clearLevel: level == null || level.isEmpty,
    );
    loadMarkedQuestions();
  }

  void setTheme(String? theme) {
    state = state.copyWith(
      selectedTheme: theme,
      clearTheme: theme == null || theme.isEmpty,
    );
    loadMarkedQuestions();
  }

  void clearFilters() {
    state = state.copyWith(
      clearOffice: true,
      clearDiscipline: true,
      clearLevel: true,
      clearTheme: true,
    );
    loadMarkedQuestions();
  }
}

final markedQuestionsProvider =
    NotifierProvider<MarkedQuestionsNotifier, MarkedQuestionsState>(
      MarkedQuestionsNotifier.new,
    );
