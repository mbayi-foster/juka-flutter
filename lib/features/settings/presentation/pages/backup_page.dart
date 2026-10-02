import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/categories/presentation/providers/categories_providers.dart';
import 'package:juka/features/currencies/presentation/providers/currencies_providers.dart';
import 'package:juka/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:juka/features/operations/presentation/providers/operations_providers.dart';
import 'package:juka/features/settings/domain/services/backup_codec.dart';
import 'package:juka/features/settings/presentation/providers/backup_providers.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/padding.dart';

/// Sauvegarde et export des données de l'application.
///
/// Tout vit sur le téléphone : la sauvegarde est un fichier JSON que
/// l'utilisateur range où il veut, et qu'il peut restaurer plus tard.
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _isBusy = false;

  Future<void> _export() async {
    setState(() => _isBusy = true);
    final now = DateTime.now();

    try {
      final service = ref.read(backupFileServiceProvider);
      final file = await service.createBackup(now: now);
      await service.share(file, createdAt: now);

      if (!mounted) return;
      context.showAppSnackBar(
        'Sauvegarde enregistrée (${file.uri.pathSegments.last}).',
      );
    } on BackupFormatException catch (failure) {
      if (!mounted) return;
      context.showAppSnackBar(failure.message, isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _isBusy = true);

    try {
      final document = await ref.read(backupFileServiceProvider).pickBackup();
      if (document == null || !mounted) return;

      final confirmed = await _confirmRestore(document);
      if (confirmed != true || !mounted) return;

      await ref.read(backupFileServiceProvider).restore(document);
      await _refreshEverything();

      if (!mounted) return;
      context.showAppSnackBar(
        'Sauvegarde restaurée : ${document.rowCount} enregistrements.',
      );
    } on BackupFormatException catch (failure) {
      if (!mounted) return;
      context.showAppSnackBar(failure.message, isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<bool?> _confirmRestore(BackupDocument document) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer cette sauvegarde ?'),
        content: Text(
          'Elle contient ${document.rowCount} enregistrements '
          '(${DateFormatter.numeric(document.createdAt)}).\n\n'
          'Vos données actuelles seront remplacées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
  }

  /// Recharge les écrans déjà ouverts avec les données restaurées.
  Future<void> _refreshEverything() async {
    await ref.read(accountsControllerProvider.notifier).load();
    await ref.read(operationsControllerProvider.notifier).load();
    await ref.read(categoriesControllerProvider.notifier).load();
    await ref.read(dashboardControllerProvider.notifier).load();
    await ref.read(exchangeRatesControllerProvider.notifier).reload();
    ref.invalidate(trackedCurrenciesProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegarde et export')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSize.pagePadding),
          children: [
            AppCard(
              title: 'Exporter mes données',
              icon: Icons.upload_file_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Un fichier contenant vos comptes, opérations, catégories, '
                    'budgets, réglages et taux de change. Conservez-le dans un '
                    'endroit sûr : c\'est votre seule copie.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  AppSize.fieldSpacing.ph,
                  AppPrimaryButton(
                    label: 'Créer une sauvegarde',
                    icon: Icons.save_alt_rounded,
                    isLoading: _isBusy,
                    onPressed: _isBusy ? null : _export,
                  ),
                ],
              ),
            ),
            AppSize.cardSpacing.ph,
            AppCard(
              title: 'Restaurer une sauvegarde',
              icon: Icons.restore_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choisissez un fichier Juka déjà exporté. Attention : vos '
                    'données actuelles seront remplacées.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  AppSize.fieldSpacing.ph,
                  AppOutlinedButton(
                    label: 'Choisir un fichier',
                    icon: Icons.folder_open_rounded,
                    onPressed: _isBusy ? null : _import,
                  ),
                ],
              ),
            ),
            AppSize.cardSpacing.ph,
            const AppCard(
              child: Text(
                'Les fichiers sont créés dans le dossier privé de '
                'l\'application puis partagés avec l\'application de votre '
                'choix (Fichiers, Drive, e-mail…). Aucune donnée ne quitte '
                'votre téléphone sans votre accord.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
