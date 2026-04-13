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

/// Fetches a Stream Chat user token from the Supabase Edge Function
/// This ensures tokens are minted server-side with MFA verification
Future<String?> fetchStreamChatToken() async {
  try {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;

    final response = await http.post(
      Uri.parse('${Env.supabaseUrl}/functions/v1/stream-chat-token'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['token'] as String?;
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
