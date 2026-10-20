import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/local_app_repository.dart';
import '../../../domain/models/content_pack.dart';
import '../../../domain/models/learning_progress.dart';
import '../../../domain/services/speech_reader.dart';
import '../../../domain/use_cases/grade_answer.dart';

enum AnswerFeedback { none, correct, almostCorrect, incorrect, selfAssessed }

class ExerciseOutcome {
  const ExerciseOutcome({required this.itemId, required this.correct});
  final String itemId;
  final bool correct;
}

class LessonViewModel extends ChangeNotifier {
  LessonViewModel(
    this._repository, {
    required this.speechReader,
    required this.lesson,
    required this.content,
    required this.knowLocales,
    required this.voiceId,
    this.tracksCompletion = true,
  }) : exercises = _buildExercises(lesson.exercises) {
    _speechSubscription = speechReader.playing.listen((playing) {
      audioPlaying = playing;
      if (!playing) speakingText = null;
      notifyListeners();
    });
  }

  final LocalAppRepository _repository;
  final GradeAnswer _gradeAnswer = const GradeAnswer();
  final SpeechReader speechReader;
  final Lesson lesson;
  final ContentPack content;
  final Set<String> knowLocales;
  final String? voiceId;
  final bool tracksCompletion;
  final List<Exercise> exercises;
  final Set<String> _queuedRetries = {};
  late final StreamSubscription<bool> _speechSubscription;

  LearningProgress progress = const LearningProgress.empty();
  final List<ExerciseOutcome> outcomes = [];
  int currentIndex = 0;
  int currentRunStreak = 0;
  int bestRunStreak = 0;
  bool loading = true;
  bool translationRevealed = false;
  bool flashcardRated = false;
  bool? flashcardKnown;
  String? submittedAnswer;
  GradeResult? gradeResult;
  AnswerFeedback feedback = AnswerFeedback.none;
  bool _completionRecorded = false;
  final Set<String> missedItemIds = {};
  bool audioPlaying = false;
  String? speakingText;

  Exercise? get currentExercise =>
      currentIndex < exercises.length ? exercises[currentIndex] : null;
  LearningItem? get currentItem {
    final exercise = currentExercise;
    return exercise == null ? null : content.items[exercise.itemId];
  }

  bool get isComplete => currentIndex >= exercises.length;
  double get completion => exercises.isEmpty
      ? 1
      : ((currentIndex + 1) / exercises.length).clamp(0, 1);
  String get note =>
      currentItem == null ? '' : progress.notes[currentItem!.id] ?? '';
  bool get canShowNote => switch (currentExercise?.kind) {
    ExerciseKind.flashcard => flashcardRated,
    ExerciseKind.typing ||
    ExerciseKind.multipleChoice => feedback != AnswerFeedback.none,
    null => false,
  };
  int get correctCount => outcomes.where((outcome) => outcome.correct).length;
  int get incorrectCount => outcomes.length - correctCount;

  Future<void> initialize() async {
    progress = await _repository.loadLearningProgress();
    exercises.removeWhere(
      (exercise) =>
          exercise.kind == ExerciseKind.flashcard &&
          progress.items.containsKey(exercise.itemId),
    );
    final item = currentItem;
    if (item != null) progress = await _repository.encounter(item.id);
    loading = false;
    notifyListeners();
  }

  void revealTranslation() {
    translationRevealed = true;
    notifyListeners();
  }

  Future<void> rateFlashcard(bool knewIt) async {
    final item = currentItem!;
    progress = await _repository.encounter(item.id);
    flashcardRated = true;
    flashcardKnown = knewIt;
    notifyListeners();
  }

