// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juka/shared/app.dart';

void main() {
  testWidgets('L\'application s\'ouvre sur le tableau de bord', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // « Tableau de bord » apparaît dans l'en-tête et dans la barre du bas.
    expect(find.text('Tableau de bord'), findsNWidgets(2));
    expect(find.text('Patrimoine net'), findsOneWidget);

    // Les quatre onglets de la barre de navigation.
    expect(find.text('Comptes'), findsOneWidget);
    expect(find.text('Opérations'), findsOneWidget);
    expect(find.text('Paramètres'), findsOneWidget);
  });
}
