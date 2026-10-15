import 'package:flutter/cupertino.dart';

import '../../../app/app_view_model.dart';
import '../../../domain/models/learning_progress.dart';
import '../../core/bule_design.dart';
import 'language_settings_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.viewModel});
  final AppViewModel viewModel;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
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
                  ),
            ],
          );
        },
      ),
    ),
  );

  Widget _noteCard(String item, String note) => Container(
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
        Text(item, style: BuleTextStyles.cardTitle),
        const SizedBox(height: BuleSpacing.xxs),
        Text(note, style: BuleTextStyles.supporting),
      ],
    ),
  );

  Future<void> _editLanguages() async {
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => LanguageSettingsView(viewModel: widget.viewModel),
      ),
    );
    if (mounted) setState(() {});
  }
}
