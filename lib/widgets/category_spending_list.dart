import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../theme/app_colors.dart';
import '../utils/category_ui.dart';
import '../utils/formatters.dart';
import '../utils/currency_context.dart';

/// Category totals rendered as icon, amount, percentage, and progress bar.
class CategorySpendingList extends StatelessWidget {
  const CategorySpendingList({
    super.key,
    required this.totals,
    this.maxItems,
    this.showAmount = true,
    this.emptyMessage = 'No category spending yet.',
  });

  final Map<ExpenseCategory, double> totals;
  final int? maxItems;
  final bool showAmount;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = totals.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.palette.field,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.donut_large_rounded,
                size: 18,
                color: context.palette.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                emptyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final visible = maxItems == null
        ? entries
        : entries.take(maxItems!).toList(growable: false);
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);

    return Column(
      children: List<Widget>.generate(visible.length, (index) {
        final entry = visible[index];
        final percent = total == 0 ? 0.0 : entry.value / total;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == visible.length - 1 ? 0 : 17,
          ),
          child: _CategoryRow(
            category: entry.key,
            amount: entry.value,
            percent: percent,
            showAmount: showAmount,
          ),
        );
      }),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.percent,
    required this.showAmount,
  });

  final ExpenseCategory category;
  final double amount;
  final double percent;
  final bool showAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(category.icon, size: 19, color: category.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      category.label,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (showAmount)
                    Text(
                      formatCurrency(amount, currency: context.currency),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            Container(color: context.palette.border),
                            FractionallySizedBox(
                              widthFactor: percent.clamp(0.0, 1.0),
                              alignment: Alignment.centerLeft,
                              child: Container(color: category.color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(percent * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.palette.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
