import 'package:flutter/cupertino.dart';

import '../../../domain/models/content_pack.dart';
import '../../../domain/models/learning_progress.dart';
import '../../core/bule_design.dart';
import '../../core/language_keyboard.dart';
import 'lesson_view_model.dart';

class LessonView extends StatefulWidget {
  const LessonView({
    super.key,
    required this.viewModel,
    this.showClickableTranslationTip = false,
    this.onClickableTranslationOpened,
  });
  final LessonViewModel viewModel;
  final bool showClickableTranslationTip;
  final Future<void> Function()? onClickableTranslationOpened;

  @override
  State<LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends State<LessonView> {
  final _answerController = TextEditingController();
  bool _translationTipOpened = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.initialize();
  }

  @override
  void dispose() {
    _answerController.dispose();
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) => CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.viewModel.lesson.title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: widget.viewModel.loading
                  ? null
                  : widget.viewModel.toggleAutoPlay,
              child: Icon(
                widget.viewModel.autoPlayAudio
                    ? CupertinoIcons.speaker_2_fill
                    : CupertinoIcons.speaker_slash_fill,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed:
                  widget.viewModel.loading ||
                      widget.viewModel.isComplete ||
                      !widget.viewModel.canShowNote
                  ? null
                  : _editNote,
              child: const Icon(CupertinoIcons.pencil),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: widget.viewModel.loading
            ? const Center(child: CupertinoActivityIndicator())
            : widget.viewModel.isComplete
            ? _completion()
            : _exercise(),
      ),
    ),
  );

  Widget _exercise() {
    final viewModel = widget.viewModel;
    final exercise = viewModel.currentExercise!;
    final item = viewModel.currentItem!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _progress(),
        const SizedBox(height: BuleSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: CupertinoColors.systemPurple.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(BuleRadius.header),
            ),
            child: Text(
              '${_toneLabel(item.register)} TONE',
              style: BuleTextStyles.eyebrow.copyWith(
                color: CupertinoColors.systemPurple,
              ),
            ),
          ),
        ),
        const SizedBox(height: BuleSpacing.sm),
        Text(
          switch (exercise.kind) {
            ExerciseKind.flashcard => 'FLASHCARD',
            ExerciseKind.typing => 'TYPE YOUR ANSWER',
            ExerciseKind.multipleChoice => 'CHOOSE THE RIGHT ANSWER',
          },
          style: BuleTextStyles.eyebrow.copyWith(
            color: exercise.kind == ExerciseKind.flashcard
                ? CupertinoColors.activeOrange
                : CupertinoColors.activeBlue,
          ),
        ),
        const SizedBox(height: BuleSpacing.xs),
        if (exercise.kind == ExerciseKind.flashcard)
          Row(
            children: [
              Expanded(child: Text(item.text, style: BuleTextStyles.pageTitle)),
              _speechButton(item.text),
            ],
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showAnswerSheet(item),
              child: Text(_typingPrompt(item), style: BuleTextStyles.pageTitle),
            ),
          ),
        if (exercise.kind != ExerciseKind.flashcard &&
            viewModel.missedItemIds.contains(item.id)) ...[
          const SizedBox(height: BuleSpacing.xs),
          Text(
            'ANSWER',
            style: BuleTextStyles.eyebrow.copyWith(
              color: CupertinoColors.activeOrange,
            ),
          ),
          const SizedBox(height: BuleSpacing.xxs),
          Row(
            children: [
              Expanded(child: Text(item.text, style: BuleTextStyles.cardTitle)),
              _speechButton(item.text),
            ],
          ),
        ],
        if (widget.showClickableTranslationTip &&
            !_translationTipOpened &&
            item.segments.any((segment) => segment.clickable)) ...[
          const SizedBox(height: BuleSpacing.sm),
          Container(
            padding: const EdgeInsets.all(BuleSpacing.sm),
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(BuleRadius.card),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.lightbulb_fill,
                  color: CupertinoColors.activeBlue,
                ),
                SizedBox(width: BuleSpacing.xs),
                Expanded(
                  child: Text(
                    'Tip: tap the prompt, then tap an underlined word or phrase to see its contextual translation.',
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: BuleSpacing.lg),
        _exerciseCard(exercise, item),
        const SizedBox(height: BuleSpacing.md),
        if (viewModel.canShowNote && viewModel.note.isNotEmpty)
          _notePreview(viewModel.note),
      ],
    );
  }

  Widget _progress() {
    final value = widget.viewModel.completion;
    return Semantics(
      label: 'Lesson progress ${(value * 100).round()} percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.viewModel.currentIndex + 1} of ${widget.viewModel.exercises.length}',
                style: BuleTextStyles.supporting.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              if (widget.viewModel.currentExercise?.kind !=
                  ExerciseKind.flashcard)
                Text(
                  '🔥 ${widget.viewModel.currentRunStreak} streak',
                  style: BuleTextStyles.supporting.copyWith(
                    color: CupertinoColors.activeOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: BuleSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(BuleRadius.header),
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: 8,
                    color: CupertinoColors.secondarySystemFill.resolveFrom(
                      context,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: constraints.maxWidth * value,
                    height: 8,
                    color: CupertinoColors.activeGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(Exercise exercise, LearningItem item) => Container(
    padding: const EdgeInsets.all(BuleSpacing.md),
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
      borderRadius: BorderRadius.circular(BuleRadius.card),
      border: Border.all(
        color: CupertinoColors.separator.resolveFrom(context),
        width: 0.5,
      ),
    ),
    child: switch (exercise.kind) {
      ExerciseKind.flashcard => _flashcard(item),
      ExerciseKind.typing => _typing(item),
      ExerciseKind.multipleChoice => _multipleChoice(item),
    },
  );

  Widget _flashcard(LearningItem item) {
    final viewModel = widget.viewModel;
    if (!viewModel.translationRevealed) {
      return CupertinoButton.filled(
        onPressed: viewModel.revealTranslation,
        child: const Text('Reveal translations'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _translations(item),
        const SizedBox(height: BuleSpacing.md),
        if (!viewModel.flashcardRated) ...[
          const Text('Did you know this?', style: BuleTextStyles.cardTitle),
          const SizedBox(height: BuleSpacing.sm),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.secondarySystemFill.resolveFrom(
                    context,
                  ),
                  onPressed: () => viewModel.rateFlashcard(false),
                  child: const Text('Not yet'),
                ),
              ),
              const SizedBox(width: BuleSpacing.sm),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: () => viewModel.rateFlashcard(true),
                  child: const Text('I know it'),
                ),
              ),
            ],
          ),
        ] else ...[
          Text(
            viewModel.flashcardKnown!
                ? 'You already know this word or phrase. Great job!'
                : 'You’re still learning this word or phrase. It has been added to your practice vocabulary.',
            style: BuleTextStyles.supporting,
          ),
          const SizedBox(height: BuleSpacing.sm),
          CupertinoButton.filled(
            onPressed: _next,
            child: const Text('Continue'),
          ),
        ],
      ],
    );
  }

  Widget _typing(LearningItem item) {
    final viewModel = widget.viewModel;
    final answered = viewModel.feedback != AnswerFeedback.none;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoTextField(
          controller: _answerController,
          enabled: !answered,
          placeholder: 'Enter ${item.kind}',
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(BuleRadius.card),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: answered ? null : (_) => _submit(),
        ),
        const SizedBox(height: BuleSpacing.xs),
        LanguageKeyboard(
          locale: item.locale,
          controller: _answerController,
          expectedText: item.acceptedAnswers.join(' '),
        ),
        const SizedBox(height: BuleSpacing.sm),
        if (!answered)
          CupertinoButton.filled(
            onPressed: _submit,
            child: const Text('Check answer'),
          ),
        if (answered) ...[
          _feedbackAndNext(item),
          if (viewModel.feedback == AnswerFeedback.incorrect) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 32),
                onPressed: viewModel.acceptSelfAssessment,
                child: const Text(
                  'My answer meant the same thing',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _multipleChoice(LearningItem item) {
    final viewModel = widget.viewModel;
    final answered = viewModel.feedback != AnswerFeedback.none;
    final correctAnswer = item.acceptedAnswers.isEmpty
        ? item.text
        : item.acceptedAnswers.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final choice in viewModel.currentChoices) ...[
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: answered && choice == correctAnswer
                      ? CupertinoColors.activeGreen
                      : answered && choice == viewModel.submittedAnswer
                      ? CupertinoColors.destructiveRed
                      : !answered && choice == viewModel.selectedChoice
                      ? CupertinoColors.activeBlue.withValues(alpha: .18)
                      : CupertinoColors.systemBackground.resolveFrom(context),
                  disabledColor: choice == correctAnswer
                      ? CupertinoColors.activeGreen.withValues(alpha: 0.72)
                      : CupertinoColors.secondarySystemFill.resolveFrom(
                          context,
                        ),
                  borderRadius: BorderRadius.circular(BuleRadius.card),
                  onPressed: answered
                      ? null
                      : () => viewModel.selectChoice(choice),
                  child: Text(
                    choice,
                    style: TextStyle(
                      color:
                          answered &&
                              (choice == correctAnswer ||
                                  choice == viewModel.submittedAnswer)
                          ? CupertinoColors.white
                          : CupertinoColors.label.resolveFrom(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _speechButton(choice),
            ],
          ),
          const SizedBox(height: BuleSpacing.xs),
        ],
        if (!answered) ...[
          const SizedBox(height: BuleSpacing.xs),
          CupertinoButton.filled(
            onPressed: viewModel.selectedChoice == null
                ? null
                : () => viewModel.submitChoice(viewModel.selectedChoice!),
            child: const Text('Confirm answer'),
          ),
        ],
        if (answered) _feedbackAndNext(item),
        if (viewModel.feedback == AnswerFeedback.incorrect)
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(0, 32),
              onPressed: viewModel.acceptSelfAssessment,
              child: const Text(
                'My answer meant the same thing',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _feedbackAndNext(LearningItem item) {
    final feedback = widget.viewModel.feedback;
    final correct =
        feedback == AnswerFeedback.correct ||
        feedback == AnswerFeedback.almostCorrect;
    final almostCorrect = feedback == AnswerFeedback.almostCorrect;
    final selfAssessed = feedback == AnswerFeedback.selfAssessed;
    final accent = feedback == AnswerFeedback.correct
        ? CupertinoColors.activeGreen
        : almostCorrect
        ? CupertinoColors.activeBlue
        : selfAssessed
        ? CupertinoColors.systemTeal
        : CupertinoColors.activeOrange;
    final heading = almostCorrect
        ? 'Almost perfect!'
        : correct
        ? 'Excellent!'
        : selfAssessed
        ? 'Thanks for checking'
        : 'Keep going!';
    final message = almostCorrect
        ? 'Your answer is at least 80% similar, so it counts as correct. Check the difference below.'
        : correct
        ? 'That’s the right answer.'
        : selfAssessed
        ? 'We saved your review without changing your mastery score.'
        : 'You’ll see this word or phrase more often so you can practice it again.';
    return Padding(
      padding: const EdgeInsets.only(top: BuleSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(BuleSpacing.md),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(BuleRadius.card),
              border: Border.all(color: accent),
            ),
            child: Column(
              children: [
                Icon(
                  feedback == AnswerFeedback.correct || selfAssessed
                      ? CupertinoIcons.check_mark_circled_solid
                      : almostCorrect
                      ? CupertinoIcons.pencil_circle_fill
                      : CupertinoIcons.arrow_counterclockwise_circle_fill,
                  color: accent,
                  size: 40,
                ),
                const SizedBox(height: BuleSpacing.xs),
                Text(heading, style: BuleTextStyles.cardTitle),
                const SizedBox(height: BuleSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: BuleTextStyles.body,
                ),
                const SizedBox(height: BuleSpacing.md),
                _answerComparison(
                  item,
                  highlightDifferences: almostCorrect || !correct,
                  accent: accent,
                ),
                if (!correct && !selfAssessed) ...[
                  const SizedBox(height: BuleSpacing.md),
                  _translations(item),
                ],
              ],
            ),
          ),
          const SizedBox(height: BuleSpacing.sm),
          CupertinoButton.filled(
            onPressed: _next,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _translations(LearningItem item) {
    final translations = widget.viewModel.knowLocales
        .map((locale) => (locale, item.translations[locale]))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final translation in translations)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _flag(translation.$1),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: BuleSpacing.xs),
                Expanded(
                  child: Text(
                    translation.$2!,
                    style: BuleTextStyles.body.copyWith(
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _answerComparison(
    LearningItem item, {
    required bool highlightDifferences,
    required Color accent,
  }) {
    final expected =
        widget.viewModel.gradeResult?.acceptedAnswer ??
        (item.acceptedAnswers.isEmpty ? item.text : item.acceptedAnswers.first);
    final submitted = widget.viewModel.submittedAnswer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BuleSpacing.sm),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(BuleRadius.card),
      ),
      child: Column(
        children: [
          Text(
            'CORRECT ANSWER',
            style: BuleTextStyles.eyebrow.copyWith(color: accent),
          ),
          const SizedBox(height: BuleSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  expected,
                  textAlign: TextAlign.center,
                  style: BuleTextStyles.pageTitle.copyWith(fontSize: 28),
                ),
              ),
              _speechButton(expected),
            ],
          ),
          if (highlightDifferences && submitted != null) ...[
            const SizedBox(height: BuleSpacing.sm),
            Text('Your answer', style: BuleTextStyles.supporting),
            const SizedBox(height: BuleSpacing.xxs),
            Text.rich(
              TextSpan(
                children: [
                  for (var index = 0; index < submitted.length; index++)
                    TextSpan(
                      text: submitted[index],
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color:
                            index < expected.length &&
                                submitted[index].toLowerCase() ==
                                    expected[index].toLowerCase()
                            ? CupertinoColors.label.resolveFrom(context)
                            : CupertinoColors.destructiveRed,
                        decoration:
                            index < expected.length &&
                                submitted[index].toLowerCase() ==
                                    expected[index].toLowerCase()
                            ? null
                            : TextDecoration.underline,
                      ),
                    ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _notePreview(String note) => Container(
    padding: const EdgeInsets.all(BuleSpacing.sm),
    decoration: BoxDecoration(
      color: CupertinoColors.systemOrange
          .resolveFrom(context)
          .withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(BuleRadius.card),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(CupertinoIcons.pencil, color: CupertinoColors.activeOrange),
        const SizedBox(width: BuleSpacing.xs),
        Expanded(child: Text(note, style: BuleTextStyles.supporting)),
      ],
    ),
  );

  Widget _completion() {
    final viewModel = widget.viewModel;
    final practiced = viewModel.outcomes
        .map((outcome) => outcome.itemId)
        .toSet()
        .map((itemId) => viewModel.content.items[itemId])
        .whereType<LearningItem>();
    return ListView(
      padding: const EdgeInsets.all(BuleSpacing.lg),
      children: [
        const Icon(
          CupertinoIcons.check_mark_circled_solid,
          color: CupertinoColors.activeGreen,
          size: 52,
        ),
        const SizedBox(height: BuleSpacing.md),
        const Text(
          'Lesson complete',
          textAlign: TextAlign.center,
          style: BuleTextStyles.pageTitle,
        ),
        const SizedBox(height: BuleSpacing.xs),
        Text(
          'Best streak: 🔥 ${viewModel.bestRunStreak}',
          textAlign: TextAlign.center,
          style: BuleTextStyles.supporting,
        ),
        const SizedBox(height: BuleSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Correct',
                viewModel.correctCount,
                CupertinoColors.activeGreen,
              ),
            ),
            const SizedBox(width: BuleSpacing.sm),
            Expanded(
              child: _summaryCard(
                'Practice again',
                viewModel.incorrectCount,
                CupertinoColors.activeOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: BuleSpacing.lg),
        const Text('What you practiced', style: BuleTextStyles.cardTitle),
        const SizedBox(height: BuleSpacing.sm),
        for (final item in practiced)
          Container(
            margin: const EdgeInsets.only(bottom: BuleSpacing.xs),
            padding: const EdgeInsets.all(BuleSpacing.sm),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemBackground.resolveFrom(
                context,
              ),
              borderRadius: BorderRadius.circular(BuleRadius.card),
            ),
            child: Row(
              children: [
                Icon(
                  viewModel.outcomes
                          .lastWhere((outcome) => outcome.itemId == item.id)
                          .correct
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.arrow_counterclockwise_circle_fill,
                  color:
                      viewModel.outcomes
                          .lastWhere((outcome) => outcome.itemId == item.id)
                          .correct
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.activeOrange,
                ),
                const SizedBox(width: BuleSpacing.sm),
                Expanded(
                  child: Text(item.text, style: BuleTextStyles.cardTitle),
                ),
                _speechButton(item.text),
                Flexible(
                  child: Text(
                    _typingPrompt(item),
                    textAlign: TextAlign.end,
                    style: BuleTextStyles.supporting,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: BuleSpacing.md),
        CupertinoButton.filled(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, int value, Color color) => Container(
    padding: const EdgeInsets.all(BuleSpacing.md),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(BuleRadius.card),
      border: Border.all(color: color),
    ),
    child: Column(
      children: [
        Text('$value', style: BuleTextStyles.pageTitle.copyWith(color: color)),
        const SizedBox(height: BuleSpacing.xxs),
        Text(label, style: BuleTextStyles.supporting),
      ],
    ),
  );

  String _typingPrompt(LearningItem item) {
    for (final locale in widget.viewModel.knowLocales) {
      final translation = item.translations[locale];
      if (translation != null) return translation;
    }
    return 'Translate this ${item.kind}';
  }

  Future<void> _submit() async {
    if (_answerController.text.trim().isEmpty) return;
    await widget.viewModel.submitTypedAnswer(_answerController.text);
  }

  String _toneLabel(String register) {
    if (register.contains('informal')) return 'INFORMAL';
    if (register.contains('formal') || register.contains('polite')) {
      return 'FORMAL';
    }
    return 'FORMAL';
  }

  Future<void> _next() async {
    _answerController.clear();
    await widget.viewModel.next();
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: widget.viewModel.note);
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Lesson note'),
        message: Padding(
          padding: const EdgeInsets.only(top: BuleSpacing.sm),
          child: CupertinoTextField(
            controller: controller,
            placeholder:
                'Add a private note for this word or phrase (up to $maxPersonalNoteLength characters)',
            minLines: 3,
            maxLines: 6,
            maxLength: maxPersonalNoteLength,
            padding: const EdgeInsets.all(14),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              await widget.viewModel.saveNote(controller.text);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _showAnswerSheet(LearningItem item) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Answer'),
        message: Padding(
          padding: const EdgeInsets.only(top: BuleSpacing.sm),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: _segmentedAnswer(item)),
                  _speechButton(item.text),
                ],
              ),
              const SizedBox(height: BuleSpacing.sm),
              Text(
                'Tap a word or expression to see only its contextual translations.',
                style: BuleTextStyles.supporting.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
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

  Widget _segmentedAnswer(LearningItem item) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final segment in item.segments)
        if (segment.clickable)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            minimumSize: Size.zero,
            onPressed: () => _showSegmentTranslations(segment),
            child: Text(
              segment.text,
              style: BuleTextStyles.cardTitle.copyWith(
                color: CupertinoColors.activeBlue,
                decoration: TextDecoration.underline,
                decorationColor: CupertinoColors.activeBlue,
              ),
            ),
          )
        else
          Text(segment.text, style: BuleTextStyles.cardTitle),
    ],
  );

  Future<void> _showSegmentTranslations(LearningSegment segment) {
    widget.onClickableTranslationOpened?.call();
    setState(() => _translationTipOpened = true);
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(segment.text, style: BuleTextStyles.cardTitle),
            ),
            _speechButton(segment.text),
          ],
        ),
        message: Padding(
          padding: const EdgeInsets.only(top: BuleSpacing.sm),
          child: Column(
            children: [
              for (final locale in widget.viewModel.knowLocales)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(_flag(locale), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: BuleSpacing.xs),
                      Expanded(
                        child: Text(
                          segment.translations[locale]!,
                          textAlign: TextAlign.left,
                          style: BuleTextStyles.body,
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

  Widget _speechButton(String text) {
    final playing = widget.viewModel.audioPlaying;
    final playingThis = playing && widget.viewModel.speakingText == text;
    return Semantics(
      label: playingThis ? 'Playing $text' : 'Listen to $text',
      button: true,
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
        onPressed: playing ? null : () => widget.viewModel.speakText(text),
        child: playingThis
            ? const CupertinoActivityIndicator(radius: 10)
            : const Icon(CupertinoIcons.speaker_2_fill, size: 21),
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
}
