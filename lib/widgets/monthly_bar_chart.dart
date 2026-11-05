import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/month_total.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/currency_context.dart';
import 'app_card.dart';
import 'chart_empty_state.dart';

/// Monthly spending bar chart built with `fl_chart`.
///
/// Bars are derived from persisted totals. The selected summary month is
/// highlighted, and every bar exposes a tooltip with its exact amount.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.months,
    required this.highlightedMonth,
    this.height = 168,
  });

  final List<MonthTotal> months;
  final DateTime highlightedMonth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxTotal = months.fold<double>(
      0,
      (maximum, item) => math.max(maximum, item.total),
    );

    if (months.isEmpty || maxTotal <= 0) {
      return AppCard(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        child: ChartEmptyState(
          icon: Icons.bar_chart_rounded,
          title: months.isEmpty
              ? 'No monthly data yet'
              : 'No spending in this period',
          message: months.isEmpty
              ? 'Add an expense to start building your monthly trend.'
              : 'There are no recorded expenses in these months. Add one or '
                    'browse another month.',
          height: height,
        ),
      );
    }

    final chartMax = maxTotal * 1.22;
    final gridInterval = chartMax / 3;
    final description = months
        .map(
          (item) =>
              '${formatMonthYear(item.month)}: ${formatCurrency(item.total, currency: context.currency)}',
        )
        .join(', ');

    return Semantics(
      label: 'Monthly spending. $description',
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(10, 20, 16, 12),
        child: SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: chartMax,
              alignment: BarChartAlignment.spaceAround,
              barGroups: List<BarChartGroupData>.generate(months.length, (
                index,
              ) {
                final item = months[index];
                final isHighlighted =
                    item.month.year == highlightedMonth.year &&
                    item.month.month == highlightedMonth.month;

                return BarChartGroupData(
                  x: index,
                  barRods: <BarChartRodData>[
                    BarChartRodData(
                      toY: item.total,
                      width: 22,
                      color: isHighlighted
                          ? context.palette.accent
                          : context.palette.navy.withValues(alpha: 0.16),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7),
                        bottom: Radius.circular(3),
                      ),
                      label: BarChartRodLabel(
                        show: isHighlighted && item.total > 0,
                        text: formatCompactCurrency(
                          item.total,
                          currency: context.currency,
                        ),
                        offset: const Offset(0, 7),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.palette.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                );
              }),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: gridInterval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: context.palette.border.withValues(alpha: 0.9),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    interval: gridInterval,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          formatCompactCurrency(
                            value,
                            currency: context.currency,
                          ),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.palette.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= months.length) {
                        return const SizedBox.shrink();
                      }

                      final month = months[index].month;
                      final isHighlighted =
                          month.year == highlightedMonth.year &&
                          month.month == highlightedMonth.month;

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          formatShortMonth(month),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isHighlighted
                                ? context.palette.navy
                                : context.palette.textMuted,
                            fontWeight: isHighlighted
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => context.palette.navy,
                  tooltipBorderRadius: BorderRadius.circular(10),
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  maxContentWidth: 150,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = months[group.x];
                    return BarTooltipItem(
                      '${formatMonthYear(item.month)}\n'
                      '${formatCurrency(item.total, currency: context.currency)}',
                      theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ) ??
                          const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }
}
