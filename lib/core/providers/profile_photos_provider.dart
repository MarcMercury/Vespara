import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/profile_photo.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Profile Photos Provider
/// Manages photo uploads, rankings, and AI recommendations
/// ═══════════════════════════════════════════════════════════════════════════

final profilePhotosProvider =
    StateNotifierProvider<ProfilePhotosNotifier, ProfilePhotosState>(
        (ref) => ProfilePhotosNotifier(Supabase.instance.client),);

/// Provider for fetching another user's photos (for ranking)
final userPhotosProvider =
    FutureProvider.family<List<ProfilePhoto>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('profile_photos')
      .select()
      .eq('user_id', userId)
      .order('position');

  return (response as List).map((json) => ProfilePhoto.fromJson(json)).toList();
});

/// Provider for checking if current user has ranked another user's photos
final existingRankingProvider =
    FutureProvider.family<PhotoRanking?, String>((ref, rankedUserId) async {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) return null;

  final response = await supabase
      .from('photo_rankings')
      .select()
      .eq('ranker_id', currentUserId)
      .eq('ranked_user_id', rankedUserId)
      .maybeSingle();

  if (response == null) return null;
  return PhotoRanking.fromJson(response);
});

// ═══════════════════════════════════════════════════════════════════════════
// STATE
// ═══════════════════════════════════════════════════════════════════════════

class ProfilePhotosState {
  const ProfilePhotosState({
    this.photos = const [],
    this.recommendation,
    this.isLoading = false,
    this.isUploading = false,
    this.error,
    this.uploadingPosition,
  });
  final List<ProfilePhoto> photos;
  final PhotoRecommendation? recommendation;
  final bool isLoading;
  final bool isUploading;
  final String? error;
  final int? uploadingPosition;

  ProfilePhotosState copyWith({
    List<ProfilePhoto>? photos,
    PhotoRecommendation? recommendation,
    bool? isLoading,
    bool? isUploading,
    String? error,
    int? uploadingPosition,
    bool clearError = false,
    bool clearRecommendation = false,
  }) =>
      ProfilePhotosState(
        photos: photos ?? this.photos,
        recommendation: clearRecommendation
            ? null
            : (recommendation ?? this.recommendation),
        isLoading: isLoading ?? this.isLoading,
        isUploading: isUploading ?? this.isUploading,
        error: clearError ? null : error,
        uploadingPosition: uploadingPosition,
      );

  /// Get primary photo URL
  String? get primaryPhotoUrl {
    final primary = photos.where((p) => p.isPrimary).firstOrNull;
    return primary?.photoUrl ?? photos.firstOrNull?.photoUrl;
  }

  /// Get photo by position (1-5)
  ProfilePhoto? photoAtPosition(int position) =>
      photos.where((p) => p.position == position).firstOrNull;

  /// Number of empty slots
  int get emptySlots => 5 - photos.length;

