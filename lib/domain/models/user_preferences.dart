class UserPreferences {
  const UserPreferences({
    required this.knowLocales,
    required this.learnLocale,
    this.voiceNamesByLocale = const {},
    this.placementLevel,
    this.voiceTipShown = false,
    this.clickableTranslationTipSeen = false,
  });
  const UserPreferences.empty()
    : knowLocales = const {},
      learnLocale = null,
      voiceNamesByLocale = const {},
      placementLevel = null,
      voiceTipShown = false,
      clickableTranslationTipSeen = false;

  final Set<String> knowLocales;
  final String? learnLocale;
  final Map<String, String> voiceNamesByLocale;
  final String? placementLevel;
  final bool voiceTipShown;
  final bool clickableTranslationTipSeen;

  bool get hasCompletedOnboarding =>
      knowLocales.isNotEmpty && learnLocale != null;
}
