class UserPreferences {
  const UserPreferences({required this.knowLocales, required this.learnLocale});
  const UserPreferences.empty() : knowLocales = const {}, learnLocale = null;

  final Set<String> knowLocales;
  final String? learnLocale;

  bool get hasCompletedOnboarding =>
      knowLocales.isNotEmpty && learnLocale != null;
}
