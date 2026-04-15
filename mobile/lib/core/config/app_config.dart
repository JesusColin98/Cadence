/// Central app configuration.
/// Pass values at build time via --dart-define:
///   flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
class AppConfig {
  const AppConfig._();

  /// Supabase project URL (NEXT_PUBLIC_SUPABASE_URL)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase anon/publishable key (NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Base URL of the deployed Next.js web app (used for API calls)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cadence.pstepanov.dev',
  );

  /// Whether this is a debug build
  static const bool isDebug = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: true,
  ) == false;
}
