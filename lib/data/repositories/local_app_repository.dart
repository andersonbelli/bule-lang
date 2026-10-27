import 'dart:convert';
import 'package:flutter/services.dart';

import '../../domain/models/content_pack.dart';
import '../../domain/models/learning_progress.dart';
import '../../domain/models/situation_progress.dart';
import '../../domain/models/user_preferences.dart';
import '../../domain/use_cases/schedule_review.dart';
import '../services/local/learning_store.dart';
import '../services/local/preferences_store.dart';
import '../services/local/situation_store.dart';

class LocalAppRepository {
  LocalAppRepository(
    this._preferencesStore, [
    LearningStore? learningStore,
    SituationStore? situationStore,
  ]) : _learningStore = learningStore ?? LearningStore(),
       _situationStore = situationStore ?? SituationStore();
  final PreferencesStore _preferencesStore;
  final LearningStore _learningStore;
  final SituationStore _situationStore;
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
      currentDayStreak: progress.currentDayStreak,
      bestDayStreak: progress.bestDayStreak,
      lastPracticeDate: progress.lastPracticeDate,
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
      currentDayStreak: progress.currentDayStreak,
      bestDayStreak: progress.bestDayStreak,
      lastPracticeDate: progress.lastPracticeDate,
    );
    await _learningStore.write(next);
    return next;
  }

  Future<LearningProgress> saveNote(String itemId, String note) async {
    final progress = await _learningStore.read();
    final notes = Map<String, String>.of(progress.notes);
    final trimmed = note.trim();
    if (trimmed.length > maxPersonalNoteLength) {
      throw ArgumentError(
        'Personal notes cannot exceed $maxPersonalNoteLength characters.',
      );
    }
    if (trimmed.isEmpty) {
      notes.remove(itemId);
    } else {
      notes[itemId] = trimmed;
    }
    final next = LearningProgress(
      items: progress.items,
      notes: notes,
      lessonCompletions: progress.lessonCompletions,
      currentDayStreak: progress.currentDayStreak,
      bestDayStreak: progress.bestDayStreak,
      lastPracticeDate: progress.lastPracticeDate,
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
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));
    final streak = progress.lastPracticeDate == todayKey
        ? progress.currentDayStreak
        : progress.lastPracticeDate == yesterdayKey
        ? progress.currentDayStreak + 1
        : 1;
    final next = LearningProgress(
      items: progress.items,
      notes: progress.notes,
      lessonCompletions: completions,
      currentDayStreak: streak,
      bestDayStreak: streak > progress.bestDayStreak
          ? streak
          : progress.bestDayStreak,
      lastPracticeDate: todayKey,
    );
    await _learningStore.write(next);
    return next;
  }

  Future<SituationProgress> loadSituationProgress() => _situationStore.read();

  Future<SituationActivity> completeSituation({
    required String situationId,
    required bool usedHelp,
    required Iterable<String> vocabularyItemIds,
  }) async {
    final situationProgress = await _situationStore.read();
    final current =
        situationProgress.activities[situationId] ??
        const SituationActivity.empty();
    final nextActivity = SituationActivity(
      completions: current.completions + 1,
      completionsWithHelp: current.completionsWithHelp + (usedHelp ? 1 : 0),
      vote: current.vote,
      comments: current.comments,
    );
    final activities = Map<String, SituationActivity>.of(
      situationProgress.activities,
    )..[situationId] = nextActivity;
    await _situationStore.write(SituationProgress(activities));

    final learning = await _learningStore.read();
    final items = Map<String, ItemProgress>.of(learning.items);
    for (final itemId in vocabularyItemIds) {
      items.putIfAbsent(itemId, () => ItemProgress.encountered(itemId));
    }
    await _learningStore.write(
      LearningProgress(
        items: items,
        notes: learning.notes,
        lessonCompletions: learning.lessonCompletions,
        currentDayStreak: learning.currentDayStreak,
        bestDayStreak: learning.bestDayStreak,
        lastPracticeDate: learning.lastPracticeDate,
      ),
    );
    return nextActivity;
  }

  Future<SituationActivity> voteSituation(String situationId, int vote) {
    if (vote < -1 || vote > 1) throw ArgumentError.value(vote, 'vote');
    return _updateSituation(
      situationId,
      (current) => SituationActivity(
        completions: current.completions,
        completionsWithHelp: current.completionsWithHelp,
        vote: vote,
        comments: current.comments,
      ),
    );
  }

  Future<SituationActivity> commentOnSituation({
    required String situationId,
    required String body,
    String? parentId,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty || trimmed.length > 500) {
      throw ArgumentError('Comments must contain 1–500 characters.');
    }
    return _updateSituation(
      situationId,
      (current) => SituationActivity(
        completions: current.completions,
        completionsWithHelp: current.completionsWithHelp,
        vote: current.vote,
        comments: [
          ...current.comments,
          SituationComment(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            body: trimmed,
            createdAt: DateTime.now().toUtc(),
            parentId: parentId,
          ),
        ],
      ),
    );
  }

  Future<SituationActivity> _updateSituation(
    String situationId,
    SituationActivity Function(SituationActivity) update,
  ) async {
    final progress = await _situationStore.read();
    final current =
        progress.activities[situationId] ?? const SituationActivity.empty();
    if (current.completions == 0) {
      throw StateError('Complete the Situation before adding feedback.');
    }
    final next = update(current);
    final activities = Map<String, SituationActivity>.of(progress.activities)
      ..[situationId] = next;
    await _situationStore.write(SituationProgress(activities));
    return next;
  }

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
