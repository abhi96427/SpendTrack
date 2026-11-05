import 'package:flutter_test/flutter_test.dart';
import 'package:spendtrack/models/expense.dart';
import 'package:spendtrack/models/expense_category.dart';
import 'package:spendtrack/models/expense_sort.dart';
import 'package:spendtrack/utils/expense_filters.dart';

void main() {
  final expenses = <Expense>[
    _expense(
      'old',
      'Old purchase',
      900,
      ExpenseCategory.food,
      DateTime(2026, 2, 1),
      note: 'market',
    ),
    _expense(
      'new',
      'Ticket',
      300,
      ExpenseCategory.transport,
      DateTime(2026, 2, 10),
      note: 'Metro pass',
    ),
    _expense(
      'middle',
      'Notebook',
      1200,
      ExpenseCategory.shopping,
      DateTime(2026, 2, 5),
      note: 'school supplies',
    ),
  ];

  test('search matches notes and category labels case-insensitively', () {
    expect(
      filterExpenses(expenses: expenses, query: 'METRO').map((e) => e.id),
      ['new'],
    );
    expect(
      filterExpenses(expenses: expenses, query: 'shopping').map((e) => e.id),
      ['middle'],
    );
  });

  test('date range is inclusive and can combine with category', () {
    final filtered = filterExpenses(
      expenses: expenses,
      from: DateTime(2026, 2, 5, 20),
      to: DateTime(2026, 2, 10, 2),
      category: ExpenseCategory.transport,
      now: DateTime(2026, 2, 20),
    );
    expect(filtered.map((e) => e.id), ['new']);
  });

  test('sorts newest, oldest, and highest amount', () {
    expect(filterExpenses(expenses: expenses).map((e) => e.id), [
      'new',
      'middle',
      'old',
    ]);
    expect(
      filterExpenses(
        expenses: expenses,
        sort: ExpenseSortOrder.oldest,
      ).map((e) => e.id),
      ['old', 'middle', 'new'],
    );
    expect(
      filterExpenses(
        expenses: expenses,
        sort: ExpenseSortOrder.highestAmount,
      ).map((e) => e.id),
      ['middle', 'old', 'new'],
    );
  });
}

Expense _expense(
  String id,
  String title,
  double amount,
  ExpenseCategory category,
  DateTime date, {
  String? note,
}) => Expense(
  id: id,
  title: title,
  amount: amount,
  category: category,
  date: date,
  createdAt: date,
  note: note,
);
