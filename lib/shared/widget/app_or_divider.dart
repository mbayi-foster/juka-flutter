import 'package:flutter/material.dart';
import 'package:juka/shared/widget/padding.dart';

/// Séparateur « ou » utilisé entre deux moyens d'authentification.
class AppOrDivider extends StatelessWidget {
  const AppOrDivider({super.key, this.label = 'ou'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        theme.dividerTheme.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.12);

    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        12.pw,
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        12.pw,
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}