  Future<void> submitTypedAnswer(String answer) async {
    final item = currentItem!;
    final result = _gradeAnswer(answer, item.acceptedAnswers);
    submittedAnswer = answer;
    gradeResult = result;
    progress = await _repository.recordAttempt(
      itemId: item.id,
      correct: result.correct,
    );
    if (!result.correct) {
      missedItemIds.add(item.id);
      _queueRetry(item.id);
    }
    _updateRunStreak(result.correct);
    outcomes.add(ExerciseOutcome(itemId: item.id, correct: result.correct));
    feedback = result.correct
        ? result.exact
              ? AnswerFeedback.correct
              : AnswerFeedback.almostCorrect
        : AnswerFeedback.incorrect;
    notifyListeners();
  }

  Future<void> submitChoice(String answer) => submitTypedAnswer(answer);

  Future<void> acceptSelfAssessment() async {
    final item = currentItem!;
    progress = await _repository.markSelfAssessed(item.id);
    feedback = AnswerFeedback.selfAssessed;
    notifyListeners();
  }

  List<String> get currentChoices {
    final item = currentItem;
    if (item == null) return const [];
    final candidates = content.items.values
        .where(
          (candidate) =>
              candidate.locale == item.locale &&
              candidate.id != item.id &&
              candidate.kind == item.kind,
        )
        .toList();
    candidates.sort(
      (left, right) => (left.text.length - item.text.length).abs().compareTo(
        (right.text.length - item.text.length).abs(),
      ),
    );
    final alternatives = candidates
        .map((candidate) => candidate.text)
        .where((text) => !item.acceptedAnswers.contains(text))
        .take(2)
        .toList();
    final correct = item.acceptedAnswers.isEmpty
        ? item.text
        : item.acceptedAnswers.first;
    final choices = <String>[...alternatives, correct];
    if (choices.length < 3) return choices;
    final position = currentIndex % 3;
    choices.remove(correct);
    choices.insert(position, correct);
    return choices;
  }

  Future<void> saveNote(String value) async {
    final item = currentItem;
    if (item == null) return;
    progress = await _repository.saveNote(item.id, value);
  }

  Future<void> speak(LearningItem item) async {
    if (item.locale != lesson.locale || audioPlaying) return;
    speakingText = item.text;
    notifyListeners();
    await speechReader.speak(
      text: item.text,
      locale: item.locale,
      voiceId: voiceId,
    );
  }

  Future<void> speakText(String text) async {
    if (audioPlaying) return;
    speakingText = text;
    notifyListeners();
    await speechReader.speak(
      text: text,
      locale: lesson.locale,
      voiceId: voiceId,
    );
  }

  Future<void> next() async {
    await speechReader.stop();
    currentIndex++;
    translationRevealed = false;
    flashcardRated = false;
    flashcardKnown = null;
    submittedAnswer = null;
    gradeResult = null;
    feedback = AnswerFeedback.none;
    final item = currentItem;
    if (item != null) progress = await _repository.encounter(item.id);
    if (isComplete && tracksCompletion && !_completionRecorded) {
      progress = await _repository.completeLesson(lesson.id);
      _completionRecorded = true;
    }
    notifyListeners();
  }

  void _queueRetry(String itemId) {
    if (!_queuedRetries.add(itemId)) return;
    final insertionIndex = (currentIndex + 3).clamp(0, exercises.length);
    exercises.insert(
      insertionIndex,
      Exercise(kind: ExerciseKind.typing, itemId: itemId),
    );
  }

  void _updateRunStreak(bool correct) {
    if (correct) {
      currentRunStreak++;
      if (currentRunStreak > bestRunStreak) bestRunStreak = currentRunStreak;
    } else {
      currentRunStreak = 0;
    }
  }

  static List<Exercise> _buildExercises(List<Exercise> authored) => [
    for (var index = 0; index < authored.length; index++)
      Exercise(
        kind: authored[index].kind == ExerciseKind.typing && index.isEven
            ? ExerciseKind.multipleChoice
            : authored[index].kind,
        itemId: authored[index].itemId,
      ),
  ];

  @override
  void dispose() {
    unawaited(_speechSubscription.cancel());
    unawaited(speechReader.stop());
    super.dispose();
  }
}
