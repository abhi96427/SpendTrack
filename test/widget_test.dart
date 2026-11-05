import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendtrack/app.dart';
import 'package:spendtrack/models/expense.dart';
import 'package:spendtrack/models/expense_category.dart';
import 'package:spendtrack/widgets/category_donut_chart.dart';
import 'package:spendtrack/widgets/monthly_bar_chart.dart';

import 'support/fake_expense_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpendTrack UI', () {
    testWidgets('shows a loading state while expenses are read', (
      WidgetTester tester,
    ) async {
      _configureView(tester);
      final storage = _BlockingLoadStorage();

      await tester.pumpWidget(SpendTrackApp(repository: storage));
      await tester.pump();

      expect(find.text('Preparing your dashboard'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      storage.release.complete();
      await tester.pumpAndSettle();

      expect(find.text('Preparing your dashboard'), findsNothing);
      expect(find.text('TOTAL SPENDING'), findsOneWidget);
    });

    testWidgets('shows an error state and retries loading', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage()..failLoad = true;
      await _pumpApp(tester, storage);

      expect(find.text("Couldn't load your expenses"), findsOneWidget);
      expect(find.text('Load failed.'), findsOneWidget);

      storage.failLoad = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load your expenses"), findsNothing);
      expect(find.text('TOTAL SPENDING'), findsOneWidget);
    });

    testWidgets('shows a meaningful empty dashboard', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage();
      await _pumpApp(tester, storage);

      expect(find.text('SpendTrack'), findsOneWidget);
      expect(find.text('TOTAL SPENDING'), findsOneWidget);
      expect(find.byKey(const Key('dashboard-add-expense')), findsOneWidget);

      await _scrollListUntilVisible(
        tester,
        find.text('No expenses yet'),
        'dashboard-list',
      );
      expect(find.text('No expenses yet'), findsOneWidget);
    });

    testWidgets('adds an expense, persists it, and updates the dashboard', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage();
      await _pumpApp(tester, storage);

      await tester.tap(find.byKey(const Key('dashboard-add-expense')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('expense-amount-field')),
        '250.50',
      );
      await tester.enterText(
        find.byKey(const Key('expense-title-field')),
        'Groceries',
      );
      await tester.tap(find.byKey(const Key('expense-category-food')));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('expense-save-button'));
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(storage.stored, hasLength(1));
      final saved = storage.stored.single;
      expect(saved.title, 'Groceries');
      expect(saved.amount, 250.50);
      expect(saved.category, ExpenseCategory.food);
      expect(saved.date.day, DateTime.now().day);

      expect(find.text('₹250.50'), findsWidgets);
      await _scrollListUntilVisible(
        tester,
        find.text('Groceries'),
        'dashboard-list',
      );
      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('validates empty, zero, and missing fields before saving', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage();
      await _pumpApp(tester, storage);

      await tester.tap(find.byKey(const Key('dashboard-add-expense')));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('expense-save-button'));
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter an amount.'), findsOneWidget);
      expect(find.text('Enter a title.'), findsOneWidget);
      expect(storage.stored, isEmpty);

      await tester.enterText(
        find.byKey(const Key('expense-amount-field')),
        '0',
      );
      await tester.enterText(
        find.byKey(const Key('expense-title-field')),
        'Zero expense',
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Amount must be greater than zero.'), findsOneWidget);
      expect(storage.stored, isEmpty);
    });

    testWidgets('does not flag untouched fields and clears fixed errors', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage();
      await _pumpApp(tester, storage);

      await tester.tap(find.byKey(const Key('dashboard-add-expense')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('expense-amount-field')),
        '50',
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter a title.'), findsNothing);

      await tester.tap(find.byKey(const Key('expense-save-button')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a title.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('expense-title-field')),
        'Snacks',
      );
      await tester.pumpAndSettle();
      expect(find.text('Enter a title.'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('expense-amount-field')),
        '0',
      );
      await tester.pumpAndSettle();
      expect(find.text('Amount must be greater than zero.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('expense-amount-field')),
        '50',
      );
      await tester.pumpAndSettle();
      expect(find.text('Amount must be greater than zero.'), findsNothing);

      await tester.tap(find.byKey(const Key('expense-save-button')));
      await tester.pumpAndSettle();

      expect(storage.stored, hasLength(1));
      expect(storage.stored.single.title, 'Snacks');
      expect(storage.stored.single.amount, 50);
    });

    testWidgets('ignores repeated rapid taps on save', (
      WidgetTester tester,
    ) async {
      final storage = _BlockingExpenseStorage();
      await _pumpApp(tester, storage);

      await tester.tap(find.byKey(const Key('dashboard-add-expense')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('expense-amount-field')),
        '99',
      );
      await tester.enterText(
        find.byKey(const Key('expense-title-field')),
        'Bus pass',
      );

      final saveButton = find.byKey(const Key('expense-save-button'));
      await tester.tap(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Saving...'), findsOneWidget);

      storage.release.complete();
      await tester.pumpAndSettle();

      expect(storage.saveCount, 1);
      expect(storage.stored, hasLength(1));
    });

    testWidgets('opens details and edits an existing expense', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage(
        initial: <Expense>[
          _expense(
            id: 'metro',
            title: 'Metro card',
            amount: 500,
            category: ExpenseCategory.transport,
            note: 'Monthly recharge',
          ),
        ],
      );
      await _pumpApp(tester, storage);
      await _openExpensesTab(tester);

      await tester.tap(find.text('Metro card'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expense-detail-screen')), findsOneWidget);
      expect(find.text('Expense details'), findsOneWidget);
      expect(find.text('Monthly recharge'), findsOneWidget);
      expect(find.text('₹500.00'), findsOneWidget);

      await tester.tap(find.byKey(const Key('detail-edit-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('expense-amount-field')),
        '650.50',
      );
      await tester.enterText(
        find.byKey(const Key('expense-title-field')),
        'Metro top-up',
      );
      await tester.tap(find.byKey(const Key('expense-save-button')));
      await tester.pumpAndSettle();

      expect(storage.stored.single.title, 'Metro top-up');
      expect(storage.stored.single.amount, 650.50);
      expect(find.byKey(const Key('expense-detail-screen')), findsOneWidget);
      expect(find.text('Metro top-up'), findsOneWidget);
      expect(find.text('₹650.50'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.space_dashboard_outlined));
      await tester.pumpAndSettle();
      expect(find.text('₹650.50'), findsWidgets);
    });

    testWidgets('deletes an expense only after confirmation', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage(
        initial: <Expense>[
          _expense(
            id: 'coffee',
            title: 'Coffee',
            amount: 120,
            category: ExpenseCategory.food,
          ),
        ],
      );
      await _pumpApp(tester, storage);
      await _openExpensesTab(tester);

      await tester.tap(find.text('Coffee'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('detail-delete-button')));
      await tester.pumpAndSettle();
      expect(find.text('Delete expense?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(storage.stored, hasLength(1));
      expect(find.byKey(const Key('expense-detail-screen')), findsOneWidget);

      await tester.tap(find.byKey(const Key('detail-delete-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(storage.stored, isEmpty);
      expect(find.byKey(const Key('expense-detail-screen')), findsNothing);
      expect(find.text('No expenses yet'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.space_dashboard_outlined));
      await tester.pumpAndSettle();
      expect(find.text('₹0.00'), findsWidgets);
      await _scrollListUntilVisible(
        tester,
        find.text('No expenses yet'),
        'dashboard-list',
      );
      expect(find.text('No expenses yet'), findsOneWidget);
    });

    testWidgets('searches and filters the transaction list', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final storage = FakeExpenseStorage(
        initial: <Expense>[
          _expense(
            id: 'metro',
            title: 'Metro card',
            amount: 500,
            category: ExpenseCategory.transport,
            date: now,
          ),
          _expense(
            id: 'groceries',
            title: 'Groceries',
            amount: 900,
            category: ExpenseCategory.food,
            date: now,
          ),
          _expense(
            id: 'old-bill',
            title: 'Old electricity bill',
            amount: 700,
            category: ExpenseCategory.bills,
            date: DateTime(now.year, now.month - 1, 10),
          ),
        ],
      );
      await _pumpApp(tester, storage);
      await _openExpensesTab(tester);

      expect(find.text('Metro card'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Old electricity bill'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Metro card')).dy,
        lessThan(tester.getTopLeft(find.text('Old electricity bill')).dy),
      );

      await tester.enterText(
        find.byKey(const Key('expenses-search-field')),
        'metro',
      );
      await tester.pumpAndSettle();

      expect(find.text('Metro card'), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);
      expect(find.text('Old electricity bill'), findsNothing);

      await tester.tap(find.byKey(const Key('expenses-search-clear')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expenses-category-food')));
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Metro card'), findsNothing);
      expect(find.text('Old electricity bill'), findsNothing);

      await tester.tap(find.byKey(const Key('expenses-clear-filters')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expenses-filter-month')));
      await tester.pumpAndSettle();

      expect(find.text('Metro card'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Old electricity bill'), findsNothing);
    });

    testWidgets('summary uses real totals, charts, and month navigation', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final storage = FakeExpenseStorage(
        initial: <Expense>[
          _expense(
            id: 'groceries',
            title: 'Groceries',
            amount: 900,
            category: ExpenseCategory.food,
            date: now,
          ),
          _expense(
            id: 'metro',
            title: 'Metro card',
            amount: 500,
            category: ExpenseCategory.transport,
            date: now,
          ),
          _expense(
            id: 'old-bill',
            title: 'Old electricity bill',
            amount: 700,
            category: ExpenseCategory.bills,
            date: DateTime(now.year, now.month - 1, 10),
          ),
        ],
      );
      await _pumpApp(tester, storage);

      await tester.tap(find.byIcon(Icons.pie_chart_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Summary'), findsWidgets);
      expect(find.byKey(const Key('summary-month-previous')), findsOneWidget);
      expect(find.text('TOTAL SPENDING'), findsOneWidget);
      expect(find.text('₹1,400.00'), findsOneWidget);
      expect(find.byType(CategoryDonutChart), findsOneWidget);
      expect(find.text('Food'), findsWidgets);
      expect(find.text('Transport'), findsWidgets);

      await tester.tap(find.byKey(const Key('summary-month-previous')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('summary-month-next')), findsOneWidget);
      expect(find.text('₹700.00'), findsWidgets);
      expect(find.text('Bills'), findsWidgets);

      await _scrollListUntilVisible(
        tester,
        find.byType(MonthlyBarChart),
        'summary-list',
      );
      expect(find.byType(MonthlyBarChart), findsOneWidget);
    });

    testWidgets('summary filters totals, breakdown, and trends by category', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final storage = FakeExpenseStorage(
        initial: <Expense>[
          _expense(
            id: 'groceries',
            title: 'Groceries',
            amount: 900,
            category: ExpenseCategory.food,
            date: now,
          ),
          _expense(
            id: 'metro',
            title: 'Metro card',
            amount: 500,
            category: ExpenseCategory.transport,
            date: now,
          ),
          _expense(
            id: 'old-bill',
            title: 'Old electricity bill',
            amount: 700,
            category: ExpenseCategory.bills,
            date: DateTime(now.year, now.month - 1, 10),
          ),
        ],
      );
      await _pumpApp(tester, storage);

      await tester.tap(find.byIcon(Icons.pie_chart_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('summary-category-all')), findsOneWidget);
      final foodFilter = find.byKey(const Key('summary-category-food'));
      expect(foodFilter, findsOneWidget);

      await tester.tap(foodFilter);
      await tester.pumpAndSettle();

      expect(find.text('FOOD SPENDING'), findsOneWidget);
      expect(find.text('₹900.00'), findsWidgets);
      expect(find.text('₹1,400.00'), findsNothing);
      expect(find.byType(CategoryDonutChart), findsOneWidget);

      await tester.tap(find.byKey(const Key('summary-month-previous')));
      await tester.pumpAndSettle();

      expect(find.text('₹0.00'), findsWidgets);
      expect(find.text('No food spending'), findsOneWidget);

      await _scrollListUntilVisible(
        tester,
        find.text('No spending in this period'),
        'summary-list',
      );
      expect(find.text('No spending in this period'), findsOneWidget);

      await tester.dragUntilVisible(
        find.byKey(const Key('summary-category-all')),
        find.byKey(const Key('summary-list')),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('summary-category-all')));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL SPENDING'), findsOneWidget);
      expect(find.text('₹700.00'), findsWidgets);
    });

    testWidgets('keeps the save action above the soft keyboard', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage();
      await _pumpApp(tester, storage);

      await tester.tap(find.byKey(const Key('dashboard-add-expense')));
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final saveRect = tester.getRect(
        find.byKey(const Key('expense-save-button')),
      );
      expect(saveRect.bottom, lessThanOrEqualTo(844 - 320));
    });
  });
}

Future<void> _pumpApp(WidgetTester tester, FakeExpenseStorage storage) async {
  _configureView(tester);

  await tester.pumpWidget(SpendTrackApp(repository: storage));
  await tester.pumpAndSettle();
}

void _configureView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openExpensesTab(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.receipt_long_outlined));
  await tester.pumpAndSettle();
}

Future<void> _scrollListUntilVisible(
  WidgetTester tester,
  Finder target,
  String listKey,
) async {
  await tester.dragUntilVisible(
    target,
    find.byKey(Key(listKey)),
    const Offset(0, -300),
  );
  await tester.pumpAndSettle();
}

Expense _expense({
  required String id,
  required String title,
  required double amount,
  required ExpenseCategory category,
  DateTime? date,
  String? note,
}) {
  final timestamp = date ?? DateTime.now();
  return Expense(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: DateTime(timestamp.year, timestamp.month, timestamp.day),
    createdAt: timestamp,
    note: note,
  );
}

/// Storage that holds writes open so a rapid double tap can be simulated.
class _BlockingExpenseStorage extends FakeExpenseStorage {
  final Completer<void> release = Completer<void>();

  @override
  Future<void> insertExpense(Expense expense) async {
    await release.future;
    return super.insertExpense(expense);
  }
}

/// Storage that keeps loading until the test releases it.
class _BlockingLoadStorage extends FakeExpenseStorage {
  final Completer<void> release = Completer<void>();

  @override
  Future<List<Expense>> loadExpenses() async {
    await release.future;
    return super.loadExpenses();
  }
}
