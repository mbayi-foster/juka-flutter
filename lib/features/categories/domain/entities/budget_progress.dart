import 'package:juka/features/categories/domain/entities/budget.dart';
import 'package:juka/features/categories/domain/entities/category.dart';

/// Niveau d'alerte d'un budget mensuel.
enum BudgetAlert {
  /// Moins de 80 % de l'enveloppe consommée.
  none,

  /// À partir de 80 % consommés.
  warning,

  /// Enveloppe dépassée.
  exceeded,
}

/// Avancement d'un budget mensuel : prévu contre réel.
class BudgetProgress {
  const BudgetProgress({
    required this.category,
    required this.budget,
    required this.carriedOver,
    required this.spent,
  });

  /// Seuil à partir duquel l'utilisateur est averti.
  static const double warningThreshold = 0.8;

  final Category category;
  final Budget budget;

  /// Reste du mois précédent ajouté à l'enveloppe (0 si le report est
  /// désactivé pour cette catégorie).
  final double carriedOver;

  /// Dépenses réelles du mois, sous-catégories comprises.
  final double spent;

  /// Enveloppe disponible pour le mois : budget mensuel + report.
  double get planned => budget.monthlyLimit + carriedOver;

  /// Reste disponible ; négatif en cas de dépassement.
  double get remaining => planned - spent;

  /// Part consommée de l'enveloppe (`1.05` = 105 %).
  double get ratio => planned <= 0 ? 0 : spent / planned;

  bool get isExceeded => spent > planned;

  bool get isAtWarning =>
      !isExceeded && planned > 0 && ratio >= warningThreshold;

  double get percentage => ratio * 100;

  BudgetAlert get alert {
    if (isExceeded) return BudgetAlert.exceeded;
    if (isAtWarning) return BudgetAlert.warning;
    return BudgetAlert.none;
  }
}
