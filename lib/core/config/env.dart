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
  static const String _geminiApiKeyDef =
      String.fromEnvironment('GEMINI_API_KEY');
  static const String _meshyApiKeyDef =
      String.fromEnvironment('MESHY_API_KEY');
  static const String _giphyApiKeyDef =
      String.fromEnvironment('GIPHY_API_KEY');
  static const String _ipinfoApiKeyDef =
      String.fromEnvironment('IPINFO_API_KEY');
  static const String _abstractApiKeyDef =
      String.fromEnvironment('ABSTRACT_API_KEY');
  static const String _huggingfaceKeyDef =
      String.fromEnvironment('HUGGINGFACE_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // APP IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════

  static String get appName => dotenv.env['APP_NAME'] ?? 'Vespara';
  static String get appDomain => dotenv.env['APP_DOMAIN'] ?? 'www.vespara.co';
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

  // ═══════════════════════════════════════════════════════════════════════════
  // GEMINI AI
  // ═══════════════════════════════════════════════════════════════════════════

  static String get geminiApiKey => _geminiApiKeyDef.isNotEmpty
      ? _geminiApiKeyDef
      : (dotenv.env['GEMINI_API_KEY'] ?? '');

  // ═══════════════════════════════════════════════════════════════════════════
  // MESHY (3D AI Generation)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get meshyApiKey => _meshyApiKeyDef.isNotEmpty
      ? _meshyApiKeyDef
      : (dotenv.env['MESHY_API_KEY'] ?? '');

  // ═══════════════════════════════════════════════════════════════════════════
  // GIPHY (GIF Search & Chat Reactions)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get giphyApiKey => _giphyApiKeyDef.isNotEmpty
      ? _giphyApiKeyDef
      : (dotenv.env['GIPHY_API_KEY'] ?? '');

  // ═══════════════════════════════════════════════════════════════════════════
  // IPINFO (IP Geolocation)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get ipinfoApiKey => _ipinfoApiKeyDef.isNotEmpty
      ? _ipinfoApiKeyDef
      : (dotenv.env['IPINFO_API_KEY'] ?? '');

  // ═══════════════════════════════════════════════════════════════════════════
  // ABSTRACT API (Email Validation)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get abstractApiKey => _abstractApiKeyDef.isNotEmpty
      ? _abstractApiKeyDef
      : (dotenv.env['ABSTRACT_API_KEY'] ?? '');

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM CHAT
  // ═══════════════════════════════════════════════════════════════════════════

  static String get streamChatApiKey =>
      dotenv.env['STREAM_CHAT_API_KEY'] ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // CLOUDINARY (Media Optimization)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';

  static String get cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // RESEND (Transactional Email - key used server-side in Edge Functions)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get resendApiKey => dotenv.env['RESEND_API_KEY'] ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // LIVEKIT (Voice/Video — Phase 2)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get livekitUrl => dotenv.env['LIVEKIT_URL'] ?? '';
  static String get livekitApiKey => dotenv.env['LIVEKIT_API_KEY'] ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // MAPBOX (Optional — enhanced location UX)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get mapboxAccessToken =>
      dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // HUGGING FACE (AI Inference API)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get huggingfaceKey => _huggingfaceKeyDef.isNotEmpty
      ? _huggingfaceKeyDef
      : (dotenv.env['HUGGINGFACE_KEY'] ?? '');
}
