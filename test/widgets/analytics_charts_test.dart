import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendtrack/models/expense_category.dart';
import 'package:spendtrack/models/month_total.dart';
import 'package:spendtrack/widgets/category_donut_chart.dart';
import 'package:spendtrack/widgets/monthly_bar_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpChart(WidgetTester tester, Widget chart) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 360, height: 320, child: chart)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CategoryDonutChart', () {
    testWidgets('shows a meaningful empty state without data', (
      WidgetTester tester,
    ) async {
      await pumpChart(
        tester,
        const CategoryDonutChart(totals: <ExpenseCategory, double>{}),
      );

      expect(find.byType(PieChart), findsNothing);
      expect(find.text('No category spending'), findsOneWidget);
      expect(
        find.text(
          'Add an expense to see how your spending is split by category.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders a fl_chart pie with percentages and total', (
      WidgetTester tester,
    ) async {
      await pumpChart(
        tester,
        const CategoryDonutChart(
          totals: <ExpenseCategory, double>{
            ExpenseCategory.food: 900,
            ExpenseCategory.transport: 500,
          },
        ),
      );

      expect(find.byType(PieChart), findsOneWidget);
      final pie = tester.widget<PieChart>(find.byType(PieChart));
      expect(
        pie.data.sections.map((section) => section.title),
        containsAll(<String>['64%', '36%']),
      );
      expect(pie.data.sections, hasLength(2));
      expect(find.text('₹1.4k'), findsOneWidget);
      expect(find.text('No category spending'), findsNothing);
    });
  });

  group('MonthlyBarChart', () {
    testWidgets('shows an empty state when there are no months', (
      WidgetTester tester,
    ) async {
      await pumpChart(
        tester,
        MonthlyBarChart(
          months: const <MonthTotal>[],
          highlightedMonth: DateTime(2026, 3),
        ),
      );

      expect(find.byType(BarChart), findsNothing);
      expect(find.text('No monthly data yet'), findsOneWidget);
    });

    testWidgets('shows an empty state when all months are zero', (
      WidgetTester tester,
    ) async {
      await pumpChart(
        tester,
        MonthlyBarChart(
          months: <MonthTotal>[
            MonthTotal(month: DateTime(2026, 1), total: 0),
            MonthTotal(month: DateTime(2026, 2), total: 0),
          ],
          highlightedMonth: DateTime(2026, 2),
        ),
      );

      expect(find.byType(BarChart), findsNothing);
      expect(find.text('No spending in this period'), findsOneWidget);
    });

    testWidgets('renders a fl_chart bar chart with real month totals', (
      WidgetTester tester,
    ) async {
      await pumpChart(
        tester,
        MonthlyBarChart(
          months: <MonthTotal>[
            MonthTotal(month: DateTime(2026, 1), total: 400),
            MonthTotal(month: DateTime(2026, 2), total: 1200),
          ],
          highlightedMonth: DateTime(2026, 2),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);
      final bar = tester.widget<BarChart>(find.byType(BarChart));
      expect(bar.data.barGroups, hasLength(2));
      expect(bar.data.barGroups.last.barRods.single.toY, 1200);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Feb'), findsOneWidget);
      expect(find.text('No spending in this period'), findsNothing);
    });
  });
}
