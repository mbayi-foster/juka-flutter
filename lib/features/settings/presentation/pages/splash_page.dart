import 'package:flutter/material.dart';
import 'package:juka/shared/widget/loading_view.dart';

/// Écran affiché le temps de lire les réglages et le profil locaux.
///
/// C'est une route comme les autres : l'application ne montre son contenu
/// qu'une fois les préférences chargées.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoadingView(message: 'Préparation de vos données…'),
    );
  }
}
