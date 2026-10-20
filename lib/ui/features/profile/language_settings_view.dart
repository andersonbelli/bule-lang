import 'package:flutter/cupertino.dart';

import '../../../app/app_view_model.dart';
import '../../../domain/models/content_pack.dart';
import '../../core/bule_design.dart';

class LanguageSettingsView extends StatefulWidget {
  const LanguageSettingsView({super.key, required this.viewModel});
  final AppViewModel viewModel;

  @override
  State<LanguageSettingsView> createState() => _LanguageSettingsViewState();
}

class _LanguageSettingsViewState extends State<LanguageSettingsView> {
  late final Set<String> knowLocales = Set.of(
    widget.viewModel.preferences.knowLocales,
  );
  late String learnLocale = widget.viewModel.preferences.learnLocale!;
  bool saving = false;

  List<ContentLanguage> get languages => widget.viewModel.content!.languages;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      middle: const Text('Languages'),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
    ),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(BuleSpacing.md),
        children: [
          const Text('Know languages', style: BuleTextStyles.pageTitle),
          const SizedBox(height: BuleSpacing.xs),
          Text(
            'Choose every language you speak fluently. Your current Learn language cannot also be selected here.',
            style: BuleTextStyles.supporting.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: BuleSpacing.md),
          for (final language in languages)
            _languageTile(language, knowMode: true),
          const SizedBox(height: BuleSpacing.lg),
          const Text('Learn language', style: BuleTextStyles.pageTitle),
          const SizedBox(height: BuleSpacing.xs),
          Text(
            'Changing this language keeps all progress from your previous language.',
            style: BuleTextStyles.supporting.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: BuleSpacing.md),
          for (final language in languages)
            _languageTile(language, knowMode: false),
          const SizedBox(height: BuleSpacing.md),
          CupertinoButton.filled(
            onPressed: knowLocales.isEmpty || saving ? null : _save,
            child: saving
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('Save languages'),
          ),
        ],
      ),
    ),
  );

  Widget _languageTile(ContentLanguage language, {required bool knowMode}) {
    final selected = knowMode
        ? knowLocales.contains(language.locale)
        : learnLocale == language.locale;
    final disabled = knowMode
        ? language.locale == learnLocale
        : knowLocales.contains(language.locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: BuleSpacing.xs),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BuleRadius.card),
        child: CupertinoListTile(
          backgroundColor: disabled
              ? CupertinoColors.secondarySystemFill.resolveFrom(context)
              : selected
              ? CupertinoColors.activeGreen
                    .resolveFrom(context)
                    .withValues(alpha: 0.10)
              : CupertinoColors.secondarySystemBackground.resolveFrom(context),
          leading: Opacity(
            opacity: disabled ? 0.45 : 1,
            child: Text(
              _flag(language.locale),
              style: const TextStyle(fontSize: 24),
            ),
          ),
          title: Text(
            language.name,
            style: BuleTextStyles.cardTitle.copyWith(
              color: disabled ? CupertinoColors.inactiveGray : null,
            ),
          ),
          subtitle: Text(
            language.variant,
            style: TextStyle(
              color: disabled ? CupertinoColors.inactiveGray : null,
            ),
          ),
          trailing: disabled
              ? null
              : Icon(
                  selected
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  color: selected
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.inactiveGray,
                ),
          onTap: disabled
              ? null
              : () => setState(() {
                  if (knowMode) {
                    selected
                        ? knowLocales.remove(language.locale)
                        : knowLocales.add(language.locale);
                  } else {
                    learnLocale = language.locale;
                  }
                }),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => saving = true);
    await widget.viewModel.saveLanguages(
      knowLocales: knowLocales,
      learnLocale: learnLocale,
    );
    if (mounted) Navigator.of(context).pop();
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
