import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Sécurisation du code PIN local.
///
/// Le code n'est jamais stocké en clair : on conserve un **sel** aléatoire et
/// l'empreinte SHA-256 de `sel:code`. Un code à 4 à 6 chiffres reste facile à
/// deviner hors ligne ; cette protection évite simplement de l'écrire en clair
/// dans la base du téléphone.
abstract final class PinHasher {
  /// Longueur minimale acceptée pour un code PIN.
  static const int minLength = 4;

  /// Longueur maximale acceptée pour un code PIN.
  static const int maxLength = 6;

  /// Longueur du sel, en octets.
  static const int saltLengthBytes = 16;

  static final RegExp _digits = RegExp(r'^\d{4,6}$');

  /// Sel aléatoire, encodé en hexadécimal.
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      saltLengthBytes,
      (_) => random.nextInt(256),
    );
    return bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Empreinte de [pin] pour un [salt] donné.
  static String hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  /// Le code PIN est-il valide (4 à 6 chiffres) ?
  static bool isValid(String pin) => _digits.hasMatch(pin);

  /// Le code saisi correspond-il à l'empreinte enregistrée ?
  static bool matches({
    required String pin,
    required String salt,
    required String expectedHash,
  }) => hash(pin, salt) == expectedHash;
}
