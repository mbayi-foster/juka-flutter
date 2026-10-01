import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/category_palette.dart';
import 'package:juka/common/constants/category_visuals.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/domain/enums/category_kind.dart';
import 'package:juka/shared/utils/validators.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';
import 'package:juka/shared/widget/padding.dart';

/// Saisie de l'éditeur de catégorie.
class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.kind,
    required this.iconKey,
    required this.colorHex,
    this.parentId,
  });

  final String name;
  final CategoryKind kind;
  final String iconKey;
  final int colorHex;
  final String? parentId;
}

/// Ouvre l'éditeur de catégorie et retourne la saisie (`null` si annulée).
Future<CategoryDraft?> showCategoryEditor(
  BuildContext context, {
  required List<Category> categories,
  Category? category,
  String? parentId,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<CategoryDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _CategoryEditorSheet(
      categories: categories,
      category: category,
      parentId: parentId,
    ),
  );
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({
    required this.categories,
    this.category,
    this.parentId,
  });

  final List<Category> categories;
  final Category? category;
  final String? parentId;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late CategoryKind _kind;
  late String _iconKey;
  late int _colorHex;
  String? _parentId;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;

    _nameController = TextEditingController(text: category?.name ?? '');
    _kind = category?.kind ?? CategoryKind.expense;
    _iconKey = category?.iconKey ?? CategoryVisuals.defaultIconKey;
    _colorHex = category?.colorHex ?? CategoryPalette.all.first;
    _parentId = category?.parentId ?? widget.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Catégories qui peuvent accueillir la catégorie éditée.
  ///
  /// On exclut la catégorie elle-même et ses descendantes, pour ne pas créer de
  /// cycle dans l'arborescence.
  List<Category> get _eligibleParents {
    final excluded = <String>{if (widget.category != null) widget.category!.id};
    final id = widget.category?.id;

    if (id != null) {
      void collect(String parentId) {
        for (final category in widget.categories) {
          if (category.parentId == parentId && excluded.add(category.id)) {
            collect(category.id);
          }
        }
      }

      collect(id);
    }

    return [
      for (final category in widget.categories)
        if (!category.isArchived &&
            category.kind == _kind &&
            !excluded.contains(category.id))
          category,
    ];
  }

  /// La catégorie peut-elle encore accepter un parent ?
  ///
  /// Une catégorie qui a déjà des sous-catégories reste au premier niveau pour
  /// garder une arborescence à deux niveaux.
  bool get _parentLocked {
    final id = widget.category?.id;
    if (id == null) return false;
    return widget.categories.any((category) => category.parentId == id);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      CategoryDraft(
        name: _nameController.text.trim(),
        kind: _kind,
        iconKey: _iconKey,
        colorHex: _colorHex,
        parentId: _parentLocked ? null : _parentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSize.pagePadding,
          AppSize.pagePadding,
          AppSize.pagePadding,
          MediaQuery.viewInsetsOf(context).bottom + AppSize.pagePadding,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              20.ph,
              AppTextField(
                label: 'Nom',
                hintText: 'Alimentation, Restaurant…',
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) =>
                    AppValidators.required(value, label: 'Le nom'),
              ),
              AppSize.fieldSpacing.ph,
              _FieldLabel('Type', color: titleColor),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final kind in CategoryKind.values)
                    ChoiceChipTile(
                      label: kind.label,
                      isSelected: _kind == kind,
                      onTap: () => setState(() {
                        _kind = kind;
                        // Un parent d'un autre type n'est plus valide.
                        if (_parentId != null &&
                            !_eligibleParents.any((c) => c.id == _parentId)) {
                          _parentId = null;
                        }
                      }),
                    ),
                ],
              ),
              AppSize.fieldSpacing.ph,
              _FieldLabel('Catégorie parente (facultatif)', color: titleColor),
              if (_parentLocked)
                const Text(
                  'Cette catégorie a déjà des sous-catégories : elle reste au '
                  'premier niveau.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChipTile(
                      label: 'Aucune',
                      isSelected: _parentId == null,
                      onTap: () => setState(() => _parentId = null),
                    ),
                    for (final parent in _eligibleParents)
                      ChoiceChipTile(
                        label: parent.name,
                        isSelected: _parentId == parent.id,
                        onTap: () => setState(() => _parentId = parent.id),
                      ),
                  ],
                ),
              AppSize.fieldSpacing.ph,
              _FieldLabel('Icône', color: titleColor),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final entry in CategoryVisuals.icons.entries)
                    _IconChoice(
                      icon: entry.value,
                      colorHex: _colorHex,
                      isSelected: _iconKey == entry.key,
                      onTap: () => setState(() => _iconKey = entry.key),
                    ),
                ],
              ),
              AppSize.fieldSpacing.ph,
              _FieldLabel('Couleur', color: titleColor),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final colorHex in CategoryPalette.all)
                    _ColorChoice(
                      colorHex: colorHex,
                      isSelected: _colorHex == colorHex,
                      onTap: () => setState(() => _colorHex = colorHex),
                    ),
                ],
              ),
              AppSize.sectionSpacing.ph,
              AppPrimaryButton(
                label: _isEditing ? 'Enregistrer' : 'Créer la catégorie',
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titre d'un groupe de champs.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Icône sélectionnable du catalogue.
class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.colorHex,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final int colorHex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Color(colorHex);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSize.radius),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(AppSize.radius),
          border: Border.all(
            color: isSelected
                ? accent
                : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.borderDark
                      : AppColors.border),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? accent : AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Pastille de couleur sélectionnable.
class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.colorHex,
    required this.isSelected,
    required this.onTap,
  });

  final int colorHex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Color(colorHex),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.textDark : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}
