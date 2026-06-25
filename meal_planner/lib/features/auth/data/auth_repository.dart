import 'package:meal_planner/core/supabase/supabase_client.dart';
import 'package:meal_planner/features/auth/domain/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class AuthRepository {
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) =>
      supabase.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) =>
      supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

  Future<void> sendPasswordResetEmail(String email) =>
      supabase.auth.resetPasswordForEmail(email);

  Future<void> signOut() => supabase.auth.signOut();

  Session? get currentSession => supabase.auth.currentSession;

  Stream<AuthState> get authStateChanges async* {
    yield supabase.auth.currentSession != null
        ? AuthAuthenticated(supabase.auth.currentUser!)
        : const AuthUnauthenticated();

    await for (final event in supabase.auth.onAuthStateChange) {
      final session = event.session;
      if (session != null) {
        yield AuthAuthenticated(session.user);
      } else {
        yield const AuthUnauthenticated();
      }
    }
  }
}
