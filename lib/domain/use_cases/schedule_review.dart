import '../models/learning_progress.dart';

class ScheduleReview {
  const ScheduleReview();

  static const _correctIntervals = [1, 3, 7, 14];

  ItemProgress call({
    required ItemProgress current,
    required bool correct,
    required DateTime now,
    bool countsTowardMastery = true,
  }) {
    if (!correct) {
      return ItemProgress(
        itemId: current.itemId,
        attempts: current.attempts + 1,
        correctAttempts: current.correctAttempts,
        streak: 0,
        dueAt: now.toUtc().add(const Duration(minutes: 10)),
        learned: false,
      );
    }

    final nextStreak = countsTowardMastery
        ? current.streak + 1
        : current.streak;
    final intervalIndex = nextStreak.clamp(1, 4) - 1;
    return ItemProgress(
      itemId: current.itemId,
      attempts: current.attempts + 1,
      correctAttempts: current.correctAttempts + 1,
      streak: nextStreak,
      dueAt: now.toUtc().add(Duration(days: _correctIntervals[intervalIndex])),
      learned: nextStreak >= 4,
    );
  }
}
