import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Champ de saisie standard de l'application.
///
/// Le label flotte au-dessus du champ dès que celui-ci devient utilisable
/// (focus / rempli) grâce à [FloatingLabelBehavior.auto].
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText,
    this.helperText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.isPassword = false,
    this.enabled = true,
    this.autofocus = false,
    this.autofillHints,
    this.inputFormatters,
    this.prefixIcon,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
    this.floatingLabelBehavior = FloatingLabelBehavior.auto,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.textAlign = TextAlign.start,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? helperText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  /// Affiche un bouton pour révéler/masquer la saisie.
  final bool isPassword;
  final bool enabled;

  /// Place le curseur dans le champ dès l'affichage de l'écran.
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FloatingLabelBehavior floatingLabelBehavior;
  final AutovalidateMode autovalidateMode;
  final TextAlign textAlign;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText = widget.isPassword;

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isPassword && _obscureText) {
      _obscureText = false;
    }
  }

  void _toggleObscureText() => setState(() => _obscureText = !_obscureText);

  @override
  Widget build(BuildContext context) {
    final hasController = widget.controller != null;

    return TextFormField(
      controller: widget.controller,
      initialValue: hasController ? null : widget.initialValue,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      textAlign: widget.textAlign,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      autovalidateMode: widget.autovalidateMode,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        helperText: widget.helperText,
        helperMaxLines: 2,
        prefixIcon: widget.prefixIcon,
        floatingLabelBehavior: widget.floatingLabelBehavior,
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: _toggleObscureText,
                tooltip: _obscureText
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}
