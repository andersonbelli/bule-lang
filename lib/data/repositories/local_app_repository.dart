import 'dart:convert';
import 'package:flutter/services.dart';

import '../../domain/models/content_pack.dart';
import '../../domain/models/learning_progress.dart';
import '../../domain/models/user_preferences.dart';
import '../../domain/use_cases/schedule_review.dart';
import '../services/local/learning_store.dart';
import '../services/local/preferences_store.dart';

class LocalAppRepository {
  LocalAppRepository(this._preferencesStore, [LearningStore? learningStore])
    : _learningStore = learningStore ?? LearningStore();
  final PreferencesStore _preferencesStore;
  final LearningStore _learningStore;
  final ScheduleReview _scheduleReview = const ScheduleReview();

  Future<ContentPack> loadContent() async {
    final source = await rootBundle.loadString(
      'assets/language-learning-starter-content.json',
    );
    return ContentPack.fromJson(jsonDecode(source) as Map<String, Object?>);
  }

  Future<UserPreferences> loadPreferences() => _preferencesStore.read();

  Future<void> savePreferences(UserPreferences value) {
    if (value.knowLocales.isEmpty || value.learnLocale == null) {
      throw ArgumentError('Know and Learn languages are required.');
    }
    if (value.knowLocales.contains(value.learnLocale)) {
      throw ArgumentError('The Learn language cannot also be a Know language.');
    }
    return _preferencesStore.write(value);
  }

  Future<LearningProgress> loadLearningProgress() => _learningStore.read();

  Future<LearningProgress> encounter(String itemId) async {
    final progress = await _learningStore.read();
    if (progress.items.containsKey(itemId)) return progress;
    final items = Map<String, ItemProgress>.of(progress.items)
      ..[itemId] = ItemProgress.encountered(itemId);
    final next = LearningProgress(
      items: items,
      notes: progress.notes,
      lessonCompletions: progress.lessonCompletions,
    );
    await _learningStore.write(next);
    return next;
  }

  Future<LearningProgress> recordAttempt({
    required String itemId,
    required bool correct,
    bool countsTowardMastery = true,
  }) async {
    final progress = await _learningStore.read();
    final current = progress.items[itemId] ?? ItemProgress.encountered(itemId);
    final items = Map<String, ItemProgress>.of(progress.items)
      ..[itemId] = _scheduleReview(
        current: current,
        correct: correct,
        now: DateTime.now(),
        countsTowardMastery: countsTowardMastery,
      );
    final next = LearningProgress(
      items: items,
      notes: progress.notes,
      lessonCompletions: progress.lessonCompletions,
    );
    await _learningStore.write(next);
    return next;
  }

  Future<LearningProgress> saveNote(String itemId, String note) async {
    final progress = await _learningStore.read();
    final notes = Map<String, String>.of(progress.notes);
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      notes.remove(itemId);
    } else {
      notes[itemId] = note;
    }
    final next = LearningProgress(
      items: progress.items,
      notes: notes,
      lessonCompletions: progress.lessonCompletions,
    );
    await _learningStore.write(next);
    return next;
  }

  Future<LearningProgress> markSelfAssessed(String itemId) async {
    final progress = await _learningStore.read();
    if (!progress.items.containsKey(itemId)) {
      return encounter(itemId);
    }
    // Keep the missed-item schedule and mastery streak unchanged. Self-review
    // explains an unmatched answer but never upgrades trusted progress.
    return progress;
  }

  Future<LearningProgress> completeLesson(String lessonId) async {
    final progress = await _learningStore.read();
    final completions = Map<String, int>.of(progress.lessonCompletions)
      ..update(lessonId, (count) => count + 1, ifAbsent: () => 1);
    final next = LearningProgress(
      items: progress.items,
      notes: progress.notes,
      lessonCompletions: completions,
    );
    await _learningStore.write(next);
    return next;
  }
}
