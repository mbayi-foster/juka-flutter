/// Profil local de l'utilisateur : son nom et, s'il le souhaite, un code PIN.
///
/// Le code PIN n'est jamais conservé en clair : seuls le sel et l'empreinte
/// ([pinHash]) sont enregistrés sur le téléphone (voir `PinHasher`).
class LocalProfile {
  const LocalProfile({
    this.name = '',
    this.pinEnabled = false,
    this.pinHash,
    this.pinSalt,
  });

  /// Nom affiché dans l'application (ex. « Mayisha »).
  final String name;

  /// `true` lorsque l'utilisateur a activé le verrouillage par code PIN.
  final bool pinEnabled;

  /// Empreinte du code PIN, `null` si aucun n'est défini.
  final String? pinHash;

  /// Sel utilisé pour l'empreinte, `null` si aucun code PIN n'est défini.
  final String? pinSalt;

  /// `true` lorsque le nom a été renseigné : l'accueil peut s'afficher.
  bool get isOnboarded => name.trim().isNotEmpty;

  /// `true` lorsque l'empreinte est exploitable.
  bool get hasPin => pinEnabled && pinHash != null && pinSalt != null;

  LocalProfile copyWith({
    String? name,
    bool? pinEnabled,
    String? pinHash,
    String? pinSalt,
    bool clearPin = false,
  }) {
    return LocalProfile(
      name: name ?? this.name,
      pinEnabled: clearPin ? false : (pinEnabled ?? this.pinEnabled),
      pinHash: clearPin ? null : (pinHash ?? this.pinHash),
      pinSalt: clearPin ? null : (pinSalt ?? this.pinSalt),
    );
  }
}
