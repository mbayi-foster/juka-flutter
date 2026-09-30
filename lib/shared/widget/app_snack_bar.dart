import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';

/// Affichage rapide d'un message en bas de l'écran.
extension AppSnackBarExtension on BuildContext {
  void showAppSnackBar(String message, {bool isError = false}) {
    if (message.trim().isEmpty) return;

    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? AppColors.error : AppColors.success,
          content: Text(message),
        ),
      );
  }
}
