import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/wealth/domain/entities/debt_progress.dart';
import 'package:juka/features/wealth/domain/entities/wealth_overview.dart';
import 'package:juka/features/wealth/domain/services/wealth_calculator.dart';
import 'package:juka/features/wealth/presentation/providers/wealth_providers.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/error_view.dart';
import 'package:juka/shared/widget/evolution_chart.dart';
import 'package:juka/shared/widget/loading_view.dart';
import 'package:juka/shared/widget/padding.dart';

/// Écran « Patrimoine et progression » : répond à « est-ce que je progresse ? ».
///
/// Le patrimoine net est calculé à partir des comptes réels, une photo est
/// enregistrée chaque mois, et les indicateurs (taux d'épargne, fonds
/// d'urgence, ratio d'endettement) ainsi que le remboursement des dettes sont
/// dérivés des opérations.
class WealthPage extends ConsumerStatefulWidget {
  const WealthPage({super.key});

  @override
  ConsumerState<WealthPage> createState() => _WealthPageState();
}

class _WealthPageState extends ConsumerState<WealthPage> {
  @override
  void initState() {
    super.initState();
    // Différé d'un microtask : Riverpod interdit de modifier un provider
    // pendant la construction de l'arbre de widgets.
    final controller = ref.read(wealthControllerProvider.notifier);
    Future.microtask(() => controller.load());
  }

  Future<void> _refresh() => ref.read(wealthControllerProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wealthControllerProvider);
    final accounts = ref.watch(accountsControllerProvider).accounts;
    final overview = state.overview;
    final currencies = _currenciesOf(accounts);

    return Scaffold(
      appBar: AppBar(title: const Text('Patrimoine')),
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
              const _Intro(),
              AppSize.sectionSpacing.ph,
              if (currencies.length > 1) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final currency in currencies)
                      ChoiceChipTile(
                        label: currency.code,
                        isSelected: state.displayedCurrency == currency,
                        onTap: () => ref
                            .read(wealthControllerProvider.notifier)
                            .selectCurrency(currency),
                      ),
                  ],
                ),
                20.ph,
              ],
              if (state.isLoading && overview == null)
                const LoadingView(message: 'Calcul de votre patrimoine…')
              else if (overview != null) ...[
                _NetWorthCard(overview: overview),
                AppSize.cardSpacing.ph,
                _IndicatorsCard(overview: overview),
                AppSize.cardSpacing.ph,
                _EvolutionCard(overview: overview),
                if (overview.debts.isNotEmpty) ...[
                  AppSize.cardSpacing.ph,
                  _DebtsCard(overview: overview),
                ],
                AppSize.cardSpacing.ph,
                _BreakdownCard(overview: overview),
              ] else if (state.hasFailed)
                ErrorView(
                  message: state.errorMessage,
                  onRetry: () => _refresh(),
                )
              else
                const _NoAccountView(),
            ],
          ),
        ),
      ),
    );
  }

  /// Devises réellement utilisées par les comptes, les plus utilisées d'abord.
  List<AppCurrency> _currenciesOf(List<Account> accounts) {
    final primary = WealthCalculator.primaryCurrency(accounts);
    final currencies = <AppCurrency>{
      for (final account in accounts)
        if (!account.isArchived) account.currency,
    };

    final sorted = currencies.toList();
    if (primary != null) {
      sorted
        ..remove(primary)
        ..insert(0, primary);
    }
    return sorted;
  }
}

/// Phrase d'introduction de l'écran.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Est-ce que je progresse ?',
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        6.ph,
        const Text(
          'Une photo de votre patrimoine est prise chaque mois à '
          'l\'ouverture de l\'application.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      ],
    );
  }
}

