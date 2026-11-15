import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/expenses/presentation/expense_detail_screen.dart';
import '../../features/expenses/presentation/expense_form_screen.dart';
import '../../features/expenses/presentation/expense_list_screen.dart';
import '../../features/scanner/presentation/scan_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.expenses,
                builder: (context, state) => const ExpenseListScreen(),
                routes: [
                  // Obrasci i detalji otvaraju se preko cijelog zaslona
                  // (iznad donje navigacije).
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ExpenseFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ExpenseDetailScreen(
                      expenseId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => ExpenseFormScreen(
                          expenseId: state.pathParameters['id'],
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
                path: AppRoutes.scan,
                builder: (context, state) => const ScanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
