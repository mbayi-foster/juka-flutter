import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/settings/domain/entities/reminder_settings.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';
import 'package:juka/shared/widget/padding.dart';

/// Rappels de saisie : quotidien, hebdomadaire et mensuel.
///
/// Première version : les préférences sont conservées sur le téléphone. La
/// programmation de notifications système viendra ensuite.
class RemindersPage extends ConsumerWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref
        .watch(settingsControllerProvider)
        .preferences
        .reminders;
    final controller = ref.read(settingsControllerProvider.notifier);

    void update(ReminderSettings next) => controller.setReminders(next);

    return Scaffold(
      appBar: AppBar(title: const Text('Rappels')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSize.pagePadding),
          children: [
            _ReminderCard(
              title: 'Saisie quotidienne',
              icon: Icons.today_rounded,
              description:
                  'Un rappel chaque jour pour noter les dépenses du '
                  'jour.',
              enabled: reminders.dailyEnabled,
              onEnabled: (value) =>
                  update(reminders.copyWith(dailyEnabled: value)),
              child: _TimeRow(
                label: 'Heure du rappel',
                minutesOfDay: reminders.dailyMinute,
                enabled: reminders.dailyEnabled,
                onChanged: (minutes) =>
                    update(reminders.copyWith(dailyMinute: minutes)),
              ),
            ),
            AppSize.cardSpacing.ph,
            _ReminderCard(
              title: 'Point hebdomadaire',
              icon: Icons.date_range_rounded,
              description:
                  'Un rendez-vous par semaine pour vérifier vos '
                  'comptes.',
              enabled: reminders.weeklyEnabled,
              onEnabled: (value) =>
                  update(reminders.copyWith(weeklyEnabled: value)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Jour'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (
                        var weekday = DateTime.monday;
                        weekday <= DateTime.sunday;
                        weekday++
                      )
                        ChoiceChipTile(
                          label: ReminderSettings.weekdayLabel(
                            weekday,
                          ).substring(0, 3),
                          isSelected: reminders.weeklyWeekday == weekday,
                          onTap: reminders.weeklyEnabled
                              ? () => update(
                                  reminders.copyWith(weeklyWeekday: weekday),
                                )
                              : () {},
                        ),
                    ],
                  ),
                  AppSize.fieldSpacing.ph,
                  _TimeRow(
                    label: 'Heure du rappel',
                    minutesOfDay: reminders.weeklyMinute,
                    enabled: reminders.weeklyEnabled,
                    onChanged: (minutes) =>
                        update(reminders.copyWith(weeklyMinute: minutes)),
                  ),
                ],
              ),
            ),
            AppSize.cardSpacing.ph,
            _ReminderCard(
              title: 'Point mensuel',
              icon: Icons.calendar_month_rounded,
              description: 'Un bilan en début de mois pour faire le point.',
              enabled: reminders.monthlyEnabled,
              onEnabled: (value) =>
                  update(reminders.copyWith(monthlyEnabled: value)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: reminders.monthlyDay,
                    decoration: const InputDecoration(
                      labelText: 'Jour du mois',
                      prefixIcon: Icon(Icons.event_rounded, size: 20),
                    ),
                    items: [
                      for (var day = 1; day <= 28; day++)
                        DropdownMenuItem(value: day, child: Text('$day')),
                    ],
                    onChanged: reminders.monthlyEnabled
                        ? (day) => day == null
                              ? null
                              : update(reminders.copyWith(monthlyDay: day))
                        : null,
                  ),
                  AppSize.fieldSpacing.ph,
                  _TimeRow(
                    label: 'Heure du rappel',
                    minutesOfDay: reminders.monthlyMinute,
                    enabled: reminders.monthlyEnabled,
                    onChanged: (minutes) =>
                        update(reminders.copyWith(monthlyMinute: minutes)),
                  ),
                ],
              ),
            ),
            AppSize.cardSpacing.ph,
            const Text(
              'Vos réglages sont conservés sur le téléphone. Les notifications '
              'système seront ajoutées dans une prochaine version.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'un rappel : titre, description, interrupteur et réglages.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.enabled,
    required this.onEnabled,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      icon: icon,
      trailing: Switch.adaptive(
        value: enabled,
        activeThumbColor: AppColors.primary,
        onChanged: onEnabled,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          AppSize.fieldSpacing.ph,
          Opacity(opacity: enabled ? 1 : 0.45, child: child),
        ],
      ),
    );
  }
}

/// Ligne « heure du rappel » : ouvre le sélecteur d'heure du système.
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minutesOfDay,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int minutesOfDay;
  final bool enabled;
  final ValueChanged<int> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (minutesOfDay ~/ 60) % 24,
        minute: minutesOfDay % 60,
      ),
    );
    if (picked == null) return;
    onChanged(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
        OutlinedButton.icon(
          onPressed: enabled ? () => _pick(context) : null,
          icon: const Icon(Icons.schedule_rounded, size: 18),
          label: Text(ReminderSettings.timeLabel(minutesOfDay)),
        ),
      ],
    );
  }
}

/// Intitulé discret au-dessus d'un réglage.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
