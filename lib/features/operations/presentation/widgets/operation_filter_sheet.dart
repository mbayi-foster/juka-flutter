import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/presentation/widgets/operation_type_selector.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';
import 'package:juka/shared/widget/padding.dart';

/// Périodes prédéfinies proposées par le filtre.
enum PeriodPreset {
  all('Tout'),
  thisMonth('Ce mois-ci'),
  last30Days('30 derniers jours'),
  thisYear('Cette année');

  const PeriodPreset(this.label);

  final String label;

  /// Bornes de la période (`from` inclus, `to` inclus jusqu'à la dernière
  /// seconde de la journée).
  (DateTime?, DateTime?) bounds(DateTime now) {
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return switch (this) {
      PeriodPreset.all => (null, null),
      PeriodPreset.thisMonth => (
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      ),
      PeriodPreset.last30Days => (
        DateTime(now.year, now.month, now.day - 29),
        endOfToday,
      ),
      PeriodPreset.thisYear => (
        DateTime(now.year),
        DateTime(now.year, 12, 31, 23, 59, 59),
      ),
    };
  }
}

/// Ouvre la feuille de filtres et retourne le filtre retenu
/// (`null` si l'utilisateur ferme sans valider).
Future<OperationFilter?> showOperationFilterSheet(
  BuildContext context, {
  required OperationFilter filter,
  required List<Account> accounts,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<OperationFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) =>
        _OperationFilterSheet(filter: filter, accounts: accounts),
  );
}

/// Filtres de la liste : période, type, compte et catégorie.
class _OperationFilterSheet extends StatefulWidget {
  const _OperationFilterSheet({required this.filter, required this.accounts});

  final OperationFilter filter;
  final List<Account> accounts;

  @override
  State<_OperationFilterSheet> createState() => _OperationFilterSheetState();
}

class _OperationFilterSheetState extends State<_OperationFilterSheet> {
  late OperationFilter _draft = widget.filter;

  /// Catégories proposées : le transfert n'est pas un choix pour un revenu ou
  /// une dépense, il est déduit du type d'opération.
  static final List<TransactionCategory> _categories = [
    for (final category in TransactionCategory.values)
      if (category != TransactionCategory.transfer) category,
  ];

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == null && b == null;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isPresetSelected(PeriodPreset preset) {
    final (from, to) = preset.bounds(DateTime.now());
    return _sameDay(_draft.from, from) && _sameDay(_draft.to, to);
  }

  void _selectPreset(PeriodPreset preset) {
    final (from, to) = preset.bounds(DateTime.now());
    setState(() {
      _draft = _draft.copyWith(
        from: from,
        to: to,
        clearPeriod: from == null && to == null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSize.pagePadding,
          AppSize.pagePadding,
          AppSize.pagePadding,
          MediaQuery.viewInsetsOf(context).bottom + AppSize.pagePadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtres',
                    style: TextStyle(
                      color: isDark ? AppColors.textWhite : AppColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _draft = const OperationFilter()),
                  child: const Text('Tout effacer'),
                ),
              ],
            ),
            8.ph,
            _Section(
              title: 'Période',
              children: [
                for (final preset in PeriodPreset.values)
                  ChoiceChipTile(
                    label: preset.label,
                    isSelected: _isPresetSelected(preset),
                    onTap: () => _selectPreset(preset),
                  ),
              ],
            ),
            20.ph,
            _Section(
              title: 'Type',
              children: [
                ChoiceChipTile(
                  label: 'Tous',
                  isSelected: !_draft.hasType,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(clearType: true)),
                ),
                for (final type in OperationType.values)
                  ChoiceChipTile(
                    label: type.label,
                    icon: OperationTypeSelector.iconOf(type),
                    accent: OperationTypeSelector.colorOf(type),
                    isSelected: _draft.type == type,
                    onTap: () =>
                        setState(() => _draft = _draft.copyWith(type: type)),
                  ),
              ],
            ),
            20.ph,
            _Section(
              title: 'Compte',
              children: [
                ChoiceChipTile(
                  label: 'Tous',
                  isSelected: !_draft.hasAccount,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(clearAccount: true),
                  ),
                ),
                for (final account in widget.accounts)
                  ChoiceChipTile(
                    label: account.name,
                    isSelected: _draft.accountId == account.id,
                    onTap: () => setState(
                      () => _draft = _draft.copyWith(accountId: account.id),
                    ),
                  ),
              ],
            ),
            20.ph,
            _Section(
              title: 'Catégorie',
              children: [
                ChoiceChipTile(
                  label: 'Toutes',
                  isSelected: !_draft.hasCategory,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(clearCategory: true),
                  ),
                ),
                for (final category in _categories)
                  ChoiceChipTile(
                    label: category.label,
                    isSelected: _draft.category == category,
                    onTap: () => setState(
                      () => _draft = _draft.copyWith(category: category),
                    ),
                  ),
              ],
            ),
            24.ph,
            AppPrimaryButton(
              label: 'Appliquer les filtres',
              icon: Icons.filter_alt_rounded,
              onPressed: () => Navigator.of(context).pop(_draft),
            ),
            8.ph,
            AppOutlinedButton(
              label: 'Fermer',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Groupe de pastilles précédé d'un titre.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        10.ph,
        Wrap(spacing: 10, runSpacing: 10, children: children),
      ],
    );
  }
}
