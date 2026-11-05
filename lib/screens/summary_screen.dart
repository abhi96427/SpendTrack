import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/add_expense_button.dart';
import '../widgets/app_card.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/category_spending_list.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_banner.dart';
import '../widgets/month_selector.dart';
import '../widgets/monthly_bar_chart.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_header.dart';

/// Month-by-month insight view built entirely from persisted expenses.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.onOpenExpense});

  final Future<void> Function(Expense? expense) onOpenExpense;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late DateTime _month;
  ExpenseCategory? _category;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _previousMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
  }

  void _nextMonth() {
    if (!_isCurrentMonth) {
      setState(() => _month = DateTime(_month.year, _month.month + 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final category = _category;
    final total = provider.totalForMonth(_month, category: category);
    final previousTotal = provider.totalForPreviousMonth(
      _month,
      category: category,
    );
    final count = provider.countForMonth(_month, category: category);
    final categoryTotals = provider.categoryTotals(
      month: _month,
      category: category,
    );
    final categoryLabel = category?.label.toLowerCase();

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const Key('summary-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          ScreenHeader(
            title: 'Summary',
            subtitle: 'Understand where your money goes',
            action: AddExpenseButton(
              key: const Key('summary-add-expense'),
              onPressed: () => widget.onOpenExpense(null),
            ),
          ),
          const SizedBox(height: 20),
          MonthSelector(
            month: _month,
            onPrevious: _previousMonth,
            onNext: _nextMonth,
            canGoNext: !_isCurrentMonth,
          ),
          if (provider.hasExpenses) ...<Widget>[
            const SizedBox(height: 14),
            CategoryFilterBar(
              selected: category,
              onSelected: (value) => setState(() => _category = value),
              keyPrefix: 'summary-category',
            ),
          ],
          if (provider.errorMessage != null) ...<Widget>[
            const SizedBox(height: 14),
            ErrorBanner(
              message: provider.errorMessage!,
              onDismiss: provider.clearError,
            ),
          ],
          const SizedBox(height: 18),
          if (!provider.hasExpenses)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: EmptyStateView(
                icon: Icons.pie_chart_rounded,
                title: 'Nothing to summarize yet',
                message:
                    'Add your first expense to see category breakdowns and '
                    'monthly spending trends here.',
                actionLabel: 'Add expense',
                onAction: () => widget.onOpenExpense(null),
                filledAction: true,
              ),
            )
          else ...<Widget>[
            _MonthlyTotalCard(
              total: total,
              previousTotal: previousTotal,
              count: count,
              month: _month,
              category: category,
            ),
            const SizedBox(height: 26),
            SectionHeader(
              title: 'Category breakdown',
              subtitle: category == null
                  ? formatMonthYear(_month)
                  : '${category.label} • ${formatMonthYear(_month)}',
            ),
            const SizedBox(height: 12),
            if (total <= 0)
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: EmptyStateView(
                  icon: Icons.donut_large_rounded,
                  title: category == null
                      ? 'No spending in this month'
                      : 'No $categoryLabel spending',
                  message: category == null
                      ? 'There are no expenses recorded for '
                            '${formatMonthYear(_month)}. Use the arrows above '
                            'to browse another month.'
                      : 'There are no $categoryLabel expenses recorded for '
                            '${formatMonthYear(_month)}. Try another category '
                            'or month.',
                  actionLabel: _isCurrentMonth ? 'Add expense' : null,
                  onAction: _isCurrentMonth
                      ? () => widget.onOpenExpense(null)
                      : null,
                  compact: true,
                ),
              )
            else
              AppCard(
                child: Column(
                  children: <Widget>[
                    CategoryDonutChart(totals: categoryTotals),
                    const SizedBox(height: 22),
                    const Divider(),
                    const SizedBox(height: 18),
                    CategorySpendingList(totals: categoryTotals),
                  ],
                ),
              ),
            const SizedBox(height: 26),
            SectionHeader(
              title: 'Monthly trend',
              subtitle: category == null
                  ? 'Six months ending ${formatMonthYear(_month)}'
                  : '${category.label} spending, six months ending '
                        '${formatMonthYear(_month)}',
            ),
            const SizedBox(height: 12),
            MonthlyBarChart(
              months: provider.monthlyTotals(
                endMonth: _month,
                count: 6,
                category: category,
              ),
              highlightedMonth: _month,
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlyTotalCard extends StatelessWidget {
  const _MonthlyTotalCard({
    required this.total,
    required this.previousTotal,
    required this.count,
    required this.month,
    this.category,
  });

  final double total;
  final double previousTotal;
  final int count;
  final DateTime month;
  final ExpenseCategory? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = _ChangeSummary.from(
      total: total,
      previousTotal: previousTotal,
    );
    final transactionLabel = count == 1
        ? '1 transaction'
        : '$count transactions';
    final heading = category == null
        ? 'TOTAL SPENDING'
        : '${category!.label.toUpperCase()} SPENDING';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.navy, AppColors.navyDeep],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -50,
              top: -60,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          heading,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.64),
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          formatMonthYear(month).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatCurrency(total),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 17,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          transactionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prev ${formatCompactCurrency(previousTotal)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  if (change != null) ...<Widget>[
                    const SizedBox(height: 14),
                    change,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeSummary extends StatelessWidget {
  const _ChangeSummary({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  static _ChangeSummary? from({
    required double total,
    required double previousTotal,
  }) {
    if (previousTotal <= 0) {
      if (total <= 0) {
        return null;
      }
      return const _ChangeSummary(
        label: 'First month with recorded spending',
        color: AppColors.accent,
        icon: Icons.auto_awesome_rounded,
      );
    }

    final change = ((total - previousTotal) / previousTotal) * 100;
    if (change.abs() < 0.05) {
      return const _ChangeSummary(
        label: 'Same as last month',
        color: AppColors.textSecondary,
        icon: Icons.remove_rounded,
      );
    }

    final isIncrease = change > 0;
    final sign = isIncrease ? '+' : '';
    return _ChangeSummary(
      label: '$sign${change.toStringAsFixed(1)}% vs last month',
      color: isIncrease ? AppColors.danger : AppColors.success,
      icon: isIncrease
          ? Icons.trending_up_rounded
          : Icons.trending_down_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
