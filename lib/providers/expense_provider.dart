import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/month_total.dart';
import '../services/expense_repository.dart';

/// Owns the in-memory expense list and keeps it in sync with local storage.
///
/// Mutations are applied optimistically, then rolled back if persistence fails,
/// so the UI never claims a change was saved when it was not.
class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({required ExpenseRepository repository})
    : _repository = repository;

  final ExpenseRepository _repository;

  List<Expense> _expenses = const <Expense>[];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  UnmodifiableListView<Expense> get expenses =>
      UnmodifiableListView<Expense>(_expenses);

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasExpenses => _expenses.isNotEmpty;
  String? get errorMessage => _errorMessage;

  int get expenseCount => _expenses.length;

  double get totalAmount =>
      _expenses.fold<double>(0, (total, expense) => total + expense.amount);

  int get currentMonthCount => countForMonth(DateTime.now());

  double get currentMonthTotal => totalForMonth(DateTime.now());

  double get todayTotal {
    final now = DateTime.now();
    return _expenses
        .where(
          (expense) =>
              expense.date.year == now.year &&
              expense.date.month == now.month &&
              expense.date.day == now.day,
        )
        .fold<double>(0, (total, expense) => total + expense.amount);
  }

  /// Most recent expenses, already ordered newest first.
  List<Expense> recentExpenses({int limit = 4}) {
    return _expenses.take(limit).toList(growable: false);
  }

  List<Expense> expensesForMonth(DateTime month, {ExpenseCategory? category}) {
    return _expenses
        .where((expense) {
          if (expense.date.year != month.year ||
              expense.date.month != month.month) {
            return false;
          }
          return category == null || expense.category == category;
        })
        .toList(growable: false);
  }

  int countForMonth(DateTime month, {ExpenseCategory? category}) {
    return expensesForMonth(month, category: category).length;
  }

  double totalForMonth(DateTime month, {ExpenseCategory? category}) {
    return expensesForMonth(
      month,
      category: category,
    ).fold<double>(0, (total, expense) => total + expense.amount);
  }

  double totalForPreviousMonth(DateTime month, {ExpenseCategory? category}) {
    return totalForMonth(
      DateTime(month.year, month.month - 1),
      category: category,
    );
  }

  /// Category totals for [month], or all time when [month] is null.
  ///
  /// When [category] is provided only that category is accumulated, which lets
  /// the summary screen reuse the same analytics for filtered views.
  ///
  /// Every category is present so callers can filter out zero values while the
  /// provider remains the single source of truth for derived spending data.
  Map<ExpenseCategory, double> categoryTotals({
    DateTime? month,
    ExpenseCategory? category,
  }) {
    final totals = <ExpenseCategory, double>{
      for (final value in ExpenseCategory.values) value: 0,
    };

    for (final expense in _expenses) {
      if (month != null &&
          (expense.date.year != month.year ||
              expense.date.month != month.month)) {
        continue;
      }
      if (category != null && expense.category != category) {
        continue;
      }
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  /// Totals for the [count] months ending with [endMonth], oldest first.
  List<MonthTotal> monthlyTotals({
    required DateTime endMonth,
    int count = 6,
    ExpenseCategory? category,
  }) {
    final totals = <MonthTotal>[];
    for (var index = count - 1; index >= 0; index--) {
      final month = DateTime(endMonth.year, endMonth.month - index);
      totals.add(
        MonthTotal(
          month: month,
          total: totalForMonth(month, category: category),
        ),
      );
    }
    return totals;
  }

  /// Loads persisted expenses. Safe to call again to retry or refresh.
  Future<void> initialize() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _repository.loadExpenses();
      _expenses = _sorted(loaded);
      _isInitialized = true;
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) {
    if (_expenses.any((item) => item.id == expense.id)) {
      _errorMessage = 'An expense with this ID already exists.';
      notifyListeners();
      return Future<bool>.value(false);
    }

    return _commit(<Expense>[
      ..._expenses,
      expense,
    ], () => _repository.insertExpense(expense));
  }

  Future<bool> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      _errorMessage = 'That expense could not be found.';
      notifyListeners();
      return false;
    }

    final updated = <Expense>[..._expenses];
    updated[index] = expense;
    return _commit(updated, () => _repository.updateExpense(expense));
  }

  Future<bool> deleteExpense(String id) async {
    final updated = _expenses.where((expense) => expense.id != id).toList();
    if (updated.length == _expenses.length) {
      _errorMessage = 'That expense could not be found.';
      notifyListeners();
      return false;
    }

    return _commit(updated, () => _repository.deleteExpense(id));
  }

  /// Removes every stored expense after the UI has confirmed the action.
  Future<bool> clearExpenses() {
    if (_expenses.isEmpty) {
      return Future<bool>.value(true);
    }
    return _commit(const <Expense>[], _repository.clearExpenses);
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  /// Applies [next] optimistically, then persists the single change.
  Future<bool> _commit(
    List<Expense> next,
    Future<void> Function() persist,
  ) async {
    final previous = _expenses;

    _expenses = _sorted(next);
    _errorMessage = null;
    notifyListeners();

    try {
      await persist();
      return true;
    } catch (error) {
      _expenses = previous;
      _errorMessage = _messageFor(error);
      notifyListeners();
      return false;
    }
  }

  List<Expense> _sorted(List<Expense> expenses) {
    return List<Expense>.of(expenses)..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) {
        return byDate;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  String _messageFor(Object error) {
    if (error is StorageException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'Your saved data is in an unexpected format.';
    }
    return 'Something went wrong. Please try again.';
  }
}
