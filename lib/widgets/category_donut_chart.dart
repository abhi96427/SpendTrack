import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../theme/app_colors.dart';
import '../utils/category_ui.dart';
import '../utils/formatters.dart';
import 'chart_empty_state.dart';

/// Category-wise donut chart built with `fl_chart`.
///
/// Each slice shows its share of the month's spending as a percentage, while
/// the center displays the filtered total.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.totals,
    this.size = 188,
    this.strokeWidth = 22,
  });

  final Map<ExpenseCategory, double> totals;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segments =
        totals.entries.where((entry) => entry.value > 0).toList(growable: false)
          ..sort((a, b) => b.value.compareTo(a.value));
    final total = segments.fold<double>(0, (sum, entry) => sum + entry.value);

    if (segments.isEmpty || total <= 0) {
      return const ChartEmptyState(
        icon: Icons.donut_large_rounded,
        title: 'No category spending',
        message:
            'Add an expense to see how your spending is split by category.',
      );
    }

    final description = segments
        .map((entry) {
          final percent = (entry.value / total) * 100;
          return '${entry.key.label} ${percent.toStringAsFixed(0)} percent';
        })
        .join(', ');

    return Semantics(
      label:
          'Spending by category, total ${formatCurrency(total)}. $description',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              child: PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: segments.length > 1 ? 2.5 : 0,
                  centerSpaceRadius: size / 2 - strokeWidth - 8,
                  sections: segments
                      .map((entry) {
                        final percent = (entry.value / total) * 100;
                        return PieChartSectionData(
                          value: entry.value,
                          color: entry.key.color,
                          radius: strokeWidth,
                          cornerRadius: 3,
                          showTitle: percent >= 7,
                          title: '${percent.round()}%',
                          titleStyle: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0,
                          ),
                        );
                      })
                      .toList(growable: false),
                  pieTouchData: PieTouchData(enabled: false),
                ),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
              ),
            ),
            IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'TOTAL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: size * 0.58,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatCompactCurrency(total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
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
