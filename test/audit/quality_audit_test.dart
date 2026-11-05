import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendtrack/app.dart';
import 'package:spendtrack/models/expense.dart';
import 'package:spendtrack/models/expense_category.dart';

import '../support/fake_expense_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpendTrack quality audit', () {
    testWidgets('reaches every mandatory screen and survives rotation', (
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

      expect(find.byKey(const Key('dashboard-list')), findsOneWidget);

      await _openExpensesTab(tester);
      expect(find.byKey(const Key('expenses-list')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pie_chart_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('summary-list')), findsOneWidget);

      await tester.tap(find.byKey(const Key('summary-add-expense')));
      await tester.pumpAndSettle();
      expect(find.text('Add expense'), findsOneWidget);
      expect(find.byKey(const Key('expense-save-button')), findsOneWidget);

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('summary-list')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.space_dashboard_outlined));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dashboard-list')), findsOneWidget);

      await _openExpensesTab(tester);
      await _scrollUntilVisible(
        tester,
        find.text('Metro card'),
        'expenses-list',
      );
      await tester.tap(find.text('Metro card'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('expense-detail-screen')), findsOneWidget);
      expect(find.text('Monthly recharge'), findsOneWidget);

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('expense-detail-screen')), findsOneWidget);
    });

    testWidgets('handles compact and landscape layouts without overflow', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage(
        initial: <Expense>[
          _expense(
            id: 'groceries',
            title: 'Groceries for the week',
            amount: 900,
            category: ExpenseCategory.food,
          ),
          _expense(
            id: 'metro',
            title: 'Metro card',
            amount: 500,
            category: ExpenseCategory.transport,
          ),
        ],
      );
      await _pumpApp(tester, storage);

      for (final size in const <Size>[
        Size(320, 568),
        Size(844, 390),
        Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'dashboard at $size');

        await _openExpensesTab(tester);
        expect(tester.takeException(), isNull, reason: 'expenses at $size');

        await tester.tap(find.byIcon(Icons.pie_chart_outline_rounded));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'summary at $size');

        await tester.tap(find.byKey(const Key('summary-add-expense')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'form at $size');

        await tester.tap(find.byType(CloseButton));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('persists data across a restart and handles long notes', (
      WidgetTester tester,
    ) async {
      final longNote = List<String>.generate(
        120,
        (index) => 'Detail $index',
      ).join(' ');
      const title = 'A long but valid expense title for testing';
      final storage = FakeExpenseStorage(
        initial: <Expense>[
          _expense(
            id: 'long-note',
            title: title,
            amount: 42.75,
            category: ExpenseCategory.other,
            note: longNote,
          ),
        ],
      );
      await _pumpApp(tester, storage);

      await _openExpensesTab(tester);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.text(longNote), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('expenses-search-field')),
        'Detail 119',
      );
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(SpendTrackApp(repository: storage));
      await tester.pumpAndSettle();

      expect(storage.loadCount, 2);
      await _openExpensesTab(tester);
      expect(find.text(title), findsOneWidget);
      expect(find.text('₹42.75'), findsWidgets);
    });

    testWidgets('opens only one form when add is tapped repeatedly', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage();
      await _pumpApp(tester, storage);

      final addButton = find.byKey(const Key('dashboard-add-expense'));
      await tester.tap(addButton);
      // The pushed route's barrier should absorb the second tap.
      await tester.tap(addButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expense-save-button')), findsOneWidget);

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.text('TOTAL SPENDING'), findsOneWidget);
      expect(find.byKey(const Key('dashboard-list')), findsOneWidget);
    });

    testWidgets('opens one delete prompt and deletes exactly once', (
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

      final deleteButton = find.byKey(const Key('detail-delete-button'));
      await tester.tap(deleteButton);
      // The modal barrier should absorb the second tap.
      await tester.tap(deleteButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Delete expense?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(storage.stored, isEmpty);
      expect(find.byKey(const Key('expense-detail-screen')), findsNothing);
      expect(find.textContaining('could not be found'), findsNothing);
    });

    testWidgets('deleting from the edit form closes both routes cleanly', (
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

      await tester.tap(find.byKey(const Key('detail-edit-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expense-delete-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(storage.stored, isEmpty);
      expect(find.byKey(const Key('expense-detail-screen')), findsNothing);
      expect(find.byKey(const Key('expenses-list')), findsOneWidget);
      expect(find.text('Expense deleted.'), findsOneWidget);
      expect(find.text('No expenses yet'), findsOneWidget);
    });

    testWidgets('keeps the form open with a readable error and retries', (
      WidgetTester tester,
    ) async {
      final storage = FakeExpenseStorage()..failSave = true;
      await _pumpApp(tester, storage);

      await tester.tap(find.byKey(const Key('dashboard-add-expense')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('expense-amount-field')),
        '75',
      );
      await tester.enterText(
        find.byKey(const Key('expense-title-field')),
        'Retry me',
      );

      await tester.tap(find.byKey(const Key('expense-save-button')));
      await tester.pumpAndSettle();

      expect(find.text('Save failed.'), findsOneWidget);
      expect(find.byKey(const Key('expense-save-button')), findsOneWidget);
      expect(find.text('Retry me'), findsOneWidget);
      expect(storage.stored, isEmpty);

      // Let the snackbar clear so it no longer covers the retry action.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      storage.failSave = false;
      await tester.tap(find.byKey(const Key('expense-save-button')));
      await tester.pumpAndSettle();

      expect(storage.stored, hasLength(1));
      expect(storage.stored.single.title, 'Retry me');
      expect(find.byKey(const Key('dashboard-list')), findsOneWidget);
      expect(find.text('Save failed.'), findsNothing);
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

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder target,
  String listKey,
) async {
  await tester.dragUntilVisible(
    target,
    find.byKey(Key(listKey)),
    const Offset(0, -250),
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
