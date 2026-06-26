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
