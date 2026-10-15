import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../../app/app_view_model.dart';
import '../../../domain/models/content_pack.dart';
import '../../../domain/models/learning_progress.dart';
import '../../core/bule_design.dart';
import '../learning/lesson_view.dart';
import '../profile/profile_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.viewModel});
  final AppViewModel viewModel;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selected = 0;

  static const _destinations = [
    ('Learn', CupertinoIcons.book),
    ('Situations', CupertinoIcons.chat_bubble_2),
    ('Community', CupertinoIcons.person_3),
    ('Chats', CupertinoIcons.bubble_left_bubble_right),
    ('Vocabulary', CupertinoIcons.textformat_abc),
    ('Profile', CupertinoIcons.person_crop_circle),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => useWideLayout(context, constraints)
        ? kIsWeb
              ? _wide()
              : BuleWideFrame(child: _wide())
        : _compact(),
  );

  Widget _compact() => CupertinoTabScaffold(
    tabBar: CupertinoTabBar(
      currentIndex: _selected.clamp(0, 3),
      onTap: (value) => setState(() => _selected = value),
      items: [
        for (final destination in _destinations.take(3))
          BottomNavigationBarItem(
            icon: Icon(destination.$2),
            label: destination.$1,
          ),
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.ellipsis_circle),
          label: 'More',
        ),
      ],
    ),
    tabBuilder: (context, index) => index == 3 ? _morePage() : _page(index),
  );

  Widget _wide() => CupertinoPageScaffold(
    child: Row(
      children: [
        Container(
          width: 220,
          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
          child: CupertinoListSection.insetGrouped(
            header: Text(
              'BULE . LANGUAGE LEARNING',
              textAlign: TextAlign.center,
              style: BuleTextStyles.eyebrow.copyWith(
                color: CupertinoColors.activeGreen,
              ),
            ),
            children: [
              for (var index = 0; index < _destinations.length; index++)
                CupertinoListTile(
                  leading: Icon(
                    _destinations[index].$2,
                    color: _destinationColor(index),
                  ),
                  title: Text(_destinations[index].$1),
                  backgroundColor: index == _selected
                      ? CupertinoColors.secondarySystemFill.resolveFrom(context)
                      : null,
                  onTap: () => setState(() => _selected = index),
                ),
            ],
          ),
        ),
        Container(
          width: 0.5,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        Expanded(child: _page(_selected)),
      ],
    ),
  );

  Widget _morePage() => CupertinoPageScaffold(
    navigationBar: const CupertinoNavigationBar(middle: Text('More')),
    child: SafeArea(
      child: CupertinoListSection.insetGrouped(
        children: [
          for (var index = 3; index < _destinations.length; index++)
            CupertinoListTile(
              leading: Icon(_destinations[index].$2),
              title: Text(_destinations[index].$1),
              trailing: const CupertinoListTileChevron(),
              onTap: () => Navigator.of(
                context,
              ).push(CupertinoPageRoute<void>(builder: (_) => _page(index))),
            ),
        ],
      ),
    ),
  );

  Widget _page(int index) => switch (index) {
    0 => _learningPage(),
    1 => _situationsPage(),
    4 => _vocabularyPage(),
    5 => ProfileView(viewModel: widget.viewModel),
    _ => _placeholder(_destinations[index].$1),
  };

  Widget _learningPage() {
    final locale = widget.viewModel.preferences.learnLocale!;
    final lessons = widget.viewModel.content!.lessons
        .where((lesson) => lesson.locale == locale)
        .toList();
    return FutureBuilder<LearningProgress>(
      future: widget.viewModel.loadLearningProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(middle: Text('Learn')),
            child: SafeArea(child: Center(child: CupertinoActivityIndicator())),
          );
        }
        final progress = snapshot.data!;
        final completions = progress.lessonCompletions;
        final available = lessons.where(
          (lesson) => !completions.containsKey(lesson.id),
        );
        final completed = lessons.where(
          (lesson) => completions.containsKey(lesson.id),
        );
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(middle: Text('Learn')),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              children: [
                const Text('Learn', style: BuleTextStyles.pageTitle),
                const SizedBox(height: BuleSpacing.xs),
                Text(
                  'Offline lessons for ${_languageName(locale)}',
                  style: BuleTextStyles.supporting.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: BuleSpacing.md),
                if (completions.length > 2) ...[
                  CupertinoListSection.insetGrouped(
                    margin: EdgeInsets.zero,
                    header: const Text('REVIEW'),
                    children: [
                      CupertinoListTile(
                        leading: const Icon(
                          CupertinoIcons.arrow_2_circlepath,
                          color: CupertinoColors.systemPurple,
                        ),
                        title: const Text(
                          'Review 10 words',
                          style: BuleTextStyles.cardTitle,
                        ),
                        subtitle: const Text(
                          'A random practice set from your vocabulary',
                        ),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () => _openReview(progress),
                      ),
                    ],
                  ),
                  const SizedBox(height: BuleSpacing.md),
                ],
                if (available.isNotEmpty)
                  CupertinoListSection.insetGrouped(
                    margin: EdgeInsets.zero,
                    header: const Text('CONTINUE LEARNING'),
                    children: [
                      for (final lesson in available) _lessonTile(lesson, 0),
                    ],
                  ),
                if (completed.isNotEmpty) ...[
                  const SizedBox(height: BuleSpacing.md),
                  CupertinoListSection.insetGrouped(
                    margin: EdgeInsets.zero,
                    header: const Text('COMPLETED'),
                    children: [
                      for (final lesson in completed)
                        _lessonTile(lesson, completions[lesson.id]!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _situationsPage() {
    final locale = widget.viewModel.preferences.learnLocale!;
    final situations = widget.viewModel.content!.situations
        .where((item) => item.locale == locale)
        .toList();
    return _listPage(
      title: 'Situations',
      intro:
          'Practice complete conversations. Vote and comment after completion.',
      children: [
        for (final situation in situations)
          CupertinoListTile(
            leading: const Icon(
              CupertinoIcons.chat_bubble_text,
              color: CupertinoColors.systemTeal,
            ),
            title: Text(situation.title, style: BuleTextStyles.cardTitle),
            subtitle: Text(
              '${_difficultyLabel(situation.difficulty)} · ${situation.estimatedMinutes} min',
              style: BuleTextStyles.supporting.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            trailing: const CupertinoListTileChevron(),
          ),
      ],
    );
  }

  Widget _lessonTile(Lesson lesson, int completionCount) => CupertinoListTile(
    leading: Icon(
      completionCount > 0
          ? CupertinoIcons.check_mark_circled_solid
          : CupertinoIcons.book,
      color: completionCount > 0
          ? CupertinoColors.activeGreen
          : CupertinoColors.activeBlue,
    ),
    title: Text(lesson.title, style: BuleTextStyles.cardTitle),
    subtitle: Text(
      completionCount > 0
          ? 'Completed $completionCount ${completionCount == 1 ? 'time' : 'times'} · ${_difficultyLabel(lesson.difficulty)}'
          : '${_difficultyLabel(lesson.difficulty)} · ${lesson.itemIds.length} words and phrases · ${lesson.estimatedMinutes} min',
      style: BuleTextStyles.supporting.copyWith(
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
    trailing: const CupertinoListTileChevron(),
    onTap: () async {
      await Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => LessonView(
            viewModel: widget.viewModel.createLessonViewModel(lesson),
          ),
        ),
      );
      if (mounted) setState(() {});
    },
  );

  Widget _vocabularyPage() => FutureBuilder<LearningProgress>(
    future: widget.viewModel.loadLearningProgress(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text('Vocabulary')),
          child: SafeArea(child: Center(child: CupertinoActivityIndicator())),
        );
      }
      final progress = snapshot.data!;
      final entries = progress.items.values.toList();
      if (entries.isEmpty) {
        return _listPage(
          title: 'Vocabulary',
          intro: 'Words and phrases appear here as you encounter them.',
          children: const [
            CupertinoListTile(
              title: Text('No vocabulary yet'),
              subtitle: Text('Start a lesson to add your first item.'),
            ),
          ],
        );
      }
      final lessons = widget.viewModel.content!.lessons;
      final assigned = <String>{};
      final sections = <Widget>[];
      for (final lesson in lessons) {
        final lessonEntries =
            entries
                .where(
                  (entry) =>
                      !assigned.contains(entry.itemId) &&
                      lesson.itemIds.contains(entry.itemId),
                )
                .toList()
              ..sort(_vocabularyPriority);
        if (lessonEntries.isEmpty) continue;
        assigned.addAll(lessonEntries.map((entry) => entry.itemId));
        sections.add(
          CupertinoListSection.insetGrouped(
            margin: const EdgeInsets.only(bottom: BuleSpacing.md),
            header: Text(lesson.title.toUpperCase()),
            children: [
              for (final entry in lessonEntries) _vocabularyTile(entry),
            ],
          ),
        );
      }
      final other =
          entries.where((entry) => !assigned.contains(entry.itemId)).toList()
            ..sort(_vocabularyPriority);
      if (other.isNotEmpty) {
        sections.add(
          CupertinoListSection.insetGrouped(
            margin: const EdgeInsets.only(bottom: BuleSpacing.md),
            header: const Text('OTHER VOCABULARY'),
            children: [for (final entry in other) _vocabularyTile(entry)],
          ),
        );
      }
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Vocabulary')),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              const Text('Vocabulary', style: BuleTextStyles.pageTitle),
              const SizedBox(height: BuleSpacing.xs),
              Text(
                '${entries.length} encountered words and phrases, grouped by lesson.',
                style: BuleTextStyles.supporting.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: BuleSpacing.md),
              ...sections,
            ],
          ),
        ),
      );
    },
  );

  Widget _vocabularyTile(ItemProgress progress) {
    final item = widget.viewModel.content!.items[progress.itemId];
    final due = !progress.dueAt.isAfter(DateTime.now());
    return CupertinoListTile(
      leading: Icon(
        progress.learned
            ? CupertinoIcons.check_mark_circled_solid
            : CupertinoIcons.clock,
        color: progress.learned
            ? CupertinoColors.activeGreen
            : due
            ? CupertinoColors.systemPurple
            : CupertinoColors.inactiveGray,
      ),
      title: Text(
        item?.text ?? progress.itemId,
        style: BuleTextStyles.cardTitle,
      ),
      subtitle: Text(
        progress.learned
            ? 'Learned · ${progress.correctAttempts}/${progress.attempts} correct'
            : due
            ? 'Review now · streak ${progress.streak}/4'
            : 'Scheduled · streak ${progress.streak}/4',
        style: BuleTextStyles.supporting.copyWith(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
      trailing: const CupertinoListTileChevron(),
      onTap: item == null ? null : () => _showVocabularyTranslations(item),
    );
  }

  int _vocabularyPriority(ItemProgress left, ItemProgress right) {
    final leftAccuracy = left.attempts == 0
        ? 0.0
        : left.correctAttempts / left.attempts;
    final rightAccuracy = right.attempts == 0
        ? 0.0
        : right.correctAttempts / right.attempts;
    return leftAccuracy.compareTo(rightAccuracy);
  }

  Future<void> _openReview(LearningProgress progress) async {
    final locale = widget.viewModel.preferences.learnLocale;
    final itemIds =
        progress.items.keys
            .where(
              (itemId) =>
                  widget.viewModel.content!.items[itemId]?.locale == locale,
            )
            .toList()
          ..shuffle();
    if (itemIds.isEmpty) return;
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => LessonView(
          viewModel: widget.viewModel.createReviewViewModel(
            itemIds.take(10).toList(),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showVocabularyTranslations(LearningItem item) {
    final languages = widget.viewModel.content!.languages;
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(item.text, style: BuleTextStyles.cardTitle),
        message: Padding(
          padding: const EdgeInsets.only(top: BuleSpacing.sm),
          child: Column(
            children: [
              for (final locale in widget.viewModel.preferences.knowLocales)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: BuleSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Text(_flag(locale), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: BuleSpacing.xs),
                      Expanded(
                        child: Text(
                          item.translations[locale]!,
                          textAlign: TextAlign.left,
                          style: BuleTextStyles.body.copyWith(
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                      Text(
                        languages
                            .firstWhere((language) => language.locale == locale)
                            .name,
                        style: BuleTextStyles.supporting.copyWith(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ),
    );
  }

  String _flag(String locale) => switch (locale) {
    'pt-BR' => '🇧🇷',
    'en-US' => '🇺🇸',
    'es-MX' => '🇲🇽',
    'fr-FR' => '🇫🇷',
    'id-ID' => '🇮🇩',
    'et-EE' => '🇪🇪',
    _ => '🌐',
  };

  Widget _placeholder(String title) => _listPage(
    title: title,
    intro:
        'This feature is part of the first release and will be connected in the next implementation slice.',
    children: const [
      CupertinoListTile(
        title: Text('No content yet'),
        subtitle: Text('Your offline learning data remains available.'),
      ),
    ],
  );

  Widget _listPage({
    required String title,
    required String intro,
    required List<Widget> children,
  }) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(middle: Text(title)),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Text(title, style: BuleTextStyles.pageTitle),
          const SizedBox(height: BuleSpacing.xs),
          Text(
            intro,
            style: BuleTextStyles.supporting.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: BuleSpacing.md),
          CupertinoListSection.insetGrouped(
            margin: EdgeInsets.zero,
            children: children,
          ),
        ],
      ),
    ),
  );

  String _languageName(String locale) => widget.viewModel.content!.languages
      .firstWhere((item) => item.locale == locale)
      .name;
  String _difficultyLabel(Difficulty value) => switch (value) {
    Difficulty.easy => 'Easy',
    Difficulty.moderate => 'Moderate',
    Difficulty.native => 'Native',
  };

  Color _destinationColor(int index) => switch (index) {
    0 => CupertinoColors.activeBlue,
    1 || 2 || 3 => CupertinoColors.systemTeal,
    4 => CupertinoColors.activeOrange,
    _ => CupertinoColors.systemPurple,
  };
}
