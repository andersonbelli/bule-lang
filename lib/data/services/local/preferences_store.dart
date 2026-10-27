import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/user_preferences.dart';

class PreferencesStore {
  static const _knowKey = 'know_locales';
  static const _learnKey = 'learn_locale';
  static const _voicesKey = 'voice_names_by_locale';
  static const _placementKey = 'placement_level';
  static const _voiceTipKey = 'voice_tip_shown';
  static const _translationTipKey = 'clickable_translation_tip_seen';

  Future<UserPreferences> read() async {
    final preferences = await SharedPreferences.getInstance();
    return UserPreferences(
      knowLocales: (preferences.getStringList(_knowKey) ?? const <String>[])
          .toSet(),
      learnLocale: preferences.getString(_learnKey),
      voiceNamesByLocale: _readVoiceNames(preferences.getString(_voicesKey)),
      placementLevel: preferences.getString(_placementKey),
      voiceTipShown: preferences.getBool(_voiceTipKey) ?? false,
      clickableTranslationTipSeen:
          preferences.getBool(_translationTipKey) ?? false,
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
    await preferences.setString(
      _voicesKey,
      jsonEncode(value.voiceNamesByLocale),
    );
    if (value.placementLevel case final level?) {
      await preferences.setString(_placementKey, level);
    } else {
      await preferences.remove(_placementKey);
    }
    await preferences.setBool(_voiceTipKey, value.voiceTipShown);
    await preferences.setBool(
      _translationTipKey,
      value.clickableTranslationTipSeen,
    );
  }

  static Map<String, String> _readVoiceNames(String? source) {
    if (source == null) return const {};
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is String) entry.key: entry.value as String,
      };
    } on FormatException {
      return const {};
    }
  }
}
