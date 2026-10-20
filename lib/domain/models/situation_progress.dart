class SituationComment {
  const SituationComment({
    required this.id,
    required this.body,
    required this.createdAt,
    this.parentId,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final String? parentId;

  factory SituationComment.fromJson(Map<String, Object?> json) =>
      SituationComment(
        id: json['id']! as String,
        body: json['body']! as String,
        createdAt: DateTime.parse(json['created_at']! as String),
        parentId: json['parent_id'] as String?,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'body': body,
    'created_at': createdAt.toUtc().toIso8601String(),
    'parent_id': parentId,
  };
}

class SituationActivity {
  const SituationActivity({
    required this.completions,
    required this.completionsWithHelp,
    required this.vote,
    required this.comments,
  });
  const SituationActivity.empty()
    : completions = 0,
      completionsWithHelp = 0,
      vote = 0,
      comments = const [];

  final int completions;
  final int completionsWithHelp;
  final int vote;
  final List<SituationComment> comments;

  factory SituationActivity.fromJson(Map<String, Object?> json) =>
      SituationActivity(
        completions: json['completions'] as int? ?? 0,
        completionsWithHelp: json['completions_with_help'] as int? ?? 0,
        vote: json['vote'] as int? ?? 0,
        comments: ((json['comments'] as List<Object?>?) ?? const [])
            .cast<Map<String, Object?>>()
            .map(SituationComment.fromJson)
            .toList(growable: false),
      );

  Map<String, Object?> toJson() => {
    'completions': completions,
    'completions_with_help': completionsWithHelp,
    'vote': vote,
    'comments': comments.map((comment) => comment.toJson()).toList(),
  };
}

class SituationProgress {
  const SituationProgress(this.activities);
  const SituationProgress.empty() : activities = const {};

  final Map<String, SituationActivity> activities;

  factory SituationProgress.fromJson(Map<String, Object?> json) =>
      SituationProgress(
        json.map(
          (id, value) => MapEntry(
            id,
            SituationActivity.fromJson(value! as Map<String, Object?>),
          ),
        ),
      );

  Map<String, Object?> toJson() =>
      activities.map((id, activity) => MapEntry(id, activity.toJson()));
}
