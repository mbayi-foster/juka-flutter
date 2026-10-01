import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/enums/report_export_format.dart';
import 'package:juka/features/reports/presentation/providers/reports_providers.dart';
import 'package:juka/features/reports/presentation/state/reports_state.dart';
import 'package:juka/features/reports/presentation/widgets/account_breakdown_card.dart';
import 'package:juka/features/reports/presentation/widgets/category_breakdown_card.dart';
import 'package:juka/features/reports/presentation/widgets/monthly_comparison_card.dart';
import 'package:juka/features/reports/presentation/widgets/report_export_sheet.dart';
import 'package:juka/features/reports/presentation/widgets/report_filters.dart';
import 'package:juka/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:juka/features/reports/presentation/widgets/top_expenses_card.dart';
import 'package:juka/features/reports/presentation/widgets/trends_card.dart';
import 'package:juka/features/wealth/domain/services/wealth_calculator.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/error_view.dart';
import 'package:juka/shared/widget/loading_view.dart';
import 'package:juka/shared/widget/padding.dart';

/// Écran « Rapports et analyses » : répond à « où part mon argent ? ».
///
/// Le rapport est calculé à partir des opérations réelles, sur la période et
/// le compte choisis, puis peut être exporté en PDF ou en tableau
/// (Excel / CSV) — les deux formats reprennent exactement les mêmes chiffres.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  @override
  void initState() {
    super.initState();
    // Différé d'un microtask : Riverpod interdit de modifier un provider
    // pendant la construction de l'arbre de widgets.
    final controller = ref.read(reportsControllerProvider.notifier);
    Future.microtask(controller.load);
  }

  Future<void> _refresh() =>
      ref.read(reportsControllerProvider.notifier).load();

  /// Devises réellement utilisées par les comptes, celle analysée d'abord.
  List<AppCurrency> _currenciesOf(List<Account> accounts, AppCurrency? active) {
    final currencies = <AppCurrency>{
      for (final account in accounts)
        if (!account.isArchived) account.currency,
    };
    final sorted = currencies.toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    final primary = active ?? WealthCalculator.primaryCurrency(accounts);
    if (primary != null && sorted.remove(primary)) sorted.insert(0, primary);
    return sorted;
  }

  /// Période libre choisie dans le calendrier.
  Future<void> _pickCustomPeriod() async {
    final now = DateTime.now();
    final current = ref.read(reportsControllerProvider).displayedPeriod;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month + 1, 0),
      initialDateRange: current == null
          ? null
          : DateTimeRange(start: current.start, end: current.end),
      helpText: 'Période du rapport',
      saveText: 'Analyser',
    );

    if (picked == null || !mounted) return;
    await ref
        .read(reportsControllerProvider.notifier)
        .selectRange(picked.start, picked.end);
  }

  Future<void> _openExportSheet() async {
    final format = await showModalBottomSheet<ReportExportFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => const ReportExportSheet(),
    );

    if (format == null || !mounted) return;
    await _export(format);
  }

  Future<void> _export(ReportExportFormat format) async {
    final exported = await ref
        .read(reportsControllerProvider.notifier)
        .export(format);

    if (!mounted) return;
    final message = exported == null
        ? (ref.read(reportsControllerProvider).exportErrorMessage ??
              'L\'export a échoué.')
        : '${exported.fileName} (${exported.readableSize}) exporté.';

    context.showAppSnackBar(message, isError: exported == null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsControllerProvider);
    final accounts = ref.watch(accountsControllerProvider).accounts;
    final report = state.report;
    final period = state.displayedPeriod;
    final canExport = report != null && !state.isEmpty && !state.isExporting;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rapports et analyses'),
            if (period != null)
              Text(
                '${period.rangeLabel} · ${report?.scopeLabel ?? 'Tous les comptes'}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Exporter le rapport',
            onPressed: canExport ? _openExportSheet : null,
            icon: state.isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
          ),
        ],
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
              AppSize.sectionSpacing,
            ),
            children: [
              ReportFilters(
                preset: state.preset,
                period: period,
                accounts: accounts,
                accountId: state.accountId,
                currency: state.currency,
                currencies: _currenciesOf(accounts, report?.currency),
                onPreset: (preset) => ref
                    .read(reportsControllerProvider.notifier)
                    .selectPreset(preset),
                onCustomRange: _pickCustomPeriod,
                onCurrency: (currency) => ref
                    .read(reportsControllerProvider.notifier)
                    .selectCurrency(currency),
                onAccount: (accountId) => ref
                    .read(reportsControllerProvider.notifier)
                    .selectAccount(accountId),
              ),
              AppSize.sectionSpacing.ph,
              ..._sections(state, report),
            ],
          ),
        ),
      ),
    );
  }

  /// Contenu de l'écran : chargement, erreur, écran vide ou sections.
  List<Widget> _sections(ReportsState state, ExpenseReport? report) {
    if (report == null) {
      return [
        if (state.isLoading)
          const LoadingView(message: 'Calcul de votre rapport…')
        else
          ErrorView(message: state.errorMessage, onRetry: _refresh),
      ];
    }

    if (state.isEmpty) return const [_NoOperationView()];

    return [
      ReportSummaryCard(report: report),
      AppSize.cardSpacing.ph,
      if (report.hasMonthlyData) ...[
        MonthlyComparisonCard(report: report),
        AppSize.cardSpacing.ph,
      ],
      if (report.hasCategoryData) ...[
        CategoryBreakdownCard(report: report),
        AppSize.cardSpacing.ph,
      ],
      if (report.hasAccountData) ...[
        AccountBreakdownCard(report: report),
        AppSize.cardSpacing.ph,
      ],
      if (report.hasTopExpenses) ...[
        TopExpensesCard(report: report),
        AppSize.cardSpacing.ph,
      ],
      TrendsCard(report: report),
      AppSize.cardSpacing.ph,
      AppPrimaryButton(
        label: 'Exporter le rapport',
        icon: Icons.ios_share_rounded,
        isLoading: state.isExporting,
        onPressed: state.isExporting ? null : _openExportSheet,
      ),
    ];
  }
}

/// Invitation affichée lorsqu'aucune opération ne tombe dans la période.
class _NoOperationView extends StatelessWidget {
  const _NoOperationView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.query_stats_rounded,
            size: 42,
            color: AppColors.textMuted,
          ),
          16.ph,
          Text(
            'Aucune donnée sur cette période',
            style: TextStyle(
              color: isDark ? AppColors.textWhite : AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          8.ph,
          const Text(
            'Les analyses se construisent à partir de vos opérations : '
            'élargissez la période ou saisissez une opération.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          20.ph,
          AppOutlinedButton(
            label: 'Saisir une opération',
            icon: Icons.add_rounded,
            isExpanded: false,
            onPressed: () => context.go(AppRoutes.operationCreate),
          ),
        ],
      ),
    );
  }
}
