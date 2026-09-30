import 'package:flutter/material.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/shared/widget/padding.dart';

/// Bouton d'authentification via un fournisseur externe (Google, Apple, ...).
class AppSocialButton extends StatelessWidget {
  const AppSocialButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Logo du fournisseur (ex : [GoogleLogo]).
  final Widget? leading;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final logo = leading;
    return SizedBox(
      width: double.infinity,
      height: AppSize.buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (logo != null) ...[logo, 12.pw],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
