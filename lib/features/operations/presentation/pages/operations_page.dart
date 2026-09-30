import 'package:flutter/material.dart';
import 'package:juka/shared/widget/coming_soon_view.dart';

/// Onglet Opérations : historique complet des revenus et dépenses.
class OperationsPage extends StatelessWidget {
  const OperationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opérations')),
      body: const ComingSoonView(
        icon: Icons.swap_horiz_rounded,
        title: 'L\'historique arrive bientôt',
        description:
            'Toutes vos opérations seront listées ici, filtrables par période, '
            'compte et catégorie.',
      ),
    );
  }
}
