import 'expense.dart';

/// Ordering options available on the expenses list.
enum ExpenseSortOrder {
  newest('Newest first', 'Newest'),
  oldest('Oldest first', 'Oldest'),
  highestAmount('Highest amount', 'Highest');

  const ExpenseSortOrder(this.label, this.shortLabel);

  /// Full label used in the sort menu.
  final String label;

  /// Compact label used in the toolbar.
  final String shortLabel;

  /// Returns a new, sorted list without mutating [expenses].
  List<Expense> sort(Iterable<Expense> expenses) {
    final result = List<Expense>.of(expenses);
    result.sort((a, b) {
      switch (this) {
        case ExpenseSortOrder.newest:
          final byDate = b.date.compareTo(a.date);
          return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
        case ExpenseSortOrder.oldest:
          final byDate = a.date.compareTo(b.date);
          return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
        case ExpenseSortOrder.highestAmount:
          final byAmount = b.amount.compareTo(a.amount);
          if (byAmount != 0) {
            return byAmount;
          }
          final byDate = b.date.compareTo(a.date);
          return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      }
    });
    return result;
  }
}
