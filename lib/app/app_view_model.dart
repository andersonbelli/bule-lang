import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/local_app_repository.dart';
import '../domain/models/content_pack.dart';
import '../domain/models/learning_progress.dart';
import '../domain/models/situation_progress.dart';
import '../domain/models/user_preferences.dart';
import '../domain/services/speech_reader.dart';
import '../ui/features/learning/lesson_view_model.dart';
import '../ui/features/situations/situation_view_model.dart';

enum AppLoadState { loading, ready, failure }

class AppViewModel extends ChangeNotifier {
  AppViewModel(this._repository, this._speechReader) {
    _speechSubscription = _speechReader.playing.listen((playing) {
      audioPlaying = playing;
      if (!playing) speakingText = null;
      notifyListeners();
    });
  }
  final LocalAppRepository _repository;
  final SpeechReader _speechReader;
  late final StreamSubscription<bool> _speechSubscription;

  AppLoadState loadState = AppLoadState.loading;
  ContentPack? content;
  UserPreferences preferences = const UserPreferences.empty();
  Object? error;
  bool audioPlaying = false;
  String? speakingText;

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
      voiceNamesByLocale: preferences.voiceNamesByLocale,
      placementLevel: preferences.placementLevel,
      voiceTipShown: preferences.voiceTipShown,
      clickableTranslationTipSeen: preferences.clickableTranslationTipSeen,
    );
    await _repository.savePreferences(next);
    preferences = next;
    notifyListeners();
  }

  Future<void> finishPlacement(String level) async {
    final next = UserPreferences(
      knowLocales: preferences.knowLocales,
      learnLocale: preferences.learnLocale,
      voiceNamesByLocale: preferences.voiceNamesByLocale,
      placementLevel: level,
      voiceTipShown: preferences.voiceTipShown,
      clickableTranslationTipSeen: preferences.clickableTranslationTipSeen,
    );
    await _repository.savePreferences(next);
    preferences = next;
    notifyListeners();
  }

  LessonViewModel createLessonViewModel(Lesson lesson) => LessonViewModel(
    _repository,
    speechReader: _speechReader,
    lesson: lesson,
    content: content!,
    knowLocales: preferences.knowLocales,
    voiceId: preferences.voiceNamesByLocale[lesson.locale],
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
      speechReader: _speechReader,
      lesson: lesson,
      content: content!,
      knowLocales: preferences.knowLocales,
      voiceId: preferences.voiceNamesByLocale[lesson.locale],
      tracksCompletion: false,
    );
  }

  SituationViewModel createSituationViewModel(Situation situation) =>
      SituationViewModel(
        _repository,
        situation: situation,
        content: content!,
        knowLocales: preferences.knowLocales,
        speechReader: _speechReader,
        voiceId: preferences.voiceNamesByLocale[situation.locale],
      );

  Future<SituationProgress> loadSituationProgress() {
    return _repository.loadSituationProgress();
  }

  Future<LearningProgress> loadLearningProgress() {
    return _repository.loadLearningProgress();
  }

  Future<void> savePersonalNote(String itemId, String note) async {
    await _repository.saveNote(itemId, note);
  }

  Future<void> speakLearningItem(LearningItem item) async {
    if (item.locale != preferences.learnLocale || audioPlaying) return;
    speakingText = item.text;
    notifyListeners();
    await _speechReader.speak(
      text: item.text,
      locale: item.locale,
      voiceId: preferences.voiceNamesByLocale[item.locale],
    );
  }

  Future<List<SpeechVoice>> availableLearnVoices() {
    return _speechReader.voicesFor(preferences.learnLocale!);
  }

  Future<void> preloadLearnVoice() async {
    final locale = preferences.learnLocale;
    if (locale == null) return;
    try {
      await _speechReader.prepare(
        locale: locale,
        voiceId: preferences.voiceNamesByLocale[locale],
      );
    } on Object {
      // Speech remains optional; speak() retains its normal fallback behavior.
    }
  }

  String? get selectedLearnVoiceId =>
      preferences.voiceNamesByLocale[preferences.learnLocale];

  Future<void> selectLearnVoice(String? voiceId) async {
    final locale = preferences.learnLocale!;
    await _speechReader.stop();
    final voices = Map<String, String>.of(preferences.voiceNamesByLocale);
    if (voiceId == null) {
      voices.remove(locale);
    } else {
      voices[locale] = voiceId;
    }
    final next = UserPreferences(
      knowLocales: preferences.knowLocales,
      learnLocale: locale,
      voiceNamesByLocale: Map.unmodifiable(voices),
      placementLevel: preferences.placementLevel,
      voiceTipShown: preferences.voiceTipShown,
      clickableTranslationTipSeen: preferences.clickableTranslationTipSeen,
    );
    await _repository.savePreferences(next);
    preferences = next;
    notifyListeners();
    await _speechReader.prepare(locale: locale, voiceId: voiceId);
  }

  Future<void> previewVoice(String? voiceId) => _speechReader.speak(
    text: learnVoicePreviewPhrase,
    locale: preferences.learnLocale!,
    voiceId: voiceId,
  );

  String get learnVoicePreviewPhrase =>
      _voicePreviewFor(preferences.learnLocale!);

  Future<void> markVoiceTipShown() async {
    if (preferences.voiceTipShown) return;
    final next = UserPreferences(
      knowLocales: preferences.knowLocales,
      learnLocale: preferences.learnLocale,
      voiceNamesByLocale: preferences.voiceNamesByLocale,
      placementLevel: preferences.placementLevel,
      voiceTipShown: true,
      clickableTranslationTipSeen: preferences.clickableTranslationTipSeen,
    );
    await _repository.savePreferences(next);
    preferences = next;
    notifyListeners();
  }

  Future<void> markClickableTranslationTipSeen() async {
    if (preferences.clickableTranslationTipSeen) return;
    final next = UserPreferences(
      knowLocales: preferences.knowLocales,
      learnLocale: preferences.learnLocale,
      voiceNamesByLocale: preferences.voiceNamesByLocale,
      placementLevel: preferences.placementLevel,
      voiceTipShown: preferences.voiceTipShown,
      clickableTranslationTipSeen: true,
    );
    await _repository.savePreferences(next);
    preferences = next;
    notifyListeners();
  }

  Future<void> recordPlacementCorrectAnswer(String itemId) async {
    await _repository.recordAttempt(itemId: itemId, correct: true);
  }

  String _voicePreviewFor(String locale) => switch (locale) {
    'pt-BR' => 'Olá! Vamos aprender juntos.',
    'en-US' => 'Hello! Let us learn together.',
    'es-MX' => '¡Hola! Vamos a aprender juntos.',
    'fr-FR' => 'Bonjour ! Apprenons ensemble.',
    'id-ID' => 'Halo! Mari belajar bersama.',
    'et-EE' => 'Tere! Õpime koos.',
    _ => 'Hello!',
  };

  @override
  void dispose() {
    unawaited(_speechSubscription.cancel());
    unawaited(_speechReader.stop());
    super.dispose();
  }
}
