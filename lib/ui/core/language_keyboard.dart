import 'package:flutter/cupertino.dart';

class LanguageKeyboard extends StatelessWidget {
  const LanguageKeyboard({
    super.key,
    required this.locale,
    required this.controller,
    this.expectedText = '',
  });

  final String locale;
  final TextEditingController controller;
  final String expectedText;

  @override
  Widget build(BuildContext context) {
    final relevant = _characters(locale)
        .where(
          (character) =>
              expectedText.toLowerCase().contains(character.toLowerCase()),
        )
        .toList();
    final characters = relevant.isEmpty ? _characters(locale) : relevant;
    if (characters.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: characters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) => CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          color: CupertinoColors.secondarySystemFill.resolveFrom(context),
          onPressed: () => _insert(characters[index]),
          child: Text(characters[index], style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  void _insert(String character) {
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : controller.text.length;
    final end = selection.isValid ? selection.end : controller.text.length;
    controller.value = TextEditingValue(
      text: controller.text.replaceRange(start, end, character),
      selection: TextSelection.collapsed(offset: start + character.length),
    );
  }

  List<String> _characters(String locale) => switch (locale) {
    'pt-BR' => const [
      'ã',
      'á',
      'à',
      'â',
      'ç',
      'é',
      'ê',
      'í',
      'õ',
      'ó',
      'ô',
      'ú',
    ],
    'es-MX' => const ['á', 'é', 'í', 'ó', 'ú', 'ü', 'ñ', '¿', '¡'],
    'fr-FR' => const [
      'à',
      'â',
      'æ',
      'ç',
      'é',
      'è',
      'ê',
      'ë',
      'î',
      'ï',
      'ô',
      'œ',
      'ù',
      'û',
      'ü',
    ],
    'id-ID' || 'en-US' => const [],
    'et-EE' => const ['ä', 'ö', 'õ', 'ü', 'š', 'ž'],
    _ => const [],
  };
}
