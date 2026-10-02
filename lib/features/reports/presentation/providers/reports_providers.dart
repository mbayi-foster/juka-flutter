import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:juka/features/categories/presentation/providers/categories_providers.dart';
import 'package:juka/features/currencies/presentation/providers/currencies_providers.dart';
import 'package:juka/features/operations/presentation/providers/operations_providers.dart';
import 'package:juka/features/reports/data/exporters/report_file_exporter.dart';
import 'package:juka/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:juka/features/reports/domain/entities/exported_report.dart';
import 'package:juka/features/reports/domain/entities/report_period.dart';
import 'package:juka/features/reports/domain/enums/report_export_format.dart';
import 'package:juka/features/reports/domain/enums/report_period_preset.dart';
import 'package:juka/features/reports/domain/failures/reports_failure.dart';
import 'package:juka/features/reports/domain/repositories/reports_repository.dart';
import 'package:juka/features/reports/domain/services/report_exporter.dart';
import 'package:juka/features/reports/domain/usecases/export_expense_report_usecase.dart';
import 'package:juka/features/reports/domain/usecases/get_expense_report_usecase.dart';
import 'package:juka/features/reports/presentation/state/reports_state.dart';

// ---------------------------------------------------------------------------
// Injection des dépendances (data -> domain)
// ---------------------------------------------------------------------------

/// Les rapports agrègent les données des autres modules : ils n'ont pas de
/// stockage propre.
final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(
    accountsRepository: ref.watch(accountsRepositoryProvider),
    operationsRepository: ref.watch(operationsRepositoryProvider),
    categoriesRepository: ref.watch(categoriesRepositoryProvider),
    // Sans devise de référence, `null` : le rapport reste sur une devise.
    converter: ref.watch(currencyConverterProvider),
  ),
);

/// Écrit les exports sur l'appareil (PDF, Excel / CSV).
final reportExporterProvider = Provider<ReportExporter>(
  (ref) => const ReportFileExporter(),
);

final getExpenseReportUseCaseProvider = Provider<GetExpenseReportUseCase>(
  (ref) => GetExpenseReportUseCase(ref.watch(reportsRepositoryProvider)),
);

final exportExpenseReportUseCaseProvider = Provider<ExportExpenseReportUseCase>(
  (ref) => ExportExpenseReportUseCase(ref.watch(reportExporterProvider)),
);

// ---------------------------------------------------------------------------
// Contrôleur
// ---------------------------------------------------------------------------

/// Calcule le rapport de la période et du compte sélectionnés.
final reportsControllerProvider =
    NotifierProvider<ReportsController, ReportsState>(ReportsController.new);

class ReportsController extends Notifier<ReportsState> {
  @override
  ReportsState build() {
    // La devise de référence et ses taux arrivent après le premier rendu : on
    // recalcule alors le rapport avec les montants convertis.
    ref.listen(currencyConverterProvider, (previous, next) {
      if (previous != next) load();
    });
    return const ReportsState();
  }

  /// Charge le rapport en conservant les filtres déjà choisis.
  ///
  /// [period] est la période à analyser (nécessaire pour une période
  /// personnalisée) ; à défaut elle est recalculée depuis [preset]. Pour le
  /// compte, `accountId: null` ne change rien : c'est `clearAccount` qui
  /// revient à « tous les comptes ». [currency] force la devise analysée ;
  /// `clearCurrency` revient à « la devise la plus active ».
  Future<void> load({
    ReportPeriodPreset? preset,
    ReportPeriod? period,
    String? accountId,
    bool clearAccount = false,
    AppCurrency? currency,
    bool clearCurrency = false,
  }) async {
    final nextPreset = preset ?? state.preset;
    final nextPeriod =
        period ??
        (preset == null ? state.displayedPeriod : null) ??
        nextPreset.resolve(DateTime.now());

    state = ReportsState(
      status: ReportsStatus.loading,
      preset: nextPreset,
      period: nextPeriod,
      accountId: clearAccount ? null : (accountId ?? state.accountId),
      selectedCurrency: clearCurrency
          ? null
          : (currency ?? state.selectedCurrency),
      // Le rapport précédent reste affiché pendant le recalcul.
      report: state.report,
    );

    await _reload();
  }

  /// Applique une période prédéfinie (ce mois-ci, 6 mois, cette année…).
  Future<void> selectPreset(ReportPeriodPreset preset) =>
      load(preset: preset, period: preset.resolve(DateTime.now()));

  /// Applique une période choisie dans le calendrier.
  Future<void> selectRange(DateTime start, DateTime end) => load(
    preset: ReportPeriodPreset.custom,
    period: ReportPeriod(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
      preset: ReportPeriodPreset.custom,
    ),
  );

  /// Analyse un seul compte (`null` = tous les comptes).
  Future<void> selectAccount(String? accountId) =>
      load(accountId: accountId, clearAccount: accountId == null);

  /// Change la devise analysée.
  ///
  /// Le compte observé est réinitialisé : les comptes d'une autre devise
  /// seraient exclus du nouveau périmètre et le rapport paraîtrait vide.
  Future<void> selectCurrency(AppCurrency currency) =>
      load(currency: currency, clearAccount: true);

  /// Exporte le rapport affiché.
  ///
  /// Retourne le fichier écrit, ou `null` en cas d'échec : le message est
  /// alors disponible dans [ReportsState.exportErrorMessage].
  Future<ExportedReport?> export(ReportExportFormat format) async {
    final report = state.report;
    if (report == null) return null;

    state = state.copyWith(isExporting: true, clearExportError: true);

    try {
      final exported = await ref.read(exportExpenseReportUseCaseProvider)(
        report: report,
        format: format,
      );
      state = state.copyWith(isExporting: false);
      return exported;
    } on ReportsFailure catch (failure) {
      state = state.copyWith(
        isExporting: false,
        exportErrorMessage: failure.message,
      );
      return null;
    }
  }

  Future<void> _reload() async {
    final period = state.displayedPeriod;
    if (period == null) return;

    try {
      final report = await ref.read(getExpenseReportUseCaseProvider)(
        period: period,
        accountId: state.accountId,
        currency: state.selectedCurrency,
      );

      state = ReportsState(
        status: report.isEmpty ? ReportsStatus.empty : ReportsStatus.ready,
        preset: state.preset,
        period: period,
        accountId: state.accountId,
        selectedCurrency: state.selectedCurrency,
        report: report,
      );
    } on ReportsFailure catch (failure) {
      state = ReportsState(
        status: ReportsStatus.failure,
        preset: state.preset,
        period: period,
        accountId: state.accountId,
        selectedCurrency: state.selectedCurrency,
        report: state.report,
        errorMessage: failure.message,
      );
    }
  }
}
