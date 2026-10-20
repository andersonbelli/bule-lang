import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/local_app_repository.dart';
import '../../../domain/models/content_pack.dart';
import '../../../domain/models/situation_progress.dart';
import '../../../domain/services/speech_reader.dart';
import '../../../domain/use_cases/grade_answer.dart';

class SituationViewModel extends ChangeNotifier {
  SituationViewModel(
    this._repository, {
    required this.situation,
    required this.content,
    required this.knowLocales,
    required this.speechReader,
    required this.voiceId,
  }) {
    _speechSubscription = speechReader.playing.listen((playing) {
      audioPlaying = playing;
      if (!playing) speakingText = null;
      notifyListeners();
    });
  }

  final LocalAppRepository _repository;
  final GradeAnswer _gradeAnswer = const GradeAnswer();
  final Situation situation;
  final ContentPack content;
  final Set<String> knowLocales;
  final SpeechReader speechReader;
  final String? voiceId;
  late final StreamSubscription<bool> _speechSubscription;

  SituationActivity activity = const SituationActivity.empty();
  int currentIndex = 0;
  bool loading = true;
  bool helpVisible = false;
  bool usedHelp = false;
  bool currentTurnUsedHelp = false;
  bool responseAccepted = false;
  bool? lastAnswerCorrect;
  String? submittedAnswer;
  bool _completionRecorded = false;
  bool audioPlaying = false;
  String? speakingText;

  SituationTurn? get currentTurn => currentIndex < situation.turns.length
      ? situation.turns[currentIndex]
      : null;
  bool get isComplete => currentIndex >= situation.turns.length;
  double get completion => situation.turns.isEmpty
      ? 1
      : (currentIndex / situation.turns.length).clamp(0, 1);
  Iterable<SituationTurn> get transcript => situation.turns.take(
    currentTurn?.role == SituationRole.computer
        ? currentIndex + 1
        : currentIndex,
  );
  Iterable<LearningItem> get vocabulary => situation.vocabularyItemIds
      .map((id) => content.items[id])
      .whereType<LearningItem>();

  Future<void> initialize() async {
    final progress = await _repository.loadSituationProgress();
    activity =
        progress.activities[situation.id] ?? const SituationActivity.empty();
    loading = false;
    notifyListeners();
  }

  String promptFor(SituationTurn turn) {
    for (final locale in knowLocales) {
      final translation = turn.translations[locale];
      if (translation != null) return translation;
    }
    return 'Respond in ${situation.locale}';
  }

  Future<void> submit(String answer) async {
    final turn = currentTurn;
    if (turn == null || turn.role != SituationRole.learner) return;
    final result = _gradeAnswer(answer, turn.acceptedAnswers);
    submittedAnswer = answer.trim();
    lastAnswerCorrect = result.correct;
    responseAccepted = result.correct;
    notifyListeners();
  }

  void showHelp() {
    helpVisible = true;
    usedHelp = true;
    currentTurnUsedHelp = true;
    notifyListeners();
  }

  void useSuggestion() {
    final turn = currentTurn;
    if (turn == null) return;
    helpVisible = true;
    usedHelp = true;
    currentTurnUsedHelp = true;
    submittedAnswer = turn.text;
    lastAnswerCorrect = true;
    responseAccepted = true;
    notifyListeners();
  }

  Future<void> next() async {
    await speechReader.stop();
    final turn = currentTurn;
    if (turn?.role == SituationRole.learner && !responseAccepted) return;
    currentIndex++;
    helpVisible = false;
    currentTurnUsedHelp = false;
    responseAccepted = false;
    lastAnswerCorrect = null;
    submittedAnswer = null;
    if (isComplete && !_completionRecorded) {
      activity = await _repository.completeSituation(
        situationId: situation.id,
        usedHelp: usedHelp,
        vocabularyItemIds: situation.vocabularyItemIds,
      );
      _completionRecorded = true;
    }
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (audioPlaying) return;
    speakingText = text;
    notifyListeners();
    await speechReader.speak(
      text: text,
      locale: situation.locale,
      voiceId: voiceId,
    );
  }

  Future<void> vote(int value) async {
    activity = await _repository.voteSituation(
      situation.id,
      activity.vote == value ? 0 : value,
    );
    notifyListeners();
  }

  Future<void> comment(String body, {String? parentId}) async {
    activity = await _repository.commentOnSituation(
      situationId: situation.id,
      body: body,
      parentId: parentId,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_speechSubscription.cancel());
    unawaited(speechReader.stop());
    super.dispose();
  }
}
