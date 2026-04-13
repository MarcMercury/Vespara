import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/env.dart';

/// Cloudinary Media Service
/// Handles image uploads with automatic optimization, resizing, and CDN delivery.
/// Falls back to direct Supabase Storage when Cloudinary is not configured.
class CloudinaryService {
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();
  static final CloudinaryService _instance = CloudinaryService._internal();

  /// Whether Cloudinary is configured and ready to use
  static bool get isConfigured =>
      Env.cloudinaryCloudName.isNotEmpty &&
      Env.cloudinaryUploadPreset.isNotEmpty;

  /// Base URL for Cloudinary delivery
  String get _baseUrl =>
      'https://res.cloudinary.com/${Env.cloudinaryCloudName}/image';

  /// Upload API endpoint
  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/${Env.cloudinaryCloudName}/image/upload';

  // ═══════════════════════════════════════════════════════════════════════════
  // UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload an image file to Cloudinary using unsigned upload preset.
  /// Returns the secure URL of the uploaded image, or null on failure.
  Future<String?> uploadImage({
    required XFile file,
    String? folder,
    Map<String, String>? context,
  }) async {
    if (!isConfigured) {
      debugPrint('Cloudinary: Not configured, skipping upload');
      return null;
    }

    try {
      final Uint8List bytes = await file.readAsBytes();
      final String extension = file.path.split('.').last.toLowerCase();

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
        ..fields['upload_preset'] = Env.cloudinaryUploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'upload.$extension',
        ));

      if (folder != null) {
        request.fields['folder'] = folder;
      }

      if (context != null) {
        // Cloudinary context as pipe-separated key=value pairs
        request.fields['context'] =
            context.entries.map((e) => '${e.key}=${e.value}').join('|');
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload failed: ${response.statusCode} $body');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }

  /// Upload a profile photo with auto-crop and face detection.
  Future<String?> uploadProfilePhoto({
    required XFile file,
    required String userId,
  }) async {
    return uploadImage(
      file: file,
      folder: 'vespara/profiles/$userId',
      context: {'user_id': userId, 'type': 'profile'},
    );
  }

  /// Upload a chat attachment.
  Future<String?> uploadChatAttachment({
    required XFile file,
    required String channelId,
  }) async {
    return uploadImage(
      file: file,
      folder: 'vespara/chat/$channelId',
      context: {'channel': channelId, 'type': 'chat'},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSFORMATION URLs
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate an optimized delivery URL from a Cloudinary URL or public ID.
  /// Applies automatic format/quality optimization and optional transformations.
  String optimizedUrl(
    String publicIdOrUrl, {
    int? width,
    int? height,
    String crop = 'fill',
    String gravity = 'auto',
    String quality = 'auto',
    String format = 'auto',
  }) {
    // If already a full Cloudinary URL, extract public ID
    String publicId = publicIdOrUrl;
    if (publicIdOrUrl.contains('res.cloudinary.com')) {
      final uri = Uri.parse(publicIdOrUrl);
      // Extract everything after /upload/ (skip version if present)
      final segments = uri.pathSegments;
      final uploadIdx = segments.indexOf('upload');
      if (uploadIdx >= 0 && uploadIdx + 1 < segments.length) {
        var start = uploadIdx + 1;
        // Skip version segment (v1234567890)
        if (segments[start].startsWith('v') &&
            int.tryParse(segments[start].substring(1)) != null) {
          start++;
        }
        publicId = segments.sublist(start).join('/');
        // Remove file extension
        final dotIdx = publicId.lastIndexOf('.');
        if (dotIdx > 0) publicId = publicId.substring(0, dotIdx);
      }
    }

    final transforms = <String>[];
    if (width != null) transforms.add('w_$width');
    if (height != null) transforms.add('h_$height');
    transforms.add('c_$crop');
    transforms.add('g_$gravity');
    transforms.add('q_$quality');
    transforms.add('f_$format');

    return '$_baseUrl/${transforms.join(',')}/$publicId';
  }

  /// Profile thumbnail (80x80, face-focused)
  String profileThumbnail(String url) =>
      optimizedUrl(url, width: 80, height: 80, gravity: 'face');

  /// Profile card image (400x500, face-focused)
  String profileCard(String url) =>
      optimizedUrl(url, width: 400, height: 500, gravity: 'face');

  /// Chat image thumbnail (200x200)
  String chatThumbnail(String url) =>
      optimizedUrl(url, width: 200, height: 200);

  /// Full-size optimized (max 1200px wide, auto quality)
  String fullSize(String url) =>
      optimizedUrl(url, width: 1200, crop: 'limit', gravity: 'auto');
}
