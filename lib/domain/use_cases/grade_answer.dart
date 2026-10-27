class GradeResult {
  const GradeResult({
    required this.correct,
    required this.exact,
    required this.similarity,
    required this.acceptedAnswer,
  });
  final bool correct;
  final bool exact;
  final double similarity;
  final String acceptedAnswer;
}

class GradeAnswer {
  const GradeAnswer();

  GradeResult call(String answer, Iterable<String> acceptedAnswers) {
    final answers = acceptedAnswers.toList();
    if (answers.isEmpty) {
      return const GradeResult(
        correct: false,
        exact: false,
        similarity: 0,
        acceptedAnswer: '',
      );
    }
    final normalized = _normalize(answer);
    final lenient = _stripDiacritics(normalized);
    var bestAnswer = answers.first;
    var bestSimilarity = 0.0;
    for (final accepted in answers) {
      final acceptedNormalized = _normalize(accepted);
      final similarity = _semanticSimilarity(
        lenient,
        _stripDiacritics(acceptedNormalized),
      );
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestAnswer = accepted;
      }
    }
    return GradeResult(
      correct: bestSimilarity >= 0.8,
      exact: answers.any((accepted) => normalized == _normalize(accepted)),
      similarity: bestSimilarity,
      acceptedAnswer: bestAnswer,
    );
  }

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[‘’]'), "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceFirst(RegExp(r'[.!?…]+$'), '');

  double _semanticSimilarity(String left, String right) {
    final editScore = _similarity(left, right);
    final leftWords = left.split(' ').where((word) => word.isNotEmpty).toSet();
    final rightWords = right
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toSet();
    if (leftWords.isEmpty || rightWords.isEmpty) return editScore;
    final overlap = leftWords.intersection(rightWords).length;
    final tokenScore = (2 * overlap) / (leftWords.length + rightWords.length);
    return editScore > tokenScore ? editScore : tokenScore;
  }

  String _stripDiacritics(String value) {
    const accented = 'áàâãäåéèêëíìîïóòôõöúùûüçñýÿšžõäöü';
    const plain = 'aaaaaaeeeeiiiiooooouuuucnyysooaou';
    return value.split('').map((character) {
      final index = accented.indexOf(character);
      return index < 0 ? character : plain[index];
    }).join();
  }

  double _similarity(String left, String right) {
    final longest = left.length > right.length ? left.length : right.length;
    if (longest == 0) return 1;
    return 1 - (_levenshtein(left, right) / longest);
  }

  int _levenshtein(String left, String right) {
    var previous = List<int>.generate(right.length + 1, (index) => index);
    for (var leftIndex = 0; leftIndex < left.length; leftIndex++) {
      final current = <int>[leftIndex + 1];
      for (var rightIndex = 0; rightIndex < right.length; rightIndex++) {
        final substitution =
            previous[rightIndex] +
            (left.codeUnitAt(leftIndex) == right.codeUnitAt(rightIndex)
                ? 0
                : 1);
        final insertion = current[rightIndex] + 1;
        final deletion = previous[rightIndex + 1] + 1;
        current.add(
          [substitution, insertion, deletion].reduce((a, b) => a < b ? a : b),
        );
      }
      previous = current;
    }
    return previous.last;
  }
}
