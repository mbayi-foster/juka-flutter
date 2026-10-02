import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/app_date_format.dart';
import 'package:juka/common/enums/app_language.dart';
import 'package:juka/features/settings/domain/enums/app_theme_mode.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';
import 'package:juka/shared/widget/padding.dart';

/// Onglet Paramètres : profil local, préférences et accès aux réglages.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final preferences = settings.preferences;
    final profile = settings.profile;
    final controller = ref.read(settingsControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(AppSize.pagePadding),
        children: [
          AppCard(
            title: 'Mon profil',
            icon: Icons.person_outline_rounded,
            trailing: TextButton(
              onPressed: () => context.push(AppRoutes.profile),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Modifier'),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty ? 'Utilisateur' : profile.name,
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.ph,
                Row(
                  children: [
                    Icon(
                      profile.hasPin
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                    6.pw,
                    Text(
                      profile.hasPin
                          ? 'Protégé par un code PIN'
                          : 'Sans code PIN',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSize.cardSpacing.ph,
          AppCard(
            title: 'Apparence et langue',
            icon: Icons.palette_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SettingsLabel('Thème'),
                Wrap(
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
                        isSelected: preferences.themeMode == mode,
                        onTap: () => controller.setThemeMode(mode),
                      ),
                  ],
                ),
                AppSize.fieldSpacing.ph,
                const _SettingsLabel('Langue'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final language in AppLanguage.values)
                      ChoiceChipTile(
                        label: language.label,
                        isSelected: preferences.language == language,
                        onTap: () => controller.setLanguage(language),
                      ),
                  ],
                ),
                AppSize.fieldSpacing.ph,
                const _SettingsLabel('Format des dates'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final format in AppDateFormat.values)
                      ChoiceChipTile(
                        label: format.example,
                        isSelected: preferences.dateFormat == format,
                        onTap: () => controller.setDateFormat(format),
                      ),
                  ],
                ),
                10.ph,
                Text(
                  'Exemple : ${DateFormatter.numeric(DateTime.now())}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          AppSize.cardSpacing.ph,
          AppCard(
            title: 'Devises et taux',
            icon: Icons.currency_exchange_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additionnez des comptes de devises différentes grâce à vos '
                  'taux de change mensuels.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                14.ph,
                _SettingsLink(
                  icon: Icons.flag_outlined,
                  label: 'Devise de référence',
                  description: preferences.referenceCurrency == null
                      ? 'Non définie — une devise à la fois'
                      : preferences.referenceCurrency!.displayName,
                  onTap: () => context.push(AppRoutes.currencies),
                ),
              ],
            ),
          ),
          AppSize.cardSpacing.ph,
          AppCard(
            title: 'Rappels',
            icon: Icons.notifications_none_rounded,
            child: _SettingsLink(
              icon: Icons.alarm_rounded,
              label: 'Saisie, point hebdo et mensuel',
              description: preferences.reminders.hasAnyEnabled
                  ? 'Rappels configurés'
                  : 'Aucun rappel activé',
              onTap: () => context.push(AppRoutes.reminders),
            ),
          ),
          AppSize.cardSpacing.ph,
          AppCard(
            title: 'Données',
            icon: Icons.inventory_2_outlined,
            child: _SettingsLink(
              icon: Icons.save_alt_rounded,
              label: 'Sauvegarde et export',
              description: 'Créer ou restaurer un fichier de sauvegarde',
              onTap: () => context.push(AppRoutes.backup),
            ),
          ),
          AppSize.cardSpacing.ph,
          AppCard(
            title: 'Catégories et budget',
            icon: Icons.sell_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          const Text(
            'Toutes vos données restent sur ce téléphone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Intitulé discret au-dessus d'une rangée de pastilles.
class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
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
