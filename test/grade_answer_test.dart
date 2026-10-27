import 'package:bule_lang/domain/use_cases/grade_answer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const grade = GradeAnswer();

  test('ignores punctuation while preserving exact feedback', () {
    final result = grade('Olá', const ['Olá!']);
    expect(result.correct, isTrue);
    expect(result.exact, isTrue);
  });

  test('accepts missing accents but reports a non-exact answer', () {
    final result = grade('voce', const ['você']);
    expect(result.correct, isTrue);
    expect(result.exact, isFalse);
    expect(result.acceptedAnswer, 'você');
  });
}
