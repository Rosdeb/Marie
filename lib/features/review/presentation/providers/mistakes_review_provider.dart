import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../practice/data/models/quiz_models.dart';
import '../../data/datasources/marked_remote_datasource.dart'
    show ReviewFilterOptions;
import '../../data/datasources/mistakes_remote_datasource.dart';

/// One question waiting to be reviewed.
class MistakeEntry {
  final Question question;

  /// When it was last got wrong. The list is ordered on this, ascending, so
  /// "the questions the user got wrong longest ago come first" is the order
  /// the server sends and the order the review session plays.
  final DateTime recordedAt;

  /// How many times it has been missed in all.
  final int timesWrong;

  /// When the spaced review brings it back.
  final DateTime? nextReviewAt;

  const MistakeEntry({
    required this.question,
    required this.recordedAt,
    this.timesWrong = 0,
    this.nextReviewAt,
  });

  factory MistakeEntry.fromRow(MistakeRow row) {
    return MistakeEntry(
      question: row.question,
      // A mistake from before the server recorded the date sorts first, which
      // is right: it is older than anything that has one.
      recordedAt: row.lastWrongAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      timesWrong: row.timesWrong,
      nextReviewAt: row.nextReviewAt,
    );
  }
}

/// Mistakes to review.
///
/// The list, the order and the filters all come from the server now. They
/// used to be worked out here, over a copy kept in the phone's own storage,
/// which is how the list on one device could disagree with the number printed
/// beside it - and how reinstalling the app wiped a user's mistakes while the
/// server still held them.
///
/// The one definition of "my mistakes" lives on the server: answered wrongly
/// and not answered correctly since. The quiz writes it; nothing else does.
/// In particular a star does not, and this file never touches the starred
/// list - that is what keeps the two counters apart.
class MistakesReviewState {
  final List<MistakeEntry> entries;

  /// Every outstanding mistake, whatever the filters. What the counter shows.
  final int total;

  /// What the chosen filters match - what Start review will play.
  final int matching;

  /// What the four filter menus offer, counted from the user's own mistakes.
  final ReviewFilterOptions filters;

  final String? selectedOffice;
  final String? selectedDiscipline;
  final String? selectedLevel;
  final String? selectedTheme;
  final bool isLoading;
  final String? errorMessage;

