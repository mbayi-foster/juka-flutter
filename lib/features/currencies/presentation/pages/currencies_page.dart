import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/currencies/presentation/providers/currencies_providers.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/padding.dart';

/// Devises suivies et taux de change mensuels vers la devise de référence.
///
/// Aucun taux n'est téléchargé : l'utilisateur saisit lui-même la valeur d'une
/// devise pour chaque mois. Ces taux servent ensuite à additionner des comptes
/// de devises différentes dans le tableau de bord et les rapports.
class CurrenciesPage extends ConsumerStatefulWidget {
  const CurrenciesPage({super.key});

  @override
  ConsumerState<CurrenciesPage> createState() => _CurrenciesPageState();
}

class _CurrenciesPageState extends ConsumerState<CurrenciesPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _changeMonth(int offset) => setState(() {
    _month = DateTime(_month.year, _month.month + offset);
  });

  Future<void> _addCurrency(List<AppCurrency> tracked) async {
    final available = [
      for (final currency in AppCurrency.values)
        if (!tracked.contains(currency)) currency,
    ];

    final selected = await showModalBottomSheet<AppCurrency>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Ajouter une devise',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            for (final currency in available)
              ListTile(
                title: Text(currency.displayName),
                subtitle: Text(currency.symbol),
                onTap: () => Navigator.of(context).pop(currency),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (selected == null) return;
    await ref.read(exchangeRatesControllerProvider.notifier).track(selected);
    if (!mounted) return;
    context.showAppSnackBar('${selected.code} ajoutée.');
  }

  Future<void> _removeCurrency(
    AppCurrency currency,
    AppCurrency? reference,
  ) async {
    await ref.read(exchangeRatesControllerProvider.notifier).untrack(currency);
    if (reference == currency) {
      await ref
          .read(settingsControllerProvider.notifier)
          .setReferenceCurrency(null);
    }
    if (!mounted) return;
    context.showAppSnackBar('${currency.code} retirée.');
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(settingsControllerProvider).preferences;
    final reference = preferences.referenceCurrency;
    final rates = ref.watch(exchangeRatesControllerProvider);
    final trackedAsync = ref.watch(trackedCurrenciesProvider);
    final tracked = switch (trackedAsync) {
      AsyncData(:final value) => value,
      _ => const <AppCurrency>[],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Devises et taux')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSize.pagePadding),
          children: [
            _referenceCard(tracked, reference),
            AppSize.cardSpacing.ph,
            _trackedCard(tracked, reference, isLoading: trackedAsync.isLoading),
            AppSize.cardSpacing.ph,
            _ratesCard(tracked, reference, rates),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Devise de référence
  // ---------------------------------------------------------------------

  Widget _referenceCard(List<AppCurrency> tracked, AppCurrency? reference) {
    return AppCard(
      title: 'Devise de référence',
      icon: Icons.flag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tous les montants du tableau de bord et des rapports sont ramenés '
            'dans cette devise pour pouvoir être additionnés.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          14.ph,
          if (tracked.isEmpty)
            const EmptyMessage(
              message: 'Ajoutez d\'abord une devise ci-dessous.',
              icon: Icons.currency_exchange_rounded,
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final currency in tracked)
                  ChoiceChipTile(
                    label: currency.code,
                    isSelected: reference == currency,
                    onTap: () => ref
                        .read(settingsControllerProvider.notifier)
                        .setReferenceCurrency(currency),
                  ),
              ],
            ),
          if (reference == null && tracked.isNotEmpty) ...[
            12.ph,
            const Text(
              'Aucune devise choisie : chaque écran continue d\'afficher une '
              'devise à la fois.',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Devises suivies
  // ---------------------------------------------------------------------

  Widget _trackedCard(
    List<AppCurrency> tracked,
    AppCurrency? reference, {
    required bool isLoading,
  }) {
    return AppCard(
      title: 'Devises suivies',
      icon: Icons.currency_exchange_rounded,
      trailing: TextButton(
        onPressed: () => _addCurrency(tracked),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Ajouter'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading && tracked.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (tracked.isEmpty)
            const EmptyMessage(
              message: 'Aucune devise suivie.',
              icon: Icons.currency_exchange_rounded,
            )
          else
            for (var index = 0; index < tracked.length; index++) ...[
              if (index > 0) const Divider(height: 18),
              _CurrencyRow(
                currency: tracked[index],
                isReference: reference == tracked[index],
                onRemove: () => _removeCurrency(tracked[index], reference),
              ),
            ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Taux mensuels
  // ---------------------------------------------------------------------

  Widget _ratesCard(
    List<AppCurrency> tracked,
    AppCurrency? reference,
    ExchangeRatesState rates,
  ) {
    final convertible = [
      for (final currency in tracked)
        if (currency != reference) currency,
    ];

    return AppCard(
      title: 'Taux de change mensuels',
      icon: Icons.trending_up_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Mois précédent',
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            DateFormatter.monthYear(_month),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Mois suivant',
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reference == null)
            const EmptyMessage(
              message:
                  'Choisissez une devise de référence pour saisir des '
                  'taux.',
              icon: Icons.flag_outlined,
            )
          else if (convertible.isEmpty)
            const EmptyMessage(
              message: 'Ajoutez une deuxième devise pour saisir un taux.',
              icon: Icons.currency_exchange_rounded,
            )
          else ...[
            Text(
              'Combien vaut 1 unité de chaque devise en ${reference.code} ?',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            14.ph,
            for (final currency in convertible) ...[
              _RateField(
                key: ValueKey(
                  '${currency.code}-${_month.year}-${_month.month}',
                ),
                currency: currency,
                reference: reference,
                initialRate: rates.rateFor(currency, _month),
                onSubmit: (rate) => _saveRate(currency, reference, rate),
              ),
              if (currency != convertible.last) AppSize.fieldSpacing.ph,
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _saveRate(
    AppCurrency currency,
    AppCurrency reference,
    double? rate,
  ) async {
    final controller = ref.read(exchangeRatesControllerProvider.notifier);

    if (rate == null) {
      await controller.deleteRate(currency: currency, month: _month);
      if (!mounted) return;
      context.showAppSnackBar('Taux de ${currency.code} effacé.');
      return;
    }

    if (rate <= 0) {
      context.showAppSnackBar(
        'Saisissez un taux supérieur à zéro.',
        isError: true,
      );
      return;
    }

    await controller.saveRate(currency: currency, month: _month, rate: rate);
    if (!mounted) return;
    context.showAppSnackBar(
      '1 ${currency.code} = ${MoneyFormatter.number(rate)} ${reference.code}',
    );
  }
}

/// Ligne d'une devise suivie.
class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.currency,
    required this.isReference,
    required this.onRemove,
  });

  final AppCurrency currency;
  final bool isReference;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currency.displayName,
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              2.ph,
              Text(
                isReference ? 'Devise de référence' : currency.label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Retirer',
          onPressed: onRemove,
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Saisie du taux d'une devise pour le mois affiché.
class _RateField extends StatelessWidget {
  const _RateField({
    super.key,
    required this.currency,
    required this.reference,
    required this.initialRate,
    required this.onSubmit,
  });

  final AppCurrency currency;
  final AppCurrency reference;
  final double? initialRate;
  final ValueChanged<double?> onSubmit;

  @override
  Widget build(BuildContext context) {
    final rate = initialRate;

    return AppTextField(
      label: '${currency.code} → ${reference.code}',
      initialValue: rate == null ? null : MoneyFormatter.number(rate),
      hintText: 'Ex. 2 850',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(Icons.swap_horiz_rounded, size: 20),
      helperText: rate == null
          ? 'Taux non saisi : les comptes en ${currency.code} seront ignorés.'
          : '1 ${currency.code} = ${MoneyFormatter.number(rate)} ${reference.code}',
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9\s.,]')),
      ],
      onFieldSubmitted: (value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) {
          onSubmit(null);
          return;
        }
        onSubmit(MoneyFormatter.tryParse(trimmed));
      },
    );
  }
}
