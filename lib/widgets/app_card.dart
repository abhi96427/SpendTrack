import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rounded surface used throughout SpendTrack.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final decoration = BoxDecoration(
      color: backgroundColor ?? context.palette.surface,
      borderRadius: radius,
      border: Border.all(color: borderColor ?? context.palette.border),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: context.palette.navy.withValues(alpha: 0.045),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
    final content = Padding(padding: padding, child: child);

    return Padding(
      padding: margin,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: decoration,
        child: onTap == null
            ? content
            : Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap, child: content),
              ),
      ),
    );
  }
}
