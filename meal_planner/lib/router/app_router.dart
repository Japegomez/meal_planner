import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_planner/features/auth/domain/auth_state.dart';
import 'package:meal_planner/features/auth/presentation/auth_provider.dart';
import 'package:meal_planner/features/auth/presentation/login_screen.dart';
import 'package:meal_planner/features/planner/presentation/planner_screen.dart';
import 'package:meal_planner/features/recipes/presentation/recipe_list_screen.dart';
import 'package:meal_planner/features/shopping/presentation/shopping_list_screen.dart';
import 'package:meal_planner/router/home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation.startsWith('/auth');
      final isAuthenticated = authState.maybeWhen(
        data: (value) => value is AuthAuthenticated,
        orElse: () => false,
      );

      if (!isAuthenticated && !isLoggingIn) {
        return '/auth/login';
      }
      if (isAuthenticated && isLoggingIn) {
        return '/home/planner';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, _) => '/home/planner',
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, _) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/planner',
                builder: (_, _) => const PlannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/recipes',
                builder: (_, _) => const RecipeListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/shopping',
                builder: (_, _) => const ShoppingListScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
