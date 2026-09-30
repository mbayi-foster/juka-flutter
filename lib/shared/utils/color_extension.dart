import 'dart:ui';

/// Ajustements de couleur liés au thème.
extension ColorReadability on Color {
  /// Éclaircit la couleur sur fond sombre afin de préserver le contraste.
  ///
  /// Sur fond clair, la couleur est renvoyée telle quelle.
  Color forBrightness(Brightness brightness) => brightness == Brightness.dark
      ? Color.lerp(this, const Color(0xFFFFFFFF), 0.35)!
      : this;
}
