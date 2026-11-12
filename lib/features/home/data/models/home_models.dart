/// The Home screen's data, as the server sends it.
///
/// Marie, 11 November 2026, Part 2, Home: eight sections, "always in this
/// order". Each one is a type here, so a section the server could not work out
/// arrives as null and the screen simply leaves it out - a Home missing one
/// section is worth far more than a Home showing an error.
library;

class HomeGreeting {
  final String firstName;

  /// The goal in the person's own words, from the onboarding question.
  final String? learningGoal;

  /// The daily target in minutes, which the ring is measured against.
  final int? dailyGoalMinutes;

  final int minutesToday;
  final int streakDays;

  const HomeGreeting({
    this.firstName = '',
    this.learningGoal,
    this.dailyGoalMinutes,
    this.minutesToday = 0,
    this.streakDays = 0,
  });

  factory HomeGreeting.fromJson(Map<String, dynamic> json) => HomeGreeting(
        firstName: json['firstName'] as String? ?? '',
        learningGoal: json['learningGoal'] as String?,
        dailyGoalMinutes: (json['dailyGoalMinutes'] as num?)?.toInt(),
        minutesToday: (json['minutesToday'] as num?)?.toInt() ?? 0,
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      );

  /// How far through the daily goal, 0..1. Null when no goal is set.
  double? get goalProgress {
    final target = dailyGoalMinutes;
    if (target == null || target <= 0) return null;
    final done = minutesToday / target;
    return done > 1 ? 1 : done;
  }
}

class HomePausedSession {
  final String sessionId;
  final String mode;
  final String? officeLabel;
  final String? subject;
  final String? level;
  final String? theme;
  final int totalQuestions;
  final int answered;

  const HomePausedSession({
    required this.sessionId,
    required this.mode,
    this.officeLabel,
    this.subject,
    this.level,
    this.theme,
    this.totalQuestions = 0,
    this.answered = 0,
  });

  factory HomePausedSession.fromJson(Map<String, dynamic> json) =>
      HomePausedSession(
        sessionId: json['sessionId'] as String? ?? '',
        mode: json['mode'] as String? ?? '',
        officeLabel: json['officeLabel'] as String?,
        subject: json['subject'] as String?,
        level: json['level'] as String?,
        theme: json['theme'] as String?,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        answered: (json['answered'] as num?)?.toInt() ?? 0,
      );

  /// "IPI · Patents · question 7 of 20", the line the mock-up shows.
  String get summary {
    final where = [officeLabel, subject, level]
        .where((p) => p != null && p.isNotEmpty)
        .join(' · ');
    final at = totalQuestions > 0
        ? 'question ${answered + 1 > totalQuestions ? totalQuestions : answered + 1} of $totalQuestions'
        : '';
    return [where, at].where((p) => p.isNotEmpty).join(' · ');
  }
}

class HomeLearningPath {
  final String office;
  final String officeLabel;
  final String subject;
  final int step;
  final int totalSteps;
  final int percentage;

  const HomeLearningPath({
    required this.office,
    required this.officeLabel,
    required this.subject,
    required this.step,
    required this.totalSteps,
    required this.percentage,
  });

  factory HomeLearningPath.fromJson(Map<String, dynamic> json) =>
      HomeLearningPath(
        office: json['office'] as String? ?? '',
        officeLabel: json['officeLabel'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        step: (json['step'] as num?)?.toInt() ?? 0,
        totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      );
}

class HomeQuestionOption {
  /// What the reader sees: the position, always A, B, C, D.
  final String letter;

  /// What is sent back when it is chosen.
  final String key;

  final String text;

  const HomeQuestionOption({
    required this.letter,
    required this.key,
    required this.text,
  });

