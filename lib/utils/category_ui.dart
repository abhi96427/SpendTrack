import 'package:flutter/material.dart';

import '../models/expense_category.dart';

/// Presentation helpers for [ExpenseCategory].
///
/// Kept out of the model so the data layer remains independent of Flutter.
extension ExpenseCategoryUi on ExpenseCategory {
  IconData get icon {
    return switch (this) {
      ExpenseCategory.food => Icons.restaurant_rounded,
      ExpenseCategory.transport => Icons.directions_car_rounded,
      ExpenseCategory.shopping => Icons.shopping_bag_rounded,
      ExpenseCategory.bills => Icons.receipt_long_rounded,
      ExpenseCategory.entertainment => Icons.movie_rounded,
      ExpenseCategory.health => Icons.medical_services_rounded,
      ExpenseCategory.education => Icons.school_rounded,
      ExpenseCategory.other => Icons.category_rounded,
    };
  }

  Color get color {
    return switch (this) {
      ExpenseCategory.food => const Color(0xFFF97316),
      ExpenseCategory.transport => const Color(0xFF3B82F6),
      ExpenseCategory.shopping => const Color(0xFFEC4899),
      ExpenseCategory.bills => const Color(0xFF8B5CF6),
      ExpenseCategory.entertainment => const Color(0xFF14B8A6),
      ExpenseCategory.health => const Color(0xFFEF4444),
      ExpenseCategory.education => const Color(0xFF6366F1),
      ExpenseCategory.other => const Color(0xFF64748B),
    };
  }
}