/// Patrimoine net et son évolution depuis le mois précédent.
class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.overview});

  final WealthOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;
    final currency = overview.currency;
    final change = overview.change;
    final previousMonth = overview.previousMonth;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Patrimoine net',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (change != null)
                _TrendPill(
                  change: change,
                  ratio: overview.changeRatio,
                  currency: currency,
                ),
            ],
          ),
          14.ph,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              currency.format(overview.netWorth, withSign: true),
              style: TextStyle(
                color: titleColor,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          12.ph,
          const Divider(height: 1),
          14.ph,
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Actifs',
                  value: currency.format(overview.assets),
                  color: AppColors.success.forBrightness(theme.brightness),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Dettes',
                  value: currency.format(overview.liabilities),
                  color: overview.liabilities > 0
                      ? AppColors.error.forBrightness(theme.brightness)
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
          12.ph,
          Text(
            previousMonth == null
                ? 'Première photo enregistrée : l\'évolution sera visible le '
                      'mois prochain.'
                : 'Comparé au mois de ${DateFormatter.monthYear(previousMonth.month)}.',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille de variation (montant + pourcentage).
class _TrendPill extends StatelessWidget {
  const _TrendPill({
    required this.change,
    required this.ratio,
    required this.currency,
  });

  final double change;
  final double? ratio;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final isUp = change >= 0;
    final color = (isUp ? AppColors.success : AppColors.error).forBrightness(
      Theme.of(context).brightness,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 16,
            color: color,
          ),
          6.pw,
          Text(
            ratio == null
                ? currency.format(change, withSign: true)
                : MoneyFormatter.percent(ratio!, withSign: false),
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicateurs : taux d'épargne, fonds d'urgence, ratio d'endettement.
class _IndicatorsCard extends StatelessWidget {
  const _IndicatorsCard({required this.overview});

  final WealthOverview overview;

  @override
  Widget build(BuildContext context) {
    final indicators = overview.indicators;

    return AppCard(
      title: 'Indicateurs',
      icon: Icons.insights_rounded,
      child: Column(
        children: [
          _IndicatorRow(
            label: 'Taux d\'épargne',
            value: indicators.savingsRate == null
                ? '—'
                : MoneyFormatter.percent(
                    indicators.savingsRate!,
                    withSign: false,
                  ),
            hint: 'Part des revenus du mois non dépensée.',
            isHealthy: indicators.isSaving,
          ),
          16.ph,
          _IndicatorRow(
            label: 'Fonds d\'urgence',
            value: indicators.emergencyFundMonths == null
                ? '—'
                : '${MoneyFormatter.number(indicators.emergencyFundMonths!, decimals: 1)} mois',
            hint:
                'Actifs mobilisables (${overview.currency.format(indicators.liquidAssets)}) '
                'rapportés aux dépenses du mois.',
            isHealthy: indicators.hasEmergencyFund,
          ),
          16.ph,
          _IndicatorRow(
            label: 'Ratio d\'endettement',
            value: indicators.debtRatio == null
                ? '—'
                : MoneyFormatter.percent(
                    indicators.debtRatio!,
                    withSign: false,
                  ),
            hint: 'Dettes rapportées aux actifs.',
            isHealthy: indicators.isDebtHealthy,
          ),
        ],
      ),
    );
  }
}

/// Ligne d'indicateur avec libellé, valeur et état.
class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.isHealthy,
  });

  final String label;
  final String value;
  final String hint;

  /// `true` lorsque l'indicateur est dans une zone satisfaisante.
  final bool isHealthy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = (isHealthy ? AppColors.success : AppColors.warning)
        .forBrightness(theme.brightness);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isHealthy ? Icons.check_rounded : Icons.priority_high_rounded,
            size: 18,
            color: color,
          ),
        ),
        12.pw,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  8.pw,
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              4.ph,
              Text(
                hint,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Courbe d'évolution du patrimoine net.
class _EvolutionCard extends StatelessWidget {
  const _EvolutionCard({required this.overview});

  final WealthOverview overview;

  @override
  Widget build(BuildContext context) {
    final history = overview.history;

    return AppCard(
      title: 'Évolution du patrimoine',
      icon: Icons.show_chart_rounded,
      child: history.isEmpty
          ? const EmptyMessage(
              message: 'L\'historique se construira au fil des mois.',
              icon: Icons.show_chart_rounded,
            )
          : EvolutionChart(
              points: [
                for (final snapshot in history)
                  (date: snapshot.month, value: snapshot.netWorth),
              ],
            ),
    );
  }
}

/// Suivi du remboursement des dettes.
class _DebtsCard extends StatelessWidget {
  const _DebtsCard({required this.overview});

  final WealthOverview overview;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Remboursement des dettes',
      icon: Icons.credit_score_rounded,
      trailing: Text(
        overview.currency.format(overview.totalDebt),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < overview.debts.length; i++) ...[
            if (i > 0) 18.ph,
            _DebtRow(debt: overview.debts[i], currency: overview.currency),
          ],
        ],
      ),
    );
  }
}