  factory HomeQuestionOption.fromJson(Map<String, dynamic> json) =>
      HomeQuestionOption(
        letter: json['letter'] as String? ?? '',
        key: json['key'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
}

class HomeQuestionOfTheDay {
  final String questionId;
  final String office;
  final String officeLabel;
  final String subject;
  final String? level;
  final String? theme;
  final String questionText;
  final List<HomeQuestionOption> options;

  const HomeQuestionOfTheDay({
    required this.questionId,
    required this.office,
    required this.officeLabel,
    required this.subject,
    this.level,
    this.theme,
    required this.questionText,
    this.options = const [],
  });

  factory HomeQuestionOfTheDay.fromJson(Map<String, dynamic> json) =>
      HomeQuestionOfTheDay(
        questionId: json['questionId'] as String? ?? '',
        office: json['office'] as String? ?? '',
        officeLabel: json['officeLabel'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        level: json['level'] as String?,
        theme: json['theme'] as String?,
        questionText: json['questionText'] as String? ?? '',
        options: ((json['options'] as List<dynamic>?) ?? [])
            .map((o) => HomeQuestionOption.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}

class HomeMistakes {
  final int dueToday;
  final int total;

  const HomeMistakes({this.dueToday = 0, this.total = 0});

  factory HomeMistakes.fromJson(Map<String, dynamic> json) => HomeMistakes(
        dueToday: (json['dueToday'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

class HomeWeekDay {
  final String day;

  /// "Mon", "Tue"... the label under each bar.
  final String weekday;
  final int questionsAnswered;
  final int minutes;

  const HomeWeekDay({
    required this.day,
    required this.weekday,
    required this.questionsAnswered,
    required this.minutes,
  });

  factory HomeWeekDay.fromJson(Map<String, dynamic> json) => HomeWeekDay(
        day: json['day'] as String? ?? '',
        weekday: json['weekday'] as String? ?? '',
        questionsAnswered: (json['questionsAnswered'] as num?)?.toInt() ?? 0,
        minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      );
}

class HomeWeakestTheme {
  final String officeLabel;
  final String subject;
  final String theme;
  final int questionsSeen;
  final int correctRate;

  const HomeWeakestTheme({
    required this.officeLabel,
    required this.subject,
    required this.theme,
    required this.questionsSeen,
    required this.correctRate,
  });

  factory HomeWeakestTheme.fromJson(Map<String, dynamic> json) =>
      HomeWeakestTheme(
        officeLabel: json['officeLabel'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        theme: json['theme'] as String? ?? '',
        questionsSeen: (json['questionsSeen'] as num?)?.toInt() ?? 0,
        correctRate: (json['correctRate'] as num?)?.toInt() ?? 0,
      );
}

class HomeThisWeek {
  final int questionsAnswered;
  final int correctAnswers;

  /// Null when nothing was answered: "0% correct" would be a judgement on a
  /// week that has not started.
  final int? correctRate;

  final int minutesPractised;
  final List<HomeWeekDay> days;
  final HomeWeakestTheme? weakestTheme;

  const HomeThisWeek({
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.correctRate,
    this.minutesPractised = 0,
    this.days = const [],
    this.weakestTheme,
  });

  factory HomeThisWeek.fromJson(Map<String, dynamic> json) => HomeThisWeek(
        questionsAnswered: (json['questionsAnswered'] as num?)?.toInt() ?? 0,
        correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
        correctRate: (json['correctRate'] as num?)?.toInt(),
        minutesPractised: (json['minutesPractised'] as num?)?.toInt() ?? 0,
        days: ((json['days'] as List<dynamic>?) ?? [])
            .map((d) => HomeWeekDay.fromJson(d as Map<String, dynamic>))
            .toList(),
        weakestTheme: json['weakestTheme'] is Map<String, dynamic>
            ? HomeWeakestTheme.fromJson(
                json['weakestTheme'] as Map<String, dynamic>)
            : null,
      );

  bool get hasAnything => questionsAnswered > 0 || minutesPractised > 0;
}

class HomeOffice {
  final String code;
  final String label;
  final int questionsAnswered;
  final int questionsTotal;
  final int percentage;

  /// False when nothing has been imported for this office yet. The card says
  /// so instead of showing a 0% bar, which would read as the reader's own
  /// failure rather than as missing content.
  final bool hasContent;

  const HomeOffice({
    required this.code,
    required this.label,
    required this.questionsAnswered,
    required this.questionsTotal,
    required this.percentage,
    required this.hasContent,
  });

  factory HomeOffice.fromJson(Map<String, dynamic> json) => HomeOffice(
        code: json['code'] as String? ?? '',
        label: json['label'] as String? ?? '',
        questionsAnswered: (json['questionsAnswered'] as num?)?.toInt() ?? 0,
        questionsTotal: (json['questionsTotal'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toInt() ?? 0,
        hasContent: json['hasContent'] as bool? ?? false,
      );
}

class HomeBadge {
  final String id;
  final String tier;
  final String officeLabel;
  final String subject;
  final String? level;
  final int percentage;

  /// "IPI · Patents · Beginner", the line the mock-up puts under the badge.
  final String title;

  const HomeBadge({
    required this.id,
    required this.tier,
    required this.officeLabel,
    required this.subject,
    this.level,
    required this.percentage,
    required this.title,
  });

  factory HomeBadge.fromJson(Map<String, dynamic> json) => HomeBadge(
        id: json['id'] as String? ?? '',
        tier: json['tier'] as String? ?? '',
        officeLabel: json['officeLabel'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        level: json['level'] as String?,
        percentage: (json['percentage'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
      );
}

class HomeBadges {
  final int total;
  final HomeBadge? latest;

  /// What the next badge needs, in one sentence.
  final String? nextText;

  const HomeBadges({this.total = 0, this.latest, this.nextText});

  factory HomeBadges.fromJson(Map<String, dynamic> json) => HomeBadges(
        total: (json['total'] as num?)?.toInt() ?? 0,
        latest: json['latest'] is Map<String, dynamic>
            ? HomeBadge.fromJson(json['latest'] as Map<String, dynamic>)
            : null,
        nextText: json['next'] is Map<String, dynamic>
            ? (json['next'] as Map<String, dynamic>)['text'] as String?
            : null,
      );
}

class HomeData {
  final HomeGreeting greeting;
  final HomePausedSession? pausedSession;
  final HomeLearningPath? learningPath;
  final HomeQuestionOfTheDay? questionOfTheDay;
  final HomeMistakes mistakes;
  final HomeThisWeek thisWeek;
  final List<HomeOffice> offices;
  final HomeBadges badges;

  const HomeData({
    this.greeting = const HomeGreeting(),
    this.pausedSession,
    this.learningPath,
    this.questionOfTheDay,
    this.mistakes = const HomeMistakes(),
    this.thisWeek = const HomeThisWeek(),
    this.offices = const [],
    this.badges = const HomeBadges(),
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? sub(String key) =>
        json[key] is Map<String, dynamic> ? json[key] as Map<String, dynamic> : null;

    final cont = sub('continueSection') ?? const {};
    final today = sub('today') ?? const {};

    return HomeData(
      greeting: HomeGreeting.fromJson(sub('greeting') ?? const {}),
      pausedSession: cont['pausedSession'] is Map<String, dynamic>
          ? HomePausedSession.fromJson(
              cont['pausedSession'] as Map<String, dynamic>)
          : null,
      learningPath: cont['learningPath'] is Map<String, dynamic>
          ? HomeLearningPath.fromJson(
              cont['learningPath'] as Map<String, dynamic>)
          : null,
      questionOfTheDay: today['questionOfTheDay'] is Map<String, dynamic>
          ? HomeQuestionOfTheDay.fromJson(
              today['questionOfTheDay'] as Map<String, dynamic>)
          : null,
      mistakes: today['mistakes'] is Map<String, dynamic>
          ? HomeMistakes.fromJson(today['mistakes'] as Map<String, dynamic>)
          : const HomeMistakes(),
      thisWeek: HomeThisWeek.fromJson(sub('thisWeek') ?? const {}),
      offices: ((json['myOffices'] as List<dynamic>?) ?? [])
          .map((o) => HomeOffice.fromJson(o as Map<String, dynamic>))
          .toList(),
      badges: HomeBadges.fromJson(sub('badges') ?? const {}),
    );
  }
}
