import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:juka/features/accounts/presentation/pages/account_form_page.dart';
import 'package:juka/features/accounts/presentation/pages/accounts_page.dart';
import 'package:juka/features/categories/presentation/pages/budgets_page.dart';
import 'package:juka/features/categories/presentation/pages/categories_page.dart';
import 'package:juka/features/currencies/presentation/pages/currencies_page.dart';
import 'package:juka/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:juka/features/main/presentation/pages/main_shell.dart';
import 'package:juka/features/operations/presentation/pages/operation_form_page.dart';
import 'package:juka/features/operations/presentation/pages/operations_page.dart';
import 'package:juka/features/reports/presentation/pages/reports_page.dart';
import 'package:juka/features/settings/presentation/pages/backup_page.dart';
import 'package:juka/features/settings/presentation/pages/lock_page.dart';
import 'package:juka/features/settings/presentation/pages/onboarding_page.dart';
import 'package:juka/features/settings/presentation/pages/profile_page.dart';
import 'package:juka/features/settings/presentation/pages/reminders_page.dart';
import 'package:juka/features/settings/presentation/pages/settings_page.dart';
import 'package:juka/features/settings/presentation/pages/splash_page.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/features/settings/presentation/state/settings_state.dart';
import 'package:juka/features/wealth/presentation/pages/wealth_page.dart';
import 'package:juka/routes/app_routes.dart';

/// Table de routage de l'application (go_router).
///
/// Les onglets principaux sont regroupés dans une `StatefulShellRoute` : la
/// barre de navigation et l'état de chaque onglet sont ainsi conservés.
///
/// L'accès au contenu est décidé par la redirection (`redirect`) : préparation
/// des données, première ouverture et déverrouillage par code PIN sont des
/// routes à part entière. Ces écrans vivaient auparavant dans le `builder` de
/// `MaterialApp`, donc au-dessus du `Navigator` : ils n'avaient pas d'`Overlay`
/// et les `SnackBar` / boîtes de dialogue y échouaient
/// (« No Overlay Widget found »).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AccessRefresh(ref);
  final router = GoRouter(
    // L'application vise le tableau de bord ; la redirection décide de ce qui
    // s'affiche réellement en premier.
    initialLocation: AppRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsControllerProvider);
      final location = state.matchedLocation;

      // 1. Réglages et profil en cours de lecture.
      if (!settings.isReady) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // 2. Première ouverture : le nom doit être renseigné.
      if (settings.needsOnboarding) {
        return location == AppRoutes.onboarding
            ? null
            : AppRoutes.onboarding;
      }

      // 3. Code PIN actif : l'application reste verrouillée. L'écran d'où
      //    l'on vient est conservé pour y revenir après le déverrouillage.
      if (settings.isLocked) {
        if (location == AppRoutes.lock) return null;
        return Uri(
          path: AppRoutes.lock,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }

      // 4. Accès accordé : les écrans de porte d'accès renvoient au contenu.
      switch (location) {
        case AppRoutes.splash:
        case AppRoutes.onboarding:
          return AppRoutes.dashboard;
        case AppRoutes.lock:
          final from = state.uri.queryParameters['from'];
          if (from == null || from.isEmpty || from == AppRoutes.lock) {
            return AppRoutes.dashboard;
          }
          return from;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.lock,
        name: 'lock',
        builder: (context, state) => const LockPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                name: 'dashboard',
                builder: (context, state) => const DashboardPage(),
                routes: [
                  GoRoute(
                    path: 'progression',
                    name: 'wealth',
                    builder: (context, state) => const WealthPage(),
                  ),
                  GoRoute(
                    path: 'rapports',
                    name: 'reports',
                    builder: (context, state) => const ReportsPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.accounts,
                name: 'accounts',
                builder: (context, state) => const AccountsPage(),
                routes: [
                  // Déclaré avant `:id` pour que « nouveau » ne soit pas
                  // interprété comme un identifiant de compte.
                  GoRoute(
                    path: 'nouveau',
                    name: 'accountCreate',
                    builder: (context, state) => const AccountFormPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'accountDetail',
                    builder: (context, state) => AccountDetailPage(
                      accountId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'modifier',
                        name: 'accountEdit',
                        builder: (context, state) => AccountFormPage(
                          accountId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.operations,
                name: 'operations',
                builder: (context, state) => const OperationsPage(),
                routes: [
                  GoRoute(
                    path: 'nouvelle',
                    name: 'operationCreate',
                    builder: (context, state) => const OperationFormPage(),
                  ),
                  GoRoute(
                    path: ':id/modifier',
                    name: 'operationEdit',
                    builder: (context, state) => OperationFormPage(
                      operationId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'categories',
                    name: 'categories',
                    builder: (context, state) => const CategoriesPage(),
                  ),
                  GoRoute(
                    path: 'budgets',
                    name: 'budgets',
                    builder: (context, state) => const BudgetsPage(),
                  ),
                  GoRoute(
                    path: 'profil',
                    name: 'profile',
                    builder: (context, state) => const ProfilePage(),
                  ),
                  GoRoute(
                    path: 'rappels',
                    name: 'reminders',
                    builder: (context, state) => const RemindersPage(),
                  ),
                  GoRoute(
                    path: 'devises',
                    name: 'currencies',
                    builder: (context, state) => const CurrenciesPage(),
                  ),
                  GoRoute(
                    path: 'sauvegarde',
                    name: 'backup',
                    builder: (context, state) => const BackupPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });

  return router;
});

/// Réévalue les redirections dès que la porte d'accès change d'état.
///
/// `routerProvider` ne se reconstruit pas : le routeur est notifié pour
/// réexaminer la route courante.
class _AccessRefresh extends ChangeNotifier {
  _AccessRefresh(Ref ref) {
    ref.listen<SettingsState>(settingsControllerProvider, (previous, next) {
      final changed =
          previous?.isReady != next.isReady ||
          previous?.needsOnboarding != next.needsOnboarding ||
          previous?.isLocked != next.isLocked;
      if (changed) notifyListeners();
    });
  }
}
