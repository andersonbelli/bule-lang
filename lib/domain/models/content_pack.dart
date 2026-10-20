enum Difficulty { easy, moderate, native }

Difficulty difficultyFromJson(String value) => switch (value) {
  'easy' => Difficulty.easy,
  'medium' => Difficulty.moderate,
  'hard' => Difficulty.native,
  _ => throw FormatException('Unknown difficulty: $value'),
};

class ContentLanguage {
  const ContentLanguage({
    required this.locale,
    required this.name,
    required this.variant,
  });
  final String locale;
  final String name;
  final String variant;

  factory ContentLanguage.fromJson(Map<String, Object?> json) =>
      ContentLanguage(
        locale: json['locale']! as String,
        name: json['name_en']! as String,
        variant: json['variant']! as String,
      );
}

class LearningItem {
  const LearningItem({
    required this.id,
    required this.locale,
    required this.text,
    required this.kind,
    required this.topic,
    required this.translations,
    required this.acceptedAnswers,
    required this.segments,
  });
  final String id;
  final String locale;
  final String text;
  final String kind;
  final String topic;
  final Map<String, String> translations;
  final List<String> acceptedAnswers;
  final List<LearningSegment> segments;

  factory LearningItem.fromJson(Map<String, Object?> json) => LearningItem(
    id: json['id']! as String,
    locale: json['locale']! as String,
    text: json['text']! as String,
    kind: json['kind']! as String,
    topic: json['topic']! as String,
    translations: (json['translations']! as Map<String, Object?>).map(
      (key, value) => MapEntry(key, value! as String),
    ),
    acceptedAnswers: (json['accepted_answers']! as List<Object?>)
        .cast<String>(),
    segments: (json['segments']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(LearningSegment.fromJson)
        .toList(growable: false),
  );
}

class LearningSegment {
  const LearningSegment({
    required this.text,
    required this.clickable,
    required this.meaningId,
    required this.lexicalItemId,
    required this.translations,
  });

  final String text;
  final bool clickable;
  final String? meaningId;
  final String? lexicalItemId;
  final Map<String, String> translations;

  factory LearningSegment.fromJson(Map<String, Object?> json) =>
      LearningSegment(
        text: json['text']! as String,
        clickable: json['clickable']! as bool,
        meaningId: json['meaning_id'] as String?,
        lexicalItemId: json['lexical_item_id'] as String?,
        translations: (json['translations']! as Map<String, Object?>).map(
          (key, value) => MapEntry(key, value! as String),
        ),
      );
}

class Lesson {
  const Lesson({
    required this.id,
    required this.locale,
    required this.title,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.itemIds,
    required this.exercises,
  });
  final String id;
  final String locale;
  final String title;
  final Difficulty difficulty;
  final int estimatedMinutes;
  final List<String> itemIds;
  final List<Exercise> exercises;

  factory Lesson.fromJson(Map<String, Object?> json) => Lesson(
    id: json['id']! as String,
    locale: json['locale']! as String,
    title: json['title_en']! as String,
    difficulty: difficultyFromJson(json['difficulty']! as String),
    estimatedMinutes: json['estimated_minutes']! as int,
    itemIds: (json['item_ids']! as List<Object?>).cast<String>(),
    exercises: (json['exercise_templates']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(Exercise.fromJson)
        .take(10)
        .toList(growable: false),
  );
}

enum ExerciseKind { flashcard, typing, multipleChoice }

class Exercise {
  const Exercise({required this.kind, required this.itemId});

  final ExerciseKind kind;
  final String itemId;

  factory Exercise.fromJson(Map<String, Object?> json) => Exercise(
    kind: switch (json['type']) {
      'flashcard' => ExerciseKind.flashcard,
      'typing' => ExerciseKind.typing,
      final value => throw FormatException('Unknown exercise type: $value'),
    },
    itemId: json['item_id']! as String,
  );
}

class Situation {
  const Situation({
    required this.id,
    required this.locale,
    required this.title,
    required this.difficulty,
    required this.titleTranslations,
    required this.mode,
    required this.turns,
    required this.vocabularyItemIds,
    required this.publicationStatus,
  });
  final String id;
  final String locale;
  final String title;
  final Difficulty difficulty;
  final Map<String, String> titleTranslations;
  final String mode;
  final List<SituationTurn> turns;
  final List<String> vocabularyItemIds;
  final String publicationStatus;

  int get estimatedMinutes {
    final words = turns.fold<int>(
      0,
      (total, turn) => total + turn.text.trim().split(RegExp(r'\s+')).length,
    );
    final learnerTurns = turns
        .where((turn) => turn.role == SituationRole.learner)
        .length;
    return ((words / 110) + (learnerTurns * 25 / 60)).ceil().clamp(1, 60);
  }

  factory Situation.fromJson(Map<String, Object?> json) => Situation(
    id: json['id']! as String,
    locale: json['locale']! as String,
    title: json['title']! as String,
    difficulty: difficultyFromJson(json['difficulty']! as String),
    titleTranslations: (json['title_translations']! as Map<String, Object?>)
        .map((key, value) => MapEntry(key, value! as String)),
    mode: json['mode']! as String,
    turns: (json['turns']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(SituationTurn.fromJson)
        .toList(growable: false),
    vocabularyItemIds: (json['vocabulary_item_ids']! as List<Object?>)
        .cast<String>(),
    publicationStatus: json['publication_status']! as String,
  );
}

enum SituationRole { computer, learner }

class SituationTurn {
  const SituationTurn({
    required this.id,
    required this.role,
    required this.text,
    required this.translations,
    required this.acceptedAnswers,
  });

  final String id;
  final SituationRole role;
  final String text;
  final Map<String, String> translations;
  final List<String> acceptedAnswers;

  factory SituationTurn.fromJson(Map<String, Object?> json) => SituationTurn(
    id: json['id']! as String,
    role: switch (json['role']) {
      'computer' => SituationRole.computer,
      'learner' => SituationRole.learner,
      final value => throw FormatException('Unknown Situation role: $value'),
    },
    text: json['text']! as String,
    translations: (json['translations']! as Map<String, Object?>).map(
      (key, value) => MapEntry(key, value! as String),
    ),
    acceptedAnswers: (json['accepted_answers']! as List<Object?>)
        .cast<String>(),
  );
}

class ContentPack {
  const ContentPack({
    required this.languages,
    required this.items,
    required this.lessons,
    required this.situations,
  });
  final List<ContentLanguage> languages;
  final Map<String, LearningItem> items;
  final List<Lesson> lessons;
  final List<Situation> situations;

  factory ContentPack.fromJson(Map<String, Object?> json) {
    final items = (json['items']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(LearningItem.fromJson)
        .toList();
    return ContentPack(
      languages: (json['languages']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(ContentLanguage.fromJson)
          .toList(),
      items: {for (final item in items) item.id: item},
      lessons: (json['lessons']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(Lesson.fromJson)
          .toList(),
      situations: (json['situations']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(Situation.fromJson)
          .toList(),
    );
  }
}
