import 'package:juka/common/enums/transaction_category.dart';

/// Montant dépensé sur une catégorie pour la période courante.
class CategorySpending {
  const CategorySpending({required this.category, required this.amount});

  final TransactionCategory category;
  final double amount;
}
