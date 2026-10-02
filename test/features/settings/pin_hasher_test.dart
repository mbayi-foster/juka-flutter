import 'package:flutter_test/flutter_test.dart';
import 'package:juka/features/settings/domain/services/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('accepte 4 à 6 chiffres et refuse le reste', () {
      expect(PinHasher.isValid('1234'), isTrue);
      expect(PinHasher.isValid('123456'), isTrue);
      expect(PinHasher.isValid('123'), isFalse);
      expect(PinHasher.isValid('1234567'), isFalse);
      expect(PinHasher.isValid('12a4'), isFalse);
      expect(PinHasher.isValid(''), isFalse);
    });

    test('le sel est aléatoire et encodé en hexadécimal', () {
      final first = PinHasher.generateSalt();
      final second = PinHasher.generateSalt();

      expect(first, hasLength(PinHasher.saltLengthBytes * 2));
      expect(first, matches(RegExp(r'^[0-9a-f]+$')));
      expect(first, isNot(second));
    });

    test('une empreinte dépend du code et du sel', () {
      const salt = 'a1b2';

      expect(PinHasher.hash('1234', salt), isNot(PinHasher.hash('1235', salt)));
      expect(PinHasher.hash('1234', salt), isNot(PinHasher.hash('1234', 'c3d4')));
      expect(PinHasher.hash('1234', salt), PinHasher.hash('1234', salt));
    });

    test('vérifie un code saisi', () {
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hash('4321', salt);

      expect(
        PinHasher.matches(pin: '4321', salt: salt, expectedHash: hash),
        isTrue,
      );
      expect(
        PinHasher.matches(pin: '0000', salt: salt, expectedHash: hash),
        isFalse,
      );
    });

    test('le code n\'apparaît jamais en clair dans l\'empreinte', () {
      final salt = PinHasher.generateSalt();
      expect(PinHasher.hash('1234', salt), isNot(contains('1234')));
    });
  });
}
