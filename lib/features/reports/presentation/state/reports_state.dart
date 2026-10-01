import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/report_period.dart';
import 'package:juka/features/reports/domain/enums/report_period_preset.dart';

/// État de l'écran « Rapports et analyses ».
enum ReportsStatus { loading, ready, empty, failure }

/// État exposé par `reportsControllerProvider`.
class ReportsState {
  const ReportsState({
    this.status = ReportsStatus.loading,
    this.preset = ReportPeriodPreset.thisMonth,
    this.report,
    this.period,
    this.accountId,
    this.errorMessage,
    this.isExporting = false,
    this.exportErrorMessage,
  });

  final ReportsStatus status;

  /// Période prédéfinie sélectionnée par l'utilisateur.
  final ReportPeriodPreset preset;

  /// Rapport calculé, `null` tant qu'aucun calcul n'a abouti.
  final ExpenseReport? report;

  /// Période analysée, résolue depuis [preset] ou choisie dans le calendrier.
  final ReportPeriod? period;

  /// Compte observé, `null` pour tous les comptes.
  final String? accountId;

  final String? errorMessage;

  /// Un export est en cours (le bouton affiche alors un indicateur).
  final bool isExporting;

  /// Dernier échec d'export, `null` si le dernier export a réussi.
  final String? exportErrorMessage;

  bool get isLoading => status == ReportsStatus.loading;

  bool get hasFailed => status == ReportsStatus.failure;

  /// Aucune opération sur la période : l'écran invite à en saisir une.
  bool get isEmpty => status == ReportsStatus.empty;

  /// Période affichée : celle en cours de chargement, sinon celle du rapport.
  ReportPeriod? get displayedPeriod => period ?? report?.period;

  AppCurrency? get currency => report?.currency;

  ReportsState copyWith({
    ReportsStatus? status,
    ReportPeriodPreset? preset,
    ExpenseReport? report,
    ReportPeriod? period,
    String? accountId,
    String? errorMessage,
    bool? isExporting,
    String? exportErrorMessage,
    bool clearExportError = false,
  }) {
    return ReportsState(
      status: status ?? this.status,
      preset: preset ?? this.preset,
      report: report ?? this.report,
      period: period ?? this.period,
      accountId: accountId ?? this.accountId,
      errorMessage: errorMessage ?? this.errorMessage,
      isExporting: isExporting ?? this.isExporting,
      exportErrorMessage: clearExportError
          ? null
          : (exportErrorMessage ?? this.exportErrorMessage),
    );
  }
}
