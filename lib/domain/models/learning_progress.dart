const maxPersonalNoteLength = 300;

class ItemProgress {
  const ItemProgress({
    required this.itemId,
    required this.attempts,
    required this.correctAttempts,
    required this.streak,
    required this.dueAt,
    required this.learned,
  });

  ItemProgress.encountered(this.itemId)
    : attempts = 0,
      correctAttempts = 0,
      streak = 0,
      dueAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      learned = false;

  final String itemId;
  final int attempts;
  final int correctAttempts;
  final int streak;
  final DateTime dueAt;
  final bool learned;

  factory ItemProgress.fromJson(Map<String, Object?> json) => ItemProgress(
    itemId: json['item_id']! as String,
    attempts: json['attempts']! as int,
    correctAttempts: json['correct_attempts']! as int,
    streak: json['streak']! as int,
    dueAt: DateTime.parse(json['due_at']! as String),
    learned: json['learned']! as bool,
  );

  Map<String, Object?> toJson() => {
    'item_id': itemId,
    'attempts': attempts,
    'correct_attempts': correctAttempts,
    'streak': streak,
    'due_at': dueAt.toUtc().toIso8601String(),
    'learned': learned,
  };
}

class LearningProgress {
  const LearningProgress({
    required this.items,
    required this.notes,
    required this.lessonCompletions,
    this.currentDayStreak = 0,
    this.bestDayStreak = 0,
    this.lastPracticeDate,
  });
  const LearningProgress.empty()
    : items = const {},
      notes = const {},
      lessonCompletions = const {},
      currentDayStreak = 0,
      bestDayStreak = 0,
      lastPracticeDate = null;

  final Map<String, ItemProgress> items;
  final Map<String, String> notes;
  final Map<String, int> lessonCompletions;
  final int currentDayStreak;
  final int bestDayStreak;
  final String? lastPracticeDate;

  factory LearningProgress.fromJson(Map<String, Object?> json) {
    final itemJson = (json['items'] as Map<String, Object?>?) ?? const {};
    final noteJson = (json['notes'] as Map<String, Object?>?) ?? const {};
    final completionJson =
        (json['lesson_completions'] as Map<String, Object?>?) ?? const {};
    return LearningProgress(
      items: itemJson.map(
        (key, value) => MapEntry(
          key,
          ItemProgress.fromJson(value! as Map<String, Object?>),
        ),
      ),
      notes: noteJson.map((key, value) => MapEntry(key, value! as String)),
      lessonCompletions: completionJson.map(
        (key, value) => MapEntry(key, value! as int),
      ),
      currentDayStreak: json['current_day_streak'] as int? ?? 0,
      bestDayStreak: json['best_day_streak'] as int? ?? 0,
      lastPracticeDate: json['last_practice_date'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'items': items.map((key, value) => MapEntry(key, value.toJson())),
    'notes': notes,
    'lesson_completions': lessonCompletions,
    'current_day_streak': currentDayStreak,
    'best_day_streak': bestDayStreak,
    'last_practice_date': lastPracticeDate,
  };
}
