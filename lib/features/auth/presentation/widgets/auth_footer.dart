import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';

/// Bas de page proposant une action alternative
/// (ex : « Pas encore de compte ? Créer un compte »).
class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          message,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}
