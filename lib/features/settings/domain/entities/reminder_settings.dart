/// Rappels configurés par l'utilisateur.
///
/// Première version : les préférences sont **enregistrées localement** mais
/// aucune notification système n'est encore programmée. Les écrans peuvent donc
/// annoncer le réglage choisi sans dépendre d'un service natif.
class ReminderSettings {
  const ReminderSettings({
    this.dailyEnabled = false,
    this.dailyMinute = 20 * 60,
    this.weeklyEnabled = false,
    this.weeklyWeekday = DateTime.monday,
    this.weeklyMinute = 19 * 60,
    this.monthlyEnabled = false,
    this.monthlyDay = 1,
    this.monthlyMinute = 9 * 60,
  });

  /// Saisie quotidienne : rappel chaque jour à [dailyMinute].
  final bool dailyEnabled;
  final int dailyMinute;

  /// Point hebdomadaire : rappel le [weeklyWeekday] à [weeklyMinute].
  final bool weeklyEnabled;
  final int weeklyWeekday;
  final int weeklyMinute;

  /// Point mensuel : rappel le [monthlyDay] à [monthlyMinute].
  final bool monthlyEnabled;
  final int monthlyDay;
  final int monthlyMinute;

  bool get hasAnyEnabled => dailyEnabled || weeklyEnabled || monthlyEnabled;

  /// `20:00` — heure lisible d'un nombre de minutes depuis minuit.
  static String timeLabel(int minutesOfDay) {
    final hour = (minutesOfDay ~/ 60) % 24;
    final minute = minutesOfDay % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  /// `lundi`…`dimanche` pour [DateTime.monday]…`DateTime.sunday`.
  static String weekdayLabel(int weekday) => const [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ][(weekday - 1).clamp(0, 6)];

  ReminderSettings copyWith({
    bool? dailyEnabled,
    int? dailyMinute,
    bool? weeklyEnabled,
    int? weeklyWeekday,
    int? weeklyMinute,
    bool? monthlyEnabled,
    int? monthlyDay,
    int? monthlyMinute,
  }) {
    return ReminderSettings(
      dailyEnabled: dailyEnabled ?? this.dailyEnabled,
      dailyMinute: dailyMinute ?? this.dailyMinute,
      weeklyEnabled: weeklyEnabled ?? this.weeklyEnabled,
      weeklyWeekday: weeklyWeekday ?? this.weeklyWeekday,
      weeklyMinute: weeklyMinute ?? this.weeklyMinute,
      monthlyEnabled: monthlyEnabled ?? this.monthlyEnabled,
      monthlyDay: monthlyDay ?? this.monthlyDay,
      monthlyMinute: monthlyMinute ?? this.monthlyMinute,
    );
  }
}
