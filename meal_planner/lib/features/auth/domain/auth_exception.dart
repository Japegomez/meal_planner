sealed class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class AuthCancelledException extends AuthException {
  const AuthCancelledException() : super('Sign-in cancelled');
}

final class AuthConfigurationException extends AuthException {
  const AuthConfigurationException(super.message);
}

final class AuthProviderException extends AuthException {
  const AuthProviderException(super.message);
}

final class AuthInvalidCredentialsException extends AuthException {
  const AuthInvalidCredentialsException()
      : super('Email o contraseña incorrectos. Comprueba los datos e inténtalo de nuevo.');
}

final class AuthEmailNotConfirmedException extends AuthException {
  const AuthEmailNotConfirmedException()
      : super('Confirma tu email antes de iniciar sesión. Revisa tu bandeja de entrada.');
}

final class AuthUserAlreadyExistsException extends AuthException {
  const AuthUserAlreadyExistsException()
      : super('Ya existe una cuenta con este email. Inicia sesión o usa otra dirección.');
}
