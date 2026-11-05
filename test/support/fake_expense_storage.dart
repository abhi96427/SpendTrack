import 'package:spendtrack/models/expense.dart';
import 'package:spendtrack/services/expense_repository.dart';

/// In-memory [ExpenseRepository] used by unit and widget tests.
class FakeExpenseStorage implements ExpenseRepository {
  FakeExpenseStorage({List<Expense> initial = const <Expense>[]})
    : _expenses = List<Expense>.of(initial);

  List<Expense> _expenses;

  bool failLoad = false;
  bool failSave = false;
  int loadCount = 0;
  int saveCount = 0;

  List<Expense> get stored => List<Expense>.unmodifiable(_expenses);

  @override
  Future<List<Expense>> loadExpenses() async {
    loadCount++;
    if (failLoad) {
      throw const StorageException('Load failed.');
    }
    return List<Expense>.of(_expenses);
  }

  @override
  Future<void> insertExpense(Expense expense) async {
    _beforeWrite();

    if (_expenses.any((item) => item.id == expense.id)) {
      throw const StorageException('An expense with this ID already exists.');
    }
    _expenses = <Expense>[..._expenses, expense];
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    _beforeWrite();

    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      throw const StorageException('That expense could not be found.');
    }

    final updated = List<Expense>.of(_expenses);
    updated[index] = expense;
    _expenses = updated;
  }

  @override
  Future<void> deleteExpense(String id) async {
    _beforeWrite();

    final updated = _expenses
        .where((expense) => expense.id != id)
        .toList(growable: false);
    if (updated.length == _expenses.length) {
      throw const StorageException('That expense could not be found.');
    }
    _expenses = updated;
  }

  @override
  Future<void> clearExpenses() async {
    _beforeWrite();
    _expenses = <Expense>[];
  }

  void _beforeWrite() {
    saveCount++;
    if (failSave) {
      throw const StorageException('Save failed.');
    }
  }
}
