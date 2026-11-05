import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import '../utils/category_ui.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/app_card.dart';

/// Create or edit a single expense.
///
/// Pops with a user-facing success message, or `null` when nothing changed.
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late DateTime _date;
  late ExpenseCategory _category;
  bool _isSaving = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;

    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense == null ? '' : formatAmountInput(expense.amount),
    );
    _noteController = TextEditingController(text: expense?.note ?? '');
    _date = expense?.date ?? DateTime.now();
    _category = expense?.category ?? ExpenseCategory.other;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);
    final initialDate = _date.isAfter(lastDate) ? lastDate : _date;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: lastDate,
    );

    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      // Validate on interaction from now on so corrected fields clear their
      // errors immediately without flagging untouched fields prematurely.
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    final amount = parseAmount(_amountController.text);
    if (amount == null) {
      return;
    }

    setState(() => _isSaving = true);

    final note = _noteController.text.trim();
    final expense = Expense(
      id: widget.expense?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: amount,
      category: _category,
      date: DateTime(_date.year, _date.month, _date.day),
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
      note: note.isEmpty ? null : note,
    );

    final provider = context.read<ExpenseProvider>();
    var saved = false;

    try {
      saved = _isEditing
          ? await provider.updateExpense(expense)
          : await provider.addExpense(expense);
    } catch (_) {
      saved = false;
    }

    if (!mounted) {
      return;
    }

    if (saved) {
      Navigator.of(
        context,
      ).pop(_isEditing ? 'Expense updated.' : 'Expense added.');
      return;
    }

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          // Keep the persistent save bar tappable while the error is visible.
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 88),
          content: Text(
            provider.errorMessage ?? 'Could not save the expense. Try again.',
          ),
        ),
      );
  }

  Future<void> _delete() async {
    final expense = widget.expense;
    if (expense == null || _isSaving) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete expense?'),
          content: Text(
            '"${expense.title}" (${formatCurrency(expense.amount)}) will be '
            'removed permanently.',
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

    setState(() => _isSaving = true);
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

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 88),
          content: Text(
            provider.errorMessage ?? 'Could not delete the expense. Try again.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit expense' : 'Add expense'),
        actions: <Widget>[
          if (_isEditing)
            IconButton(
              key: const Key('expense-delete-button'),
              onPressed: _isSaving ? null : _delete,
              tooltip: 'Delete expense',
              color: AppColors.danger,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: <Widget>[
                    _AmountCard(
                      controller: _amountController,
                      category: _category,
                      enabled: !_isSaving,
                      autofocus: !_isEditing,
                    ),
                    const SizedBox(height: 22),
                    const _FieldLabel('What was it for?'),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('expense-title-field'),
                      controller: _titleController,
                      enabled: !_isSaving,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      validator: validateExpenseTitle,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Lunch with the team',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _FieldLabel('Category'),
                    const SizedBox(height: 10),
                    _CategorySelector(
                      selected: _category,
                      enabled: !_isSaving,
                      onSelected: (category) =>
                          setState(() => _category = category),
                    ),
                    const SizedBox(height: 22),
                    const _FieldLabel('Date'),
                    const SizedBox(height: 8),
                    _DateField(
                      date: _date,
                      enabled: !_isSaving,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 22),
                    const _FieldLabel('Note'),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('expense-note-field'),
                      controller: _noteController,
                      enabled: !_isSaving,
                      minLines: 3,
                      maxLines: 4,
                      maxLength: 200,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Add any details you want to remember',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              _SaveBar(
                isSaving: _isSaving,
                isEditing: _isEditing,
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.controller,
    required this.category,
    required this.enabled,
    required this.autofocus,
  });

  final TextEditingController controller;
  final ExpenseCategory category;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'AMOUNT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(category.icon, size: 14, color: category.color),
                    const SizedBox(width: 5),
                    Text(
                      category.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: category.color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          TextFormField(
            key: const Key('expense-amount-field'),
            controller: controller,
            autofocus: autofocus,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            validator: validateExpenseAmount,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: AppColors.navy,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: theme.textTheme.displaySmall?.copyWith(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted.withValues(alpha: 0.45),
              ),
              prefixText: '₹ ',
              prefixStyle: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
              filled: false,
              contentPadding: const EdgeInsets.only(top: 4, bottom: 2),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final ExpenseCategory selected;
  final bool enabled;
  final ValueChanged<ExpenseCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 9.0;
        final width = (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: ExpenseCategory.values
              .map((category) {
                return SizedBox(
                  width: width,
                  child: _CategoryOption(
                    key: Key('expense-category-${category.name}'),
                    category: category,
                    selected: category == selected,
                    enabled: enabled,
                    onTap: () => onSelected(category),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    super.key,
    required this.category,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ExpenseCategory category;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16);

    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      child: Material(
        color: selected ? AppColors.accentSoft : AppColors.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: radius,
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Stack(
              children: <Widget>[
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          category.icon,
                          size: 17,
                          color: category.color,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: selected
                                ? AppColors.accentDark
                                : AppColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        key: const Key('expense-date-field'),
        onTap: enabled ? onTap : null,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Expense date',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatFullDate(date),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isSaving,
    required this.isEditing,
    required this.onSave,
  });

  final bool isSaving;
  final bool isEditing;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        bottom: !keyboardVisible,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: FilledButton.icon(
            key: const Key('expense-save-button'),
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(
              isSaving
                  ? 'Saving...'
                  : isEditing
                  ? 'Save changes'
                  : 'Save expense',
            ),
          ),
        ),
      ),
    );
  }
}
