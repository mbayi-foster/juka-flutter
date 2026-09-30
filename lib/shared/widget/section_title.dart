import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';

/// Titre de section, avec action optionnelle à droite.
///
/// Sert à séparer des groupes de cartes (« Comptes actifs », « Comptes
/// archivés »…) sans dupliquer la mise en forme.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? AppColors.textWhite : AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
