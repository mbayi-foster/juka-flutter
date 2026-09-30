import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juka/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:juka/features/auth/presentation/pages/login_page.dart';
import 'package:juka/features/auth/presentation/pages/register_page.dart';
import 'package:juka/shared/theme/app_theme.dart';

Widget _wrap(Widget page) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.light, home: page),
  );
}

void main() {
  testWidgets('La page de connexion affiche ses champs et l\'option Google', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Bon retour !'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
  });

  testWidgets('La page d\'inscription affiche ses champs et l\'option Google', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const RegisterPage()));
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsOneWidget);
    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(find.text('S\'inscrire avec Google'), findsOneWidget);
  });

  testWidgets('La page de réinitialisation affiche le champ e-mail', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const ForgotPasswordPage()));
    await tester.pumpAndSettle();

    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Envoyer le lien'), findsOneWidget);
  });

  testWidgets('La connexion refuse un formulaire vide', (tester) async {
    await tester.pumpWidget(_wrap(const LoginPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('L\'adresse e-mail est obligatoire'), findsOneWidget);
    expect(find.text('Le mot de passe est obligatoire'), findsOneWidget);
  });
}
