import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/features/settings/data/services/backup_file_service.dart';
import 'package:juka/shared/database/app_database.dart';

/// Sauvegarde locale : écriture du fichier JSON et restauration.
final backupFileServiceProvider = Provider<BackupFileService>(
  (ref) => BackupFileService(ref.watch(appDatabaseProvider)),
);
