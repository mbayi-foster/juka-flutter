import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/account_type_visuals.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/accounts/presentation/widgets/balance_history_chart.dart';
import 'package:juka/features/accounts/presentation/widgets/reconciliation_card.dart';
import 'package:juka/features/accounts/presentation/widgets/reconciliation_sheet.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/error_view.dart';
import 'package:juka/shared/widget/loading_view.dart';
import 'package:juka/shared/widget/padding.dart';

/// Détail d'un compte : solde courant, historique et rapprochement.
class AccountDetailPage extends ConsumerStatefulWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends ConsumerState<AccountDetailPage> {
  @override
  void initState() {
    super.initState();
    // Accès direct par lien profond : on s'assure que les comptes sont chargés.
    if (ref.read(accountsControllerProvider).accounts.isEmpty) {
      final controller = ref.read(accountsControllerProvider.notifier);
      Future.microtask(controller.load);
    }
  }

  Future<void> _refresh() =>
      ref.read(accountsControllerProvider.notifier).load();

  /// Ouvre la saisie du solde réel, puis enregistre le rapprochement.
  Future<void> _reconcile(Account account) async {
    final realBalance = await showReconciliationSheet(context, account);
    if (realBalance == null || !mounted) return;

    final error = await ref
        .read(accountsControllerProvider.notifier)
        .reconcile(id: account.id, realBalance: realBalance);

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar('Rapprochement enregistré.');
  }

  Future<void> _toggleArchive(Account account) async {
    final error = await ref
        .read(accountsControllerProvider.notifier)
        .setArchived(id: account.id, isArchived: !account.isArchived);

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar(
      account.isArchived ? 'Compte restauré.' : 'Compte archivé.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsControllerProvider);
    final account = state.accountById(widget.accountId);

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compte')),
        body: state.isLoading
            ? const LoadingView(message: 'Chargement du compte…')
            : const ErrorView(
                message: 'Ce compte est introuvable.',
                icon: Icons.search_off_rounded,
              ),
      );
    }

    final history = ref.watch(accountBalanceHistoryProvider(account.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            onPressed: () => context.push(AppRoutes.accountEdit(account.id)),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: account.isArchived ? 'Restaurer' : 'Archiver',
            onPressed: () => _toggleArchive(account),
            icon: Icon(
              account.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
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
              _BalanceHeaderCard(account: account),
              AppSize.cardSpacing.ph,
              AppCard(
                title: 'Historique du solde',
                icon: Icons.show_chart_rounded,
                child: history.when(
                  data: (points) => BalanceHistoryChart(
                    points: points,
                    currency: account.currency,
                  ),
                  loading: () => const LoadingView(height: 180),
                  error: (error, stackTrace) => const EmptyMessage(
                    message: 'Historique indisponible pour ce compte.',
                  ),
                ),
              ),
              AppSize.cardSpacing.ph,
              ReconciliationCard(
                account: account,
                onReconcile: () => _reconcile(account),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête du détail : identité du compte, solde et mouvements.
class _BalanceHeaderCard extends StatelessWidget {
  const _BalanceHeaderCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;
    final accent = AccountTypeVisuals.colorOf(account.type);
    final note = account.note;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  AccountTypeVisuals.iconOf(account.type),
                  size: 21,
                  color: accent.forBrightness(theme.brightness),
                ),
              ),
              12.pw,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    4.ph,
                    Text(
                      '${account.type.label} · ${account.currency.displayName}',
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
              if (account.isArchived) const _ArchivedPill(),
            ],
          ),
          18.ph,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              account.currency.format(account.currentBalance),
              style: TextStyle(
                color: titleColor,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          6.ph,
          const Text(
            'Solde actuel',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          16.ph,
          const Divider(height: 1),
          14.ph,
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Solde initial',
                  value: account.currency.format(account.initialBalance),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Mouvement',
                  value: account.currency.format(
                    account.movement,
                    withSign: true,
                  ),
                ),
              ),
            ],
          ),
          if (note != null) ...[
            14.ph,
            Text(
              note,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Étiquette signalant qu'un compte est archivé.
class _ArchivedPill extends StatelessWidget {
  const _ArchivedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Archivé',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Statistique secondaire affichée sous le solde.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: isDark ? AppColors.textWhite : AppColors.textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
