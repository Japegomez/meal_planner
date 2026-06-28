import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/core/config/env.dart';
import 'package:meal_planner/features/auth/data/auth_repository.dart';
import 'package:meal_planner/features/auth/domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// True while login, OAuth, or sign-up is in progress (avoids sign-out on pause).
final authOperationInProgressProvider = StateProvider<bool>((ref) => false);

final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!Env.hasSupabase) {
    return Stream.value(const AuthUnauthenticated());
  }
  return ref.watch(authRepositoryProvider).authStateChanges;
});
