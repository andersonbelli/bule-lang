import 'package:flutter/cupertino.dart';

import '../../../domain/models/content_pack.dart';
import '../../../domain/models/situation_progress.dart';
import '../../core/bule_design.dart';
import '../../core/language_keyboard.dart';
import 'situation_view_model.dart';

class SituationView extends StatefulWidget {
  const SituationView({super.key, required this.viewModel});

  final SituationViewModel viewModel;

  @override
  State<SituationView> createState() => _SituationViewState();
}

class _SituationViewState extends State<SituationView> {
  final _answerController = TextEditingController();

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
        middle: Text(widget.viewModel.situation.title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.viewModel.toggleAutoPlay,
          child: Icon(
            widget.viewModel.autoPlayAudio
                ? CupertinoIcons.speaker_2_fill
                : CupertinoIcons.speaker_slash_fill,
          ),
        ),
      ),
      child: SafeArea(
        child: widget.viewModel.loading
            ? const Center(child: CupertinoActivityIndicator())
            : widget.viewModel.isComplete
            ? _completion()
            : _practice(),
      ),
    ),
  );

  Widget _practice() {
    final viewModel = widget.viewModel;
    final turn = viewModel.currentTurn!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemFill.resolveFrom(
                      context,
                    ),
                    borderRadius: BorderRadius.circular(BuleRadius.header),
                  ),
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: constraints.maxWidth * viewModel.completion,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen,
                      borderRadius: BorderRadius.circular(BuleRadius.header),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: BuleSpacing.sm),
            Text(
              '${viewModel.currentIndex + 1}/${viewModel.situation.turns.length}',
              style: BuleTextStyles.supporting,
            ),
          ],
        ),
        const SizedBox(height: BuleSpacing.md),
        for (final transcriptTurn in viewModel.transcript)
          _conversationBubble(transcriptTurn),
        if (turn.role == SituationRole.computer) ...[
          const SizedBox(height: BuleSpacing.sm),
          CupertinoButton.filled(
            onPressed: viewModel.next,
            child: const Text('Reply'),
          ),
        ] else
          _learnerTurn(turn),
      ],
    );
  }

  Widget _conversationBubble(SituationTurn turn) {
    final learner = turn.role == SituationRole.learner;
    final character = Text(
      learner ? '🙂' : '🧑',
      style: const TextStyle(fontSize: 28),
      semanticsLabel: learner ? 'Learner' : 'Conversation partner',
    );
    final bubble = Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(BuleSpacing.sm),
        decoration: BoxDecoration(
          color:
              (learner
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemTeal)
                  .withValues(alpha: learner ? 0.12 : 0.10),
          borderRadius: BorderRadius.circular(BuleRadius.card),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(turn.text, style: BuleTextStyles.body)),
            _speechButton(turn.text),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: BuleSpacing.sm),
      child: Row(
        mainAxisAlignment: learner
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: learner
            ? [bubble, const SizedBox(width: BuleSpacing.xs), character]
            : [character, const SizedBox(width: BuleSpacing.xs), bubble],
      ),
    );
  }

  Widget _learnerTurn(SituationTurn turn) {
    final viewModel = widget.viewModel;
    return Container(
      padding: const EdgeInsets.all(BuleSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(BuleRadius.card),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🙂', style: TextStyle(fontSize: 24)),
              const SizedBox(width: BuleSpacing.xs),
              Text(
                'YOUR TURN',
                style: BuleTextStyles.eyebrow.copyWith(
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: BuleSpacing.xs),
          Text(viewModel.promptFor(turn), style: BuleTextStyles.cardTitle),
          const SizedBox(height: BuleSpacing.sm),
          CupertinoTextField(
            controller: _answerController,
            enabled: !viewModel.responseAccepted,
            placeholder: 'Type what you would say',
            minLines: 2,
            maxLines: 4,
            padding: const EdgeInsets.all(14),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: BuleSpacing.xs),
          LanguageKeyboard(
            locale: viewModel.situation.locale,
            controller: _answerController,
            expectedText: turn.acceptedAnswers.join(' '),
          ),
          const SizedBox(height: BuleSpacing.sm),
          if (!viewModel.responseAccepted)
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    color: CupertinoColors.secondarySystemFill.resolveFrom(
                      context,
                    ),
                    onPressed: viewModel.showHelp,
                    child: const Text('Help'),
                  ),
                ),
                const SizedBox(width: BuleSpacing.sm),
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: _answerController.text.trim().isEmpty
                        ? null
                        : _submit,
                    child: const Text('Check reply'),
                  ),
                ),
              ],
            ),
          if (viewModel.lastAnswerCorrect == false) ...[
            const SizedBox(height: BuleSpacing.sm),
            Text(
              'Not quite. Try again, or use Help to see a natural reply.',
              style: BuleTextStyles.supporting.copyWith(
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ],
          if (viewModel.helpVisible) ...[
            const SizedBox(height: BuleSpacing.sm),
            Container(
              padding: const EdgeInsets.all(BuleSpacing.sm),
              decoration: BoxDecoration(
                color: CupertinoColors.systemOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(BuleRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('SUGGESTED REPLY', style: BuleTextStyles.eyebrow),
                  const SizedBox(height: BuleSpacing.xxs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(turn.text, style: BuleTextStyles.cardTitle),
                      ),
                      _speechButton(turn.text),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (viewModel.responseAccepted) ...[
            const SizedBox(height: BuleSpacing.sm),
            Text(
              viewModel.currentTurnUsedHelp
                  ? 'Reply accepted with help.'
                  : 'Great reply!',
              style: BuleTextStyles.cardTitle.copyWith(
                color: CupertinoColors.activeGreen,
              ),
            ),
            const SizedBox(height: BuleSpacing.sm),
            CupertinoButton.filled(
              onPressed: _next,
              child: const Text('Continue'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _completion() {
    final viewModel = widget.viewModel;
    return ListView(
      padding: const EdgeInsets.all(BuleSpacing.md),
      children: [
        const Icon(
          CupertinoIcons.check_mark_circled_solid,
          color: CupertinoColors.activeGreen,
          size: 52,
        ),
        const SizedBox(height: BuleSpacing.sm),
        const Text(
          'Situation complete',
          textAlign: TextAlign.center,
          style: BuleTextStyles.pageTitle,
        ),
        const SizedBox(height: BuleSpacing.xs),
        Text(
          viewModel.usedHelp
              ? 'Completed with help. Try it again when you are ready.'
              : 'You completed the conversation without help.',
          textAlign: TextAlign.center,
          style: BuleTextStyles.supporting,
        ),
        const SizedBox(height: BuleSpacing.lg),
        const Text(
          'Vocabulary from this Situation',
          style: BuleTextStyles.cardTitle,
        ),
        const SizedBox(height: BuleSpacing.sm),
        CupertinoListSection.insetGrouped(
          margin: EdgeInsets.zero,
          children: [
            for (final item in viewModel.vocabulary)
              CupertinoListTile(
                title: Text(item.text),
                trailing: const CupertinoListTileChevron(),
                onTap: () => _showVocabulary(item),
              ),
          ],
        ),
        const SizedBox(height: BuleSpacing.lg),
        const Text('Feedback', style: BuleTextStyles.cardTitle),
        const SizedBox(height: BuleSpacing.xs),
        Text(
          'Voting and comments are available after completion.',
          style: BuleTextStyles.supporting,
        ),
        const SizedBox(height: BuleSpacing.sm),
        Row(
          children: [
            Expanded(
              child: CupertinoButton(
                color: viewModel.activity.vote == 1
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.secondarySystemFill.resolveFrom(context),
                onPressed: () => viewModel.vote(1),
                child: const Icon(CupertinoIcons.hand_thumbsup),
              ),
            ),
            const SizedBox(width: BuleSpacing.sm),
            Expanded(
              child: CupertinoButton(
                color: viewModel.activity.vote == -1
                    ? CupertinoColors.activeOrange
                    : CupertinoColors.secondarySystemFill.resolveFrom(context),
                onPressed: () => viewModel.vote(-1),
                child: const Icon(CupertinoIcons.hand_thumbsdown),
              ),
            ),
          ],
        ),
        const SizedBox(height: BuleSpacing.md),
        CupertinoButton.filled(
          onPressed: () => _addComment(),
          child: const Text('Add comment'),
        ),
        const SizedBox(height: BuleSpacing.sm),
        for (final comment in viewModel.activity.comments.where(
          (comment) => comment.parentId == null,
        ))
          _comment(comment),
        const SizedBox(height: BuleSpacing.lg),
        CupertinoButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _comment(SituationComment comment) => Container(
    margin: const EdgeInsets.only(bottom: BuleSpacing.sm),
    padding: const EdgeInsets.all(BuleSpacing.sm),
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
      borderRadius: BorderRadius.circular(BuleRadius.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(comment.body, style: BuleTextStyles.body),
        CupertinoButton(
          padding: const EdgeInsets.only(top: 6),
          minimumSize: Size.zero,
          onPressed: () => _addComment(parentId: comment.id),
          child: const Text('Reply', style: TextStyle(fontSize: 13)),
        ),
        for (final reply in widget.viewModel.activity.comments.where(
          (reply) => reply.parentId == comment.id,
        ))
          Padding(
            padding: const EdgeInsets.only(
              left: BuleSpacing.md,
              top: BuleSpacing.xs,
            ),
            child: Text('↳ ${reply.body}', style: BuleTextStyles.supporting),
          ),
      ],
    ),
  );

  Widget _speechButton(String text) {
    final playing = widget.viewModel.audioPlaying;
    final playingThis = playing && widget.viewModel.speakingText == text;
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      minimumSize: const Size(36, 36),
      onPressed: playing ? null : () => widget.viewModel.speak(text),
      child: playingThis
          ? const CupertinoActivityIndicator(radius: 10)
          : const Icon(CupertinoIcons.speaker_2_fill, size: 20),
    );
  }

  Future<void> _submit() async {
    if (_answerController.text.trim().isEmpty) return;
    await widget.viewModel.submit(_answerController.text);
  }

  Future<void> _next() async {
    _answerController.clear();
    await widget.viewModel.next();
  }

  Future<void> _showVocabulary(LearningItem item) =>
      showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(item.text),
          message: Column(
            children: [
              for (final locale in widget.viewModel.knowLocales)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('${_flag(locale)} ${item.translations[locale]}'),
                ),
            ],
          ),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ),
      );

  Future<void> _addComment({String? parentId}) async {
    final controller = TextEditingController();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(parentId == null ? 'Add comment' : 'Reply'),
        message: CupertinoTextField(
          controller: controller,
          maxLength: 500,
          minLines: 2,
          maxLines: 5,
          placeholder: 'Share useful feedback',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await widget.viewModel.comment(
                controller.text,
                parentId: parentId,
              );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Post'),
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
