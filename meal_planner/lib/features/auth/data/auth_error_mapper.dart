import 'package:meal_planner/features/auth/domain/auth_exception.dart' as app_auth;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

app_auth.AuthException mapAuthError(Object error) {
  if (error is app_auth.AuthException) {
    return error;
  }

  if (error is AuthApiException) {
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();

    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return const app_auth.AuthInvalidCredentialsException();
    }

    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return const app_auth.AuthEmailNotConfirmedException();
    }

    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        message.contains('user already registered') ||
        message.contains('already been registered')) {
      return const app_auth.AuthUserAlreadyExistsException();
    }

    return app_auth.AuthProviderException(error.message);
  }

  return app_auth.AuthProviderException(error.toString());
}
