import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/features/accounts/data/datasources/accounts_local_data_source.dart';
import 'package:juka/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:juka/features/accounts/presentation/pages/account_form_page.dart';
import 'package:juka/features/accounts/presentation/pages/accounts_page.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/theme/app_theme.dart';

/// Écran large : toutes les cartes de la page sont construites par la liste et
/// donc trouvables par les tests.
void _useLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// `sqflite` n'est pas disponible dans l'environnement de test : on injecte la
/// source en mémoire. C'est précisément l'intérêt de l'interface
/// [AccountsLocalDataSource] — permuter l'implémentation sans rien changer
/// d'autre.
ProviderContainer _createContainer() => ProviderContainer(
  overrides: [
    accountsLocalDataSourceProvider.overrideWith(
      (ref) => AccountsLocalDataSourceImpl(),
    ),
  ],
);

Widget _wrap(Widget page, [ProviderContainer? container]) {
  final scope = container ?? _createContainer();
  if (container == null) addTearDown(scope.dispose);

  return UncontrolledProviderScope(
    container: scope,
    child: MaterialApp(theme: AppTheme.light, home: page),
  );
}

/// Enveloppe munie d'un routeur, pour les écrans qui naviguent.
Widget _wrapRouted(Widget page, ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => page),
      GoRoute(
        path: AppRoutes.accounts,
        builder: (context, state) =>
            const Scaffold(body: Text('Liste des comptes')),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

Future<ProviderContainer> _loadedContainer(WidgetTester tester) async {
  final container = _createContainer();
  addTearDown(container.dispose);

  // La source en mémoire simule une latence : `runAsync` laisse le temps réel
  // s'écouler, faute de quoi l'attente ne se terminerait jamais dans le temps
  // simulé du test de widget.
  await tester.runAsync(
    () => container.read(accountsControllerProvider.notifier).load(),
  );
  return container;
}

void main() {
  testWidgets('La liste affiche les comptes, les totaux et les archives', (
    tester,
  ) async {
    _useLargeSurface(tester);
    await tester.pumpWidget(_wrap(const AccountsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Comptes'), findsOneWidget);
    expect(find.text('Là où se trouve votre argent.'), findsOneWidget);
    expect(find.text('Compte courant'), findsOneWidget);
    expect(find.text('3 450,80 €'), findsOneWidget);

    // Totaux par devise (les devises ne sont jamais additionnées entre elles).
    expect(find.text('Solde total'), findsOneWidget);
    expect(find.text('13 106,60 €'), findsOneWidget);
    // La seule devise XOF n'a qu'un compte : le total et le solde coïncident.
    expect(find.text('128 500 F CFA'), findsNWidgets(2));

    // Archivés regroupés à part.
    expect(find.text('Comptes actifs'), findsOneWidget);
    expect(find.text('Comptes archivés'), findsOneWidget);
    expect(find.text('Ancien compte'), findsOneWidget);
  });

  testWidgets('Le formulaire crée un compte avec sa devise et son solde', (
    tester,
  ) async {
    _useLargeSurface(tester);
    final container = await _loadedContainer(tester);
    final initialCount = container
        .read(accountsControllerProvider)
        .accounts
        .length;

    await tester.pumpWidget(_wrapRouted(const AccountFormPage(), container));
    await tester.pumpAndSettle();

    // Champs : 1) nom, 2) solde initial, 3) note.
    await tester.enterText(find.byType(TextFormField).at(0), 'Compte joint');
    await tester.enterText(find.byType(TextFormField).at(1), '1 500,50');
    await tester.tap(find.text('Créer le compte'));
    await tester.pumpAndSettle();

    final accounts = container.read(accountsControllerProvider).accounts;
    expect(accounts.length, initialCount + 1);

    final created = accounts.firstWhere(
      (account) => account.name == 'Compte joint',
    );
    expect(created.initialBalance, 1500.50);
    expect(created.currentBalance, 1500.50);

    // L'écran est refermé sur la liste.
    expect(find.text('Liste des comptes'), findsOneWidget);
  });

  testWidgets('Le formulaire refuse un nom trop court et un solde invalide', (
    tester,
  ) async {
    _useLargeSurface(tester);
    await tester.pumpWidget(_wrap(const AccountFormPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'A');
    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    await tester.tap(find.text('Créer le compte'));
    await tester.pumpAndSettle();

    expect(find.text('Le nom du compte est trop court'), findsOneWidget);
    expect(find.text('Saisissez un montant valide'), findsOneWidget);
  });

  testWidgets(
    'Le détail montre le solde, l\'historique et l\'écart de rapprochement',
    (tester) async {
      _useLargeSurface(tester);
      final container = await _loadedContainer(tester);
      final account = container
          .read(accountsControllerProvider)
          .accounts
          .firstWhere((item) => item.name == 'Espèces');

      await tester.pumpWidget(
        _wrap(AccountDetailPage(accountId: account.id), container),
      );
      await tester.pumpAndSettle();

      expect(find.text('Espèces'), findsWidgets);
      expect(find.text('Solde actuel'), findsOneWidget);
      expect(find.text('145,30 €'), findsWidgets);
      expect(find.text('Historique du solde'), findsOneWidget);
      expect(find.text('Sur 6 mois'), findsOneWidget);

      expect(find.text('Rapprochement'), findsOneWidget);
      expect(find.text('140,00 €'), findsOneWidget);
      expect(find.text('-5,30 €'), findsOneWidget);
      expect(find.text('Rapprocher le compte'), findsOneWidget);
    },
  );

  testWidgets('L\'archivage retire le compte des totaux', (tester) async {
    _useLargeSurface(tester);
    final container = await _loadedContainer(tester);
    final account = container
        .read(accountsControllerProvider)
        .accounts
        .firstWhere((item) => item.name == 'Espèces');

    // Comme le chargement, l'archivage attend la latence simulée : on laisse
    // le temps réel s'écouler.
    await tester.runAsync(
      () => container
          .read(accountsControllerProvider.notifier)
          .setArchived(id: account.id, isArchived: true),
    );

    final state = container.read(accountsControllerProvider);
    expect(state.activeAccounts.any((item) => item.id == account.id), isFalse);
    expect(state.archivedAccounts.any((item) => item.id == account.id), isTrue);
    expect(state.totalsByCurrency.values, isNot(contains(145.30)));
  });
}
