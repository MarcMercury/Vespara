import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration wrapper
/// Provides type-safe access to all environment variables
/// Uses --dart-define for web/production, .env for local development
class Env {
  Env._();

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPILE-TIME CONSTANTS (from --dart-define)
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _supabaseUrlDef = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKeyDef =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _openaiApiKeyDef =
      String.fromEnvironment('OPENAI_API_KEY');
  static const String _googleMapsApiKeyDef =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // APP IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════

    static String get appName => dotenv.env['APP_NAME'] ?? 'Kult';
    static String get appDomain => dotenv.env['APP_DOMAIN'] ?? 'www.kult.app';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '0.1.0-alpha';

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPABASE CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  static String get supabaseUrl => _supabaseUrlDef.isNotEmpty
      ? _supabaseUrlDef
      : (dotenv.env['SUPABASE_URL'] ?? '');

  static String get supabaseAnonKey => _supabaseAnonKeyDef.isNotEmpty
      ? _supabaseAnonKeyDef
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

  static String get supabaseServiceRole =>
      dotenv.env['SUPABASE_SERVICE_ROLE'] ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // OPENAI CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  static String get openaiApiKey => _openaiApiKeyDef.isNotEmpty
      ? _openaiApiKeyDef
      : (dotenv.env['OPENAI_API_KEY'] ?? '');

  static String get openaiAdminKey => dotenv.env['OPENAI_ADMIN_KEY'] ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // GOOGLE CLOUD SERVICES
  // ═══════════════════════════════════════════════════════════════════════════

  static String get googleProjectId =>
      dotenv.env['GOOGLE_PROJECT_ID'] ?? '';

  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';

  static String get googleMapsApiKey => _googleMapsApiKeyDef.isNotEmpty
      ? _googleMapsApiKeyDef
      : (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '');
}
