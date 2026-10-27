import 'package:flutter/cupertino.dart';

import '../../../app/app_view_model.dart';
import '../../../domain/models/content_pack.dart';
import '../../../domain/models/learning_progress.dart';
import '../../../domain/services/speech_reader.dart';
import '../../core/bule_design.dart';
import 'language_settings_view.dart';
import 'speaker_selection_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.viewModel});
  final AppViewModel viewModel;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Future<List<SpeechVoice>>? _voices;
  String? _voiceLocale;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: const CupertinoNavigationBar(middle: Text('Profile')),
    child: SafeArea(
      child: FutureBuilder<LearningProgress>(
        future: widget.viewModel.loadLearningProgress(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final progress = snapshot.data!;
          final notes = progress.notes.entries.toList();
          final languages = widget.viewModel.content!.languages;
          String name(String locale) => languages
              .firstWhere((language) => language.locale == locale)
              .name;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              const Text('Guest profile', style: BuleTextStyles.pageTitle),
              const SizedBox(height: BuleSpacing.xs),
              Text(
                'Your learning progress and private notes are stored on this device.',
                style: BuleTextStyles.supporting.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: BuleSpacing.md),
              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.zero,
                header: const Text('LANGUAGES'),
                children: [
                  CupertinoListTile(
                    title: const Text('Know'),
                    subtitle: Text(
                      widget.viewModel.preferences.knowLocales
                          .map(name)
                          .join(', '),
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('Learn'),
                    subtitle: Text(
                      name(widget.viewModel.preferences.learnLocale!),
                    ),
                  ),
                  CupertinoListTile(
                    leading: const Icon(
                      CupertinoIcons.pencil,
                      color: CupertinoColors.activeBlue,
                    ),
                    title: const Text('Change languages'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: _editLanguages,
                  ),
                ],
              ),
              const SizedBox(height: BuleSpacing.lg),
              _voiceSettings(name),
              const SizedBox(height: BuleSpacing.lg),
              const Text('Private notes', style: BuleTextStyles.cardTitle),
              const SizedBox(height: BuleSpacing.sm),
              if (notes.isEmpty)
                Text(
                  'Notes you add to words and phrases will appear here.',
                  style: BuleTextStyles.supporting.copyWith(
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                )
              else
                for (final note in notes)
                  _noteCard(
                    widget.viewModel.content!.items[note.key]?.text ?? note.key,
                    note.value,
                    widget.viewModel.content!.items[note.key],
                  ),
            ],
          );
        },
      ),
    ),
  );

  Widget _noteCard(String item, String note, LearningItem? learningItem) =>
      Container(
        margin: const EdgeInsets.only(bottom: BuleSpacing.xs),
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
            Row(
              children: [
                Expanded(child: Text(item, style: BuleTextStyles.cardTitle)),
                if (learningItem?.locale ==
                    widget.viewModel.preferences.learnLocale)
                  Semantics(
                    label:
                        widget.viewModel.audioPlaying &&
                            widget.viewModel.speakingText == item
                        ? 'Playing $item'
                        : 'Listen to $item',
                    button: true,
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                      onPressed: widget.viewModel.audioPlaying
                          ? null
                          : () => widget.viewModel.speakLearningItem(
                              learningItem!,
                            ),
                      child:
                          widget.viewModel.audioPlaying &&
                              widget.viewModel.speakingText == item
                          ? const CupertinoActivityIndicator(radius: 10)
                          : const Icon(CupertinoIcons.speaker_2_fill, size: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: BuleSpacing.xxs),
            Text(note, style: BuleTextStyles.supporting),
          ],
        ),
      );

  Widget _voiceSettings(String Function(String) languageName) {
    final locale = widget.viewModel.preferences.learnLocale!;
    if (_voiceLocale != locale) {
      _voiceLocale = locale;
      _voices = widget.viewModel.availableLearnVoices();
    }
    return FutureBuilder<List<SpeechVoice>>(
      future: _voices,
      builder: (context, snapshot) {
        final selectedId = widget.viewModel.selectedLearnVoiceId;
        final voices = snapshot.data ?? const <SpeechVoice>[];
        final selected = voices
            .where(
              (voice) => voice.id == selectedId || voice.name == selectedId,
            )
            .firstOrNull;
        return CupertinoListSection.insetGrouped(
          margin: EdgeInsets.zero,
          header: const Text('SPEECH'),
          footer: Text(
            'Used only for ${languageName(locale)} words and phrases.',
          ),
          children: [
            CupertinoListTile(
              leading: const Icon(
                CupertinoIcons.speaker_2_fill,
                color: CupertinoColors.systemPurple,
              ),
              title: const Text('Choose your speaker'),
              subtitle: Text('Selected: ${selected?.name ?? 'Automatic'}'),
              additionalInfo:
                  snapshot.connectionState == ConnectionState.waiting
                  ? const CupertinoActivityIndicator()
                  : null,
              trailing: const CupertinoListTileChevron(),
              onTap: snapshot.hasData
                  ? () async {
                      await Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (_) =>
                              SpeakerSelectionView(viewModel: widget.viewModel),
                        ),
                      );
                      if (mounted) setState(() {});
                    }
                  : null,
            ),
            CupertinoListTile(
              leading: const Icon(
                CupertinoIcons.play_circle_fill,
                color: CupertinoColors.systemPurple,
              ),
              title: const Text('Voice example'),
              subtitle: Text('“${widget.viewModel.learnVoicePreviewPhrase}”'),
              trailing: widget.viewModel.audioPlaying
                  ? const CupertinoActivityIndicator()
                  : const Icon(CupertinoIcons.speaker_2),
              onTap: widget.viewModel.audioPlaying
                  ? null
                  : () => widget.viewModel.previewVoice(
                      widget.viewModel.selectedLearnVoiceId,
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editLanguages() async {
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => LanguageSettingsView(viewModel: widget.viewModel),
      ),
    );
    if (mounted) {
      _voiceLocale = null;
      _voices = null;
      setState(() {});
    }
  }
}
