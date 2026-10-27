import 'package:flutter/cupertino.dart';

import '../../../app/app_view_model.dart';
import '../../../domain/models/content_pack.dart';
import '../../../domain/use_cases/grade_answer.dart';
import '../../core/bule_design.dart';

class PlacementView extends StatefulWidget {
  const PlacementView({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<PlacementView> createState() => _PlacementViewState();
}

class _PlacementViewState extends State<PlacementView> {
  final _controller = TextEditingController();
  final _grader = const GradeAnswer();
  List<LearningItem>? _questions;
  int _index = 0;
  int _correct = 0;
  bool _saving = false;
  bool _answerRevealed = false;
  GradeResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: const CupertinoNavigationBar(
      middle: Text('Your starting level'),
    ),
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(BuleSpacing.md),
            child: _questions == null ? _choice() : _test(),
          ),
        ),
      ),
    ),
  );

  Widget _choice() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Spacer(),
      const Icon(
        CupertinoIcons.gauge,
        size: 56,
        color: CupertinoColors.activeGreen,
      ),
      const SizedBox(height: BuleSpacing.md),
      const Text(
        'Where should we begin?',
        textAlign: TextAlign.center,
        style: BuleTextStyles.pageTitle,
      ),
      const SizedBox(height: BuleSpacing.xs),
      const Text(
        'Start from the basics, or take a short test that moves from easy to advanced lessons.',
        textAlign: TextAlign.center,
        style: BuleTextStyles.body,
      ),
      const SizedBox(height: BuleSpacing.lg),
      CupertinoButton.filled(
        onPressed: _saving ? null : () => _finish('beginner'),
        child: const Text('Start from zero'),
      ),
      const SizedBox(height: BuleSpacing.sm),
      CupertinoButton(
        color: CupertinoColors.secondarySystemFill.resolveFrom(context),
        onPressed: _startTest,
        child: const Text('Take the level test'),
      ),
      const Spacer(),
    ],
  );

  Widget _test() {
    final item = _questions![_index];
    final prompt = widget.viewModel.preferences.knowLocales
        .map((locale) => item.translations[locale])
        .whereType<String>()
        .firstOrNull;
    return ListView(
      children: [
        Text(
          'QUESTION ${_index + 1} OF ${_questions!.length}',
          style: BuleTextStyles.eyebrow,
        ),
        const SizedBox(height: BuleSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            color: CupertinoColors.secondarySystemFill.resolveFrom(context),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _index / _questions!.length,
              child: const ColoredBox(color: CupertinoColors.activeGreen),
            ),
          ),
        ),
        const SizedBox(height: BuleSpacing.xl),
        Text(
          prompt ?? 'Translate into ${item.locale}',
          style: BuleTextStyles.pageTitle,
        ),
        const SizedBox(height: BuleSpacing.xs),
        Text(
          'Difficulty increases as you continue.',
          style: BuleTextStyles.supporting,
        ),
        const SizedBox(height: BuleSpacing.lg),
        CupertinoTextField(
          controller: _controller,
          autofocus: true,
          enabled: _result == null,
          placeholder: 'Type your answer',
          padding: const EdgeInsets.all(14),
          onSubmitted: (_) => _submit(),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: BuleSpacing.sm),
        if (_result == null) ...[
          CupertinoButton.filled(
            onPressed: _controller.text.trim().isEmpty ? null : _submit,
            child: const Text('Check answer'),
          ),
          const SizedBox(height: BuleSpacing.xs),
          CupertinoButton(
            onPressed: _answerRevealed
                ? null
                : () => setState(() => _answerRevealed = true),
            child: const Text('Not sure'),
          ),
        ] else ...[
          _feedback(item),
          const SizedBox(height: BuleSpacing.sm),
          CupertinoButton.filled(
            onPressed: _continue,
            child: Text(
              _index + 1 == _questions!.length ? 'See my level' : 'Continue',
            ),
          ),
        ],
        if (_answerRevealed && _result == null) ...[
          const SizedBox(height: BuleSpacing.sm),
          Container(
            padding: const EdgeInsets.all(BuleSpacing.sm),
            decoration: BoxDecoration(
              color: CupertinoColors.systemOrange.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(BuleRadius.card),
            ),
            child: Text(
              'Correct answer: ${item.acceptedAnswers.firstOrNull ?? item.text}\nType an answer above to continue.',
              style: BuleTextStyles.body,
            ),
          ),
        ],
      ],
    );
  }

  Widget _feedback(LearningItem item) {
    final correct = _result!.correct;
    final color = correct
        ? CupertinoColors.activeGreen
        : CupertinoColors.destructiveRed;
    return Container(
      padding: const EdgeInsets.all(BuleSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(BuleRadius.card),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(
            correct
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.xmark_circle_fill,
            color: color,
            size: 34,
          ),
          const SizedBox(height: BuleSpacing.xs),
          Text(
            correct ? 'Correct!' : 'Not quite',
            style: BuleTextStyles.cardTitle,
          ),
          const SizedBox(height: BuleSpacing.xs),
          Text(
            'Correct answer: ${_result!.acceptedAnswer.isEmpty ? item.text : _result!.acceptedAnswer}',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _startTest() {
    final locale = widget.viewModel.preferences.learnLocale!;
    final lessons = widget.viewModel.content!.lessons.where(
      (lesson) => lesson.locale == locale,
    );
    final questions = <LearningItem>[];
    for (final difficulty in Difficulty.values) {
      final ids = lessons
          .where((lesson) => lesson.difficulty == difficulty)
          .expand((lesson) => lesson.itemIds);
      for (final id in ids.take(2)) {
        final item = widget.viewModel.content!.items[id];
        if (item != null) questions.add(item);
      }
    }
    setState(() => _questions = questions);
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    final result = _grader(
      _controller.text,
      _questions![_index].acceptedAnswers,
    );
    if (result.correct) {
      await widget.viewModel.recordPlacementCorrectAnswer(
        _questions![_index].id,
      );
    }
    if (result.correct && !_answerRevealed) {
      _correct++;
    }
    setState(() => _result = result);
  }

  Future<void> _continue() async {
    _controller.clear();
    if (_index + 1 < _questions!.length) {
      setState(() {
        _index++;
        _result = null;
        _answerRevealed = false;
      });
      return;
    }
    final ratio = _correct / _questions!.length;
    await _finish(
      ratio >= .75
          ? 'advanced'
          : ratio >= .4
          ? 'intermediate'
          : 'beginner',
    );
  }

  Future<void> _finish(String level) async {
    setState(() => _saving = true);
    await widget.viewModel.finishPlacement(level);
  }
}
