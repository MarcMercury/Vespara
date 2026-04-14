import 'package:flutter/foundation.dart';

/// LiveKit Service — Phase 2 scaffolding for voice/video rooms.
/// This service is a placeholder. When LiveKit credentials are configured,
/// it will handle room creation, joining, and audio/video track management.
///
/// Required env vars: LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET
/// The API secret should only be used server-side (Edge Function).
class LiveKitService {
  factory LiveKitService() => _instance;
  LiveKitService._internal();
  static final LiveKitService _instance = LiveKitService._internal();

  /// Whether LiveKit is configured
  static bool get isConfigured {
    final url = _envGet('LIVEKIT_URL');
    return url.isNotEmpty;
  }

  static String _envGet(String key) {
    // Will be added to Env class when LiveKit is activated
    try {
      // ignore: avoid_dynamic_calls
      return '';
    } catch (_) {
      return '';
    }
  }

  /// Request a room token from the Edge Function.
  /// The Edge Function creates the token server-side using the API secret.
  Future<String?> getRoomToken({
    required String roomName,
    required String participantName,
    required String accessToken,
  }) async {
    if (!isConfigured) {
      debugPrint('LiveKit: Not configured');
      return null;
    }

    // TODO: Call Edge Function to mint LiveKit token
    // POST /functions/v1/livekit-token
    // { room_name, participant_name }
    debugPrint('LiveKit: getRoomToken() — not yet implemented');
    return null;
  }

  /// Connect to a LiveKit room (to be implemented with livekit_client).
  Future<void> joinRoom({
    required String token,
    required String roomName,
  }) async {
    debugPrint('LiveKit: joinRoom() — Phase 2, not yet implemented');
  }

  /// Disconnect from the current room.
  Future<void> leaveRoom() async {
    debugPrint('LiveKit: leaveRoom() — Phase 2, not yet implemented');
  }

  /// Toggle microphone mute.
  Future<void> toggleMicrophone() async {
    debugPrint('LiveKit: toggleMicrophone() — Phase 2');
  }

  /// Toggle camera on/off.
  Future<void> toggleCamera() async {
    debugPrint('LiveKit: toggleCamera() — Phase 2');
  }
}
