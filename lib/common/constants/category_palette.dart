/// Palette de couleurs proposée pour les catégories.
///
/// Les valeurs sont des entiers ARGB afin que le domaine et la couche de
/// données restent indépendants de Flutter.
abstract final class CategoryPalette {
  static const int violet = 0xFF6C63FF;
  static const int green = 0xFF2E7D32;
  static const int blue = 0xFF0288D1;
  static const int orange = 0xFFEB8A3E;
  static const int pink = 0xFFEC407A;
  static const int teal = 0xFF26A69A;
  static const int brown = 0xFF8D6E63;
  static const int purple = 0xFF7E57C2;
  static const int amber = 0xFFF5B301;
  static const int red = 0xFFE53935;
  static const int indigo = 0xFF3F51B5;
  static const int grey = 0xFF8A8A8A;

  /// Toutes les couleurs, dans l'ordre proposé par le sélecteur.
  static const List<int> all = [
    violet,
    green,
    blue,
    orange,
    pink,
    teal,
    brown,
    purple,
    amber,
    red,
    indigo,
    grey,
  ];
}
