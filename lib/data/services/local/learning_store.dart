import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/learning_progress.dart';

class LearningStore {
  static const _key = 'learning_progress_v1';

  Future<LearningProgress> read() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_key);
    if (value == null) return const LearningProgress.empty();
    return LearningProgress.fromJson(jsonDecode(value) as Map<String, Object?>);
  }

  Future<void> write(LearningProgress value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(value.toJson()));
  }
}
