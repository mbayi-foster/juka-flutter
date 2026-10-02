import 'package:flutter_test/flutter_test.dart';
import 'package:juka/features/settings/domain/services/backup_codec.dart';

const _createdAt = 1_790_000_000_000;

void main() {
  group('BackupCodec', () {
    test('écrit toutes les tables, même vides', () {
      final content = BackupCodec.encode(
        rows: {
          'accounts': [
            {'id': 'acc-1', 'name': 'Espèces', 'currency': 'CDF'},
          ],
          'operations': [
            {'id': 'op-1', 'amount': 12.5},
            {'id': 'op-2', 'amount': 30.0},
          ],
        },
        createdAt: DateTime.fromMillisecondsSinceEpoch(_createdAt),
      );

      final document = BackupCodec.decode(content);

      expect(document.createdAt.millisecondsSinceEpoch, _createdAt);
      expect(document.rowCount, 3);
      expect(document.counts['operations'], 2);
      expect(document.tables['accounts']!.single['name'], 'Espèces');
      // Les tables sans donnée sont présentes mais vides.
      expect(document.tables.keys, containsAll(BackupCodec.tables));
      expect(document.tables['budgets'], isEmpty);
    });

    test('refuse un contenu qui n\'est pas du JSON', () {
      expect(
        () => BackupCodec.decode('pas du json'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuse un JSON qui ne vient pas de Juka', () {
      expect(
        () => BackupCodec.decode('{"format":"autre","version":1,"tables":{}}'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('refuse une sauvegarde d\'une version plus récente', () {
      expect(
        () => BackupCodec.decode(
          '{"format":"${BackupCodec.format}","version":99,"tables":{}}',
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('ignore les colonnes inconnues en trop', () {
      final content = BackupCodec.encode(
        rows: {
          'accounts': [
            {'id': 'acc-1', 'colonne_absente': true},
          ],
        },
        createdAt: DateTime.fromMillisecondsSinceEpoch(_createdAt),
      );

      final document = BackupCodec.decode(content);
      expect(document.tables['accounts']!.single['colonne_absente'], isTrue);
    });
  });
}
