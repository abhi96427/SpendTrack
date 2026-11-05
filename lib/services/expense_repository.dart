import '../models/expense.dart';

/// Abstraction over local expense persistence.
///
/// CRUD is deliberately granular so the provider can persist a single change
/// instead of rewriting the entire dataset on every edit. Keeping this as an
/// interface means storage can be swapped (for example with an in-memory fake)
/// and allows providers to be tested in isolation.
abstract interface class ExpenseRepository {
  /// Returns every stored expense, newest first.
  Future<List<Expense>> loadExpenses();

  /// Stores a new expense.
  ///
  /// Throws a [StorageException] when the record cannot be written or its id
  /// already exists.
  Future<void> insertExpense(Expense expense);

  /// Replaces the stored expense with the same id.
  ///
  /// Throws a [StorageException] when no matching record exists.
  Future<void> updateExpense(Expense expense);

  /// Removes the expense with [id].
  ///
  /// Throws a [StorageException] when no matching record exists.
  Future<void> deleteExpense(String id);

  /// Removes every stored expense.
  Future<void> clearExpenses();
}

/// A user-facing persistence failure.
///
/// [message] is safe to display in the UI; [cause] is kept for diagnostics.
class StorageException implements Exception {
  const StorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'StorageException: $message';
}
