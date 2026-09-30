import 'package:flutter/material.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/shared/widget/app_back_button.dart';

/// Structure commune à tous les écrans d'authentification :
/// fond de page, zone sûre, marges et défilement.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.children,
    this.showBackButton = false,
    this.centered = false,
    this.fallbackLocation = '/login',
  });

  /// Contenu de l'écran, empilé verticalement.
  final List<Widget> children;

  /// Affiche une flèche de retour dans l'AppBar.
  final bool showBackButton;

  /// Centre verticalement le contenu (écrans courts).
  final bool centered;

  /// Destination du retour lorsque la pile est vide.
  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBackButton
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: AppBackButton(fallbackLocation: fallbackLocation),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = centered && constraints.hasBoundedHeight
                ? constraints.maxHeight
                : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSize.pagePadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: centered
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: children,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
