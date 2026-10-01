import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/category_visuals.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/categories/domain/entities/budget_progress.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/presentation/providers/categories_providers.dart';
import 'package:juka/features/categories/presentation/widgets/budget_editor_sheet.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/error_view.dart';
import 'package:juka/shared/widget/loading_view.dart';
import 'package:juka/shared/widget/padding.dart';
import 'package:juka/shared/widget/section_title.dart';

/// Budgets mensuels : prévu contre réel, alertes et report du reste.
class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  @override
  void initState() {
    super.initState();
    final controller = ref.read(categoriesControllerProvider.notifier);
    Future.microtask(controller.load);
  }

  Future<void> _editBudget(Category category) async {
    final state = ref.read(categoriesControllerProvider);
    final budget = state.budgetOf(category.id);

    final result = await showBudgetEditor(
      context,
      category: category,
      budget: budget,
    );
    if (result == null || !mounted) return;

    final controller = ref.read(categoriesControllerProvider.notifier);
    final error = result.isDeleted
        ? await controller.deleteBudget(category.id)
        : await controller.saveBudget(
            categoryId: category.id,
            monthlyLimit: result.monthlyLimit,
            carryOver: result.carryOver,
          );

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar(
      result.isDeleted ? 'Budget supprimé.' : 'Budget enregistré.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesControllerProvider);
    final progress = ref.watch(budgetProgressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(categoriesControllerProvider.notifier).load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSize.pagePadding,
              8,
              AppSize.pagePadding,
              AppSize.sectionSpacing,
            ),
            children: [
              Text(
                DateFormatter.monthYear(DateTime.now()),
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              6.ph,
              const Text(
                'Comparez ce que vous aviez prévu à ce que vous avez '
                'réellement dépensé.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              AppSize.sectionSpacing.ph,
              progress.when(
                data: (items) => _BudgetsContent(
                  items: items,
                  unbudgeted: state.budgetable
                      .where((category) => state.budgetOf(category.id) == null)
                      .toList(),
                  onEdit: _editBudget,
                ),
                loading: () =>
                    const LoadingView(message: 'Calcul de vos budgets…'),
                error: (error, stackTrace) => ErrorView(
                  message: state.errorMessage,
                  onRetry: () =>
                      ref.read(categoriesControllerProvider.notifier).load(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contenu des budgets : synthèse, jauges puis catégories sans budget.
class _BudgetsContent extends StatelessWidget {
  const _BudgetsContent({
    required this.items,
    required this.unbudgeted,
    required this.onEdit,
  });

  final List<BudgetProgress> items;
  final List<Category> unbudgeted;
  final ValueChanged<Category> onEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && unbudgeted.isEmpty) {
      return const EmptyMessage(
        message: 'Aucune catégorie de dépense disponible pour un budget.',
        icon: Icons.savings_outlined,
      );
    }

    final planned = items.fold<double>(0, (sum, item) => sum + item.planned);
    final spent = items.fold<double>(0, (sum, item) => sum + item.spent);
    final alerts = items.where((item) => item.alert != BudgetAlert.none).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isNotEmpty) ...[
          _BudgetsSummaryCard(planned: planned, spent: spent, alerts: alerts),
          AppSize.cardSpacing.ph,
          const SectionTitle(title: 'Suivi par catégorie'),
          12.ph,
          for (final item in items) ...[
            _BudgetCard(progress: item, onEdit: () => onEdit(item.category)),
            12.ph,
          ],
        ],
        if (unbudgeted.isNotEmpty) ...[
          const SectionTitle(title: 'Sans budget'),
          8.ph,
          const Text(
            'Définissez une enveloppe pour suivre ces catégories.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          12.ph,
          for (final category in unbudgeted) ...[
            _UnbudgetedRow(category: category, onTap: () => onEdit(category)),
            12.ph,
          ],
        ],
      ],
    );
  }
}

/// Synthèse du mois : total prévu, total dépensé et nombre d'alertes.
class _BudgetsSummaryCard extends StatelessWidget {
  const _BudgetsSummaryCard({
    required this.planned,
    required this.spent,
    required this.alerts,
  });

  final double planned;
  final double spent;
  final int alerts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      title: 'Total du mois',
      icon: Icons.insights_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryAmount(
                  label: 'Prévu',
                  value: MoneyFormatter.currency(planned),
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                ),
              ),
              Expanded(
                child: _SummaryAmount(
                  label: 'Dépensé',
                  value: MoneyFormatter.currency(spent),
                  color: AppColors.error.forBrightness(theme.brightness),
                ),
              ),
              Expanded(
                child: _SummaryAmount(
                  label: 'Reste',
                  value: MoneyFormatter.currency(planned - spent),
                  color: (planned - spent) < 0
                      ? AppColors.error.forBrightness(theme.brightness)
                      : AppColors.success.forBrightness(theme.brightness),
                ),
              ),
            ],
          ),
          if (alerts > 0) ...[
            12.ph,
            Text(
              alerts == 1
                  ? '1 budget demande votre attention.'
                  : '$alerts budgets demandent votre attention.',
              style: TextStyle(
                color: AppColors.warning.forBrightness(theme.brightness),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Montant étiqueté de la synthèse.
class _SummaryAmount extends StatelessWidget {
  const _SummaryAmount({
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

/// Jauge d'un budget : prévu, réel, alerte et report.
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.progress, required this.onEdit});

  final BudgetProgress progress;
  final VoidCallback onEdit;

  Color _statusColor(ThemeData theme) => switch (progress.alert) {
    BudgetAlert.exceeded => AppColors.error,
    BudgetAlert.warning => AppColors.warning,
    BudgetAlert.none => AppColors.success,
  }.forBrightness(theme.brightness);

  String _statusLabel() {
    if (progress.isExceeded) {
      final excess = progress.spent - progress.planned;
      return 'Dépassé de ${MoneyFormatter.currency(excess)}';
    }
    return 'Reste ${MoneyFormatter.currency(progress.remaining)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;
    final accent = Color(progress.category.colorHex);
    final statusColor = _statusColor(theme);

    return AppCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CategoryVisuals.iconOfKey(progress.category.iconKey),
                  size: 17,
                  color: accent,
                ),
              ),
              12.pw,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    4.ph,
                    Text(
                      progress.budget.carryOver && progress.carriedOver > 0
                          ? 'Prévu ${MoneyFormatter.currency(progress.planned)} '
                                '(dont '
                                '${MoneyFormatter.currency(progress.carriedOver)} '
                                'reportés)'
                          : 'Prévu '
                                '${MoneyFormatter.currency(progress.planned)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              8.pw,
              if (progress.alert != BudgetAlert.none)
                Icon(
                  progress.isExceeded
                      ? Icons.error_outline_rounded
                      : Icons.warning_amber_rounded,
                  size: 20,
                  color: statusColor,
                ),
            ],
          ),
          12.ph,
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark
                  ? AppColors.borderDark
                  : AppColors.backgroundWhite,
              color: statusColor,
            ),
          ),
          8.ph,
          Row(
            children: [
              Expanded(
                child: Text(
                  _statusLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              8.pw,
              Text(
                '${MoneyFormatter.currency(progress.spent)} · '
                '${MoneyFormatter.percent(progress.ratio, decimals: 0, withSign: false)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Catégorie sans budget : propose d'en définir un.
class _UnbudgetedRow extends StatelessWidget {
  const _UnbudgetedRow({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Color(category.colorHex);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              CategoryVisuals.iconOfKey(category.iconKey),
              size: 19,
              color: accent,
            ),
          ),
          12.pw,
          Expanded(
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.add_circle_outline_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
