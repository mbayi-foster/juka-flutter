import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/auth/presentation/providers/auth_providers.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/padding.dart';

/// Onglet Paramètres : compte de l'utilisateur et préférences.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(AppSize.pagePadding),
        children: [
          AppCard(
            title: 'Mon compte',
            icon: Icons.person_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Utilisateur',
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.ph,
                Text(
                  user?.email ?? 'Non connecté',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          AppSize.cardSpacing.ph,
          AppOutlinedButton(
            label: 'Se déconnecter',
            icon: Icons.logout_rounded,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (!context.mounted) return;
              context.go(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}
