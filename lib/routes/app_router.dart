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
import 'package:juka/features/settings/presentation/pages/profile_page.dart';
import 'package:juka/features/settings/presentation/pages/reminders_page.dart';
import 'package:juka/features/settings/presentation/pages/settings_page.dart';
import 'package:juka/features/wealth/presentation/pages/wealth_page.dart';
import 'package:juka/routes/app_routes.dart';

/// Table de routage de l'application (go_router).
///
/// Les onglets principaux sont regroupés dans une `StatefulShellRoute` : la
/// barre de navigation et l'état de chaque onglet sont ainsi conservés. Tout
/// est local : il n'y a plus d'écran de connexion réseau (le nom et le code PIN
/// sont vérifiés par la porte d'accès de `MyApp`).
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    // L'application s'ouvre directement sur le tableau de bord.
    initialLocation: AppRoutes.dashboard,
    routes: [
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
}
