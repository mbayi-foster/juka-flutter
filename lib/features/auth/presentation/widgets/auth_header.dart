import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/shared/widget/app_logo.dart';
import 'package:juka/shared/widget/padding.dart';

/// En-tête d'un écran d'authentification (logo optionnel, titre, sous-titre).
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogo = false,
    this.centered = false,
  });

  final String title;
  final String subtitle;
  final bool showLogo;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;
    final alignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (showLogo) ...[
          const Center(child: AppLogo()),
          AppSize.sectionSpacing.ph,
        ],
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: titleColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        10.ph,
        Text(
          subtitle,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
