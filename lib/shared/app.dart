import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/features/settings/domain/enums/app_theme_mode.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/routes/app_router.dart';
import 'package:juka/shared/theme/app_theme.dart';

/// Racine de l'application : thème choisi par l'utilisateur et table de routage.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'Juka',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      routerConfig: AppRouter.router,
    );
  }
}