  const MistakesReviewState({
    this.entries = const [],
    this.total = 0,
    this.matching = 0,
    this.filters = const ReviewFilterOptions(),
    this.selectedOffice,
    this.selectedDiscipline,
    this.selectedLevel,
    this.selectedTheme,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasFilter =>
      (selectedOffice ?? '').isNotEmpty ||
      (selectedDiscipline ?? '').isNotEmpty ||
      (selectedLevel ?? '').isNotEmpty ||
      (selectedTheme ?? '').isNotEmpty;

  MistakesReviewState copyWith({
    List<MistakeEntry>? entries,
    int? total,
    int? matching,
    ReviewFilterOptions? filters,
    String? selectedOffice,
    String? selectedDiscipline,
    String? selectedLevel,
    String? selectedTheme,
    bool? isLoading,
    String? errorMessage,
    bool clearOffice = false,
    bool clearDiscipline = false,
    bool clearLevel = false,
    bool clearTheme = false,
    bool clearError = false,
  }) {
    return MistakesReviewState(
      entries: entries ?? this.entries,
      total: total ?? this.total,
      matching: matching ?? this.matching,
      filters: filters ?? this.filters,
      selectedOffice: clearOffice
          ? null
          : (selectedOffice ?? this.selectedOffice),
      selectedDiscipline: clearDiscipline
          ? null
          : (selectedDiscipline ?? this.selectedDiscipline),
      selectedLevel: clearLevel ? null : (selectedLevel ?? this.selectedLevel),
      selectedTheme: clearTheme ? null : (selectedTheme ?? this.selectedTheme),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// The rows to show.
  ///
  /// The filtering and the ordering are the server's, so this no longer does
  /// either: the list arrives filtered and oldest-first, and re-sorting it
  /// here could only make the twenty on screen disagree with the twenty the
  /// Start review button plays.
  List<MistakeEntry> get filteredEntries => entries;

  List<String> get availableOffices =>
      filters.offices.map((o) => o.name).toList();

  /// The reader's wording, so a sheet called "UnitaryPatent" is offered as
  /// "Unitary Patent" - and the key is kept for the request.
  List<String> get availableDisciplines =>
      filters.disciplines.map((d) => d.label).toList();

  /// Beginner, Intermediate, Advanced, Expert - the server's order, not
  /// alphabetical, which would read Advanced, Beginner, Expert, Intermediate.
  List<String> get availableLevels =>
      filters.levels.map((l) => l.name).toList();

  /// Appendix B's order, like every other list of themes in the app.
  List<String> get availableThemes =>
      filters.themes.map((t) => t.name).toList();

  /// The stored key behind a discipline the user picked by its label.
  String? disciplineKeyFor(String? label) {
    if (label == null || label.isEmpty) return null;
    for (final d in filters.disciplines) {
      if (d.label == label || d.name == label) return d.name;
    }
    return label;
  }
}

class MistakesReviewNotifier extends Notifier<MistakesReviewState> {
  /// Big enough that the list rarely needs a second page, and the review
  /// session never does - a session is twenty questions.
  static const int _pageSize = 100;

  late MistakesRemoteDataSource _remote;

  @override
  MistakesReviewState build() {
    _remote = ref.watch(mistakesRemoteDataSourceProvider);

    final isAuth = ref.watch(authProvider.select((s) => s.isAuthenticated));
    if (!isAuth) {
      // The mistakes are kept with the account. The Review screen puts up its
      // own sign-in sheet, so this is not an error state.
      return const MistakesReviewState();
    }

    Future.microtask(loadMistakes);
    return const MistakesReviewState(isLoading: true);
  }

  Future<void> loadMistakes() async {
    state = state.copyWith(isLoading: true, clearError: true);

    // The discipline is chosen by its label and sent by its key.
    final subject = state.disciplineKeyFor(state.selectedDiscipline);

    try {
      final page = await _remote.list(
        office: state.selectedOffice,
        subject: subject,
        level: state.selectedLevel,
        theme: state.selectedTheme,
        limit: _pageSize,
      );

      final counts = await _remote.counts(
        office: state.selectedOffice,
        subject: subject,
        level: state.selectedLevel,
        theme: state.selectedTheme,
      );

      final filters = await _remote.filters(
        // The office decides which disciplines and themes exist.
        office: state.selectedOffice,
        subject: subject,
      );

      state = state.copyWith(
        entries: page.rows.map(MistakeEntry.fromRow).toList(),
        // Unfiltered, so choosing a filter does not move the number on the
        // Review screen or on Home.
        total: counts.total,
        matching: counts.matching,
        filters: filters,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Mistakes] load failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load your mistakes.',
      );
    }
  }

  /// Just the numbers, for a screen that shows the count and not the list.
  Future<void> refreshCounts() async {
    try {
      final counts = await _remote.counts();
      state = state.copyWith(total: counts.total, matching: counts.matching);
    } catch (e) {
      debugPrint('[Mistakes] counts failed: $e');
    }
  }

  /// What a review session should be started with.
  ///
  /// The office is whatever the user filtered to, or nothing at all - and
  /// nothing at all means every office. It used to default to IPI, so a user
  /// who had chosen no filter was quietly given IPI's mistakes and only IPI's.
  Map<String, String?> sessionArguments() => {
    'office': state.selectedOffice,
    'subject': state.disciplineKeyFor(state.selectedDiscipline),
    'level': state.selectedLevel,
    'theme': state.selectedTheme,
  };

  // ------------------------------------------------------------------ filters

  void setOffice(String? office) {
    state = state.copyWith(
      selectedOffice: office,
      clearOffice: office == null || office.isEmpty,
      clearDiscipline: true,
      clearTheme: true,
    );
    loadMistakes();
  }

  void setDiscipline(String? discipline) {
    state = state.copyWith(
      selectedDiscipline: discipline,
      clearDiscipline: discipline == null || discipline.isEmpty,
      clearTheme: true,
    );
    loadMistakes();
  }

  void setLevel(String? level) {
    state = state.copyWith(
      selectedLevel: level,
      clearLevel: level == null || level.isEmpty,
    );
    loadMistakes();
  }

  void setTheme(String? theme) {
    state = state.copyWith(
      selectedTheme: theme,
      clearTheme: theme == null || theme.isEmpty,
    );
    loadMistakes();
  }

  void clearFilters() {
    state = state.copyWith(
      clearOffice: true,
      clearDiscipline: true,
      clearLevel: true,
      clearTheme: true,
    );
    loadMistakes();
  }
}

final mistakesReviewProvider =
    NotifierProvider<MistakesReviewNotifier, MistakesReviewState>(
      MistakesReviewNotifier.new,
    );
