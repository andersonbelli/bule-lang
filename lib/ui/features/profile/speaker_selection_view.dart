import 'package:flutter/cupertino.dart';

import '../../../app/app_view_model.dart';
import '../../../domain/services/speech_reader.dart';
import '../../core/bule_design.dart';

class SpeakerSelectionView extends StatefulWidget {
  const SpeakerSelectionView({super.key, required this.viewModel});

  final AppViewModel viewModel;

  @override
  State<SpeakerSelectionView> createState() => _SpeakerSelectionViewState();
}

class _SpeakerSelectionViewState extends State<SpeakerSelectionView> {
  late final Future<List<SpeechVoice>> _voices = widget.viewModel
      .availableLearnVoices();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.viewModel.selectedLearnVoiceId;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) => CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Choose your speaker'),
      ),
      child: SafeArea(
        child: FutureBuilder<List<SpeechVoice>>(
          future: _voices,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CupertinoActivityIndicator());
            }
            final voices = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              children: [
                const Icon(
                  CupertinoIcons.speaker_2_fill,
                  size: 48,
                  color: CupertinoColors.systemPurple,
                ),
                const SizedBox(height: BuleSpacing.md),
                const Text(
                  'Pick the voice you want to hear',
                  textAlign: TextAlign.center,
                  style: BuleTextStyles.pageTitle,
                ),
                const SizedBox(height: BuleSpacing.xs),
                Text(
                  'Tap a speaker to select it and hear this phrase:',
                  textAlign: TextAlign.center,
                  style: BuleTextStyles.supporting.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: BuleSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(BuleSpacing.md),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemPurple.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(BuleRadius.card),
                  ),
                  child: Text(
                    '“${widget.viewModel.learnVoicePreviewPhrase}”',
                    textAlign: TextAlign.center,
                    style: BuleTextStyles.cardTitle,
                  ),
                ),
                const SizedBox(height: BuleSpacing.lg),
                _option(name: 'Automatic', voiceId: null),
                for (final voice in voices)
                  _option(name: voice.name, voiceId: voice.id),
                if (voices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(BuleSpacing.md),
                    child: Text(
                      'No additional offline voices are installed. Automatic voice remains available.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: BuleSpacing.md),
                CupertinoButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Use this speaker'),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _option({required String name, required String? voiceId}) {
    final selected = _selectedId == voiceId;
    final playing = selected && widget.viewModel.audioPlaying;
    return Padding(
      padding: const EdgeInsets.only(bottom: BuleSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? CupertinoColors.systemPurple.withValues(alpha: .12)
              : CupertinoColors.secondarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(BuleRadius.card),
          border: Border.all(
            color: selected
                ? CupertinoColors.systemPurple
                : CupertinoColors.separator.resolveFrom(context),
            width: selected ? 2 : .5,
          ),
        ),
        child: CupertinoListTile(
          leading: Icon(
            selected
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.circle,
            color: selected
                ? CupertinoColors.systemPurple
                : CupertinoColors.inactiveGray,
          ),
          title: Text(name, style: BuleTextStyles.cardTitle),
          subtitle: Text(selected ? 'Selected speaker' : 'Tap to hear sample'),
          trailing: playing
              ? const CupertinoActivityIndicator()
              : const Icon(CupertinoIcons.play_circle),
          onTap: widget.viewModel.audioPlaying
              ? null
              : () => _selectAndPreview(voiceId),
        ),
      ),
    );
  }

  Future<void> _selectAndPreview(String? voiceId) async {
    setState(() => _selectedId = voiceId);
    await widget.viewModel.selectLearnVoice(voiceId);
    await widget.viewModel.previewVoice(voiceId);
  }
}
