import 'package:flutter_test/flutter_test.dart';
import 'package:spendtrack/utils/validators.dart';

void main() {
  group('validateExpenseTitle', () {
    test('rejects empty and whitespace-only titles', () {
      expect(validateExpenseTitle(null), 'Enter a title.');
      expect(validateExpenseTitle(''), 'Enter a title.');
      expect(validateExpenseTitle('   '), 'Enter a title.');
    });

    test('rejects titles over 80 characters', () {
      expect(
        validateExpenseTitle('a' * 81),
        'Keep the title under 80 characters.',
      );
    });

    test('accepts a normal title', () {
      expect(validateExpenseTitle('Lunch with the team'), isNull);
    });
  });

  group('validateExpenseAmount', () {
    test('rejects empty and non-numeric amounts', () {
      expect(validateExpenseAmount(null), 'Enter an amount.');
      expect(validateExpenseAmount(''), 'Enter an amount.');
      expect(validateExpenseAmount('abc'), 'Enter a valid number.');
    });

    test('rejects non-finite amounts', () {
      expect(validateExpenseAmount('NaN'), 'Enter a valid number.');
      expect(validateExpenseAmount('Infinity'), 'Enter a valid number.');
      expect(validateExpenseAmount('-Infinity'), 'Enter a valid number.');
    });

    test('rejects zero and negative amounts', () {
      expect(validateExpenseAmount('0'), 'Amount must be greater than zero.');
      expect(
        validateExpenseAmount('0.00'),
        'Amount must be greater than zero.',
      );
      expect(validateExpenseAmount('-25'), 'Amount must be greater than zero.');
    });

    test('rejects excessively large amounts', () {
      expect(validateExpenseAmount('1000000001'), 'Amount is too large.');
    });

    test('accepts positive amounts including thousands separators', () {
      expect(validateExpenseAmount('0.01'), isNull);
      expect(validateExpenseAmount('250.50'), isNull);
      expect(validateExpenseAmount('1,250.50'), isNull);
    });
  });

  group('parseAmount', () {
    test('parses numbers and removes thousands separators', () {
      expect(parseAmount('1,250.50'), 1250.50);
      expect(parseAmount(' 42 '), 42);
    });

    test('returns null for invalid or non-finite input', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount('not a number'), isNull);
      expect(parseAmount('NaN'), isNull);
      expect(parseAmount('Infinity'), isNull);
    });
  });
}
