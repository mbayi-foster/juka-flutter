import 'package:juka/shared/utils/money_formatter.dart';

/// Validateurs de formulaires réutilisables dans toute l'application.
///
/// Chaque méthode retourne `null` lorsque la valeur est valide, sinon le
/// message d'erreur à afficher sous le champ.
abstract final class AppValidators {
  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Longueur minimale d'un mot de passe accepté par l'application.
  static const int minPasswordLength = 8;

  static String? required(String? value, {String label = 'Ce champ'}) {
    if ((value ?? '').trim().isEmpty) {
      return '$label est obligatoire';
    }
    return null;
  }

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'L\'adresse e-mail est obligatoire';
    }
    if (!_emailRegExp.hasMatch(input)) {
      return 'Veuillez saisir une adresse e-mail valide';
    }
    return null;
  }

  static String? personName(String? value, {String label = 'Ce champ'}) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return '$label est obligatoire';
    }
    if (input.length < 2) {
      return '$label est trop court';
    }
    return null;
  }

  static String? password(String? value, {int minLength = minPasswordLength}) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    if (input.length < minLength) {
      return 'Au moins $minLength caractères';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  /// Vérifie qu'une saisie est un montant exploitable (`-1 200,50`, `50000`…).
  static String? amount(String? value, {String label = 'Le montant'}) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return '$label est obligatoire';
    }
    if (MoneyFormatter.tryParse(input) == null) {
      return 'Saisissez un montant valide';
    }
    return null;
  }
}
