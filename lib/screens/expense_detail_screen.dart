import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import '../utils/category_ui.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import 'expense_form_screen.dart';

/// Read-only view of a single transaction with edit and delete actions.
class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool _isDeleting = false;

  Expense? _findExpense(ExpenseProvider provider) {
    for (final expense in provider.expenses) {
      if (expense.id == widget.expenseId) {
        return expense;
      }
    }
    return null;
  }

  Future<void> _edit(Expense expense) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => ExpenseFormScreen(expense: expense),
      ),
    );

    if (!mounted || message == null) {
      return;
    }

    final stillExists = context.read<ExpenseProvider>().expenses.any(
      (item) => item.id == widget.expenseId,
    );
    if (!stillExists) {
      Navigator.of(context).pop(message);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete(Expense expense) async {
    if (_isDeleting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete expense?'),
          content: Text(
            '"${expense.title}" (${formatCurrency(expense.amount)}) will be '
            'removed permanently. This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);
    final provider = context.read<ExpenseProvider>();
    var deleted = false;

    try {
      deleted = await provider.deleteExpense(expense.id);
    } catch (_) {
      deleted = false;
    }

    if (!mounted) {
      return;
    }

    if (deleted) {
      Navigator.of(context).pop('Expense deleted.');
      return;
    }

    setState(() => _isDeleting = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Could not delete the expense. Try again.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expense = _findExpense(provider);

    return Scaffold(
      key: const Key('expense-detail-screen'),
      appBar: AppBar(
        title: const Text('Expense details'),
        actions: <Widget>[
          if (expense != null)
            IconButton(
              key: const Key('detail-edit-button'),
              onPressed: _isDeleting ? null : () => _edit(expense),
              tooltip: 'Edit expense',
              icon: const Icon(Icons.edit_rounded),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: expense == null
            ? const _RemovedExpenseView()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: <Widget>[
                  _DetailHero(expense: expense),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Details'),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    child: Column(
                      children: <Widget>[
                        _DetailRow(
                          icon: expense.category.icon,
                          iconColor: expense.category.color,
                          label: 'Category',
                          value: expense.category.label,
                        ),
                        const Divider(indent: 44),
                        _DetailRow(
                          icon: Icons.calendar_today_rounded,
                          iconColor: AppColors.accent,
                          label: 'Date',
                          value: formatFullDate(expense.date),
                        ),
                        const Divider(indent: 44),
                        _DetailRow(
                          icon: Icons.notes_rounded,
                          iconColor: AppColors.textSecondary,
                          label: 'Note',
                          value: expense.note ?? 'No note added',
                          valueMuted: expense.note == null,
                        ),
                        const Divider(indent: 44),
                        _DetailRow(
                          icon: Icons.schedule_rounded,
                          iconColor: AppColors.textSecondary,
                          label: 'Recorded',
                          value: formatShortDate(expense.createdAt),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  FilledButton.icon(
                    key: const Key('detail-edit-filled-button'),
                    onPressed: _isDeleting ? null : () => _edit(expense),
                    icon: const Icon(Icons.edit_rounded, size: 19),
                    label: const Text('Edit expense'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('detail-delete-button'),
                    onPressed: _isDeleting ? null : () => _delete(expense),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 20),
                    label: Text(_isDeleting ? 'Deleting...' : 'Delete expense'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            color: AppColors.navy.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: expense.category.color.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    expense.category.icon,
                    size: 21,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    expense.category.label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  formatRelativeDate(expense.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              expense.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCurrency(expense.amount),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueMuted = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool valueMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: valueMuted
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RemovedExpenseView extends StatelessWidget {
  const _RemovedExpenseView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.receipt_long_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              'This expense is no longer available',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'It may have been deleted from another screen.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
