import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

/// The person's own preferences: the daily goal and the two reminders.
///
/// Marie's mock-up of 2 November, Settings: "notifications (daily reminder,
/// question of the day)"; and her Part 2 Account section puts the daily
/// reminder under Preferences, where it can be reached in one tap.
///
/// Both reminders start off. A notification nobody asked for is the one thing
/// a paid app cannot afford to get wrong.
class Preferences {
  final String? learningGoal;
  final int? dailyGoalMinutes;
  final bool dailyReminder;
  final bool questionOfTheDay;

  const Preferences({
    this.learningGoal,
    this.dailyGoalMinutes,
    this.dailyReminder = false,
    this.questionOfTheDay = false,
  });

  factory Preferences.fromJson(Map<String, dynamic> json) => Preferences(
        learningGoal: json['learningGoal'] as String?,
        dailyGoalMinutes: (json['dailyGoalMinutes'] as num?)?.toInt(),
        dailyReminder: json['dailyReminder'] as bool? ?? false,
        questionOfTheDay: json['questionOfTheDay'] as bool? ?? false,
      );

  Preferences copyWith({
    String? learningGoal,
    int? dailyGoalMinutes,
    bool? dailyReminder,
    bool? questionOfTheDay,
  }) =>
      Preferences(
        learningGoal: learningGoal ?? this.learningGoal,
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        dailyReminder: dailyReminder ?? this.dailyReminder,
        questionOfTheDay: questionOfTheDay ?? this.questionOfTheDay,
      );
}

class PreferencesNotifier extends Notifier<Preferences> {
  late final ApiClient _apiClient;

  @override
  Preferences build() {
    _apiClient = ref.watch(apiClientProvider);
    Future.microtask(load);
    return const Preferences();
  }

  Future<void> load() async {
    try {
      final response = await _apiClient.get(ApiConstants.preferences);
      final data = response is Map<String, dynamic> ? response['data'] : null;
      if (data is Map<String, dynamic>) state = Preferences.fromJson(data);
    } catch (e) {
      // The switches keep whatever they were showing. A preference screen
      // that cannot read the server is better left looking unchanged than
      // silently flipped to off.
      debugPrint('[Preferences] load failed: $e');
    }
  }

  /// Saves one change, showing it at once and putting it back if it fails.
  ///
  /// A switch that waits for the network before moving feels broken; one that
  /// moves and stays moved after a failed save is a lie. So it moves, and
  /// returns on its own if the server refused.
  Future<bool> save({
    String? learningGoal,
    int? dailyGoalMinutes,
    bool? dailyReminder,
    bool? questionOfTheDay,
  }) async {
    final before = state;
    state = state.copyWith(
      learningGoal: learningGoal,
      dailyGoalMinutes: dailyGoalMinutes,
      dailyReminder: dailyReminder,
      questionOfTheDay: questionOfTheDay,
    );

    try {
      final response = await _apiClient.patch(
        ApiConstants.preferences,
        // Only what changed is sent, so one switch cannot overwrite
        // another preference with a stale value.
        body: {
          'learningGoal': ?learningGoal,
          'dailyGoalMinutes': ?dailyGoalMinutes,
          'dailyReminder': ?dailyReminder,
          'questionOfTheDay': ?questionOfTheDay,
        },
      );
      final data = response is Map<String, dynamic> ? response['data'] : null;
      if (data is Map<String, dynamic>) state = Preferences.fromJson(data);
      return true;
    } catch (e) {
      debugPrint('[Preferences] save failed: $e');
      state = before;
      return false;
    }
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, Preferences>(PreferencesNotifier.new);
