import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/categories/domain/entities/budget.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/utils/validators.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/padding.dart';

/// Résultat de l'éditeur de budget.
class BudgetEditorResult {
  const BudgetEditorResult.saved({
    required this.monthlyLimit,
    required this.carryOver,
  }) : isDeleted = false;

  const BudgetEditorResult.deleted()
    : monthlyLimit = 0,
      carryOver = false,
      isDeleted = true;

  final double monthlyLimit;
  final bool carryOver;
  final bool isDeleted;
}

/// Ouvre l'éditeur de budget d'une catégorie (`null` si annulé).
Future<BudgetEditorResult?> showBudgetEditor(
  BuildContext context, {
  required Category category,
  Budget? budget,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<BudgetEditorResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) =>
        _BudgetEditorSheet(category: category, budget: budget),
  );
}

class _BudgetEditorSheet extends StatefulWidget {
  const _BudgetEditorSheet({required this.category, this.budget});

  final Category category;
  final Budget? budget;

  @override
  State<_BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends State<_BudgetEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late bool _carryOver;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;

    _amountController = TextEditingController(
      text: budget == null ? '' : MoneyFormatter.number(budget.monthlyLimit),
    );
    _carryOver = budget?.carryOver ?? false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      BudgetEditorResult.saved(
        monthlyLimit: MoneyFormatter.tryParse(_amountController.text) ?? 0,
        carryOver: _carryOver,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSize.pagePadding,
          AppSize.pagePadding,
          AppSize.pagePadding,
          MediaQuery.viewInsetsOf(context).bottom + AppSize.pagePadding,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Budget mensuel',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              6.ph,
              Text(
                widget.category.name,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              20.ph,
              AppTextField(
                label: 'Enveloppe mensuelle',
                hintText: '0',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.savings_outlined, size: 20),
                helperText: 'Montant prévu chaque mois pour cette catégorie.',
                validator: (value) =>
                    AppValidators.amount(value, label: 'L\'enveloppe'),
                onFieldSubmitted: (_) => _submit(),
              ),
              8.ph,
              SwitchListTile.adaptive(
                value: _carryOver,
                onChanged: (value) => setState(() => _carryOver = value),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Reporter le reste du mois',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Le montant non dépensé le mois précédent s\'ajoute à '
                  'l\'enveloppe du mois en cours.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
              AppSize.sectionSpacing.ph,
              AppPrimaryButton(
                label: 'Enregistrer le budget',
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
              if (widget.budget != null) ...[
                8.ph,
                AppOutlinedButton(
                  label: 'Supprimer le budget',
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(const BudgetEditorResult.deleted()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
