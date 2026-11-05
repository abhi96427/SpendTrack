import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/expense_sort.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/currency_context.dart';
import '../utils/expense_filters.dart';
import '../widgets/add_expense_button.dart';
import '../widgets/app_card.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_banner.dart';
import '../widgets/expense_tile.dart';
import '../widgets/screen_header.dart';

/// Searchable, filterable list of every recorded transaction.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, required this.onOpenExpense});

  final Future<void> Function(Expense? expense) onOpenExpense;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  ExpenseCategory? _category;
  bool _thisMonthOnly = false;
  DateTimeRange? _dateRange;
  ExpenseSortOrder _sortOrder = ExpenseSortOrder.newest;

  bool get _hasFilters =>
      _query.trim().isNotEmpty ||
      _category != null ||
      _thisMonthOnly ||
      _dateRange != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Expense> _filteredExpenses(ExpenseProvider provider) {
    return filterExpenses(
      expenses: provider.expenses,
      query: _query,
      category: _category,
      currentMonthOnly: _thisMonthOnly,
      from: _dateRange?.start,
      to: _dateRange?.end,
      sort: _sortOrder,
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _dateRange,
      helpText: 'Select expense date range',
    );
    if (picked != null && mounted) setState(() => _dateRange = picked);
  }

  Map<DateTime, List<Expense>> _groupByDay(List<Expense> expenses) {
    final groups = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      groups.putIfAbsent(day, () => <Expense>[]).add(expense);
    }
    return groups;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
      _thisMonthOnly = false;
      _dateRange = null;
      _sortOrder = ExpenseSortOrder.newest;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final filtered = _filteredExpenses(provider);
    final groups = _groupByDay(filtered);
    final filteredTotal = filtered.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const Key('expenses-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          ScreenHeader(
            title: 'Expenses',
            subtitle: provider.expenseCount == 1
                ? '1 transaction recorded'
                : '${provider.expenseCount} transactions recorded',
            action: AddExpenseButton(
              key: const Key('expenses-add-expense'),
              onPressed: () => widget.onOpenExpense(null),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('expenses-search-field'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search by title, category or note',
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('expenses-search-clear'),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      tooltip: 'Clear search',
                      icon: Icon(Icons.close_rounded, size: 19),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          CategoryFilterBar(
            selected: _category,
            onSelected: (category) => setState(() => _category = category),
            keyPrefix: 'expenses-category',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('expenses-date-range'),
                  onPressed: _pickDateRange,
                  icon: Icon(Icons.date_range_rounded),
                  label: Text(
                    _dateRange == null
                        ? 'Date range'
                        : '${formatCompactDate(_dateRange!.start)} – ${formatCompactDate(_dateRange!.end)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              PopupMenuButton<ExpenseSortOrder>(
                key: const Key('expenses-sort-menu'),
                initialValue: _sortOrder,
                tooltip: 'Sort expenses',
                onSelected: (order) => setState(() => _sortOrder = order),
                itemBuilder: (_) => ExpenseSortOrder.values
                    .map(
                      (order) =>
                          PopupMenuItem(value: order, child: Text(order.label)),
                    )
                    .toList(),
                child: Row(
                  children: [
                    Icon(Icons.sort_rounded, color: context.palette.accent),
                    const SizedBox(width: 5),
                    Text(
                      _sortOrder.shortLabel,
                      style: TextStyle(color: context.palette.accent),
                    ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: context.palette.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_dateRange != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('expenses-clear-date-range'),
                onPressed: () => setState(() => _dateRange = null),
                icon: Icon(Icons.close_rounded, size: 16),
                label: const Text('Remove date range'),
              ),
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    key: const Key('expenses-filter-month'),
                    selected: _thisMonthOnly,
                    onSelected: (selected) =>
                        setState(() => _thisMonthOnly = selected),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: _thisMonthOnly
                          ? context.palette.accent
                          : context.palette.textSecondary,
                    ),
                    label: const Text('This month'),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _thisMonthOnly
                          ? context.palette.accentDark
                          : context.palette.textSecondary,
                    ),
                    selectedColor: context.palette.accentSoft,
                    backgroundColor: context.palette.surface,
                    side: BorderSide(
                      color: _thisMonthOnly
                          ? context.palette.accent.withValues(alpha: 0.45)
                          : context.palette.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_hasFilters)
                TextButton(
                  key: const Key('expenses-clear-filters'),
                  onPressed: _clearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: context.palette.textSecondary,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Clear filters'),
                ),
            ],
          ),
          if (provider.errorMessage != null) ...<Widget>[
            const SizedBox(height: 6),
            ErrorBanner(
              message: provider.errorMessage!,
              onDismiss: provider.clearError,
            ),
          ],
          const SizedBox(height: 18),
          if (provider.expenses.isEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: EmptyStateView(
                icon: Icons.receipt_long_rounded,
                title: 'No expenses yet',
                message:
                    'Start by recording your first expense. Everything you '
                    'add is saved on this device.',
                actionLabel: 'Add expense',
                onAction: () => widget.onOpenExpense(null),
                filledAction: true,
              ),
            )
          else if (filtered.isEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: EmptyStateView(
                icon: Icons.search_off_rounded,
                title: 'No matching expenses',
                message:
                    'No transactions match the current search and filters. '
                    'Try widening your search.',
                actionLabel: 'Clear filters',
                onAction: _clearFilters,
              ),
            )
          else ...<Widget>[
            _FilteredSummary(count: filtered.length, total: filteredTotal),
            const SizedBox(height: 22),
            if (_sortOrder == ExpenseSortOrder.highestAmount)
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0; index < filtered.length; index++) ...[
                      ExpenseTile(
                        expense: filtered[index],
                        onTap: () => widget.onOpenExpense(filtered[index]),
                      ),
                      if (index != filtered.length - 1)
                        const Divider(indent: 75, endIndent: 16),
                    ],
                  ],
                ),
              )
            else
              for (final entry in groups.entries) ...<Widget>[
                _DayHeader(
                  day: entry.key,
                  total: entry.value.fold<double>(
                    0,
                    (total, expense) => total + expense.amount,
                  ),
                ),
                const SizedBox(height: 9),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      for (
                        var index = 0;
                        index < entry.value.length;
                        index++
                      ) ...<Widget>[
                        ExpenseTile(
                          expense: entry.value[index],
                          onTap: () => widget.onOpenExpense(entry.value[index]),
                        ),
                        if (index != entry.value.length - 1)
                          const Divider(indent: 75, endIndent: 16),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
          ],
        ],
      ),
    );
  }
}

class _FilteredSummary extends StatelessWidget {
  const _FilteredSummary({required this.count, required this.total});

  final int count;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      backgroundColor: context.palette.accentSoft,
      borderColor: context.palette.accent.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      borderRadius: 18,
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.filter_alt_rounded,
              size: 19,
              color: context.palette.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 1 ? '1 transaction shown' : '$count transactions shown',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.navySoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatCurrency(total, currency: context.currency),
            style: theme.textTheme.titleMedium?.copyWith(
              color: context.palette.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.total});

  final DateTime day;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            formatRelativeDate(day),
            style: theme.textTheme.labelLarge?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ),
        Text(
          formatCurrency(total, currency: context.currency),
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.palette.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
