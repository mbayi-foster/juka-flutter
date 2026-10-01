import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/enums/transaction_category.dart';

/// Identité visuelle des catégories.
///
/// Deux usages cohabitent le temps de la migration vers les catégories
/// personnalisables :
///
/// * le catalogue [icons], utilisé par les catégories stockées en base (leur
///   `iconKey` référence une clé de ce catalogue) ;
/// * les correspondances historiques basées sur [TransactionCategory].
abstract final class CategoryVisuals {
  /// Icônes proposées lors de la création d'une catégorie.
  static const Map<String, IconData> icons = {
    'cart': Icons.shopping_cart_rounded,
    'basket': Icons.shopping_basket_rounded,
    'home': Icons.home_rounded,
    'car': Icons.directions_car_rounded,
    'restaurant': Icons.restaurant_rounded,
    'game': Icons.sports_esports_rounded,
    'health': Icons.favorite_rounded,
    'bag': Icons.shopping_bag_rounded,
    'subscription': Icons.subscriptions_rounded,
    'salary': Icons.payments_rounded,
    'savings': Icons.savings_rounded,
    'transfer': Icons.swap_horiz_rounded,
    'school': Icons.school_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'pet': Icons.pets_rounded,
    'gift': Icons.card_giftcard_rounded,
    'phone': Icons.smartphone_rounded,
    'bank': Icons.account_balance_rounded,
    'tools': Icons.handyman_rounded,
    'child': Icons.child_care_rounded,
    'coffee': Icons.local_cafe_rounded,
    'sport': Icons.fitness_center_rounded,
    'other': Icons.category_rounded,
  };

  /// Clé d'icône utilisée par défaut.
  static const String defaultIconKey = 'other';

  /// Icône correspondant à une clé du catalogue.
  static IconData iconOfKey(String? iconKey) =>
      icons[iconKey] ?? Icons.category_rounded;

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
    TransactionCategory.transfer => Icons.swap_horiz_rounded,
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
    TransactionCategory.transfer => AppColors.info,
    TransactionCategory.other => AppColors.categoryOther,
  };
}
