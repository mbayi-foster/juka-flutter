import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/category_visuals.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/presentation/providers/categories_providers.dart';
import 'package:juka/features/categories/presentation/state/categories_state.dart';
import 'package:juka/features/categories/presentation/widgets/category_editor_sheet.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/error_view.dart';
import 'package:juka/shared/widget/loading_view.dart';
import 'package:juka/shared/widget/padding.dart';
import 'package:juka/shared/widget/section_title.dart';

/// Gestion des catégories : création, modification, sous-catégories, archivage.
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    // Différé d'un microtask : Riverpod interdit de modifier un provider
    // pendant la construction de l'arbre de widgets.
    final controller = ref.read(categoriesControllerProvider.notifier);
    Future.microtask(controller.load);
  }

  Future<void> _edit({Category? category, String? parentId}) async {
    final state = ref.read(categoriesControllerProvider);

    final draft = await showCategoryEditor(
      context,
      categories: state.categories,
      category: category,
      parentId: parentId,
    );
    if (draft == null || !mounted) return;

    final error = await ref
        .read(categoriesControllerProvider.notifier)
        .saveCategory(
          id: category?.id,
          name: draft.name,
          kind: draft.kind,
          iconKey: draft.iconKey,
          colorHex: draft.colorHex,
          parentId: draft.parentId,
        );

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar(
      category == null ? 'Catégorie créée.' : 'Catégorie modifiée.',
    );
  }

  Future<void> _toggleArchive(Category category) async {
    final error = await ref
        .read(categoriesControllerProvider.notifier)
        .setCategoryArchived(id: category.id, isArchived: !category.isArchived);

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar(
      category.isArchived ? 'Catégorie restaurée.' : 'Catégorie archivée.',
    );
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text(
          '« ${category.name} » sera définitivement supprimée. Les catégories '
          'utilisées par une opération ou un budget doivent être archivées.',
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
        .read(categoriesControllerProvider.notifier)
        .deleteCategory(category.id);

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar('Catégorie supprimée.');
  }

  /// Aplatit l'arborescence : chaque catégorie avec sa profondeur.
  List<(Category, int)> _flatten(CategoriesState state) {
    final result = <(Category, int)>[];

    void add(Category category, int depth) {
      result.add((category, depth));
      for (final child in state.childrenOf(category.id)) {
        if (!child.isArchived) add(child, depth + 1);
      }
    }

    for (final root in state.roots) {
      if (!root.isArchived) add(root, 0);
    }

    // Catégories dont le parent est archivé ou introuvable.
    final rendered = {for (final entry in result) entry.$1.id};
    for (final category in state.activeCategories) {
      if (!rendered.contains(category.id)) result.add((category, 0));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tree = _flatten(state);
    final archived = state.archivedCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle catégorie'),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSize.pagePadding,
            8,
            AppSize.pagePadding,
            96,
          ),
          children: [
            Text(
              'Là où vous décidez comment dépenser.',
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            6.ph,
            const Text(
              'Créez vos catégories et leurs sous-catégories pour classer vos '
              'opérations.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            AppSize.sectionSpacing.ph,
            if (tree.isEmpty && state.isLoading)
              const LoadingView(message: 'Chargement de vos catégories…')
            else if (tree.isEmpty && state.hasFailed)
              ErrorView(
                message: state.errorMessage,
                onRetry: () =>
                    ref.read(categoriesControllerProvider.notifier).load(),
              )
            else ...[
              AppCard(
                title: 'Mes catégories',
                icon: Icons.sell_outlined,
                child: tree.isEmpty
                    ? const EmptyMessage(
                        message: 'Aucune catégorie active.',
                        icon: Icons.category_outlined,
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < tree.length; i++) ...[
                            if (i > 0) const Divider(height: 18),
                            _CategoryRow(
                              category: tree[i].$1,
                              depth: tree[i].$2,
                              isArchived: false,
                              canHaveChildren: tree[i].$2 == 0,
                              onEdit: () => _edit(category: tree[i].$1),
                              onAddChild: () => _edit(parentId: tree[i].$1.id),
                              onToggleArchive: () => _toggleArchive(tree[i].$1),
                              onDelete: () => _delete(tree[i].$1),
                            ),
                          ],
                        ],
                      ),
              ),
              if (archived.isNotEmpty) ...[
                AppSize.cardSpacing.ph,
                const SectionTitle(title: 'Catégories archivées'),
                12.ph,
                AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < archived.length; i++) ...[
                        if (i > 0) const Divider(height: 18),
                        _CategoryRow(
                          category: archived[i],
                          depth: 0,
                          isArchived: true,
                          canHaveChildren: false,
                          onToggleArchive: () => _toggleArchive(archived[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Ligne d'une catégorie dans l'arborescence.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.depth,
    required this.isArchived,
    required this.canHaveChildren,
    this.onEdit,
    this.onAddChild,
    this.onToggleArchive,
    this.onDelete,
  });

  final Category category;
  final int depth;
  final bool isArchived;
  final bool canHaveChildren;
  final VoidCallback? onEdit;
  final VoidCallback? onAddChild;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Color(category.colorHex);

    return Padding(
      padding: EdgeInsets.only(left: depth * 18),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.ph,
                Text(
                  category.isSubCategory
                      ? 'Sous-catégorie · ${category.kind.label}'
                      : category.kind.label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (onToggleArchive != null)
            PopupMenuButton<String>(
              tooltip: 'Actions',
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                  case 'child':
                    onAddChild?.call();
                  case 'archive':
                    onToggleArchive?.call();
                  case 'delete':
                    onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                if (canHaveChildren && onAddChild != null)
                  const PopupMenuItem(
                    value: 'child',
                    child: Text('Ajouter une sous-catégorie'),
                  ),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(isArchived ? 'Restaurer' : 'Archiver'),
                ),
                if (onDelete != null && !isArchived)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
