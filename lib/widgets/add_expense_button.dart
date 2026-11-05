import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Compact circular add action used in screen headers.
class AddExpenseButton extends StatelessWidget {
  const AddExpenseButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Add expense',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: context.palette.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }
}
