import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/padding.dart';

/// Écran d'erreur avec action de relance optionnelle.
///
/// Mutualisé pour que tous les écrans présentent le même état d'échec.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  /// Message affiché ; un texte générique est utilisé s'il est absent.
  final String? message;

  /// Action de relance, masquée si `null`.
  final VoidCallback? onRetry;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onRetry = this.onRetry;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.textMuted),
          16.ph,
          Text(
            message ?? 'Une erreur est survenue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.textWhite : AppColors.textDark,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            20.ph,
            AppOutlinedButton(
              label: 'Réessayer',
              icon: Icons.refresh_rounded,
              isExpanded: false,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
