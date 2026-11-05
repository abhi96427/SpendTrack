import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_colors.dart';
import '../utils/category_ui.dart';
import '../utils/formatters.dart';
import '../utils/currency_context.dart';

/// A single transaction row. The parent supplies card clipping and dividers.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    this.showChevron = true,
  });

  final Expense expense;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label:
          '${expense.title}, ${expense.category.label}, '
          '${formatCurrency(expense.amount, currency: context.currency)}, ${formatRelativeDate(expense.date)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: expense.category.color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    expense.category.icon,
                    size: 22,
                    color: expense.category.color,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        expense.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${expense.category.label}  ·  '
                        '${formatRelativeDate(expense.date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  formatCurrency(expense.amount, currency: context.currency),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.palette.textPrimary,
                  ),
                ),
                if (showChevron) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: context.palette.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
