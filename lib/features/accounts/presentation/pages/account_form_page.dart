import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/accounts/presentation/widgets/account_type_selector.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/utils/validators.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/error_view.dart';
import 'package:juka/shared/widget/padding.dart';

/// Formulaire de création (sans [accountId]) ou de modification d'un compte.
class AccountFormPage extends ConsumerStatefulWidget {
  const AccountFormPage({super.key, this.accountId});

  /// Compte à modifier ; `null` pour une création.
  final String? accountId;

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _noteController = TextEditingController();

  AccountType _type = AccountType.bank;
  AppCurrency _currency = AppCurrency.eur;
  bool _isSaving = false;

  /// Compte en cours de modification, lu une seule fois à l'initialisation :
  /// le formulaire travaille ensuite sur sa propre copie.
  Account? _existing;

  bool get _isEditing => widget.accountId != null;

  @override
  void initState() {
    super.initState();

    final accountId = widget.accountId;
    if (accountId == null) return;

    final account = ref.read(accountsControllerProvider).accountById(accountId);
    _existing = account;
    if (account == null) return;

    _nameController.text = account.name;
    _balanceController.text = MoneyFormatter.number(
      account.initialBalance,
      decimals: account.currency.decimalDigits,
    );
    _noteController.text = account.note ?? '';
    _type = account.type;
    _currency = account.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final note = _noteController.text;
    final initialBalance =
        MoneyFormatter.tryParse(_balanceController.text) ?? 0;

    setState(() => _isSaving = true);

    final controller = ref.read(accountsControllerProvider.notifier);
    final accountId = widget.accountId;
    final error = accountId == null
        ? await controller.create(
            name: name,
            type: _type,
            currency: _currency,
            initialBalance: initialBalance,
            note: note,
          )
        : await controller.update(
            id: accountId,
            name: name,
            type: _type,
            currency: _currency,
            initialBalance: initialBalance,
            note: note,
          );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }

    context.showAppSnackBar(_isEditing ? 'Compte mis à jour.' : 'Compte créé.');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.accounts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Accès direct à une fiche inexistante (lien profond, compte supprimé…).
    if (_isEditing && _existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier le compte')),
        body: const ErrorView(
          message: 'Ce compte est introuvable.',
          icon: Icons.search_off_rounded,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le compte' : 'Nouveau compte'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSize.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Nom du compte',
                  hintText: 'Compte courant, Orange Money…',
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                  validator: (value) => AppValidators.personName(
                    value,
                    label: 'Le nom du compte',
                  ),
                ),
                AppSize.fieldSpacing.ph,
                Text(
                  'Type de compte',
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                10.ph,
                AccountTypeSelector(
                  value: _type,
                  onChanged: (type) => setState(() => _type = type),
                ),
                AppSize.fieldSpacing.ph,
                _CurrencyField(
                  value: _currency,
                  onChanged: (currency) => setState(() => _currency = currency),
                ),
                AppSize.fieldSpacing.ph,
                AppTextField(
                  label: 'Solde initial',
                  hintText: '0',
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                  helperText: _type.isLiability
                      ? 'Saisissez un montant négatif : c\'est ce que vous devez.'
                      : 'Montant présent sur le compte au moment de sa création.',
                  validator: (value) =>
                      AppValidators.amount(value, label: 'Le solde initial'),
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
                AppPrimaryButton(
                  label: _isEditing ? 'Enregistrer' : 'Créer le compte',
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
}

/// Choix de la devise du compte.
class _CurrencyField extends StatelessWidget {
  const _CurrencyField({required this.value, required this.onChanged});

  final AppCurrency value;
  final ValueChanged<AppCurrency> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AppCurrency>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Devise',
        prefixIcon: Icon(Icons.currency_exchange_rounded, size: 20),
      ),
      items: [
        for (final currency in AppCurrency.values)
          DropdownMenuItem(
            value: currency,
            child: Text(currency.displayName, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (currency) {
        if (currency != null) onChanged(currency);
      },
    );
  }
}
