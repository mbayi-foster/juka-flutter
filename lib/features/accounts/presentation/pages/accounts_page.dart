import 'package:flutter/material.dart';
import 'package:juka/shared/widget/coming_soon_view.dart';

/// Onglet Comptes : liste des comptes bancaires et des soldes.
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comptes')),
      body: const ComingSoonView(
        icon: Icons.account_balance_rounded,
        title: 'Vos comptes arrivent bientôt',
        description:
            'Vous pourrez ajouter vos comptes courants, livrets et cartes '
            'pour suivre chaque solde au même endroit.',
      ),
    );
  }
}
