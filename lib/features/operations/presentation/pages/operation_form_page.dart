import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/presentation/providers/operations_providers.dart';
import 'package:juka/features/operations/presentation/widgets/operation_type_selector.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/utils/validators.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';
import 'package:juka/shared/widget/error_view.dart';
import 'package:juka/shared/widget/padding.dart';

/// Saisie rapide d'un revenu, d'une dépense ou d'un transfert.
///
/// Le même écran sert à modifier une opération existante ([operationId] non
/// nul). Le bouton d'enregistrement est en bas du formulaire.
class OperationFormPage extends ConsumerStatefulWidget {
  const OperationFormPage({super.key, this.operationId});

  /// Opération à modifier ; `null` pour une nouvelle saisie.
  final String? operationId;

  @override
  ConsumerState<OperationFormPage> createState() => _OperationFormPageState();
}

class _OperationFormPageState extends ConsumerState<OperationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _labelController = TextEditingController();
  final _noteController = TextEditingController();

  OperationType _type = OperationType.expense;
  TransactionCategory _category = TransactionCategory.other;
  DateTime _date = DateTime.now();
  String? _accountId;
  String? _transferAccountId;
  bool _isSaving = false;

  /// Opération en cours de modification, lue une seule fois à l'initialisation.
  Operation? _existing;

  bool get _isEditing => widget.operationId != null;

  bool get _isTransfer => _type.isTransfer;

  /// Catégories proposées : le transfert est déduit du type d'opération.
  static final List<TransactionCategory> _categories = [
    for (final category in TransactionCategory.values)
      if (category != TransactionCategory.transfer) category,
  ];

  @override
  void initState() {
    super.initState();

    // Les comptes sont indispensables pour rattacher l'opération.
    Future.microtask(ref.read(accountsControllerProvider.notifier).load);

    final operationId = widget.operationId;
    if (operationId == null) return;

    final operation = ref
        .read(operationsControllerProvider)
        .operationById(operationId);
    _existing = operation;
    if (operation == null) return;

    _labelController.text = operation.label;
    _amountController.text = MoneyFormatter.number(operation.amount);
    _noteController.text = operation.note ?? '';
    _type = operation.type;
    _category = operation.category;
    _date = operation.date;
    _accountId = operation.accountId;
    _transferAccountId = operation.transferAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _labelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );

    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  /// Enregistre l'opération (création, transfert ou modification).
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final accounts = ref.read(accountsControllerProvider).accounts;
    final accountId =
        _accountId ?? (accounts.isEmpty ? null : accounts.first.id);
    if (accountId == null) {
      context.showAppSnackBar('Créez d\'abord un compte.', isError: true);
      return;
    }

    final transferAccountId = _transferAccountId;
    if (!_isEditing &&
        _isTransfer &&
        (transferAccountId == null || transferAccountId == accountId)) {
      context.showAppSnackBar(
        'Choisissez deux comptes différents pour le transfert.',
        isError: true,
      );
      return;
    }

    final label = _labelController.text.trim();
    final note = _noteController.text;
    final amount = MoneyFormatter.tryParse(_amountController.text) ?? 0;
    final operationId = widget.operationId;
    final controller = ref.read(operationsControllerProvider.notifier);

    setState(() => _isSaving = true);

    final String? error;
    if (operationId != null) {
      error = await controller.update(
        id: operationId,
        label: label,
        type: _type,
        amount: amount,
        category: _category,
        accountId: accountId,
        date: _date,
        note: note,
      );
    } else if (_isTransfer) {
      error = await controller.createTransfer(
        label: label,
        amount: amount,
        fromAccountId: accountId,
        toAccountId: transferAccountId!,
        date: _date,
        note: note,
      );
    } else {
      error = await controller.create(
        label: label,
        type: _type,
        amount: amount,
        category: _category,
        accountId: accountId,
        date: _date,
        note: note,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }

    context.showAppSnackBar(
      _isEditing ? 'Opération mise à jour.' : 'Opération enregistrée.',
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.operations);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsControllerProvider).accounts;

    // Accès direct à une opération inexistante (lien profond, suppression…).
    if (_isEditing && _existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier l\'opération')),
        body: const ErrorView(
          message: 'Cette opération est introuvable.',
          icon: Icons.search_off_rounded,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier l\'opération' : 'Nouvelle opération',
        ),
      ),
      body: accounts.isEmpty
          ? const _NoAccountView()
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSize.pagePadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FieldLabel('Type d\'opération'),
                      OperationTypeSelector(
                        value: _type,
                        onChanged: (type) => setState(() => _type = type),
                      ),
                      AppSize.fieldSpacing.ph,
                      AppTextField(
                        label: 'Montant',
                        hintText: '0',
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                          size: 20,
                        ),
                        helperText: _isTransfer
                            ? 'Montant déplacé entre les deux comptes.'
                            : 'Montant toujours positif : le sens est donné '
                                  'par le type.',
                        validator: _validateAmount,
                      ),
                      AppSize.fieldSpacing.ph,
                      AppTextField(
                        label: 'Libellé',
                        hintText: 'Courses, loyer, salaire…',
                        controller: _labelController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.label_outline_rounded,
                          size: 20,
                        ),
                        validator: (value) => AppValidators.personName(
                          value,
                          label: 'Le libellé',
                        ),
                      ),
                      if (!_isTransfer) ...[
                        AppSize.fieldSpacing.ph,
                        const _FieldLabel('Catégorie'),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final category in _categories)
                              ChoiceChipTile(
                                label: category.label,
                                isSelected: _category == category,
                                onTap: () =>
                                    setState(() => _category = category),
                              ),
                          ],
                        ),
                      ],
                      AppSize.fieldSpacing.ph,
                      _FieldLabel(
                        _isTransfer
                            ? 'Compte à débiter'
                            : (_type.isIncome
                                  ? 'Compte à créditer'
                                  : 'Compte à débiter'),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final account in accounts)
                            ChoiceChipTile(
                              label: account.name,
                              isSelected:
                                  _selectedAccountId(accounts) == account.id,
                              onTap: () =>
                                  setState(() => _accountId = account.id),
                            ),
                        ],
                      ),
                      if (_isTransfer) ...[
                        AppSize.fieldSpacing.ph,
                        const _FieldLabel('Compte à créditer'),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final account in accounts)
                              if (account.id != _selectedAccountId(accounts))
                                ChoiceChipTile(
                                  label: account.name,
                                  accent: AppColors.success,
                                  isSelected: _transferAccountId == account.id,
                                  onTap: () => setState(
                                    () => _transferAccountId = account.id,
                                  ),
                                ),
                          ],
                        ),
                      ],
                      AppSize.fieldSpacing.ph,
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(AppSize.radius),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.event_rounded, size: 20),
                          ),
                          child: Text(
                            DateFormatter.shortDate(_date),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      AppSize.fieldSpacing.ph,
                      AppTextField(
                        label: 'Note (facultatif)',
                        controller: _noteController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(
                          Icons.sticky_note_2_outlined,
                          size: 20,
                        ),
                      ),
                      AppSize.sectionSpacing.ph,
                      // Bouton d'enregistrement de l'opération.
                      AppPrimaryButton(
                        label: _isEditing
                            ? 'Enregistrer les modifications'
                            : (_isTransfer
                                  ? 'Enregistrer le transfert'
                                  : 'Ajouter l\'opération'),
                        icon: Icons.check_rounded,
                        isLoading: _isSaving,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Compte retenu : celui choisi, sinon le premier disponible.
  String? _selectedAccountId(List<Account> accounts) =>
      _accountId ?? (accounts.isEmpty ? null : accounts.first.id);

  String? _validateAmount(String? value) {
    final error = AppValidators.amount(value, label: 'Le montant');
    if (error != null) return error;

    final amount = MoneyFormatter.tryParse(value ?? '');
    if (amount == null || amount <= 0) {
      return 'Le montant doit être supérieur à 0';
    }
    return null;
  }
}

/// Titre d'un groupe de champs.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? AppColors.textWhite : AppColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Message affiché tant qu'aucun compte n'existe.
class _NoAccountView extends StatelessWidget {
  const _NoAccountView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSize.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 42,
              color: AppColors.textMuted,
            ),
            16.ph,
            Text(
              'Créez d\'abord un compte',
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            8.ph,
            const Text(
              'Une opération doit être rattachée à un compte pour être '
              'enregistrée.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            20.ph,
            AppPrimaryButton(
              label: 'Créer un compte',
              icon: Icons.add_rounded,
              isExpanded: false,
              onPressed: () => context.go(AppRoutes.accountCreate),
            ),
          ],
        ),
      ),
    );
  }
}
