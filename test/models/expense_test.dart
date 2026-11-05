import 'package:flutter_test/flutter_test.dart';
import 'package:spendtrack/models/expense.dart';
import 'package:spendtrack/models/expense_category.dart';

void main() {
  group('Expense serialization', () {
    test('round-trips all fields', () {
      final expense = Expense(
        id: 'expense-1',
        title: 'Coffee',
        amount: 4.5,
        category: ExpenseCategory.food,
        date: DateTime(2026, 11, 4),
        createdAt: DateTime(2026, 11, 4, 9, 30),
        note: 'Morning coffee',
      );

      final restored = Expense.fromJson(expense.toJson());

      expect(restored, equals(expense));
    });

    test('falls back to Other for unknown categories', () {
      final restored = Expense.fromJson(<String, dynamic>{
        'id': 'expense-2',
        'title': 'Mystery purchase',
        'amount': 10,
        'category': 'not-a-category',
        'date': '2026-11-04T00:00:00.000',
        'createdAt': '2026-11-04T00:00:00.000',
      });

      expect(restored.category, ExpenseCategory.other);
    });

    test('rejects invalid amounts', () {
      expect(
        () => Expense.fromJson(<String, dynamic>{
          'id': 'expense-3',
          'title': 'Invalid',
          'amount': 0,
          'category': 'food',
          'date': '2026-11-04T00:00:00.000',
          'createdAt': '2026-11-04T00:00:00.000',
        }),
        throwsFormatException,
      );
    });

    test('rejects missing required fields', () {
      expect(
        () => Expense.fromJson(<String, dynamic>{
          'id': 'expense-4',
          'amount': 12,
          'category': 'food',
          'date': '2026-11-04T00:00:00.000',
        }),
        throwsFormatException,
      );
    });
  });
}
