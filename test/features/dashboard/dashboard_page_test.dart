import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juka/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:juka/shared/theme/app_theme.dart';

import '../../support/dashboard_fakes.dart';

Widget _wrap(Widget page) => ProviderScope(
  overrides: dashboardTestOverrides,
  child: MaterialApp(theme: AppTheme.light, home: page),
);

/// Écran large, pour que toutes les sections du tableau de bord soient
/// construites par la `ListView` et donc trouvables par les tests.
Future<void> _pumpDashboard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_wrap(const DashboardPage()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Le tableau de bord affiche ses indicateurs clés', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(find.text('Tableau de bord'), findsOneWidget);
    expect(find.text('Patrimoine net'), findsOneWidget);
    expect(find.text('Ce mois-ci'), findsOneWidget);
    expect(find.text('Répartition des dépenses'), findsOneWidget);
    expect(find.text('Budgets consommés'), findsOneWidget);
    expect(find.text('Dernières opérations'), findsOneWidget);
    expect(find.text('Alertes'), findsOneWidget);
  });

  testWidgets('Le patrimoine net et son évolution sont formatés', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(find.text('24 850,00 €'), findsOneWidget);
    expect(find.text('+3,2 %'), findsOneWidget);
    expect(find.text('Il y a un mois : 24 070,00 €'), findsOneWidget);
  });

  testWidgets('Les flux du mois et la répartition sont affichés', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(find.text('Revenus'), findsOneWidget);
    expect(find.text('Dépenses'), findsOneWidget);
    expect(find.text('Épargne'), findsOneWidget);
    expect(find.text('Logement'), findsWidgets);
    expect(find.text('Alimentation'), findsWidgets);
  });

  testWidgets('Les alertes et dernières opérations sont listées', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(find.text('Budget Loisirs dépassé'), findsOneWidget);
    expect(find.text('Salaire'), findsOneWidget);
    expect(find.text('+3 200,00 €'), findsOneWidget);
  });
}
