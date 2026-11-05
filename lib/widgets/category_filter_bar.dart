import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../theme/app_colors.dart';
import '../utils/category_ui.dart';

/// Horizontally scrollable category filter shared by list and analytics views.
///
/// Passing `null` selects every category. [keyPrefix] keeps widget-test keys
/// unique per screen, for example `expenses-category-food`.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.keyPrefix,
  });

  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onSelected;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _FilterPill(
            key: Key('$keyPrefix-all'),
            label: 'All',
            icon: Icons.grid_view_rounded,
            color: context.palette.brand,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in ExpenseCategory.values) ...<Widget>[
            const SizedBox(width: 8),
            _FilterPill(
              key: Key('$keyPrefix-${category.name}'),
              label: category.label,
              icon: category.icon,
              color: category.color,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected ? color : context.palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : context.palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 17, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? Colors.white
                      : context.palette.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
