import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/presentation/providers/operations_providers.dart';
import 'package:juka/features/operations/presentation/widgets/operation_filter_sheet.dart';
import 'package:juka/features/operations/presentation/widgets/operation_tile.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/error_view.dart';
import 'package:juka/shared/widget/loading_view.dart';
import 'package:juka/shared/widget/padding.dart';

/// Onglet Opérations : historique filtrable des revenus, dépenses et transferts.
class OperationsPage extends ConsumerStatefulWidget {
  const OperationsPage({super.key});

  @override
  ConsumerState<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends ConsumerState<OperationsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(operationsControllerProvider).filter.query,
    );

    // Différé d'un microtask : Riverpod interdit de modifier un provider
    // pendant la construction de l'arbre de widgets.
    final accountsController = ref.read(accountsControllerProvider.notifier);
    final operationsController = ref.read(
      operationsControllerProvider.notifier,
    );
    Future.microtask(() async {
      await accountsController.load();
      await operationsController.load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(operationsControllerProvider.notifier).load();

  Future<void> _applyFilter(OperationFilter filter) =>
      ref.read(operationsControllerProvider.notifier).applyFilter(filter);

  void _onSearchChanged(String value) {
    final filter = ref.read(operationsControllerProvider).filter;
    if (filter.query == value) return;
    _applyFilter(filter.copyWith(query: value));
  }

  Future<void> _openFilters() async {
    final filter = ref.read(operationsControllerProvider).filter;
    final accounts = ref.read(accountsControllerProvider).accounts;

    final selected = await showOperationFilterSheet(
      context,
      filter: filter,
      accounts: accounts,
    );

    if (selected == null || !mounted) return;
    await _applyFilter(selected);
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    await _applyFilter(const OperationFilter());
  }

  Future<void> _handleAction(
    Operation operation,
    OperationAction action,
  ) async {
    if (action == OperationAction.edit) {
      context.push(AppRoutes.operationEdit(operation.id));
      return;
    }
    await _confirmDelete(operation);
  }

  Future<void> _confirmDelete(Operation operation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'opération ?'),
        content: Text(
          '« ${operation.label} » sera définitivement supprimée et le solde '
          'du compte sera ajusté en conséquence.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(operationsControllerProvider.notifier)
        .delete(operation.id);

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar('Opération supprimée.');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(operationsControllerProvider);
    final accounts = ref.watch(accountsControllerProvider).accounts;
    final accountsById = {for (final account in accounts) account.id: account};

    return Scaffold(
      appBar: AppBar(title: const Text('Opérations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.operationCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle opération'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSize.pagePadding,
              8,
              AppSize.pagePadding,
              96,
            ),
            children: [
              _OperationsSummaryCard(
                totals: _totalsByCurrency(state.operations, accountsById),
              ),
              16.ph,
              AppTextField(
                label: 'Rechercher',
                hintText: 'Libellé ou note…',
                controller: _searchController,
                textInputAction: TextInputAction.search,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                onChanged: _onSearchChanged,
              ),
              12.ph,
              Row(
                children: [
                  Expanded(
                    child: AppOutlinedButton(
                      label: state.filter.activeCount == 0
                          ? 'Filtres'
                          : 'Filtres (${state.filter.activeCount})',
                      icon: Icons.filter_alt_outlined,
                      onPressed: _openFilters,
                    ),
                  ),
                  if (!state.filter.isEmpty) ...[
                    12.pw,
                    Expanded(
                      child: AppOutlinedButton(
                        label: 'Réinitialiser',
                        icon: Icons.filter_alt_off_outlined,
                        onPressed: _clearFilters,
                      ),
                    ),
                  ],
                ],
              ),
              20.ph,
              if (state.operations.isEmpty && state.isLoading)
                const LoadingView(message: 'Chargement de vos opérations…')
              else if (state.operations.isEmpty && state.hasFailed)
                ErrorView(
                  message: state.errorMessage,
                  onRetry: () => _refresh(),
                )
              else if (state.operations.isEmpty)
                EmptyMessage(
                  message: state.filter.isEmpty
                      ? 'Aucune opération enregistrée. Utilisez le bouton '
                            'ci-dessous pour saisir la première.'
                      : 'Aucune opération ne correspond à votre recherche.',
                  icon: Icons.receipt_long_rounded,
                )
              else
                for (final operation in state.operations) ...[
                  OperationTile(
                    operation: operation,
                    accounts: accountsById,
                    onTap: () =>
                        context.push(AppRoutes.operationEdit(operation.id)),
                    onAction: (action) => _handleAction(operation, action),
                  ),
                  12.ph,
                ],
            ],
          ),
        ),
      ),
    );
  }

  /// Totaux par devise : les devises ne s'additionnent pas entre elles et les
  /// transferts ne comptent ni comme revenu ni comme dépense.
  List<_CurrencyTotals> _totalsByCurrency(
    List<Operation> operations,
    Map<String, Account> accountsById,
  ) {
    final totals = <AppCurrency, _CurrencyTotals>{};

    for (final operation in operations) {
      if (!operation.type.countsInStats) continue;

      final currency =
          accountsById[operation.accountId]?.currency ?? AppCurrency.eur;
      final current = totals[currency] ?? _CurrencyTotals(currency: currency);
      totals[currency] = operation.isIncome
          ? current.copyWith(income: current.income + operation.amount)
          : current.copyWith(expenses: current.expenses + operation.amount);
    }

    return totals.values.toList()..sort((a, b) => b.income.compareTo(a.income));
  }
}

/// Carte de synthèse des montants de la sélection courante.
class _OperationsSummaryCard extends StatelessWidget {
  const _OperationsSummaryCard({required this.totals});

  final List<_CurrencyTotals> totals;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Sélection',
      icon: Icons.insights_rounded,
      child: totals.isEmpty
          ? const EmptyMessage(
              message: 'Aucun revenu ni dépense sur cette sélection.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < totals.length; i++) ...[
                  if (i > 0) 14.ph,
                  _CurrencyTotalRow(totals: totals[i]),
                ],
                12.ph,
                const Text(
                  'Les transferts déplacent de l\'argent entre vos comptes : '
                  'ils ne sont pas comptés comme dépense.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Ligne de synthèse : revenus, dépenses et solde pour une devise.
class _CurrencyTotalRow extends StatelessWidget {
  const _CurrencyTotalRow({required this.totals});

  final _CurrencyTotals totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          totals.currency.displayName,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        6.ph,
        Row(
          children: [
            Expanded(
              child: _Amount(
                label: 'Revenus',
                value: totals.currency.format(totals.income),
                color: AppColors.success.forBrightness(theme.brightness),
              ),
            ),
            Expanded(
              child: _Amount(
                label: 'Dépenses',
                value: totals.currency.format(totals.expenses),
                color: AppColors.error.forBrightness(theme.brightness),
              ),
            ),
            Expanded(
              child: _Amount(
                label: 'Solde',
                value: totals.currency.format(totals.net, withSign: true),
                color: isDark ? AppColors.textWhite : AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Montant étiqueté affiché dans la carte de synthèse.
class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
        ),
        2.ph,
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Totaux d'une devise pour la sélection courante.
class _CurrencyTotals {
  const _CurrencyTotals({
    required this.currency,
    this.income = 0,
    this.expenses = 0,
  });

  final AppCurrency currency;
  final double income;
  final double expenses;

  double get net => income - expenses;

  _CurrencyTotals copyWith({double? income, double? expenses}) =>
      _CurrencyTotals(
        currency: currency,
        income: income ?? this.income,
        expenses: expenses ?? this.expenses,
      );
}
