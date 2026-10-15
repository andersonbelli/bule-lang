import 'package:flutter/cupertino.dart';

import '../../../app/app_view_model.dart';
import '../../../domain/models/content_pack.dart';
import '../../core/bule_design.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.viewModel});
  final AppViewModel viewModel;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final Set<String> _know = {};
  String? _learn;
  int _step = 0;
  bool _saving = false;

  List<ContentLanguage> get _languages => widget.viewModel.content!.languages;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      middle: Text(switch (_step) {
        0 => 'Languages you know',
        1 => 'Language to learn',
        _ => 'Review',
      }),
      leading: _step > 0
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _step--),
              child: const Text('Back'),
            )
          : null,
    ),
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'GET STARTED',
                  style: BuleTextStyles.eyebrow.copyWith(
                    color: CupertinoColors.activeOrange,
                  ),
                ),
                const SizedBox(height: BuleSpacing.xs),
                Text(switch (_step) {
                  0 => 'What do you speak?',
                  1 => 'What do you want to learn?',
                  _ => 'Ready to begin?',
                }, style: BuleTextStyles.pageTitle),
                const SizedBox(height: BuleSpacing.xs),
                Text(
                  switch (_step) {
                    0 =>
                      'Know languages are languages you speak fluently or natively. Choose one or more.',
                    1 => 'Choose exactly one language to practice.',
                    _ =>
                      'Check your choices before saving them on this device.',
                  },
                  style: BuleTextStyles.body.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: BuleSpacing.lg),
                Expanded(child: _step == 2 ? _review() : _languageList()),
                const SizedBox(height: BuleSpacing.sm),
                CupertinoButton.filled(
                  onPressed: _canContinue && !_saving ? _continue : null,
                  child: _saving
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : Text(_step == 2 ? 'Save and start' : 'Continue'),
                ),
                if (_step == 0) ...[
                  const SizedBox(height: BuleSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(BuleSpacing.sm),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange
                          .resolveFrom(context)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(BuleRadius.card),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.device_phone_portrait,
                          color: CupertinoColors.activeOrange,
                        ),
                        const SizedBox(width: BuleSpacing.sm),
                        Expanded(
                          child: Text(
                            'Guest mode is automatic. Your progress stays on this device.',
                            style: BuleTextStyles.supporting.copyWith(
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  bool get _canContinue => switch (_step) {
    0 => _know.isNotEmpty,
    1 => _learn != null,
    _ => true,
  };

  Widget _languageList() => ListView.separated(
    itemCount: _languages.length,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      final language = _languages[index];
      final selected = _step == 0
          ? _know.contains(language.locale)
          : _learn == language.locale;
      final disabled = _step == 1 && _know.contains(language.locale);
      final borderColor = disabled
          ? CupertinoColors.systemTeal.resolveFrom(context)
          : selected
          ? CupertinoColors.activeGreen
          : CupertinoColors.separator.resolveFrom(context);
      return Semantics(
        selected: selected,
        button: true,
        label: '${language.name}, ${language.variant}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BuleRadius.card),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BuleRadius.card),
              border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            ),
            child: CupertinoListTile(
              leading: Text(
                _flag(language.locale),
                style: const TextStyle(fontSize: 24),
              ),
              backgroundColor: disabled
                  ? CupertinoColors.systemTeal
                        .resolveFrom(context)
                        .withValues(alpha: 0.12)
                  : selected
                  ? CupertinoColors.activeGreen
                        .resolveFrom(context)
                        .withValues(alpha: 0.10)
                  : CupertinoColors.secondarySystemBackground.resolveFrom(
                      context,
                    ),
              backgroundColorActivated: CupertinoColors.secondarySystemFill
                  .resolveFrom(context),
              title: Text(language.name, style: BuleTextStyles.cardTitle),
              subtitle: Text(
                language.variant,
                style: BuleTextStyles.supporting.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              trailing: disabled
                  ? Text(
                      'KNOW',
                      style: BuleTextStyles.eyebrow.copyWith(
                        color: CupertinoColors.systemTeal.resolveFrom(context),
                      ),
                    )
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
                      if (_step == 0) {
                        selected
                            ? _know.remove(language.locale)
                            : _know.add(language.locale);
                      } else {
                        _learn = language.locale;
                      }
                    }),
            ),
          ),
        ),
      );
    },
  );

  Widget _review() {
    String names(Iterable<String> locales) => locales
        .map(
          (locale) =>
              _languages.firstWhere((item) => item.locale == locale).name,
        )
        .join(', ');
    return ListView(
      children: [
        _reviewSelection(
          label: 'KNOW LANGUAGES',
          icon: CupertinoIcons.chat_bubble_2_fill,
          color: CupertinoColors.systemTeal,
          locales: _know,
          names: names(_know),
        ),
        const SizedBox(height: BuleSpacing.md),
        _reviewSelection(
          label: 'LEARN LANGUAGE',
          icon: CupertinoIcons.book_fill,
          color: CupertinoColors.activeGreen,
          locales: {_learn!},
          names: names([_learn!]),
        ),
      ],
    );
  }

  Widget _reviewSelection({
    required String label,
    required IconData icon,
    required Color color,
    required Set<String> locales,
    required String names,
  }) => Container(
    padding: const EdgeInsets.all(BuleSpacing.md),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(BuleRadius.card),
      border: Border.all(color: color, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: BuleSpacing.xs),
            Text(label, style: BuleTextStyles.eyebrow.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: BuleSpacing.sm),
        Text(
          locales.map(_flag).join('  '),
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: BuleSpacing.xs),
        Text(names, style: BuleTextStyles.cardTitle),
      ],
    ),
  );

  String _flag(String locale) => switch (locale) {
    'pt-BR' => '🇧🇷',
    'en-US' => '🇺🇸',
    'es-MX' => '🇲🇽',
    'fr-FR' => '🇫🇷',
    'id-ID' => '🇮🇩',
    'et-EE' => '🇪🇪',
    _ => '🌐',
  };

  Future<void> _continue() async {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    setState(() => _saving = true);
    await widget.viewModel.saveLanguages(
      knowLocales: _know,
      learnLocale: _learn!,
    );
  }
}
