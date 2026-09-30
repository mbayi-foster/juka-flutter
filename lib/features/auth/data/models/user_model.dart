import 'package:juka/features/auth/domain/entities/app_user.dart';

/// Représentation « transport » de l'utilisateur (JSON de l'API).
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.emailVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      emailVerified:
          json['emailVerifiedAt'] != null || json['emailVerified'] == true,
    );
  }

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool emailVerified;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'emailVerified': emailVerified,
  };

  /// Convertit le modèle en entité du domaine.
  AppUser toEntity() => AppUser(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    emailVerified: emailVerified,
  );
}
