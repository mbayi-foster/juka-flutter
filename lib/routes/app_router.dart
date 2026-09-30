import 'package:go_router/go_router.dart';
import 'package:juka/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:juka/features/accounts/presentation/pages/account_form_page.dart';
import 'package:juka/features/accounts/presentation/pages/accounts_page.dart';
import 'package:juka/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:juka/features/auth/presentation/pages/login_page.dart';
import 'package:juka/features/auth/presentation/pages/register_page.dart';
import 'package:juka/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:juka/features/main/presentation/pages/main_shell.dart';
import 'package:juka/features/operations/presentation/pages/operation_form_page.dart';
import 'package:juka/features/operations/presentation/pages/operations_page.dart';
import 'package:juka/features/settings/presentation/pages/settings_page.dart';
import 'package:juka/routes/app_routes.dart';

/// Table de routage de l'application (go_router).
///
/// Les onglets principaux sont regroupés dans une `StatefulShellRoute` : la
/// barre de navigation et l'état de chaque onglet sont ainsi conservés. Les
/// écrans d'authentification restent hors de la coquille, donc sans barre de
/// navigation.
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
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
    ],
  );
}
