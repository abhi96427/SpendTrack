import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Friendly empty or no-results state with an optional real action.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.filledAction = false,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool filledAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 20,
        vertical: compact ? 14 : 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: compact ? 48 : 62,
            height: compact ? 48 : 62,
            decoration: BoxDecoration(
              color: context.palette.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 22 : 28,
              color: context.palette.accent,
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: compact
                ? theme.textTheme.titleSmall
                : theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.palette.textSecondary,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 16),
            if (filledAction)
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.add_rounded, size: 19),
                label: Text(actionLabel!),
              )
            else
              TextButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.arrow_forward_rounded, size: 17),
                label: Text(actionLabel!),
              ),
          ],
        ],
      ),
    );
  }
}
