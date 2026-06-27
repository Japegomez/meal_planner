import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meal_planner/core/config/env.dart';
import 'package:meal_planner/core/supabase/supabase_client.dart';
import 'package:meal_planner/features/auth/domain/auth_exception.dart';
import 'package:meal_planner/features/auth/domain/auth_state.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class AuthRepository {
  GoogleSignIn? get _googleSignIn {
    if (!Env.hasGoogleSignIn) return null;
    return GoogleSignIn(
      serverClientId: Env.googleWebClientId,
      clientId: !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.iOS &&
              Env.googleIosClientId.isNotEmpty
          ? Env.googleIosClientId
          : null,
    );
  }

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

  Future<AuthResponse> signInWithGoogle() async {
    final googleSignIn = _googleSignIn;
    if (googleSignIn == null) {
      throw const AuthConfigurationException(
        'GOOGLE_WEB_CLIENT_ID is not configured',
      );
    }

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthCancelledException();
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthProviderException('Google Sign-In returned no id token');
    }

    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  Future<AuthResponse> signInWithApple() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      throw const AuthConfigurationException(
        'Sign in with Apple is only available on Apple platforms',
      );
    }

    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthProviderException('Apple Sign-In returned no id token');
    }

    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await supabase.auth.signOut();
  }

  Future<void> deleteAccount() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthProviderException('No authenticated user');
    }

    await _deleteUserAvatar(userId);
    await supabase.rpc<void>('delete_user_account');
    await signOut();
  }

  Future<void> _deleteUserAvatar(String userId) async {
    try {
      await supabase.storage.from('avatars').remove(['$userId/avatar.jpg']);
    } catch (_) {
      // Best-effort cleanup before account deletion.
    }
  }

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

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
