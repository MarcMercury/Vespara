import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../services/stream_chat_service.dart';

/// Chat backend mode - Stream Chat or native Supabase
enum ChatBackend { stream, supabase }

/// Determines which chat backend to use based on configuration
class ChatBackendConfig {
  static ChatBackend get activeBackend {
    final key = Env.streamChatApiKey;
    if (key.isNotEmpty) return ChatBackend.stream;
    return ChatBackend.supabase;
  }

  static bool get isStreamEnabled => activeBackend == ChatBackend.stream;
}

/// Provider for the current chat backend mode
final chatBackendProvider = Provider<ChatBackend>((ref) {
  return ChatBackendConfig.activeBackend;
});

/// Cached Stream Chat token to avoid repeated edge function calls
String? _cachedStreamToken;
DateTime? _cachedStreamTokenAt;
String? _cachedStreamTokenUserId;
const _streamTokenCacheTTL = Duration(minutes: 55); // tokens typically last 1h

/// Fetches a Stream Chat user token from the Supabase Edge Function.
/// Uses an in-memory cache to avoid redundant edge function invocations.
Future<String?> fetchStreamChatToken({bool forceRefresh = false}) async {
  try {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _cachedStreamToken = null;
      return null;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;

    // Return cached token if still valid for the same user
    if (!forceRefresh &&
        _cachedStreamToken != null &&
        _cachedStreamTokenAt != null &&
        _cachedStreamTokenUserId == userId &&
        DateTime.now().difference(_cachedStreamTokenAt!) < _streamTokenCacheTTL) {
      debugPrint('Stream Chat token: using cached token');
      return _cachedStreamToken;
    }

    final response = await http.post(
      Uri.parse('${Env.supabaseUrl}/functions/v1/stream-chat-token'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
        'apikey': Env.supabaseAnonKey,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'] as String?;
      // Cache the token
      _cachedStreamToken = token;
      _cachedStreamTokenAt = DateTime.now();
      _cachedStreamTokenUserId = userId;
      return token;
    } else if (response.statusCode == 403) {
      debugPrint('Stream Chat token: MFA verification required');
      return null;
    } else {
      debugPrint('Stream Chat token error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    debugPrint('Stream Chat token fetch error: $e');
    return null;
  }
}

/// Clears the cached Stream Chat token (call on sign-out)
void clearStreamChatTokenCache() {
  _cachedStreamToken = null;
  _cachedStreamTokenAt = null;
  _cachedStreamTokenUserId = null;
}

/// Initializes Stream Chat connection after successful auth + MFA
Future<bool> initializeStreamChat({
  required String userId,
  required String displayName,
  String? avatarUrl,
}) async {
  if (!ChatBackendConfig.isStreamEnabled) return false;

  try {
    final token = await fetchStreamChatToken();
    if (token == null) return false;

    await StreamChatService.connectUser(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      token: token,
    );
    return true;
  } catch (e) {
    debugPrint('Stream Chat init error: $e');
    return false;
  }
}
