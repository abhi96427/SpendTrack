import 'package:flutter_test/flutter_test.dart';
import 'package:spendtrack/models/expense.dart';
import 'package:spendtrack/models/expense_category.dart';
import 'package:spendtrack/providers/expense_provider.dart';

import '../support/fake_expense_storage.dart';

Expense _expense({
  String id = 'expense-1',
  String title = 'Coffee',
  double amount = 100,
  DateTime? date,
  ExpenseCategory category = ExpenseCategory.food,
}) {
  final timestamp = date ?? DateTime.now();
  return Expense(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: DateTime(timestamp.year, timestamp.month, timestamp.day),
    createdAt: timestamp,
  );
}

void main() {
  group('ExpenseProvider', () {
    test('loads stored expenses newest first', () async {
      final older = _expense(
        id: 'older',
        title: 'Older',
        date: DateTime(2026, 1, 1),
      );
      final newer = _expense(
        id: 'newer',
        title: 'Newer',
        date: DateTime(2026, 2, 1),
      );
      final provider = ExpenseProvider(
        repository: FakeExpenseStorage(initial: <Expense>[older, newer]),
      );

      await provider.initialize();

      expect(provider.isInitialized, isTrue);
      expect(provider.expenses.map((expense) => expense.id), <String>[
        'newer',
        'older',
      ]);
      expect(provider.expenseCount, 2);
    });

    test('adds, updates, and deletes expenses through storage', () async {
      final storage = FakeExpenseStorage();
      final provider = ExpenseProvider(repository: storage);
      await provider.initialize();

      final item = _expense(amount: 250);
      expect(await provider.addExpense(item), isTrue);
      expect(storage.stored, hasLength(1));
      expect(provider.totalAmount, 250);

      final edited = item.copyWith(title: 'Groceries', amount: 300);
      expect(await provider.updateExpense(edited), isTrue);
      expect(storage.stored.single.title, 'Groceries');
      expect(provider.totalAmount, 300);

      expect(await provider.deleteExpense(item.id), isTrue);
      expect(storage.stored, isEmpty);
      expect(provider.expenses, isEmpty);
    });

    test('rolls back the optimistic update when saving fails', () async {
      final storage = FakeExpenseStorage();
      final provider = ExpenseProvider(repository: storage);
      await provider.initialize();

      storage.failSave = true;
      final added = await provider.addExpense(_expense());

      expect(added, isFalse);
      expect(provider.expenses, isEmpty);
      expect(storage.stored, isEmpty);
      expect(provider.errorMessage, 'Save failed.');
    });

    test('rolls back failed updates and deletes', () async {
      final item = _expense();
      final storage = FakeExpenseStorage(initial: <Expense>[item]);
      final provider = ExpenseProvider(repository: storage);
      await provider.initialize();

      storage.failSave = true;

      final updated = item.copyWith(title: 'Changed');
      expect(await provider.updateExpense(updated), isFalse);
      expect(provider.expenses.single.title, item.title);
      expect(storage.stored.single.title, item.title);

      expect(await provider.deleteExpense(item.id), isFalse);
      expect(provider.expenses, hasLength(1));
      expect(storage.stored, hasLength(1));
      expect(provider.errorMessage, 'Save failed.');
    });

    test(
      'rejects duplicate ids and unknown records without persisting',
      () async {
        final item = _expense();
        final storage = FakeExpenseStorage(initial: <Expense>[item]);
        final provider = ExpenseProvider(repository: storage);
        await provider.initialize();

        expect(await provider.addExpense(item), isFalse);
        expect(
          provider.errorMessage,
          'An expense with this ID already exists.',
        );
        expect(storage.stored, hasLength(1));

        final missing = _expense(id: 'missing');
        expect(await provider.updateExpense(missing), isFalse);
        expect(provider.errorMessage, 'That expense could not be found.');

        expect(await provider.deleteExpense('missing'), isFalse);
        expect(provider.errorMessage, 'That expense could not be found.');
        expect(storage.stored, hasLength(1));
      },
    );

    test('loads current-month and today totals from real data', () async {
      final now = DateTime.now();
      final provider = ExpenseProvider(
        repository: FakeExpenseStorage(
          initial: <Expense>[
            _expense(id: 'today', amount: 100, date: now),
            _expense(
              id: 'last-month',
              amount: 50,
              date: DateTime(now.year, now.month - 1, 10),
            ),
          ],
        ),
      );

      await provider.initialize();

      expect(provider.totalAmount, 150);
      expect(provider.todayTotal, 100);
      expect(provider.currentMonthCount, 1);
    });

    test('computes monthly, category, and trend analytics', () async {
      final now = DateTime.now();
      final provider = ExpenseProvider(
        repository: FakeExpenseStorage(
          initial: <Expense>[
            _expense(id: 'food', amount: 100, date: now),
            _expense(
              id: 'transport',
              amount: 50,
              date: now,
              category: ExpenseCategory.transport,
            ),
            _expense(
              id: 'bills',
              amount: 200,
              date: DateTime(now.year, now.month - 1, 12),
              category: ExpenseCategory.bills,
            ),
          ],
        ),
      );

      await provider.initialize();

      expect(provider.countForMonth(now), 2);
      expect(provider.totalForMonth(now), 150);
      expect(provider.totalForPreviousMonth(now), 200);

      final currentCategories = provider.categoryTotals(month: now);
      expect(currentCategories[ExpenseCategory.food], 100);
      expect(currentCategories[ExpenseCategory.transport], 50);
      expect(currentCategories[ExpenseCategory.bills], 0);

      final allTimeCategories = provider.categoryTotals();
      expect(allTimeCategories[ExpenseCategory.bills], 200);

      final trend = provider.monthlyTotals(endMonth: now, count: 3);
      expect(trend, hasLength(3));
      expect(trend.first.total, 0);
      expect(trend[1].total, 200);
      expect(trend.last.total, 150);
      expect(trend.last.month.year, now.year);
      expect(trend.last.month.month, now.month);
    });

    test('filters every analytic by category', () async {
      final now = DateTime.now();
      final provider = ExpenseProvider(
        repository: FakeExpenseStorage(
          initial: <Expense>[
            _expense(id: 'food-now', amount: 100, date: now),
            _expense(
              id: 'transport-now',
              amount: 50,
              date: now,
              category: ExpenseCategory.transport,
            ),
            _expense(
              id: 'food-previous',
              amount: 75,
              date: DateTime(now.year, now.month - 1, 8),
            ),
            _expense(
              id: 'bills-previous',
              amount: 200,
              date: DateTime(now.year, now.month - 1, 12),
              category: ExpenseCategory.bills,
            ),
          ],
        ),
      );

      await provider.initialize();

      expect(provider.countForMonth(now, category: ExpenseCategory.food), 1);
      expect(provider.totalForMonth(now, category: ExpenseCategory.food), 100);
      expect(
        provider.totalForPreviousMonth(now, category: ExpenseCategory.food),
        75,
      );

      final foodCategories = provider.categoryTotals(
        month: now,
        category: ExpenseCategory.food,
      );
      expect(foodCategories[ExpenseCategory.food], 100);
      expect(foodCategories[ExpenseCategory.transport], 0);
      expect(foodCategories[ExpenseCategory.bills], 0);

      final foodTrend = provider.monthlyTotals(
        endMonth: now,
        count: 3,
        category: ExpenseCategory.food,
      );
      expect(foodTrend.map((item) => item.total), <double>[0, 75, 100]);

      final transportTrend = provider.monthlyTotals(
        endMonth: now,
        count: 3,
        category: ExpenseCategory.transport,
      );
      expect(transportTrend.map((item) => item.total), <double>[0, 0, 50]);
    });

    test('analytics update automatically after mutations', () async {
      final now = DateTime.now();
      final storage = FakeExpenseStorage(
        initial: <Expense>[_expense(id: 'first', amount: 40, date: now)],
      );
      final provider = ExpenseProvider(repository: storage);
      await provider.initialize();

      var notifications = 0;
      provider.addListener(() => notifications++);

      expect(provider.totalForMonth(now), 40);
      expect(provider.categoryTotals(month: now)[ExpenseCategory.food], 40);

      await provider.addExpense(
        _expense(
          id: 'second',
          amount: 60,
          date: now,
          category: ExpenseCategory.transport,
        ),
      );

      expect(notifications, greaterThan(0));
      expect(provider.totalForMonth(now), 100);
      expect(provider.countForMonth(now), 2);
      expect(
        provider.categoryTotals(month: now)[ExpenseCategory.transport],
        60,
      );
      expect(
        provider.totalForMonth(now, category: ExpenseCategory.transport),
        60,
      );

      await provider.deleteExpense('first');

      expect(provider.totalForMonth(now), 60);
      expect(provider.categoryTotals(month: now)[ExpenseCategory.food], 0);
    });

    test('reports load errors and can retry', () async {
      final storage = FakeExpenseStorage()..failLoad = true;
      final provider = ExpenseProvider(repository: storage);

      await provider.initialize();

      expect(provider.isInitialized, isFalse);
      expect(provider.errorMessage, 'Load failed.');

      storage.failLoad = false;
      await provider.initialize();

      expect(provider.isInitialized, isTrue);
      expect(provider.errorMessage, isNull);
    });
  });
}
