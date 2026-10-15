import 'package:flutter/foundation.dart';

import '../data/repositories/local_app_repository.dart';
import '../domain/models/content_pack.dart';
import '../domain/models/learning_progress.dart';
import '../domain/models/user_preferences.dart';
import '../ui/features/learning/lesson_view_model.dart';

enum AppLoadState { loading, ready, failure }

class AppViewModel extends ChangeNotifier {
  AppViewModel(this._repository);
  final LocalAppRepository _repository;

  AppLoadState loadState = AppLoadState.loading;
  ContentPack? content;
  UserPreferences preferences = const UserPreferences.empty();
  Object? error;

  Future<void> initialize() async {
    loadState = AppLoadState.loading;
    notifyListeners();
    try {
      final values = await Future.wait([
        _repository.loadContent(),
        _repository.loadPreferences(),
      ]);
      content = values[0] as ContentPack;
      preferences = values[1] as UserPreferences;
      loadState = AppLoadState.ready;
    } catch (exception) {
      error = exception;
      loadState = AppLoadState.failure;
    }
    notifyListeners();
  }

  Future<void> saveLanguages({
    required Set<String> knowLocales,
    required String learnLocale,
  }) async {
    final next = UserPreferences(
      knowLocales: Set.unmodifiable(knowLocales),
      learnLocale: learnLocale,
    );
    await _repository.savePreferences(next);
    preferences = next;
    notifyListeners();
  }

  LessonViewModel createLessonViewModel(Lesson lesson) => LessonViewModel(
    _repository,
    lesson: lesson,
    content: content!,
    knowLocales: preferences.knowLocales,
  );

  LessonViewModel createReviewViewModel(List<String> itemIds) {
    final lesson = Lesson(
      id: 'vocabulary_review',
      locale: preferences.learnLocale!,
      title: 'Vocabulary review',
      difficulty: Difficulty.moderate,
      estimatedMinutes: 5,
      itemIds: itemIds,
      exercises: [
        for (final itemId in itemIds)
          Exercise(kind: ExerciseKind.typing, itemId: itemId),
      ],
    );
    return LessonViewModel(
      _repository,
      lesson: lesson,
      content: content!,
      knowLocales: preferences.knowLocales,
      tracksCompletion: false,
    );
  }

  Future<LearningProgress> loadLearningProgress() {
    return _repository.loadLearningProgress();
  }
}
