import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/shared/widget/padding.dart';

/// Message centré affiché lorsqu'une liste ne contient aucun élément.
class EmptyMessage extends StatelessWidget {
  const EmptyMessage({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textMuted),
            8.pw,
          ],
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
