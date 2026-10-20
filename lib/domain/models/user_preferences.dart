class UserPreferences {
  const UserPreferences({
    required this.knowLocales,
    required this.learnLocale,
    this.voiceNamesByLocale = const {},
  });
  const UserPreferences.empty()
    : knowLocales = const {},
      learnLocale = null,
      voiceNamesByLocale = const {};

  final Set<String> knowLocales;
  final String? learnLocale;
  final Map<String, String> voiceNamesByLocale;

  bool get hasCompletedOnboarding =>
      knowLocales.isNotEmpty && learnLocale != null;
}
