import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Compact empty state used by analytics charts.
///
/// Charts are only meaningful when they have data, so both chart widgets fall
/// back to this view instead of drawing empty axes or a blank canvas.
class ChartEmptyState extends StatelessWidget {
  const ChartEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.height = 150,
  });

  final IconData icon;
  final String title;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppColors.field,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
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
