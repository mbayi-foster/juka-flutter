import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/shared/widget/padding.dart';

/// Indicateur de chargement pleine largeur, avec message optionnel.
///
/// Mutualisé pour que tous les écrans présentent le même état d'attente.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message, this.height = 260});

  final String? message;

  /// Hauteur occupée : évite un saut de mise en page dans une liste.
  final double height;

  @override
  Widget build(BuildContext context) {
    final message = this.message;

    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.6),
            if (message != null) ...[
              16.ph,
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
