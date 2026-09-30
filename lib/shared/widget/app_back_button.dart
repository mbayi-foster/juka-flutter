import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Flèche de retour compatible avec `go_router` : dépile la pile si possible,
/// sinon redirige vers [fallbackLocation] (cas d'un lien profond).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.fallbackLocation = '/'});

  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Retour',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackLocation);
        }
      },
    );
  }
}
