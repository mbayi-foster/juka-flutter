// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juka/shared/app.dart';

import 'support/dashboard_fakes.dart';

void main() {
  testWidgets('L\'application s\'ouvre sur le tableau de bord', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: dashboardTestOverrides, child: const MyApp()),
    );
    await tester.pumpAndSettle();

    // En-tête du tableau de bord…
    expect(find.text('Tableau de bord'), findsOneWidget);
    expect(find.text('Patrimoine net'), findsOneWidget);

    // …et les quatre onglets de la barre de navigation.
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Comptes'), findsOneWidget);
    expect(find.text('Opérations'), findsOneWidget);
    expect(find.text('Paramètres'), findsOneWidget);
  });
}
