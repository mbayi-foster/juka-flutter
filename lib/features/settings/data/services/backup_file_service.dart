import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import 'package:juka/features/settings/domain/services/backup_codec.dart';
import 'package:juka/shared/database/app_database.dart';

/// Écrit, partage et restaure le fichier de sauvegarde des données locales.
///
/// Le fichier est déposé dans les documents de l'application puis envoyé où
/// l'utilisateur le souhaite via la feuille de partage du système : aucune
/// permission de stockage n'est nécessaire.
class BackupFileService {
  const BackupFileService(this._appDatabase);

  /// Sous-dossier des sauvegardes, dans les documents de l'application.
  static const String folderName = 'sauvegardes';

  static const String _readErrorMessage = 'La sauvegarde n\'a pas pu être lue.';
  static const String _writeErrorMessage =
      'La sauvegarde n\'a pas pu être enregistrée sur l\'appareil.';
  static const String _restoreErrorMessage =
      'La sauvegarde n\'a pas pu être restaurée.';

  final AppDatabase _appDatabase;

  /// Rassemble toutes les tables et écrit le fichier JSON.
  Future<File> createBackup({DateTime? now}) async {
    final db = await _appDatabase.database;
    final rows = <String, List<Map<String, Object?>>>{};

    for (final table in BackupCodec.tables) {
      rows[table] = await db.query(table);
    }

    final content = BackupCodec.encode(
      rows: rows,
      createdAt: now ?? DateTime.now(),
    );

    try {
      final file = await _write(_fileName(now ?? DateTime.now()), content);
      return file;
    } catch (_) {
      throw const BackupFormatException(_writeErrorMessage);
    }
  }

  /// Ouvre la feuille de partage du système pour un fichier écrit.
  Future<void> share(File file, {required DateTime createdAt}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          fileNameOverrides: [file.uri.pathSegments.last],
          subject: 'Sauvegarde Juka',
          text:
              'Sauvegarde Juka du ${createdAt.day}/${createdAt.month}/'
              '${createdAt.year}',
        ),
      );
    } catch (_) {
      // Le fichier est déjà écrit : un partage annulé n'est pas une erreur.
      return;
    }
  }

  /// Laisse l'utilisateur choisir un fichier de sauvegarde.
  ///
  /// Retourne `null` s'il annule, lève [BackupFormatException] si le fichier
  /// n'est pas exploitable.
  Future<BackupDocument?> pickBackup() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Choisir une sauvegarde Juka',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked == null) return null;

    final String content;
    try {
      content = utf8.decode(await picked.readAsBytes());
    } catch (_) {
      throw const BackupFormatException(_readErrorMessage);
    }

    return BackupCodec.decode(content);
  }

  /// Remplace toutes les données locales par celles de [document].
  Future<void> restore(BackupDocument document) async {
    if (document.tables.isEmpty) {
      throw const BackupFormatException(
        'Cette sauvegarde ne contient aucune donnée.',
      );
    }

    final db = await _appDatabase.database;
    try {
      await db.transaction((txn) async {
        for (final table in BackupCodec.tables) {
          await txn.delete(table);
        }
        for (final table in BackupCodec.tables) {
          final rows = document.tables[table];
          if (rows == null) continue;

          final batch = txn.batch();
          for (final row in rows) {
            batch.insert(
              table,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        }
      });
    } catch (_) {
      throw const BackupFormatException(_restoreErrorMessage);
    }
  }

  Future<File> _write(String fileName, String content) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/$folderName');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content, flush: true);
    return file;
  }

  /// `juka-sauvegarde-2026-10-01-1930.json`.
  static String _fileName(DateTime now) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'juka-sauvegarde-${now.year}-${two(now.month)}-${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}.json';
  }
}
