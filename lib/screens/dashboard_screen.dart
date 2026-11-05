import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/currency_context.dart';
import '../widgets/app_card.dart';
import '../widgets/category_spending_list.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_banner.dart';
import '../widgets/expense_tile.dart';
import '../widgets/monthly_bar_chart.dart';
import '../widgets/section_header.dart';

/// Premium overview of total spending, trends, categories, and recent activity.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenExpense,
    required this.onViewAllExpenses,
    required this.onViewSummary,
  });

  final Future<void> Function(Expense? expense) onOpenExpense;
  final VoidCallback onViewAllExpenses;
  final VoidCallback onViewSummary;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final now = DateTime.now();
    final recent = provider.recentExpenses(limit: 4);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: provider.initialize,
        child: ListView(
          key: const Key('dashboard-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: <Widget>[
            const _DashboardHeader(),
            const SizedBox(height: 22),
            _TotalSpendingCard(
              totalAmount: provider.totalAmount,
              monthTotal: provider.currentMonthTotal,
              todayTotal: provider.todayTotal,
              expenseCount: provider.expenseCount,
              onAdd: () => onOpenExpense(null),
            ),
            if (provider.errorMessage != null) ...<Widget>[
              const SizedBox(height: 14),
              ErrorBanner(
                message: provider.errorMessage!,
                onDismiss: provider.clearError,
              ),
            ],
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Monthly spending',
              subtitle: 'Your last six months',
              actionLabel: 'Summary',
              onAction: onViewSummary,
            ),
            const SizedBox(height: 12),
            MonthlyBarChart(
              months: provider.monthlyTotals(endMonth: now, count: 6),
              highlightedMonth: now,
            ),
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Spending by category',
              subtitle: formatMonthYear(now),
              actionLabel: 'View all',
              onAction: onViewAllExpenses,
            ),
            const SizedBox(height: 12),
            AppCard(
              child: CategorySpendingList(
                totals: provider.categoryTotals(month: now),
                maxItems: 4,
                emptyMessage: 'No spending recorded this month.',
              ),
            ),
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Recent transactions',
              actionLabel: provider.hasExpenses ? 'View all' : null,
              onAction: provider.hasExpenses ? onViewAllExpenses : null,
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: EmptyStateView(
                  icon: Icons.receipt_long_rounded,
                  title: 'No expenses yet',
                  message:
                      'Add your first expense and it will appear here '
                      'with your monthly insights.',
                  actionLabel: 'Add expense',
                  onAction: () => onOpenExpense(null),
                  compact: true,
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (var index = 0; index < recent.length; index++) ...[
                      ExpenseTile(
                        expense: recent[index],
                        onTap: () => onOpenExpense(recent[index]),
                      ),
                      if (index != recent.length - 1)
                        const Divider(indent: 75, endIndent: 16),
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: context.palette.brand,
            borderRadius: BorderRadius.circular(15),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: context.palette.navy.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'SpendTrack',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatFullDate(DateTime.now()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalSpendingCard extends StatelessWidget {
  const _TotalSpendingCard({
    required this.totalAmount,
    required this.monthTotal,
    required this.todayTotal,
    required this.expenseCount,
    required this.onAdd,
  });

  final double totalAmount;
  final double monthTotal;
  final double todayTotal;
  final int expenseCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entryLabel = expenseCount == 1 ? '1 entry' : '$expenseCount entries';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[context.palette.brand, context.palette.brandDeep],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.palette.navy.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -42,
              top: -56,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
            Positioned(
              right: 32,
              bottom: -58,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.palette.accent.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'TOTAL SPENDING',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.66),
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
                          entryLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
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
                      formatCurrency(totalAmount, currency: context.currency),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _HeroStat(
                          label: 'This month',
                          value: formatCurrency(
                            monthTotal,
                            currency: context.currency,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _HeroStat(
                          label: 'Today',
                          value: formatCurrency(
                            todayTotal,
                            currency: context.currency,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('dashboard-add-expense'),
                      onPressed: onAdd,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: context.palette.navy,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add expense'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.58),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
