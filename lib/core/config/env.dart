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
  static const String _streamChatApiKeyDef =
      String.fromEnvironment('STREAM_CHAT_API_KEY');
  static const String _cloudinaryCloudNameDef =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String _cloudinaryUploadPresetDef =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  /// Safe dotenv access — returns fallback when dotenv is not loaded
  static String _dotenv(String key, [String fallback = '']) {
    try {
      return dotenv.env[key] ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════

  static String get appName => _dotenv('APP_NAME', 'Vespara');
  static String get appDomain => _dotenv('APP_DOMAIN', 'www.vespara.co');
  static String get appVersion => _dotenv('APP_VERSION', '0.1.0-alpha');

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPABASE CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  static String get supabaseUrl => _supabaseUrlDef.isNotEmpty
      ? _supabaseUrlDef
      : _dotenv('SUPABASE_URL');

  static String get supabaseAnonKey => _supabaseAnonKeyDef.isNotEmpty
      ? _supabaseAnonKeyDef
      : _dotenv('SUPABASE_ANON_KEY');

  static String get supabaseServiceRole => _dotenv('SUPABASE_SERVICE_ROLE');

  // ═══════════════════════════════════════════════════════════════════════════
  // OPENAI CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  static String get openaiApiKey => _openaiApiKeyDef.isNotEmpty
      ? _openaiApiKeyDef
      : _dotenv('OPENAI_API_KEY');

  static String get openaiAdminKey => _dotenv('OPENAI_ADMIN_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // GOOGLE CLOUD SERVICES
  // ═══════════════════════════════════════════════════════════════════════════

  static String get googleProjectId => _dotenv('GOOGLE_PROJECT_ID');

  static String get googleClientId => _dotenv('GOOGLE_CLIENT_ID');

  static String get googleMapsApiKey => _googleMapsApiKeyDef.isNotEmpty
      ? _googleMapsApiKeyDef
      : _dotenv('GOOGLE_MAPS_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // GEMINI AI
  // ═══════════════════════════════════════════════════════════════════════════

  static String get geminiApiKey => _geminiApiKeyDef.isNotEmpty
      ? _geminiApiKeyDef
      : _dotenv('GEMINI_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // MESHY (3D AI Generation)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get meshyApiKey => _meshyApiKeyDef.isNotEmpty
      ? _meshyApiKeyDef
      : _dotenv('MESHY_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // GIPHY (GIF Search & Chat Reactions)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get giphyApiKey => _giphyApiKeyDef.isNotEmpty
      ? _giphyApiKeyDef
      : _dotenv('GIPHY_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // IPINFO (IP Geolocation)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get ipinfoApiKey => _ipinfoApiKeyDef.isNotEmpty
      ? _ipinfoApiKeyDef
      : _dotenv('IPINFO_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // ABSTRACT API (Email Validation)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get abstractApiKey => _abstractApiKeyDef.isNotEmpty
      ? _abstractApiKeyDef
      : _dotenv('ABSTRACT_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM CHAT
  // ═══════════════════════════════════════════════════════════════════════════

  static String get streamChatApiKey => _streamChatApiKeyDef.isNotEmpty
      ? _streamChatApiKeyDef
      : _dotenv('STREAM_CHAT_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // CLOUDINARY (Media Optimization)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get cloudinaryCloudName => _cloudinaryCloudNameDef.isNotEmpty
      ? _cloudinaryCloudNameDef
      : _dotenv('CLOUDINARY_CLOUD_NAME');

  static String get cloudinaryUploadPreset => _cloudinaryUploadPresetDef.isNotEmpty
      ? _cloudinaryUploadPresetDef
      : _dotenv('CLOUDINARY_UPLOAD_PRESET');

  // ═══════════════════════════════════════════════════════════════════════════
  // RESEND (Transactional Email - key used server-side in Edge Functions)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get resendApiKey => _dotenv('RESEND_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // LIVEKIT (Voice/Video — Phase 2)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get livekitUrl => _dotenv('LIVEKIT_URL');
  static String get livekitApiKey => _dotenv('LIVEKIT_API_KEY');

  // ═══════════════════════════════════════════════════════════════════════════
  // MAPBOX (Optional — enhanced location UX)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get mapboxAccessToken => _dotenv('MAPBOX_ACCESS_TOKEN');

  // ═══════════════════════════════════════════════════════════════════════════
  // HUGGING FACE (AI Inference API)
  // ═══════════════════════════════════════════════════════════════════════════

  static String get huggingfaceKey => _huggingfaceKeyDef.isNotEmpty
      ? _huggingfaceKeyDef
      : _dotenv('HUGGINGFACE_KEY');
}
