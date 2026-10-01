import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/wealth/data/exceptions/wealth_exception.dart';
import 'package:juka/features/wealth/domain/entities/net_worth_snapshot.dart';
import 'package:juka/features/wealth/domain/failures/wealth_failure.dart';
import 'package:juka/features/wealth/domain/repositories/wealth_repository.dart';

/// Implémentation du contrat [WealthRepository] au-dessus de la source locale.
///
/// Elle traduit les [WealthException] techniques en [WealthFailure] métier.
class WealthRepositoryImpl implements WealthRepository {
  const WealthRepositoryImpl(this._localDataSource);

  final WealthRepository _localDataSource;

  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  Future<List<NetWorthSnapshot>> fetchSnapshots({
    required AppCurrency currency,
    int? limit,
  }) => _guard(
    () => _localDataSource.fetchSnapshots(currency: currency, limit: limit),
  );

  @override
  Future<NetWorthSnapshot> saveSnapshot(NetWorthSnapshot snapshot) =>
      _guard(() => _localDataSource.saveSnapshot(snapshot));

  @override
  Future<void> clearSnapshots(AppCurrency currency) =>
      _guard(() => _localDataSource.clearSnapshots(currency));

  /// Exécute [action] et convertit les erreurs techniques en [WealthFailure].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on WealthFailure {
      rethrow;
    } on WealthException catch (exception) {
      throw WealthFailure(exception.message);
    } catch (_) {
      throw const WealthFailure(_unexpectedMessage);
    }
  }
}
