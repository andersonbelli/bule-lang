import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../../app/app_view_model.dart';
import '../../../domain/models/content_pack.dart';
import '../../../domain/models/learning_progress.dart';
import '../../../domain/models/situation_progress.dart';
import '../../core/bule_design.dart';
import '../learning/lesson_view.dart';
import '../profile/profile_view.dart';
import '../profile/speaker_selection_view.dart';
import '../situations/situation_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.viewModel});
  final AppViewModel viewModel;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.preloadLearnVoice());
  }

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
            header: Column(
              children: [
                Image.asset('assets/app_icon.png', width: 48, height: 48),
                const SizedBox(height: BuleSpacing.xs),
                Text(
                  'BULE . LANGUAGE LEARNING',
                  textAlign: TextAlign.center,
                  style: BuleTextStyles.eyebrow.copyWith(
                    color: CupertinoColors.activeGreen,
                  ),
                ),
              ],
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
        final recommendedDifficulty = _recommendedDifficulty;
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
                _streakCard(progress),
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
                  for (final difficulty in Difficulty.values)
                    if (available.any(
                      (lesson) => lesson.difficulty == difficulty,
                    )) ...[
                      CupertinoListSection.insetGrouped(
                        margin: EdgeInsets.zero,
                        header: Text(
                          difficulty == recommendedDifficulty
                              ? 'RECOMMENDED FOR YOUR LEVEL'
                              : '${_difficultyLabel(difficulty).toUpperCase()} LESSONS',
                        ),
                        children: [
                          for (final lesson in available.where(
                            (lesson) => lesson.difficulty == difficulty,
                          ))
                            _lessonTile(lesson, 0),
                        ],
                      ),
                      const SizedBox(height: BuleSpacing.md),
                    ],
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
    final situations =
        widget.viewModel.content!.situations
            .where((item) => item.locale == locale)
            .toList()
          ..sort((left, right) {
            final target = _recommendedDifficulty.index;
            return (left.difficulty.index - target).abs().compareTo(
              (right.difficulty.index - target).abs(),
            );
          });
    return FutureBuilder<SituationProgress>(
      future: widget.viewModel.loadSituationProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(middle: Text('Situations')),
            child: SafeArea(child: Center(child: CupertinoActivityIndicator())),
          );
        }
        final progress = snapshot.data!;
        return _listPage(
          title: 'Situations',
          intro:
              'Suggested for your ${widget.viewModel.preferences.placementLevel} level first. Feedback, voting, and comments unlock after completion.',
          children: [
            for (final situation in situations)
              CupertinoListTile(
                leading: Icon(
                  (progress.activities[situation.id]?.completions ?? 0) > 0
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.chat_bubble_text,
                  color:
                      (progress.activities[situation.id]?.completions ?? 0) > 0
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemTeal,
                ),
                title: Text(situation.title, style: BuleTextStyles.cardTitle),
                subtitle: Text(
                  _situationSubtitle(situation, progress),
                  style: BuleTextStyles.supporting.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                trailing: const CupertinoListTileChevron(),
                onTap: () async {
                  await Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => SituationView(
                        viewModel: widget.viewModel.createSituationViewModel(
                          situation,
                        ),
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              ),
          ],
        );
      },
    );
  }

  String _situationSubtitle(Situation situation, SituationProgress progress) {
    final completions = progress.activities[situation.id]?.completions ?? 0;
    final recommended = situation.difficulty == _recommendedDifficulty
        ? 'Suggested · '
        : '';
    final details =
        '$recommended${_difficultyLabel(situation.difficulty)} · ${situation.estimatedMinutes} min · Authored';
    return completions == 0
        ? details
        : '$details · Completed $completions ${completions == 1 ? 'time' : 'times'}';
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
          ? 'Completed $completionCount ${completionCount == 1 ? 'time' : 'times'} · ${_lessonTone(lesson)} tone'
          : '${lesson.itemIds.length} words and phrases · ${lesson.estimatedMinutes} min · ${_lessonTone(lesson)} tone',
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
            showClickableTranslationTip:
                !widget.viewModel.preferences.clickableTranslationTipSeen,
            onClickableTranslationOpened:
                widget.viewModel.markClickableTranslationTipSeen,
          ),
        ),
      );
      final latest = await widget.viewModel.loadLearningProgress();
      if (mounted &&
          latest.lessonCompletions.values.fold<int>(
                0,
                (sum, count) => sum + count,
              ) ==
              1 &&
          !widget.viewModel.preferences.voiceTipShown) {
        await _showVoiceTip();
      }
      if (mounted) setState(() {});
    },
  );

  Widget _streakCard(LearningProgress progress) {
    final isBest =
        progress.currentDayStreak > 0 &&
        progress.currentDayStreak == progress.bestDayStreak;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(BuleSpacing.md),
      decoration: BoxDecoration(
        color:
            (isBest ? CupertinoColors.systemOrange : CupertinoColors.systemGrey)
                .withValues(alpha: .12),
        borderRadius: BorderRadius.circular(BuleRadius.card),
      ),
      child: Row(
        children: [
          Text(isBest ? '🔥🎉' : '🔥', style: const TextStyle(fontSize: 30)),
          const SizedBox(width: BuleSpacing.sm),
          Expanded(
            child: Text(
              isBest
                  ? '${progress.currentDayStreak} ${progress.currentDayStreak == 1 ? 'day' : 'days'} — your best streak so far!'
                  : '${progress.currentDayStreak} day streak\nBest: ${progress.bestDayStreak} days',
              style: BuleTextStyles.cardTitle,
            ),
          ),
        ],
      ),
    );
  }

  String _lessonTone(Lesson lesson) {
    final registers = lesson.itemIds
        .map((id) => widget.viewModel.content!.items[id]?.register ?? 'neutral')
        .toSet();
    final hasInformal = registers.any((value) => value.contains('informal'));
    final hasFormal = registers.any(
      (value) => value == 'formal' || value.contains('polite'),
    );
    if (hasInformal) return 'Informal';
    if (hasFormal) return 'Formal';
    return 'Formal';
  }

  Future<void> _showVoiceTip() async {
    await widget.viewModel.markVoiceTipShown();
    if (!mounted) return;
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => SpeakerSelectionView(viewModel: widget.viewModel),
      ),
    );
  }

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
      final currentLocale = widget.viewModel.preferences.learnLocale!;
      final currentEntries = _vocabularyEntriesForLocale(
        entries,
        currentLocale,
      );
      final previousLanguages = widget.viewModel.content!.languages.where(
        (language) =>
            language.locale != currentLocale &&
            _vocabularyEntriesForLocale(entries, language.locale).isNotEmpty,
      );
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Vocabulary')),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              const Text('Vocabulary', style: BuleTextStyles.pageTitle),
              const SizedBox(height: BuleSpacing.xs),
              Text(
                '${entries.length} encountered words and phrases. Your current language appears first.',
                style: BuleTextStyles.supporting.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: BuleSpacing.md),
              _vocabularyLanguageHeader(
                currentLocale,
                currentEntries.length,
                current: true,
              ),
              const SizedBox(height: BuleSpacing.sm),
              if (currentEntries.isEmpty)
                _emptyVocabularyLanguage()
              else
                ..._vocabularyLessonSections(currentEntries, currentLocale),
              if (previousLanguages.isNotEmpty) ...[
                const SizedBox(height: BuleSpacing.lg),
                Text(
                  'PREVIOUS LANGUAGES',
                  style: BuleTextStyles.eyebrow.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: BuleSpacing.sm),
                for (final language in previousLanguages) ...[
                  _vocabularyLanguageHeader(
                    language.locale,
                    _vocabularyEntriesForLocale(
                      entries,
                      language.locale,
                    ).length,
                    current: false,
                  ),
                  const SizedBox(height: BuleSpacing.sm),
                  ..._vocabularyLessonSections(
                    _vocabularyEntriesForLocale(entries, language.locale),
                    language.locale,
                  ),
                  const SizedBox(height: BuleSpacing.md),
                ],
              ],
            ],
          ),
        ),
      );
    },
  );

  List<ItemProgress> _vocabularyEntriesForLocale(
    List<ItemProgress> entries,
    String locale,
  ) => entries
      .where(
        (entry) =>
            widget.viewModel.content!.items[entry.itemId]?.locale == locale,
      )
      .toList();

  List<Widget> _vocabularyLessonSections(
    List<ItemProgress> entries,
    String locale,
  ) {
    final assigned = <String>{};
    final sections = <Widget>[];
    final lessons = widget.viewModel.content!.lessons.where(
      (lesson) => lesson.locale == locale,
    );
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
          children: [for (final entry in lessonEntries) _vocabularyTile(entry)],
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
    return sections;
  }

  Widget _vocabularyLanguageHeader(
    String locale,
    int count, {
    required bool current,
  }) {
    final language = widget.viewModel.content!.languages.firstWhere(
      (language) => language.locale == locale,
    );
    final accent = current
        ? CupertinoColors.activeGreen
        : CupertinoColors.systemPurple;
    return Container(
      padding: const EdgeInsets.all(BuleSpacing.md),
      decoration: BoxDecoration(
        color: accent.resolveFrom(context).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(BuleRadius.card),
        border: Border.all(
          color: accent.resolveFrom(context).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Text(_flag(locale), style: const TextStyle(fontSize: 30)),
          const SizedBox(width: BuleSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current ? 'CURRENTLY LEARNING' : 'SAVED LANGUAGE',
                  style: BuleTextStyles.eyebrow.copyWith(color: accent),
                ),
                const SizedBox(height: BuleSpacing.xxs),
                Text(
                  '${language.name} · ${language.variant}',
                  style: BuleTextStyles.cardTitle,
                ),
              ],
            ),
          ),
          Text(
            '$count',
            style: BuleTextStyles.cardTitle.copyWith(color: accent),
          ),
        ],
      ),
    );
  }

  Widget _emptyVocabularyLanguage() => Container(
    margin: const EdgeInsets.only(bottom: BuleSpacing.md),
    padding: const EdgeInsets.all(BuleSpacing.md),
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
      borderRadius: BorderRadius.circular(BuleRadius.card),
    ),
    child: Text(
      'Start a lesson to add vocabulary for this language.',
      style: BuleTextStyles.supporting.copyWith(
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    ),
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
      trailing:
          item != null &&
              item.locale == widget.viewModel.preferences.learnLocale
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [_speechButton(item), const CupertinoListTileChevron()],
            )
          : const CupertinoListTileChevron(),
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
          showClickableTranslationTip:
              !widget.viewModel.preferences.clickableTranslationTipSeen,
          onClickableTranslationOpened:
              widget.viewModel.markClickableTranslationTipSeen,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showVocabularyTranslations(LearningItem item) async {
    final languages = widget.viewModel.content!.languages;
    final progress = await widget.viewModel.loadLearningProgress();
    if (!mounted) return;
    final note = progress.notes[item.id] ?? '';
    final editNote = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(item.text, style: BuleTextStyles.cardTitle)),
            if (item.locale == widget.viewModel.preferences.learnLocale)
              _speechButton(item),
          ],
        ),
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
              if (note.isNotEmpty) ...[
                const SizedBox(height: BuleSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(BuleSpacing.sm),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemOrange
                        .resolveFrom(context)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(BuleRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERSONAL NOTE',
                        style: BuleTextStyles.eyebrow.copyWith(
                          color: CupertinoColors.activeOrange,
                        ),
                      ),
                      const SizedBox(height: BuleSpacing.xxs),
                      Text(note, style: BuleTextStyles.supporting),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              note.isEmpty ? 'Add personal note' : 'Edit personal note',
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Close'),
        ),
      ),
    );
    if (editNote == true && mounted) {
      await _editVocabularyNote(item, note);
    }
  }

  Future<void> _editVocabularyNote(
    LearningItem item,
    String currentNote,
  ) async {
    final controller = TextEditingController(text: currentNote);
    final saved = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Note for ${item.text}'),
        message: Padding(
          padding: const EdgeInsets.only(top: BuleSpacing.sm),
          child: CupertinoTextField(
            controller: controller,
            placeholder:
                'Add a private note (up to $maxPersonalNoteLength characters)',
            minLines: 3,
            maxLines: 6,
            maxLength: maxPersonalNoteLength,
            padding: const EdgeInsets.all(14),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              await widget.viewModel.savePersonalNote(item.id, controller.text);
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ),
    );
    controller.dispose();
    if (saved == true && mounted) setState(() {});
  }

  Widget _speechButton(LearningItem item) {
    final playing = widget.viewModel.audioPlaying;
    final playingThis = playing && widget.viewModel.speakingText == item.text;
    return Semantics(
      label: playingThis ? 'Playing ${item.text}' : 'Listen to ${item.text}',
      button: true,
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
        onPressed: playing
            ? null
            : () => widget.viewModel.speakLearningItem(item),
        child: playingThis
            ? const CupertinoActivityIndicator(radius: 10)
            : const Icon(CupertinoIcons.speaker_2_fill, size: 20),
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

  Difficulty get _recommendedDifficulty =>
      switch (widget.viewModel.preferences.placementLevel) {
        'advanced' => Difficulty.native,
        'intermediate' => Difficulty.moderate,
        _ => Difficulty.easy,
      };

  Color _destinationColor(int index) => switch (index) {
    0 => CupertinoColors.activeBlue,
    1 || 2 || 3 => CupertinoColors.systemTeal,
    4 => CupertinoColors.activeOrange,
    _ => CupertinoColors.systemPurple,
  };
}
