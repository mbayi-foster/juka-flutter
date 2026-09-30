import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/enums/transaction_category.dart';

/// Identité visuelle (icône + couleur) de chaque [TransactionCategory].
///
/// Centraliser ces correspondances évite de dupliquer des `switch` dans chaque
/// écran (tableau de bord, opérations, comptes…).
abstract final class CategoryVisuals {
  static IconData iconOf(TransactionCategory category) => switch (category) {
    TransactionCategory.housing => Icons.home_rounded,
    TransactionCategory.food => Icons.shopping_basket_rounded,
    TransactionCategory.transport => Icons.directions_car_rounded,
    TransactionCategory.restaurants => Icons.restaurant_rounded,
    TransactionCategory.leisure => Icons.sports_esports_rounded,
    TransactionCategory.health => Icons.favorite_rounded,
    TransactionCategory.shopping => Icons.shopping_bag_rounded,
    TransactionCategory.subscriptions => Icons.subscriptions_rounded,
    TransactionCategory.salary => Icons.payments_rounded,
    TransactionCategory.savings => Icons.savings_rounded,
    TransactionCategory.other => Icons.category_rounded,
  };

  static Color colorOf(TransactionCategory category) => switch (category) {
    TransactionCategory.housing => AppColors.categoryHousing,
    TransactionCategory.food => AppColors.categoryFood,
    TransactionCategory.transport => AppColors.categoryTransport,
    TransactionCategory.restaurants => AppColors.categoryRestaurants,
    TransactionCategory.leisure => AppColors.categoryLeisure,
    TransactionCategory.health => AppColors.categoryHealth,
    TransactionCategory.shopping => AppColors.categoryShopping,
    TransactionCategory.subscriptions => AppColors.categorySubscriptions,
    TransactionCategory.salary => AppColors.categoryIncome,
    TransactionCategory.savings => AppColors.categorySavings,
    TransactionCategory.other => AppColors.categoryOther,
  };
}
