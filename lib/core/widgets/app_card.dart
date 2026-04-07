import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? borderRadius;
  final bool isExpired;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius,
    this.isExpired = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Card(
      margin: EdgeInsets.zero,
      color: color ?? (isExpired ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.5) : theme.colorScheme.surfaceContainer),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: isExpired ? 0.05 : 0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
