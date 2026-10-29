import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/features/settings/domain/enums/app_theme_mode.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/routes/app_router.dart';
import 'package:juka/shared/theme/app_theme.dart';

/// Racine de l'application : thème et langue choisis par l'utilisateur, puis
/// table de routage (qui gère aussi l'accueil et le code PIN par redirection).
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    // Le code PIN est redemandé après un passage en arrière-plan.
    if (lifecycleState == AppLifecycleState.paused) {
      ref.read(settingsControllerProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final preferences = settings.preferences;

    return MaterialApp.router(
      title: 'Juka',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (preferences.themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      // La langue choisie pilote les écrans Material (calendriers, menus
      // contextuels, sélecteurs) et le format des dates de l'application.
      locale: Locale(preferences.language.code),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
