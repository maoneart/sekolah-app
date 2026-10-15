import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_state.dart';
import '../features/academic/presentation/academic_screen.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/admin/presentation/role_access_screen.dart';
import '../features/attendance/presentation/qr_scan_screen.dart';
import '../features/attendance/presentation/student_qr_card_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import 'main_navigation_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isLoggedIn = authState.isAuthenticated;

      // When authentication is still resolving
      if (authState.isLoading) return null;

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/scan-qr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QrScanScreen(),
      ),
      GoRoute(
        path: '/my-card',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StudentQrCardScreen(),
      ),
      GoRoute(
        path: '/admin/roles',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RoleAccessScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/academic',
                builder: (context, state) => const AcademicScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finance',
                builder: (context, state) => const FinanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
