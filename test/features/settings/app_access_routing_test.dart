import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juka/features/settings/domain/entities/local_profile.dart';
import 'package:juka/features/settings/domain/entities/settings_snapshot.dart';
import 'package:juka/features/settings/domain/services/pin_hasher.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/shared/app.dart';

import '../../support/dashboard_fakes.dart';
import '../../support/settings_fakes.dart';

/// Lance l'application entière sur un profil donné, sans base de données.
Widget _app(SettingsSnapshot snapshot) => ProviderScope(
  overrides: [
    settingsRepositoryProvider.overrideWith(
      (ref) => FakeSettingsRepository(snapshot: snapshot),
    ),
    ...dashboardTestOverrides,
  ],
  child: const MyApp(),
);

void main() {
  testWidgets('La première ouverture affiche l\'accueil', (tester) async {
    await tester.pumpWidget(_app(const SettingsSnapshot()));
    await tester.pumpAndSettle();

    // La redirection du routeur mène à l'accueil, pas au tableau de bord.
    expect(find.text('Bienvenue sur Juka'), findsOneWidget);
    expect(find.text('Tableau de bord'), findsNothing);
  });

  testWidgets('Un code PIN actif verrouille l\'application', (tester) async {
    const salt = 'sel-de-test';

    await tester.pumpWidget(
      _app(
        SettingsSnapshot(
          profile: LocalProfile(
            name: 'Test',
            pinEnabled: true,
            pinSalt: salt,
            pinHash: PinHasher.hash('1234', salt),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Déverrouiller'), findsOneWidget);
    expect(find.text('Tableau de bord'), findsNothing);

    await tester.enterText(find.byType(TextFormField), '1234');
    await tester.tap(find.text('Déverrouiller'));
    await tester.pumpAndSettle();

    // Le déverrouillage lève la redirection vers l'écran de verrouillage.
    expect(find.text('Tableau de bord'), findsOneWidget);
  });
}