/// Ligne de suivi d'une dette.
class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.debt, required this.currency});

  final DebtProgress debt;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;
    final color = debt.isRepaid
        ? AppColors.success.forBrightness(theme.brightness)
        : AppColors.warning.forBrightness(theme.brightness);
    final payoffDate = debt.estimatedPayoffDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                debt.account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            8.pw,
            Text(
              '${currency.format(debt.remainingDebt)} restants',
              style: TextStyle(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        8.ph,
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: debt.progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: isDark
                ? AppColors.borderDark
                : AppColors.backgroundWhite,
            color: color,
          ),
        ),
        8.ph,
        Text(
          _statusLabel(debt, payoffDate),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  String _statusLabel(DebtProgress debt, DateTime? payoffDate) {
    if (debt.isRepaid) {
      return 'Dette soldée : ${debt.progress > 0 ? '${(debt.progress * 100).round()} % remboursés' : 'aucun montant restant'}.';
    }

    final parts = <String>[
      '${(debt.progress * 100).round()} % remboursés sur '
          '${currency.format(debt.initialDebt)}',
    ];

    final months = debt.monthsRemaining;
    if (months == null) {
      parts.add('Rythme de remboursement inconnu');
    } else {
      parts.add('Soldée dans $months mois');
      if (payoffDate != null) {
        parts.add('soit ${DateFormatter.monthYear(payoffDate)}');
      }
    }

    return '${parts.join(' · ')}.';
  }
}

/// Composition du patrimoine : comptes d'actifs et dettes.
class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.overview});

  final WealthOverview overview;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;
    final accounts = WealthCalculator.assetAccounts(
      overview.accounts,
      overview.currency,
    );
    final debts = overview.debts;

    return AppCard(
      title: 'Composition',
      icon: Icons.account_balance_wallet_rounded,
      child: accounts.isEmpty && debts.isEmpty
          ? const EmptyMessage(message: 'Aucun compte pour cette devise.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < accounts.length; i++) ...[
                  if (i > 0) 12.ph,
                  _BreakdownRow(
                    label: accounts[i].name,
                    value: overview.currency.format(accounts[i].currentBalance),
                    color: titleColor,
                  ),
                ],
                if (accounts.isNotEmpty) ...[
                  14.ph,
                  const Divider(height: 1),
                  14.ph,
                ],
                for (var i = 0; i < debts.length; i++) ...[
                  if (i > 0) 12.ph,
                  _BreakdownRow(
                    label: '${debts[i].account.name} (dette)',
                    value: overview.currency.format(-debts[i].remainingDebt),
                    color: AppColors.error.forBrightness(
                      Theme.of(context).brightness,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Ligne « libellé / montant » de la composition.
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        8.pw,
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Statistique secondaire affichée sous le patrimoine.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
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
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        4.ph,
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Invitation à créer un compte lorsque le patrimoine ne peut pas être calculé.
class _NoAccountView extends StatelessWidget {
  const _NoAccountView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 42,
            color: AppColors.textMuted,
          ),
          16.ph,
          Text(
            'Aucun compte à suivre',
            style: TextStyle(
              color: isDark ? AppColors.textWhite : AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          8.ph,
          const Text(
            'Le patrimoine est calculé à partir de vos comptes : créez-en un '
            'pour lancer le suivi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          20.ph,
          AppOutlinedButton(
            label: 'Créer un compte',
            icon: Icons.add_rounded,
            isExpanded: false,
            onPressed: () => context.go(AppRoutes.accountCreate),
          ),
        ],
      ),
    );
  }
}
