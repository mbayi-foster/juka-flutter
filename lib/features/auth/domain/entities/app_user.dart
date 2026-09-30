/// Utilisateur authentifié, tel qu'exposé au reste de l'application.
///
/// Cette entité est indépendante de la couche de données : elle ne connaît
/// ni JSON ni API.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.emailVerified = false,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;

  /// `true` lorsque l'adresse e-mail a été confirmée.
  final bool emailVerified;

  /// Nom complet, ou l'adresse e-mail si aucun nom n'est renseigné.
  String get displayName {
    final fullName = [
      firstName,
      lastName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ').trim();
    return fullName.isEmpty ? email : fullName;
  }

  @override
  String toString() =>
      'AppUser(id: $id, email: $email, displayName: $displayName)';
}
