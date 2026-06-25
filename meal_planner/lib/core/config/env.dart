/// Runtime configuration via --dart-define (CI/Codemagic) or launch args.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://eu.posthog.com',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasSentry => sentryDsn.isNotEmpty;

  static bool get hasPosthog => posthogApiKey.isNotEmpty;

  static bool get isProduction =>
      const bool.fromEnvironment('dart.vm.product');
}
