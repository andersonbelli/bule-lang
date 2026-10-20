class SpeechVoice {
  const SpeechVoice({
    required this.name,
    required this.locale,
    this.identifier,
  });

  final String name;
  final String locale;
  final String? identifier;

  String get id => identifier ?? name;
}

abstract interface class SpeechReader {
  Stream<bool> get playing;

  Future<List<SpeechVoice>> voicesFor(String locale);

  Future<void> speak({
    required String text,
    required String locale,
    String? voiceId,
  });

  Future<void> stop();
}
