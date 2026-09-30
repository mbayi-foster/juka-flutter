import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/accounts/presentation/widgets/account_tile.dart';
import 'package:juka/features/accounts/presentation/widgets/accounts_summary_card.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/error_view.dart';
import 'package:juka/shared/widget/loading_view.dart';
import 'package:juka/shared/widget/padding.dart';
import 'package:juka/shared/widget/section_title.dart';

/// Onglet Comptes : là où se trouve votre argent.
///
/// Permet de créer, modifier et archiver des comptes (banque, mobile money,
/// espèces, épargne, dette, créance) et d'accéder à leur détail.
class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  @override
  void initState() {
    super.initState();
    // Différé d'un microtask : Riverpod interdit de modifier un provider
    // pendant la construction de l'arbre de widgets.
    final controller = ref.read(accountsControllerProvider.notifier);
    Future.microtask(controller.load);
  }

  Future<void> _refresh() =>
      ref.read(accountsControllerProvider.notifier).load();

  /// Archive ou restaure un compte, avec retour utilisateur.
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

  void _handleAction(Account account, AccountAction action) {
    if (action == AccountAction.edit) {
      context.push(AppRoutes.accountEdit(account.id));
      return;
    }
    _toggleArchive(account);
  }

  void _openAccount(Account account) =>
      context.push(AppRoutes.accountDetail(account.id));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsControllerProvider);
    final isEmpty = state.accounts.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Comptes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.accountCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau compte'),
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
              const _AccountsIntro(),
              AppSize.sectionSpacing.ph,
              if (isEmpty && state.isLoading)
                const LoadingView(message: 'Chargement de vos comptes…')
              else if (isEmpty && state.hasFailed)
                ErrorView(
                  message: state.errorMessage,
                  onRetry: () => _refresh(),
                )
              else ...[
                AccountsSummaryCard(
                  totals: state.totalsByCurrency,
                  activeCount: state.activeAccounts.length,
                  archivedCount: state.archivedAccounts.length,
                ),
                24.ph,
                const SectionTitle(title: 'Comptes actifs'),
                12.ph,
                if (state.activeAccounts.isEmpty)
                  const EmptyMessage(
                    message: 'Aucun compte actif. Créez-en un pour commencer.',
                    icon: Icons.account_balance_wallet_outlined,
                  )
                else
                  for (final account in state.activeAccounts) ...[
                    AccountTile(
                      account: account,
                      onTap: () => _openAccount(account),
                      onAction: (action) => _handleAction(account, action),
                    ),
                    12.ph,
                  ],
                if (state.archivedAccounts.isNotEmpty) ...[
                  12.ph,
                  const SectionTitle(title: 'Comptes archivés'),
                  12.ph,
                  for (final account in state.archivedAccounts) ...[
                    AccountTile(
                      account: account,
                      onTap: () => _openAccount(account),
                      onAction: (action) => _handleAction(account, action),
                    ),
                    12.ph,
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Phrase d'introduction de l'onglet.
class _AccountsIntro extends StatelessWidget {
  const _AccountsIntro();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Là où se trouve votre argent.',
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        6.ph,
        const Text(
          'Banque, mobile money, espèces, épargne, dettes et créances.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      ],
    );
  }
}
