import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'app_card.dart';

/// Month switcher used on the Summary screen.
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      borderRadius: 18,
      child: Row(
        children: <Widget>[
          IconButton(
            key: const Key('summary-month-previous'),
            onPressed: onPrevious,
            tooltip: 'Previous month',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.field,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              formatMonthYear(month),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const Key('summary-month-next'),
            onPressed: canGoNext ? onNext : null,
            tooltip: 'Next month',
            style: IconButton.styleFrom(
              backgroundColor: canGoNext ? AppColors.field : AppColors.border,
              shape: const CircleBorder(),
              disabledForegroundColor: AppColors.textMuted,
            ),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
