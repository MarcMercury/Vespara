import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration wrapper
/// Provides type-safe access to all environment variables
class Env {
  Env._();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // APP IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get appName => dotenv.env['APP_NAME'] ?? 'Vespara';
  static String get appDomain => dotenv.env['APP_DOMAIN'] ?? 'www.vespara.co';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '0.1.0-alpha';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SUPABASE CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get supabaseUrl => 
    dotenv.env['SUPABASE_URL'] ?? 'https://nazcwlfirmbuxuzlzjtz.supabase.co';
  
  static String get supabaseAnonKey => 
    dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  static String get supabaseServiceRole => 
    dotenv.env['SUPABASE_SERVICE_ROLE'] ?? '';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // OPENAI CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get openaiApiKey => 
    dotenv.env['OPENAI_API_KEY'] ?? '';
  
  static String get openaiAdminKey => 
    dotenv.env['OPENAI_ADMIN_KEY'] ?? '';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // GOOGLE CLOUD SERVICES
  // ═══════════════════════════════════════════════════════════════════════════
  
  static String get googleProjectId => 
    dotenv.env['GOOGLE_PROJECT_ID'] ?? 'vespara-484323';
  
  static String get googleClientId => 
    dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  
  static String get googleMapsApiKey => 
    dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
}
