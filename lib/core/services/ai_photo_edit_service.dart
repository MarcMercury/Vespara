import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// AI Photo Editing Service
/// Provides AI-powered photo enhancements using OpenAI and Cloudinary transformations.
class AiPhotoEditService {
  factory AiPhotoEditService() => _instance;
  AiPhotoEditService._internal();
  static final AiPhotoEditService _instance = AiPhotoEditService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Available AI edit types with descriptions
  static const Map<String, AiEditOption> editOptions = {
    'enhance': AiEditOption(
      id: 'enhance',
      label: 'Auto Enhance',
      description: 'Improve lighting, contrast, and clarity',
      icon: 'auto_fix_high',
    ),
    'retouch': AiEditOption(
      id: 'retouch',
      label: 'Soft Retouch',
      description: 'Subtle skin smoothing and blemish removal',
      icon: 'face_retouching_natural',
    ),
    'background_blur': AiEditOption(
      id: 'background_blur',
      label: 'Background Blur',
      description: 'Professional depth-of-field blur effect',
      icon: 'blur_on',
    ),
    'background_remove': AiEditOption(
      id: 'background_remove',
      label: 'Remove Background',
      description: 'Remove background for a clean look',
      icon: 'content_cut',
    ),
    'artistic_warm': AiEditOption(
      id: 'artistic_warm',
      label: 'Warm Glow',
      description: 'Golden hour warmth and soft light',
      icon: 'wb_sunny',
    ),
    'artistic_cool': AiEditOption(
      id: 'artistic_cool',
      label: 'Cool Tone',
      description: 'Elegant cool blue tones',
      icon: 'ac_unit',
    ),
    'artistic_noir': AiEditOption(
      id: 'artistic_noir',
      label: 'Noir',
      description: 'Dramatic black and white',
      icon: 'filter_b_and_w',
    ),
    'artistic_vintage': AiEditOption(
      id: 'artistic_vintage',
      label: 'Vintage',
      description: 'Classic film-like grain and color',
      icon: 'photo_camera_front',
    ),
    'crop_smart': AiEditOption(
      id: 'crop_smart',
      label: 'Smart Crop',
      description: 'AI-powered crop focusing on your best angle',
      icon: 'crop',
    ),
  };

  /// Apply a Cloudinary transformation based on edit type.
  /// Returns the transformed URL or null on failure.
  String? applyCloudinaryEdit({
    required String imageUrl,
    required String editType,
  }) {
    if (!imageUrl.contains('res.cloudinary.com')) {
      debugPrint('AiPhotoEdit: URL is not a Cloudinary image');
      return null;
    }

    // Build transformation string based on edit type
    String transformation;
    switch (editType) {
      case 'enhance':
        transformation = 'e_improve,e_auto_brightness,e_auto_contrast,q_auto:best';
        break;
      case 'retouch':
        transformation = 'e_improve:outdoor,e_auto_brightness,e_sharpen:50';
        break;
      case 'background_blur':
        transformation = 'e_background_removal/e_blur:800/b_auto';
        break;
      case 'background_remove':
        transformation = 'e_background_removal';
        break;
      case 'artistic_warm':
        transformation = 'e_art:incognito,e_tint:40:orange:yellow,e_brightness:10';
        break;
      case 'artistic_cool':
        transformation = 'e_art:frost,e_blue:30,e_brightness:5';
        break;
      case 'artistic_noir':
        transformation = 'e_grayscale,e_contrast:40,e_brightness:-10';
        break;
      case 'artistic_vintage':
        transformation = 'e_art:audrey,e_sepia:30,e_vignette:30';
        break;
      case 'crop_smart':
        transformation = 'c_fill,g_auto:faces,w_800,h_1000,q_auto:best';
        break;
      default:
        return null;
    }

    // Insert transformation into the Cloudinary URL
    final uri = Uri.parse(imageUrl);
    final segments = uri.pathSegments.toList();
    final uploadIdx = segments.indexOf('upload');

    if (uploadIdx < 0) return null;

    // Insert transformation after 'upload'
    segments.insert(uploadIdx + 1, transformation);
    final newPath = '/${segments.join('/')}';
    final newUri = uri.replace(path: newPath);

    return newUri.toString();
  }

  /// Generate an AI-enhanced version using OpenAI Vision for analysis
  /// then apply the recommended Cloudinary transformations.
  /// Routes through edge function proxy when available for security.
  Future<Map<String, dynamic>> analyzeAndRecommend(String imageUrl) async {
    try {
      // Route through edge function proxy (secure)
      if (Env.supabaseUrl.isNotEmpty) {
        final response = await Supabase.instance.client.functions.invoke(
          'ai-proxy',
          body: {
            'action': 'photo_analysis',
            'prompt': 'Analyze this dating profile photo and suggest the best 2-3 edits. Photo URL: $imageUrl',
          },
        );

        if (response.status == 200) {
          final content = response.data['content'] as String? ?? '';
          final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
          if (jsonMatch != null) {
            return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
          }
        }
      }

      // Fallback: direct call (local dev only)
      final apiKey = Env.openaiApiKey;
      if (apiKey.isEmpty) {
        return {
          'recommendations': ['enhance', 'crop_smart'],
          'analysis': 'AI analysis unavailable — try Auto Enhance for best results.',
        };
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional photo editor. Analyze this profile photo and recommend edits. Reply with JSON: {"recommendations": ["edit_type1", "edit_type2"], "analysis": "brief description"}. Valid edit types: enhance, retouch, background_blur, background_remove, artistic_warm, artistic_cool, artistic_noir, artistic_vintage, crop_smart',
            },
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': 'Analyze this profile photo and suggest the best 2-3 edits:'},
                {'type': 'image_url', 'image_url': {'url': imageUrl}},
              ],
            },
          ],
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('AI photo analysis error: $e');
    }

    return {
      'recommendations': ['enhance', 'crop_smart'],
      'analysis': 'Try Auto Enhance for a quick improvement.',
    };
  }

  /// Save an AI edit record to the database
  Future<void> saveEditRecord({
    required String photoId,
    required String userId,
    required String editType,
    required String originalUrl,
    String? resultUrl,
  }) async {
    await _supabase.from('photo_ai_edits').insert({
      'photo_id': photoId,
      'user_id': userId,
      'edit_type': editType,
      'original_url': originalUrl,
      'result_url': resultUrl,
      'status': resultUrl != null ? 'completed' : 'pending',
      'completed_at': resultUrl != null ? DateTime.now().toIso8601String() : null,
    });
  }
}

class AiEditOption {
  const AiEditOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
  final String id;
  final String label;
  final String description;
  final String icon;
}
