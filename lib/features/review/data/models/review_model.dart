class PracticeSessionTiming {
  final int answeredSeconds;
  final int wallClockSeconds;
  final int questionsTimed;
  final String source;

  const PracticeSessionTiming({
    this.answeredSeconds = 0,
    this.wallClockSeconds = 0,
    this.questionsTimed = 0,
    this.source = '',
  });

  factory PracticeSessionTiming.fromJson(Map<String, dynamic> json) {
    return PracticeSessionTiming(
      answeredSeconds: (json['answeredSeconds'] as num?)?.toInt() ?? 0,
      wallClockSeconds: (json['wallClockSeconds'] as num?)?.toInt() ?? 0,
      questionsTimed: (json['questionsTimed'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'answeredSeconds': answeredSeconds,
    'wallClockSeconds': wallClockSeconds,
    'questionsTimed': questionsTimed,
    'source': source,
  };
}

class PracticeHistoryTimeSummary {
  final String spent;
  final int spentSeconds;
  final int allowedSeconds;
  final double usagePercentage;
  final double averageSecondsPerQuestion;

  const PracticeHistoryTimeSummary({
    this.spent = '',
    this.spentSeconds = 0,
    this.allowedSeconds = 0,
    this.usagePercentage = 0.0,
    this.averageSecondsPerQuestion = 0.0,
  });

  factory PracticeHistoryTimeSummary.fromJson(Map<String, dynamic> json) {
    return PracticeHistoryTimeSummary(
      spent: json['spent'] as String? ?? '',
      spentSeconds: (json['spentSeconds'] as num?)?.toInt() ?? 0,
      allowedSeconds: (json['allowedSeconds'] as num?)?.toInt() ?? 0,
      usagePercentage: (json['usagePercentage'] as num?)?.toDouble() ?? 0.0,
      averageSecondsPerQuestion:
          (json['averageSecondsPerQuestion'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'spent': spent,
    'spentSeconds': spentSeconds,
    'allowedSeconds': allowedSeconds,
    'usagePercentage': usagePercentage,
    'averageSecondsPerQuestion': averageSecondsPerQuestion,
  };
}

class PracticeHistorySummary {
  final int sessionsSubmitted;
  final int questionsAnswered;
  final int correctAnswers;
  final int wrongAnswers;
  final double successPercentage;
  final double failPercentage;
  final double averageScorePercentage;
  final PracticeHistoryTimeSummary? time;

  const PracticeHistorySummary({
    this.sessionsSubmitted = 0,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.successPercentage = 0.0,
    this.failPercentage = 0.0,
    this.averageScorePercentage = 0.0,
    this.time,
  });

  factory PracticeHistorySummary.fromJson(Map<String, dynamic> json) {
    return PracticeHistorySummary(
      sessionsSubmitted: (json['sessionsSubmitted'] as num?)?.toInt() ?? 0,
      questionsAnswered: (json['questionsAnswered'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (json['wrongAnswers'] as num?)?.toInt() ?? 0,
      successPercentage:
          (json['successPercentage'] as num?)?.toDouble() ?? 0.0,
      failPercentage: (json['failPercentage'] as num?)?.toDouble() ?? 0.0,
      averageScorePercentage:
          (json['averageScorePercentage'] as num?)?.toDouble() ?? 0.0,
      time: json['time'] is Map<String, dynamic>
          ? PracticeHistoryTimeSummary.fromJson(
              json['time'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionsSubmitted': sessionsSubmitted,
    'questionsAnswered': questionsAnswered,
    'correctAnswers': correctAnswers,
    'wrongAnswers': wrongAnswers,
    'successPercentage': successPercentage,
    'failPercentage': failPercentage,
    'averageScorePercentage': averageScorePercentage,
    if (time != null) 'time': time!.toJson(),
  };
}

class PracticeHistoryMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final PracticeHistorySummary? summary;

  const PracticeHistoryMeta({
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPages = 1,
    this.summary,
  });

  factory PracticeHistoryMeta.fromJson(Map<String, dynamic> json) {
    return PracticeHistoryMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      summary: json['summary'] is Map<String, dynamic>
          ? PracticeHistorySummary.fromJson(
              json['summary'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'page': page,
    'limit': limit,
    'total': total,
    'totalPages': totalPages,
    if (summary != null) 'summary': summary!.toJson(),
  };
}

class PracticeHistoryResult {
  final bool success;
  final int statusCode;
  final String message;
  final PracticeHistoryMeta? meta;
  final List<ReviewSession> sessions;

  const PracticeHistoryResult({
    this.success = true,
    this.statusCode = 200,
    this.message = '',
    this.meta,
    this.sessions = const [],
  });

  factory PracticeHistoryResult.fromJson(Map<String, dynamic> json) {
    final metaObj = json['meta'] is Map<String, dynamic>
        ? PracticeHistoryMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : null;

    final rawData = json['data'];
    final List<ReviewSession> parsedSessions = [];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          parsedSessions.add(ReviewSession.fromJson(item));
        }
      }
    }

    return PracticeHistoryResult(
      success: json['success'] as bool? ?? true,
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 200,
      message: json['message'] as String? ?? '',
      meta: metaObj,
      sessions: parsedSessions,
    );
  }
}

class ReviewSession {
  final String id;
  final String sessionId;
  final String title;
  final String topic;
  final String jurisdiction;
  final String office;
  final String discipline;
  final String mode;
  final String level;
  final int score;
  final int totalQuestions;
  final int correctCount;
  final int incorrectCount;
  final int flaggedCount;
  final double percentage;
  final String formatted;
  final String completedAt;
  final String completedDate;
  final bool isFlagged;
  final String timeTaken;
  final int timeTakenSeconds;
  final int timeLimitMinutes;
  final bool withinTimeLimit;
  final String averageTimePerQuestion;
  final double averageSecondsPerQuestion;
  final int averageMsPerQuestion;
  final PracticeSessionTiming? timing;

  const ReviewSession({
    required this.id,
    this.sessionId = '',
    required this.title,
    required this.topic,
    required this.jurisdiction,
    this.office = '',
    this.discipline = '',
    this.mode = '',
    required this.level,
    this.score = 0,
    required this.totalQuestions,
    required this.correctCount,
    this.incorrectCount = 0,
    required this.flaggedCount,
    this.percentage = 0.0,
    this.formatted = '',
    this.completedAt = '',
    required this.completedDate,
    this.isFlagged = false,
    this.timeTaken = '',
    this.timeTakenSeconds = 0,
    this.timeLimitMinutes = 0,
    this.withinTimeLimit = true,
    this.averageTimePerQuestion = '',
    this.averageSecondsPerQuestion = 0.0,
    this.averageMsPerQuestion = 0,
    this.timing,
  });

  factory ReviewSession.fromJson(Map<String, dynamic> json) {
    final sId = json['sessionId'] as String? ?? json['id'] as String? ?? '';
    final office = json['office'] as String? ?? 'IPI';
    final discipline = json['discipline'] as String? ?? '';
    final mode = json['mode'] as String? ?? 'practice';
    final level = json['level'] as String? ?? '';
    final score = (json['score'] as num?)?.toInt() ?? 0;
    final total = (json['totalQuestions'] as num?)?.toInt() ?? 20;
    final percentage = (json['percentage'] as num?)?.toDouble() ??
        (total > 0 ? (score / total) * 100 : 0.0);
    final formatted = json['formatted'] as String? ?? '$score / $total';
    final completedAtRaw = json['completedAt'] as String? ?? '';
    final time = json['timeTaken'] as String? ?? '';
    final timeTakenSeconds = (json['timeTakenSeconds'] as num?)?.toInt() ?? 0;
    final timeLimitMinutes = (json['timeLimitMinutes'] as num?)?.toInt() ?? 0;
    final withinTimeLimit = json['withinTimeLimit'] as bool? ?? true;
    final avgTimePerQ = json['averageTimePerQuestion'] as String? ?? '';
    final avgSecPerQ =
        (json['averageSecondsPerQuestion'] as num?)?.toDouble() ?? 0.0;
    final avgMsPerQ = (json['averageMsPerQuestion'] as num?)?.toInt() ?? 0;

    final timingObj = json['timing'] is Map<String, dynamic>
        ? PracticeSessionTiming.fromJson(
            json['timing'] as Map<String, dynamic>)
        : null;

    final incorrect = (json['incorrectCount'] as num?)?.toInt() ??
        ((total - score) > 0 ? (total - score) : 0);
    final flagged = (json['flaggedCount'] as num?)?.toInt() ??
        ((total - score) > 0 ? (total - score) : 0);

    String formattedDate = 'Recently';
    if (completedAtRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(completedAtRaw).toLocal();
        formattedDate =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = completedAtRaw;
      }
    }

    final modeLabel = mode == 'by_level'
        ? (level.isNotEmpty ? '$level Level' : 'Level Practice')
        : (mode == 'demo'
            ? 'Demo Session'
            : (mode == 'review_mistakes'
                ? 'Mistakes Review'
                : (mode == 'by_theme' ? 'Theme Practice' : 'Official Exam')));

    final title = discipline.isNotEmpty
        ? '$discipline - $modeLabel'
        : '$office $modeLabel';

    return ReviewSession(
      id: sId,
      sessionId: sId,
      title: title,
      topic: discipline.isNotEmpty ? discipline : office,
      jurisdiction: office,
      office: office,
      discipline: discipline,
      mode: mode,
      level: level.isNotEmpty ? level : mode.toUpperCase(),
      score: score,
      totalQuestions: total,
      correctCount: score,
      incorrectCount: incorrect,
      flaggedCount: flagged,
      percentage: percentage,
      formatted: formatted,
      completedAt: completedAtRaw,
      completedDate: formattedDate,
      timeTaken: time,
      timeTakenSeconds: timeTakenSeconds,
      timeLimitMinutes: timeLimitMinutes,
      withinTimeLimit: withinTimeLimit,
      averageTimePerQuestion: avgTimePerQ,
      averageSecondsPerQuestion: avgSecPerQ,
      averageMsPerQuestion: avgMsPerQ,
      timing: timingObj,
      isFlagged: flagged > 0 || (total - score) > 0,
    );
  }

  double get accuracy => percentage > 0
      ? percentage
      : (totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0);
}

class MistakesSummary {
  final int total;
  final List<OfficeMistakes> byOffice;

  const MistakesSummary({
    this.total = 0,
    this.byOffice = const [],
  });

  factory MistakesSummary.fromJson(Map<String, dynamic> json) {
    final rawByOffice = json['byOffice'] as List<dynamic>? ?? [];
    return MistakesSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      byOffice: rawByOffice
          .map((o) => OfficeMistakes.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OfficeMistakes {
  final String office;
  final int mistakes;

  const OfficeMistakes({
    required this.office,
    required this.mistakes,
  });

  factory OfficeMistakes.fromJson(Map<String, dynamic> json) {
    return OfficeMistakes(
      office: json['office'] as String? ?? '',
      mistakes: (json['mistakes'] as num?)?.toInt() ?? 0,
    );
  }
}
