import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/situation_progress.dart';

class SituationStore {
  static const _key = 'situation_progress_v1';

  Future<SituationProgress> read() async {
    final preferences = await SharedPreferences.getInstance();
    final source = preferences.getString(_key);
    if (source == null) return const SituationProgress.empty();
    return SituationProgress.fromJson(
      jsonDecode(source) as Map<String, Object?>,
    );
  }

  Future<void> write(SituationProgress progress) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(progress.toJson()));
  }
}
