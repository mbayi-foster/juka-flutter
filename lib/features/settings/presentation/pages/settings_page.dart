import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/auth/presentation/providers/auth_providers.dart';
import 'package:juka/features/settings/domain/enums/app_theme_mode.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';
import 'package:juka/shared/widget/padding.dart';

/// Onglet Paramètres : compte de l'utilisateur et préférences.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final themeMode = ref.watch(settingsControllerProvider);
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
          AppCard(
            title: 'Apparence',
            icon: Icons.palette_outlined,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final mode in AppThemeMode.values)
                  ChoiceChipTile(
                    label: mode.label,
                    icon: switch (mode) {
                      AppThemeMode.system => Icons.brightness_auto_rounded,
                      AppThemeMode.light => Icons.light_mode_rounded,
                      AppThemeMode.dark => Icons.dark_mode_rounded,
                    },
                    isSelected: themeMode == mode,
                    onTap: () => ref
                        .read(settingsControllerProvider.notifier)
                        .setThemeMode(mode),
                  ),
              ],
            ),
          ),
          AppSize.cardSpacing.ph,
          AppCard(
            title: 'Catégories et budget',
            icon: Icons.sell_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Là où vous décidez comment dépenser.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                14.ph,
                _SettingsLink(
                  icon: Icons.category_outlined,
                  label: 'Catégories',
                  description: 'Créer, organiser et archiver',
                  onTap: () => context.push(AppRoutes.categories),
                ),
                const Divider(height: 20),
                _SettingsLink(
                  icon: Icons.savings_outlined,
                  label: 'Budgets mensuels',
                  description: 'Prévu contre réel, alertes à 80 % et 100 %',
                  onTap: () => context.push(AppRoutes.budgets),
                ),
              ],
            ),
          ),
          AppSize.cardSpacing.ph,
          AppCard(
            title: 'Analyses et suivi',
            icon: Icons.query_stats_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Là où vous comprenez où part votre argent.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                14.ph,
                _SettingsLink(
                  icon: Icons.insights_outlined,
                  label: 'Rapports et analyses',
                  description: 'Par catégorie, par compte, export PDF ou Excel',
                  onTap: () => context.push(AppRoutes.reports),
                ),
                const Divider(height: 20),
                _SettingsLink(
                  icon: Icons.trending_up_rounded,
                  label: 'Patrimoine et progression',
                  description: 'Patrimoine net, épargne et remboursement',
                  onTap: () => context.push(AppRoutes.wealth),
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

/// Raccourci vers un écran de réglages.
class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSize.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            12.pw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? AppColors.textWhite : AppColors.textDark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  2.ph,
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
