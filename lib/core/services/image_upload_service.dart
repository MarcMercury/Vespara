import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'permission_service.dart';

/// Image Upload Service
/// Handles uploading images to Supabase Storage with proper error handling
class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();
  
  final PermissionService _permissionService = PermissionService();
  final Uuid _uuid = const Uuid();
  
  SupabaseClient get _supabase => Supabase.instance.client;
  String? get _userId => _supabase.auth.currentUser?.id;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE PHOTO UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Upload profile photo with full permission handling and UI feedback
  Future<String?> uploadProfilePhoto({
    required BuildContext context,
    VoidCallback? onUploadStart,
    VoidCallback? onUploadComplete,
    void Function(String error)? onError,
  }) async {
    if (_userId == null) {
      onError?.call('You must be logged in to upload photos');
      return null;
    }
    
    // Show image source picker
    final XFile? imageFile = await _permissionService.showImageSourcePicker(
      context: context,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    
    if (imageFile == null) return null;
    
    onUploadStart?.call();
    
    try {
      // Upload to Supabase Storage
      final url = await _uploadToStorage(
        file: imageFile,
        bucket: 'avatars',
        path: '$_userId/profile_${_uuid.v4()}',
      );
      
      if (url != null) {
        // Update user profile
        await _updateProfileAvatar(url);
      }
      
      onUploadComplete?.call();
      return url;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      onError?.call('Failed to upload photo. Please try again.');
      return null;
    }
  }
  
  /// Upload multiple photos (for onboarding/dating profile)
  Future<List<String>> uploadMultiplePhotos({
    required BuildContext context,
    int maxPhotos = 6,
    VoidCallback? onUploadStart,
    void Function(int current, int total)? onProgress,
    VoidCallback? onUploadComplete,
    void Function(String error)? onError,
  }) async {
    if (_userId == null) {
      onError?.call('You must be logged in to upload photos');
      return [];
    }
    
    // Pick multiple images
    final List<XFile> images = await _permissionService.pickMultipleImages(
      context: context,
      limit: maxPhotos,
    );
    
    if (images.isEmpty) return [];
    
    onUploadStart?.call();
    
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        onProgress?.call(i + 1, images.length);
        
        final url = await _uploadToStorage(
          file: images[i],
          bucket: 'photos',
          path: '$_userId/photo_${_uuid.v4()}',
        );
        
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        debugPrint('Error uploading photo ${i + 1}: $e');
      }
    }
    
    if (uploadedUrls.isNotEmpty) {
      await _updateProfilePhotos(uploadedUrls);
    }
    
    onUploadComplete?.call();
    return uploadedUrls;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STORAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Upload file to Supabase Storage
  Future<String?> _uploadToStorage({
    required XFile file,
    required String bucket,
    required String path,
  }) async {
    try {
      final String extension = file.path.split('.').last.toLowerCase();
      final String fullPath = '$path.$extension';
      
      // Read file bytes
      final Uint8List bytes = await file.readAsBytes();
      
      // Upload to Supabase
      await _supabase.storage.from(bucket).uploadBinary(
        fullPath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$extension',
          upsert: true,
        ),
      );
      
      // Get public URL
      final String publicUrl = _supabase.storage.from(bucket).getPublicUrl(fullPath);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Storage upload error: $e');
      rethrow;
    }
  }
  
  /// Update user's avatar_url in profiles table
  Future<void> _updateProfileAvatar(String url) async {
    if (_userId == null) return;
    
    await _supabase.from('profiles').update({
      'avatar_url': url,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId!);
  }
  
  /// Update user's photos array in profiles table
  Future<void> _updateProfilePhotos(List<String> newUrls) async {
    if (_userId == null) return;
    
    // Get existing photos
    final response = await _supabase
        .from('profiles')
        .select('photos')
        .eq('id', _userId!)
        .single();
    
    final List<String> existingPhotos = 
        (response['photos'] as List<dynamic>?)?.cast<String>() ?? [];
    
    // Append new photos
    final updatedPhotos = [...existingPhotos, ...newUrls];
    
    await _supabase.from('profiles').update({
      'photos': updatedPhotos,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId!);
  }
  
  /// Delete a photo from storage and profile
  Future<bool> deletePhoto({
    required String url,
    required String bucket,
  }) async {
    if (_userId == null) return false;
    
    try {
      // Extract path from URL
      final Uri uri = Uri.parse(url);
      final String path = uri.pathSegments.skip(2).join('/'); // Skip 'storage/v1/object/public/bucket'
      
      await _supabase.storage.from(bucket).remove([path]);
      
      // Remove from profile photos array
      final response = await _supabase
          .from('profiles')
          .select('photos')
          .eq('id', _userId!)
          .single();
      
      final List<String> photos = 
          (response['photos'] as List<dynamic>?)?.cast<String>() ?? [];
      
      photos.remove(url);
      
      await _supabase.from('profiles').update({
        'photos': photos,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _userId!);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }
}

/// Widget for displaying photo upload progress
class PhotoUploadProgress extends StatelessWidget {
  final int current;
  final int total;
  
  const PhotoUploadProgress({
    super.key,
    required this.current,
    required this.total,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: current / total,
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF4A9EFF)),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Uploading $current of $total...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
