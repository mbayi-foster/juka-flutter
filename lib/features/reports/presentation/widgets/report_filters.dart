import 'package:flutter/material.dart';
import 'package:juka/common/constants/account_type_visuals.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/reports/domain/entities/report_period.dart';
import 'package:juka/features/reports/domain/enums/report_period_preset.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';
import 'package:juka/shared/widget/padding.dart';

/// Filtres du rapport : période analysée, devise et compte observé.
///
/// Les sélections relancent le calcul ; elles sont donc remontées au
/// contrôleur par [onPreset], [onCustomRange], [onCurrency] et [onAccount].
class ReportFilters extends StatelessWidget {
  const ReportFilters({
    super.key,
    required this.preset,
    required this.period,
    required this.accounts,
    required this.accountId,
    required this.currency,
    required this.currencies,
    required this.onPreset,
    required this.onCustomRange,
    required this.onCurrency,
    required this.onAccount,
  });

  /// Période prédéfinie sélectionnée.
  final ReportPeriodPreset preset;

  /// Période affichée, `null` tant que le premier calcul n'a pas abouti.
  final ReportPeriod? period;

  /// Tous les comptes de l'utilisateur.
  final List<Account> accounts;

  /// Compte observé, `null` pour tous les comptes.
  final String? accountId;

  /// Devise analysée : les comptes des autres devises sont exclus du filtre,
  /// puisque les montants ne sont jamais additionnés entre devises.
  final AppCurrency? currency;

  /// Devises réellement utilisées par les comptes, la devise analysée d'abord.
  /// Le sélecteur est masqué tant qu'il n'y en a qu'une.
  final List<AppCurrency> currencies;

  final ValueChanged<ReportPeriodPreset> onPreset;

  /// Ouvre le calendrier pour choisir une période libre.
  final VoidCallback onCustomRange;

  /// Analyse une autre devise.
  final ValueChanged<AppCurrency> onCurrency;

  final ValueChanged<String?> onAccount;

  @override
  Widget build(BuildContext context) {
    final selectable = [
      for (final account in accounts)
        if (!account.isArchived &&
            (currency == null || account.currency == currency))
          account,
    ];
    final currentPeriod = period;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel('Période'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in ReportPeriodPreset.values)
              ChoiceChipTile(
                label: item.isCustom && preset.isCustom && currentPeriod != null
                    ? currentPeriod.rangeLabel
                    : item.label,
                isSelected: preset == item,
                icon: item.isCustom ? Icons.calendar_month_rounded : null,
                onTap: () => item.isCustom ? onCustomRange() : onPreset(item),
              ),
          ],
        ),
        if (currencies.length > 1) ...[
          AppSize.fieldSpacing.ph,
          const _FilterLabel('Devise'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in currencies)
                ChoiceChipTile(
                  label: item.displayName,
                  isSelected: (currency ?? currencies.first) == item,
                  onTap: () => onCurrency(item),
                ),
            ],
          ),
        ],
        if (selectable.isNotEmpty) ...[
          AppSize.fieldSpacing.ph,
          const _FilterLabel('Compte'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChipTile(
                label: 'Tous les comptes',
                isSelected: accountId == null,
                icon: Icons.apps_rounded,
                onTap: () => onAccount(null),
              ),
              for (final account in selectable)
                ChoiceChipTile(
                  label: account.name,
                  isSelected: accountId == account.id,
                  icon: AccountTypeVisuals.iconOf(account.type),
                  accent: AccountTypeVisuals.colorOf(account.type),
                  onTap: () => onAccount(account.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Intitulé discret au-dessus d'une rangée de pastilles.
class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: isDark ? AppColors.border : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
