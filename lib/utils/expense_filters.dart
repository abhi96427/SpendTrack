import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/expense_sort.dart';

/// Applies the expenses screen search, category, date, and sort rules.
///
/// Keeping this logic outside the widget makes the behaviour directly
/// testable and ensures the screen and tests share one interpretation of an
/// inclusive date range.
List<Expense> filterExpenses({
  required Iterable<Expense> expenses,
  String query = '',
  ExpenseCategory? category,
  DateTime? from,
  DateTime? to,
  bool currentMonthOnly = false,
  ExpenseSortOrder sort = ExpenseSortOrder.newest,
  DateTime? now,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final today = now ?? DateTime.now();
  final monthStart = DateTime(today.year, today.month);
  final monthEnd = DateTime(today.year, today.month + 1, 0);
  final rangeStart = from == null ? null : _dayOnly(from);
  final rangeEnd = to == null ? null : _dayOnly(to);

  final filtered = expenses.where((expense) {
    final day = _dayOnly(expense.date);

    if (currentMonthOnly &&
        (day.isBefore(monthStart) || day.isAfter(monthEnd))) {
      return false;
    }
    if (rangeStart != null && day.isBefore(rangeStart)) {
      return false;
    }
    if (rangeEnd != null && day.isAfter(rangeEnd)) {
      return false;
    }
    if (category != null && expense.category != category) {
      return false;
    }
    if (normalizedQuery.isNotEmpty) {
      final searchable =
          '${expense.title} ${expense.category.label} '
                  '${expense.note ?? ''}'
              .toLowerCase();
      if (!searchable.contains(normalizedQuery)) {
        return false;
      }
    }
    return true;
  });

  return sort.sort(filtered);
}

DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);