  /// Total rankings across all photos
  int get totalRankingsReceived =>
      photos.fold(0, (sum, p) => sum + (p.score?.totalRankings ?? 0));
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class ProfilePhotosNotifier extends StateNotifier<ProfilePhotosState> {
  ProfilePhotosNotifier(this._supabase) : super(const ProfilePhotosState()) {
    loadMyPhotos();
  }
  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════
  // LOAD PHOTOS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> loadMyPhotos() async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load photos with their scores from profile_photos table
      final response = await _supabase.from('profile_photos').select('''
            *,
            photo_scores(*)
          ''').eq('user_id', _userId!).order('position');

      var photos = (response as List)
          .map((json) => ProfilePhoto.fromJson(json))
          .toList();

      // If no photos in profile_photos table, check profiles table for onboarding photos
      if (photos.isEmpty) {
        final profileResponse = await _supabase
            .from('profiles')
            .select('avatar_url, photos')
            .eq('id', _userId!)
            .maybeSingle();

        if (profileResponse != null) {
          final List<String> photoUrls = [];
          
          // Add avatar_url first if it exists
          if (profileResponse['avatar_url'] != null) {
            photoUrls.add(profileResponse['avatar_url'] as String);
          }
          
          // Add additional photos from profiles.photos array
          final additionalPhotos = List<String>.from(profileResponse['photos'] ?? []);
          for (final url in additionalPhotos) {
            if (!photoUrls.contains(url)) {
              photoUrls.add(url);
            }
          }

          // Migrate onboarding photos to profile_photos table
          for (int i = 0; i < photoUrls.length && i < 5; i++) {
            final photoUrl = photoUrls[i];
            await _supabase.from('profile_photos').upsert({
              'user_id': _userId!,
              'photo_url': photoUrl,
              'position': i + 1,
              'is_primary': i == 0,
              'storage_path': photoUrl,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id,position');
          }

          // Reload after migration
          if (photoUrls.isNotEmpty) {
            final migratedResponse = await _supabase.from('profile_photos').select('''
                  *,
                  photo_scores(*)
                ''').eq('user_id', _userId!).order('position');

            photos = (migratedResponse as List)
                .map((json) => ProfilePhoto.fromJson(json))
                .toList();
          }
        }
      }

      state = state.copyWith(
        photos: photos,
        isLoading: false,
      );

      // Generate AI recommendation
      _generateRecommendation();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load photos: $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UPLOAD PHOTO
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> uploadPhoto(Uint8List imageBytes, int position,
      {String extension = 'jpg',}) async {
    if (_userId == null) return false;
    if (position < 1 || position > 5) return false;

    state = state.copyWith(
      isUploading: true,
      uploadingPosition: position,
      clearError: true,
    );

    try {
      // Check if replacing existing photo
      final existingPhoto = state.photoAtPosition(position);

      // Generate unique filename
      final uuid = const Uuid().v4();
      final storagePath = '$_userId/$uuid.$extension';

      // Upload to storage
      await _supabase.storage.from('profile-photos').uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: 'image/$extension',
              upsert: true,
            ),
          );

      // Get public URL
      final photoUrl =
          _supabase.storage.from('profile-photos').getPublicUrl(storagePath);

      if (existingPhoto != null) {
        // Update existing photo (triggers version increment)
        await _supabase.from('profile_photos').update({
          'photo_url': photoUrl,
          'storage_path': storagePath,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingPhoto.id);

        // Delete old file from storage
        try {
          await _supabase.storage
              .from('profile-photos')
              .remove([existingPhoto.storagePath]);
        } catch (_) {
          // Ignore storage deletion errors
        }
      } else {
        // Insert new photo
        final isPrimary = state.photos.isEmpty;
        await _supabase.from('profile_photos').insert({
          'user_id': _userId,
          'photo_url': photoUrl,
          'storage_path': storagePath,
          'position': position,
          'is_primary': isPrimary,
        });
      }

      state = state.copyWith(
        isUploading: false,
      );

      // Reload photos
      await loadMyPhotos();
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to upload photo: $e',
      );
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DELETE PHOTO
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> deletePhoto(String photoId) async {
    if (_userId == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final photo = state.photos.where((p) => p.id == photoId).firstOrNull;
      if (photo == null) return false;

      // Delete from database (CASCADE handles scores)
      await _supabase.from('profile_photos').delete().eq('id', photoId);

      // Delete from storage
      try {
        await _supabase.storage
            .from('profile-photos')
            .remove([photo.storagePath]);
      } catch (_) {
        // Ignore storage errors
      }

      // If deleted photo was primary, make first remaining photo primary
      if (photo.isPrimary && state.photos.length > 1) {
        final remaining = state.photos.where((p) => p.id != photoId).first;
        await setAsPrimary(remaining.id);
      }

      state = state.copyWith(isLoading: false);
      await loadMyPhotos();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete photo: $e',
      );
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SET PRIMARY PHOTO
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> setAsPrimary(String photoId) async {
    if (_userId == null) return false;

    try {
      await _supabase
          .from('profile_photos')
          .update({'is_primary': true}).eq('id', photoId);

      await loadMyPhotos();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to set primary: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REORDER PHOTOS
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> reorderPhotos(List<String> photoIdsInOrder) async {
    if (_userId == null) return false;

    try {
      // Update positions
      for (int i = 0; i < photoIdsInOrder.length; i++) {
        await _supabase
            .from('profile_photos')
            .update({'position': i + 1}).eq('id', photoIdsInOrder[i]);
      }

      await loadMyPhotos();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to reorder: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // APPLY AI RECOMMENDATION
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> applyAIRecommendation() async {
    final recommendation = state.recommendation;
    if (recommendation == null || !recommendation.hasRecommendation) {
      return false;
    }

    // Reorder photos according to AI recommendation
    final success = await reorderPhotos(recommendation.recommendedOrder);

    if (success && recommendation.recommendedPrimaryId != null) {
      await setAsPrimary(recommendation.recommendedPrimaryId!);
    }

    return success;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUBMIT RANKING (for ranking another user's photos)
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> submitRanking({
    required String rankedUserId,
    required List<String> rankedPhotoIds,
    required Map<String, int> photoVersions,
  }) async {
    if (_userId == null) return false;
    if (_userId == rankedUserId) return false; // Can't rank own photos

    try {
      await _supabase.from('photo_rankings').upsert(
        {
          'ranker_id': _userId,
          'ranked_user_id': rankedUserId,
          'ranked_photo_ids': rankedPhotoIds,
          'photo_versions': photoVersions,
          'is_valid': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'ranker_id,ranked_user_id',
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to submit ranking: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENERATE AI RECOMMENDATION
  // ═══════════════════════════════════════════════════════════════════════

  void _generateRecommendation() {
    final photosWithScores = state.photos
        .where(
          (p) => p.score != null && p.score!.hasEnoughData,
        )
        .toList();

    if (photosWithScores.isEmpty) {
      state = state.copyWith(
        recommendation: PhotoRecommendation(
          totalRankings: state.totalRankingsReceived,
          insights: _getInsights(),
        ),
      );
      return;
    }

    // Sort by average rank (ascending - lower is better)
    photosWithScores.sort(
      (a, b) => a.score!.averageRank.compareTo(b.score!.averageRank),
    );

    // Best photo
    final bestPhoto = photosWithScores.first;

    // Calculate average confidence
    final avgConfidence = photosWithScores.fold(
          0.0,
          (sum, p) => sum + p.score!.confidenceScore,
        ) /
        photosWithScores.length;

    // Total rankings
    final totalRankings = photosWithScores.fold(
      0,
      (sum, p) => sum + p.score!.totalRankings,
    );

    state = state.copyWith(
      recommendation: PhotoRecommendation(
        recommendedPrimaryId: bestPhoto.id,
        recommendedOrder: photosWithScores.map((p) => p.id).toList(),
        confidence: avgConfidence,
        totalRankings: totalRankings,
        insights: _getInsights(bestPhoto: bestPhoto),
      ),
    );
  }

  List<String> _getInsights({ProfilePhoto? bestPhoto}) {
    final insights = <String>[];

    final totalRankings = state.totalRankingsReceived;

    if (totalRankings == 0) {
      insights.add('Get more profile views to receive photo rankings');
    } else if (totalRankings < 5) {
      insights.add(
          '${5 - totalRankings} more rankings needed for AI recommendations',);
    }

    if (bestPhoto != null) {
      final score = bestPhoto.score!;
      if (score.averageRank <= 1.5) {
        insights.add('Your top photo is a crowd favorite! 🔥');
      }

      if (!bestPhoto.isPrimary) {
        insights.add('Consider making your best-ranked photo your primary');
      }
    }

    if (state.photos.length < 3) {
      insights.add('Add more photos to get better ranking data');
    }

    return insights;
  }
}
