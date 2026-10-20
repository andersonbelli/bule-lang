import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/services/speech_reader.dart';

class FlutterSpeechReader implements SpeechReader {
  FlutterSpeechReader({FlutterTts? engine}) : _engine = engine ?? FlutterTts() {
    _engine.setStartHandler(() => _setPlaying(true));
    _engine.setCompletionHandler(() => _setPlaying(false));
    _engine.setCancelHandler(() => _setPlaying(false));
    _engine.setErrorHandler((_) => _setPlaying(false));
  }

  final FlutterTts _engine;
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  String? _configuredLocale;
  String? _configuredVoiceId;
  bool _isPlaying = false;

  @override
  Stream<bool> get playing => _playingController.stream;

  @override
  Future<List<SpeechVoice>> voicesFor(String locale) async {
    final voices = await _engine.getVoices;
    if (voices is! List) return const [];

    final normalizedLocale = _normalize(locale);
    final matches = <String, SpeechVoice>{};
    for (final voice in voices.whereType<Map>()) {
      final voiceLocale = voice['locale']?.toString();
      final voiceName = voice['name']?.toString();
      final identifier = voice['identifier']?.toString();
      final needsNetwork = voice['network_required']?.toString() == '1';
      if (voiceLocale != null &&
          voiceName != null &&
          !needsNetwork &&
          _normalize(voiceLocale) == normalizedLocale) {
        final speechVoice = SpeechVoice(
          name: voiceName,
          locale: voiceLocale,
          identifier: identifier,
        );
        matches[speechVoice.id] = speechVoice;
      }
    }
    return matches.values.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
  }

  @override
  Future<void> speak({
    required String text,
    required String locale,
    String? voiceId,
  }) async {
    final value = text.trim();
    if (value.isEmpty || _isPlaying) return;

    await stop();
    _setPlaying(true);

    try {
      if (_configuredLocale != locale || _configuredVoiceId != voiceId) {
        await _configure(locale, voiceId);
      }
      final result = await _engine.speak(value);
      if (result != 1) {
        await _engine.setLanguage(locale);
        _configuredVoiceId = null;
        final fallbackResult = await _engine.speak(value);
        if (fallbackResult != 1) _setPlaying(false);
      }
    } on Object {
      _setPlaying(false);
      rethrow;
    }
  }

  Future<void> _configure(String locale, String? voiceId) async {
    await _engine.setLanguage(locale);
    await _engine.setSpeechRate(0.45);
    await _engine.setVolume(1.0);
    await _engine.setPitch(1.0);

    final voices = await voicesFor(locale);
    final selected = voiceId == null
        ? voices.firstOrNull
        : voices
              .where((voice) => voice.id == voiceId || voice.name == voiceId)
              .firstOrNull;
    if (selected != null) {
      final voice = <String, String>{
        'name': selected.name,
        'locale': selected.locale,
        'identifier': ?selected.identifier,
      };
      try {
        final result = await _engine.setVoice(voice);
        if (result == 0) await _engine.setLanguage(locale);
      } on Object {
        await _engine.setLanguage(locale);
      }
    }
    _configuredLocale = locale;
    _configuredVoiceId = voiceId;
  }

  String _normalize(String locale) => locale.replaceAll('_', '-').toLowerCase();

  @override
  Future<void> stop() async {
    await _engine.stop();
    _setPlaying(false);
  }

  void _setPlaying(bool value) {
    if (_isPlaying == value) return;
    _isPlaying = value;
    _playingController.add(value);
  }
}
