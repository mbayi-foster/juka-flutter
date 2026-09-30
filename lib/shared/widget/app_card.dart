import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/shared/widget/padding.dart';

/// Surface standard de l'application : fond, bordure, rayon et titre.
///
/// Toutes les cartes (tableau de bord, réglages…) s'appuient sur ce widget afin
/// de conserver une apparence homogène sans dupliquer de décoration.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  /// Contenu de la carte.
  final Widget child;

  /// Titre affiché en en-tête, avec une action optionnelle à droite.
  final String? title;

  /// Icône affichée à gauche du titre.
  final IconData? icon;

  /// Widget affiché à droite du titre (badge, bouton…).
  final Widget? trailing;

  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: AppColors.textMuted),
                      8.pw,
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
                AppSize.fieldSpacing.ph,
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
