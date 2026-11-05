import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:spendtrack/models/app_currency.dart';
import 'package:spendtrack/models/app_settings.dart';
import 'package:spendtrack/models/expense.dart';
import 'package:spendtrack/models/expense_category.dart';
import 'package:spendtrack/services/expense_database.dart';
import 'package:spendtrack/services/expense_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Expense _expense({
  String id = 'expense-1',
  String title = 'Train ticket',
  double amount = 45.75,
  ExpenseCategory category = ExpenseCategory.transport,
  DateTime? date,
  DateTime? createdAt,
  String? note,
}) {
  final timestamp = date ?? DateTime(2026, 3, 14, 9, 30);
  return Expense(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: DateTime(timestamp.year, timestamp.month, timestamp.day),
    createdAt: createdAt ?? timestamp,
    note: note,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDirectory;
  late String databasePath;
  late ExpenseDatabase database;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('spendtrack_db_');
    databasePath = p.join(tempDirectory.path, 'spendtrack.db');
    database = ExpenseDatabase(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('ExpenseDatabase', () {
    test('starts empty', () async {
      expect(await database.loadExpenses(), isEmpty);
    });

    test('inserts and reloads every field', () async {
      final expense = _expense(note: '  Monthly recharge  ');

      await database.insertExpense(expense);
      final loaded = await database.loadExpenses();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, expense.id);
      expect(loaded.single.title, expense.title);
      expect(loaded.single.amount, expense.amount);
      expect(loaded.single.category, ExpenseCategory.transport);
      expect(loaded.single.date, expense.date);
      expect(loaded.single.createdAt, expense.createdAt);
      expect(loaded.single.note, 'Monthly recharge');
    });

    test('returns expenses newest first with a stable tie-breaker', () async {
      final older = _expense(
        id: 'older',
        date: DateTime(2026, 1, 5),
        createdAt: DateTime(2026, 1, 5, 8),
      );
      final newer = _expense(
        id: 'newer',
        date: DateTime(2026, 2, 5),
        createdAt: DateTime(2026, 2, 5, 8),
      );
      final sameDayLater = _expense(
        id: 'same-day-later',
        date: DateTime(2026, 2, 5),
        createdAt: DateTime(2026, 2, 5, 18),
      );

      for (final expense in <Expense>[older, sameDayLater, newer]) {
        await database.insertExpense(expense);
      }

      final loaded = await database.loadExpenses();
      expect(loaded.map((expense) => expense.id), <String>[
        'same-day-later',
        'newer',
        'older',
      ]);
    });

    test('updates an existing record', () async {
      final original = _expense();
      await database.insertExpense(original);

      final edited = original.copyWith(
        title: 'Train ticket (first class)',
        amount: 120.25,
        category: ExpenseCategory.other,
        note: 'Seat reservation',
      );
      await database.updateExpense(edited);

      final loaded = await database.loadExpenses();
      expect(loaded, hasLength(1));
      expect(loaded.single, edited);
    });

    test('deletes a record', () async {
      final keep = _expense(id: 'keep');
      await database.insertExpense(keep);
      await database.insertExpense(_expense(id: 'remove'));

      await database.deleteExpense('remove');

      final loaded = await database.loadExpenses();
      expect(loaded.map((expense) => expense.id), <String>['keep']);
    });

    test('clears all records', () async {
      await database.insertExpense(_expense(id: 'one'));
      await database.insertExpense(_expense(id: 'two'));

      await database.clearExpenses();

      expect(await database.loadExpenses(), isEmpty);
    });

    test('persists settings across database reopen', () async {
      const settings = AppSettings(
        themeMode: AppThemeMode.dark,
        currency: AppCurrency.usd,
      );
      expect(await database.loadSettings(), AppSettings.defaults);
      await database.saveSettings(settings);
      expect(await database.loadSettings(), settings);
      await database.close();

      final reopened = ExpenseDatabase(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(reopened.close);
      expect(await reopened.loadSettings(), settings);
    });

    test('reports duplicate ids as a storage error', () async {
      final expense = _expense();
      await database.insertExpense(expense);

      await expectLater(
        database.insertExpense(expense),
        throwsA(
          isA<StorageException>().having(
            (error) => error.message,
            'message',
            contains('already exists'),
          ),
        ),
      );
      expect(await database.loadExpenses(), hasLength(1));
    });

    test('reports missing records when updating or deleting', () async {
      await expectLater(
        database.updateExpense(_expense(id: 'missing')),
        throwsA(isA<StorageException>()),
      );
      await expectLater(
        database.deleteExpense('missing'),
        throwsA(isA<StorageException>()),
      );
    });

    test('keeps data after the database is closed and reopened', () async {
      await database.insertExpense(_expense(id: 'persisted', amount: 999.99));
      await database.close();

      final reopened = ExpenseDatabase(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      addTearDown(reopened.close);

      final loaded = await reopened.loadExpenses();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'persisted');
      expect(loaded.single.amount, 999.99);
    });

    test('wraps open failures in a user-facing storage error', () async {
      final blockedPath = p.join(tempDirectory.path, 'not-a-database');
      // A directory occupying the database path makes SQLite refuse to open.
      Directory(blockedPath).createSync();

      final broken = ExpenseDatabase(
        factory: databaseFactoryFfi,
        databasePath: blockedPath,
      );
      addTearDown(broken.close);

      await expectLater(
        broken.loadExpenses(),
        throwsA(
          isA<StorageException>().having(
            (error) => error.message,
            'message',
            contains('Unable to open'),
          ),
        ),
      );
    });
  });
}
