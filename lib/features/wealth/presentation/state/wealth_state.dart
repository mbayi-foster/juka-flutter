import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/wealth/domain/entities/wealth_overview.dart';

/// État de l'écran « Patrimoine et progression ».
enum WealthStatus { loading, ready, empty, failure }

/// État exposé par `wealthControllerProvider`.
class WealthState {
  const WealthState({
    this.status = WealthStatus.loading,
    this.overview,
    this.currency,
    this.errorMessage,
  });

  final WealthStatus status;

  /// Données affichées, `null` tant qu'aucun calcul n'a abouti.
  final WealthOverview? overview;

  /// Devise demandée par l'utilisateur ; `null` = devise principale.
  final AppCurrency? currency;

  final String? errorMessage;

  bool get isLoading => status == WealthStatus.loading;

  bool get hasFailed => status == WealthStatus.failure;

  /// Aucun compte n'existe encore : l'écran invite à en créer un.
  bool get isEmpty => status == WealthStatus.empty;

  /// Devise effectivement affichée.
  AppCurrency? get displayedCurrency => overview?.currency ?? currency;

  WealthState copyWith({
    WealthStatus? status,
    WealthOverview? overview,
    AppCurrency? currency,
    String? errorMessage,
  }) {
    return WealthState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      currency: currency ?? this.currency,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
