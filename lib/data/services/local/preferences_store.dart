import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/user_preferences.dart';

class PreferencesStore {
  static const _knowKey = 'know_locales';
  static const _learnKey = 'learn_locale';

  Future<UserPreferences> read() async {
    final preferences = await SharedPreferences.getInstance();
    return UserPreferences(
      knowLocales: (preferences.getStringList(_knowKey) ?? const <String>[])
          .toSet(),
      learnLocale: preferences.getString(_learnKey),
    );
  }

  Future<void> write(UserPreferences value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _knowKey,
      value.knowLocales.toList()..sort(),
    );
    if (value.learnLocale case final locale?) {
      await preferences.setString(_learnKey, locale);
    } else {
      await preferences.remove(_learnKey);
    }
  }
}
