import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:juka/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:juka/features/dashboard/presentation/widgets/budget_progress_card.dart';
import 'package:juka/features/dashboard/presentation/widgets/dashboard_alerts_card.dart';
import 'package:juka/features/dashboard/presentation/widgets/flow_summary_card.dart';
import 'package:juka/features/dashboard/presentation/widgets/net_worth_card.dart';
import 'package:juka/features/dashboard/presentation/widgets/recent_operations_card.dart';
import 'package:juka/features/dashboard/presentation/widgets/spending_breakdown_card.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/padding.dart';

/// Onglet d'accueil : répond à « où j'en suis ? » en un coup d'œil.
///
/// Il regroupe le patrimoine net, les flux du mois, la répartition des
/// dépenses, les budgets consommés ainsi que les dernières opérations et
/// alertes.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Premier chargement dès l'affichage de l'onglet. Il est différé d'un
    // microtask car Riverpod interdit de modifier un provider pendant la
    // construction de l'arbre de widgets.
    final controller = ref.read(dashboardControllerProvider.notifier);
    Future.microtask(controller.load);
  }

  Future<void> _refresh() =>
      ref.read(dashboardControllerProvider.notifier).load();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    final overview = state.overview;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSize.pagePadding,
              16,
              AppSize.pagePadding,
              AppSize.sectionSpacing,
            ),
            children: [
              const _DashboardHeader(),
              AppSize.sectionSpacing.ph,
              if (overview != null)
                _DashboardContent(overview: overview)
              else if (state.isLoading)
                const _DashboardLoading()
              else
                _DashboardError(message: state.errorMessage, onRetry: _refresh),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête de l'écran : titre et promesse de la page.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tableau de bord',
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        6.ph,
        const Text(
          'Où j\'en suis, en un coup d\'œil.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14.5),
        ),
      ],
    );
  }
}

/// Contenu complet du tableau de bord, une fois les données disponibles.
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NetWorthCard(netWorth: overview.netWorth),
        AppSize.cardSpacing.ph,
        FlowSummaryCard(flow: overview.flow, period: overview.period),
        AppSize.cardSpacing.ph,
        SpendingBreakdownCard(items: overview.sortedSpendingByCategory),
        AppSize.cardSpacing.ph,
        BudgetProgressCard(budgets: overview.budgets),
        AppSize.cardSpacing.ph,
        RecentOperationsCard(operations: overview.recentOperations),
        AppSize.cardSpacing.ph,
        DashboardAlertsCard(alerts: overview.alerts),
      ],
    );
  }
}

/// Indicateur affiché pendant le premier chargement.
class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.6),
            16.ph,
            const Text(
              'Chargement de votre tableau de bord…',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran d'erreur avec possibilité de relancer le chargement.
class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: AppColors.textMuted,
          ),
          16.ph,
          Text(
            message ?? 'Impossible de charger vos données.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.textWhite : AppColors.textDark,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
          20.ph,
          AppOutlinedButton(
            label: 'Réessayer',
            icon: Icons.refresh_rounded,
            isExpanded: false,
            onPressed: () => onRetry(),
          ),
        ],
      ),
    );
  }
}
