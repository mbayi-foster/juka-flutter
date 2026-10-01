import 'package:juka/features/reports/domain/entities/category_breakdown.dart';
import 'package:juka/features/reports/domain/enums/trend_direction.dart';

/// Dépenses d'un mois et leur moyenne mobile sur trois mois.
class TrendPoint {
  const TrendPoint({
    required this.month,
    required this.amount,
    required this.movingAverage,
  });

  /// Premier jour du mois.
  final DateTime month;

  /// Dépenses du mois.
  final double amount;

  /// Moyenne des trois mois qui se terminent à [month] : elle lisse les mois
  /// exceptionnels et fait ressortir la tendance de fond.
  final double movingAverage;
}

/// Tendance de fond des dépenses, déduite des derniers mois.
class TrendAnalysis {
  const TrendAnalysis({
    required this.points,
    required this.movers,
    required this.direction,
    required this.averageRecent,
    required this.averagePrevious,
  });

  /// Derniers mois observés, du plus ancien au plus récent.
  final List<TrendPoint> points;

  /// Catégories ayant le plus varié par rapport à la période précédente.
  final List<CategoryBreakdown> movers;

  final TrendDirection direction;

  /// Moyenne mensuelle des trois derniers mois.
  final double averageRecent;

  /// Moyenne mensuelle des trois mois précédents.
  final double averagePrevious;

  /// Écart relatif entre les deux moyennes ; `null` sans base de comparaison.
  double? get changeRatio => averagePrevious.abs() < 0.005
      ? null
      : (averageRecent - averagePrevious) / averagePrevious.abs();

  /// `true` dès qu'un des mois observés contient des dépenses.
  bool get hasData => points.any((point) => point.amount != 0);
}
