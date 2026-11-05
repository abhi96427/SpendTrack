import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/error_state_view.dart';
import 'dashboard_screen.dart';
import 'expense_detail_screen.dart';
import 'expense_form_screen.dart';
import 'expenses_screen.dart';
import 'summary_screen.dart';
import 'settings_screen.dart';

/// Hosts the primary tabs and the shared add/edit expense route.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  Future<void> _openExpense(Expense? expense) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: expense == null,
        builder: (_) => expense == null
            ? const ExpenseFormScreen()
            : ExpenseDetailScreen(expenseId: expense.id),
      ),
    );

    if (message != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    if (!provider.isInitialized) {
      if (provider.isLoading) {
        return const Scaffold(body: _StartupView());
      }
      return Scaffold(
        body: SafeArea(
          child: ErrorStateView(
            message:
                provider.errorMessage ??
                'Something went wrong. Please try again.',
            onRetry: provider.initialize,
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          DashboardScreen(
            onOpenExpense: _openExpense,
            onViewAllExpenses: () => _selectTab(1),
            onViewSummary: () => _selectTab(2),
          ),
          ExpensesScreen(onOpenExpense: _openExpense),
          SummaryScreen(onOpenExpense: _openExpense),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _selectTab,
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(top: BorderSide(color: context.palette.border)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.palette.navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Expenses',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: Icon(Icons.pie_chart_rounded),
              label: 'Summary',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupView extends StatelessWidget {
  const _StartupView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: context.palette.brand,
              borderRadius: BorderRadius.circular(21),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: context.palette.navy.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text('SpendTrack', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Preparing your dashboard',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ],
      ),
    );
  }
}
