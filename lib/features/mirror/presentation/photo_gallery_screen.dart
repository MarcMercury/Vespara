import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/models/profile_photo.dart';
import '../../../core/providers/profile_photos_provider.dart';
import '../../../core/services/ai_photo_edit_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PHOTO GALLERY SCREEN
/// Full-featured photo management with AI editing, view tracking,
/// and time-sensitive / view-limited photo options.
/// ════════════════════════════════════════════════════════════════════════════

class PhotoGalleryScreen extends ConsumerStatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  ConsumerState<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends ConsumerState<PhotoGalleryScreen> {
  bool _isUploading = false;
  int? _selectedPhotoIndex;
  String? _userId;

  static const int maxPhotos = 30;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  Widget build(BuildContext context) {
    final photosState = ref.watch(profilePhotosProvider);

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(photosState),
            Expanded(
              child: photosState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: VesparaColors.glow))
                  : _buildPhotoGrid(photosState),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildUploadFab(photosState),
    );
  }

  Widget _buildHeader(ProfilePhotosState state) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'MY GALLERY',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: VesparaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.photos.length} / $maxPhotos photos',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showGallerySettings,
              icon: const Icon(Icons.settings_outlined,
                  color: VesparaColors.secondary),
            ),
          ],
        ),
      );

  Widget _buildPhotoGrid(ProfilePhotosState state) {
    final photos = state.photos;

    if (photos.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) => _buildPhotoTile(photos[index], index),
    );
  }

  Widget _buildPhotoTile(ProfilePhoto photo, int index) {
    final isExpired = photo.isPrimary == false &&
        _isPhotoExpired(photo);

    return GestureDetector(
      onTap: () => _showPhotoDetail(photo, index),
      onLongPress: () => _showPhotoOptions(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: photo.isPrimary
                ? VesparaColors.accentRose.withOpacity(0.8)
                : VesparaColors.border,
            width: photo.isPrimary ? 2 : 1,
          ),
          boxShadow: photo.isPrimary
              ? [
                  BoxShadow(
                    color: VesparaColors.accentRose.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo image
              Image.network(
                photo.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: VesparaColors.surface,
                  child: const Icon(Icons.broken_image,
                      color: VesparaColors.inactive, size: 32),
                ),
              ),

              // Expired overlay
              if (isExpired)
                Container(
                  color: VesparaColors.background.withOpacity(0.7),
                  child: const Center(
                    child: Icon(Icons.timer_off,
                        color: VesparaColors.secondary, size: 32),
                  ),
                ),

              // Bottom info strip
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      color: VesparaColors.background.withOpacity(0.6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // View count
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility,
                                  size: 10, color: VesparaColors.secondary),
                              const SizedBox(width: 3),
                              Text(
                                '${photo.score?.totalRankings ?? 0}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: VesparaColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          // Status indicators
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (photo.isPrimary)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: VesparaColors.accentRose
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'PRIMARY',
                                    style: GoogleFonts.inter(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w700,
                                      color: VesparaColors.accentRose,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // AI badge
              if (photo.version > 1)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: VesparaColors.accentViolet.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.auto_fix_high,
                        size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: VesparaColors.glow.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(Icons.add_a_photo_rounded,
                  size: 40, color: VesparaColors.glow.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              'Your gallery is empty',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload up to $maxPhotos photos to showcase yourself',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _uploadPhotos,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('Upload Photos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.accentRose,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );

  Widget? _buildUploadFab(ProfilePhotosState state) {
    if (state.photos.length >= maxPhotos) return null;

    return FloatingActionButton.extended(
      onPressed: _isUploading ? null : _uploadPhotos,
      backgroundColor: VesparaColors.accentRose,
      icon: _isUploading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
      label: Text(
        _isUploading ? 'Uploading...' : 'Add Photos',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  bool _isPhotoExpired(ProfilePhoto photo) {
    // Check using metadata from the photo if available
    return false; // Will be enhanced when expires_at is in the model
  }

  Future<void> _uploadPhotos() async {
    if (_userId == null) return;

    setState(() => _isUploading = true);

    try {
      final uploadService = ImageUploadService();
      final urls = await uploadService.uploadMultiplePhotos(
        context: context,
        maxPhotos: 10,
        onProgress: (current, total) {
          debugPrint('Uploading $current of $total');
        },
      );

      if (urls.isNotEmpty) {
        // Refresh photos
        ref.read(profilePhotosProvider.notifier).loadMyPhotos();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${urls.length} photo(s) uploaded successfully'),
              backgroundColor: VesparaColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    }

    setState(() => _isUploading = false);
  }

  void _showPhotoDetail(ProfilePhoto photo, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PhotoDetailSheet(
        photo: photo,
        userId: _userId!,
        onEdit: () {
          Navigator.pop(context);
          _showAiEditSheet(photo);
        },
        onTimeSensitive: () {
          Navigator.pop(context);
          _showTimeSensitiveSheet(photo);
        },
        onSetPrimary: () {
          ref.read(profilePhotosProvider.notifier).setAsPrimary(photo.id);
          Navigator.pop(context);
        },
        onDelete: () {
          ref.read(profilePhotosProvider.notifier).deletePhoto(photo.id);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showPhotoOptions(ProfilePhoto photo) {
    _showPhotoDetail(photo, 0);
  }

  void _showAiEditSheet(ProfilePhoto photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AiEditSheet(
        photo: photo,
        userId: _userId!,
        onEditApplied: () {
          ref.read(profilePhotosProvider.notifier).loadMyPhotos();
        },
      ),
    );
  }

  void _showTimeSensitiveSheet(ProfilePhoto photo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _TimeSensitiveSheet(
        photo: photo,
        userId: _userId!,
      ),
    );
  }

  void _showGallerySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gallery Settings',
                style: GoogleFonts.cinzel(
                    fontSize: 18, color: VesparaColors.primary)),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.sort, color: VesparaColors.secondary),
              title: const Text('Reorder Photos',
                  style: TextStyle(color: VesparaColors.primary)),
              subtitle: const Text('Drag to rearrange your gallery',
                  style: TextStyle(color: VesparaColors.secondary)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high,
                  color: VesparaColors.accentViolet),
              title: const Text('Enhance All',
                  style: TextStyle(color: VesparaColors.primary)),
              subtitle: const Text('Auto-enhance all your photos',
                  style: TextStyle(color: VesparaColors.secondary)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Photo Detail Bottom Sheet — full screen photo with options
class _PhotoDetailSheet extends StatelessWidget {
  const _PhotoDetailSheet({
    required this.photo,
    required this.userId,
    required this.onEdit,
    required this.onTimeSensitive,
    required this.onSetPrimary,
    required this.onDelete,
  });
  final ProfilePhoto photo;
  final String userId;
  final VoidCallback onEdit;
  final VoidCallback onTimeSensitive;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: VesparaColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VesparaColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Photo
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      photo.photoUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statChip(Icons.visibility, '${photo.score?.totalRankings ?? 0} views'),
                        _statChip(Icons.star, 'Pos ${photo.position}'),
                        if (photo.version > 1)
                          _statChip(Icons.auto_fix_high, 'Enhanced'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            icon: Icons.auto_fix_high,
                            label: 'Edit',
                            color: VesparaColors.accentViolet,
                            onTap: onEdit,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionButton(
                            icon: Icons.timer,
                            label: 'Time Limit',
                            color: VesparaColors.accentGold,
                            onTap: onTimeSensitive,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _actionButton(
                            icon: Icons.star,
                            label: photo.isPrimary ? 'Primary' : 'Set Primary',
                            color: photo.isPrimary
                                ? VesparaColors.accentRose
                                : VesparaColors.secondary,
                            onTap: photo.isPrimary ? null : onSetPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          color: VesparaColors.error, size: 18),
                      label: const Text('Delete Photo',
                          style: TextStyle(color: VesparaColors.error)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _statChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VesparaColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: VesparaColors.glow),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: VesparaColors.primary)),
          ],
        ),
      );

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

/// AI Edit Bottom Sheet
class _AiEditSheet extends StatefulWidget {
  const _AiEditSheet({
    required this.photo,
    required this.userId,
    required this.onEditApplied,
  });
  final ProfilePhoto photo;
  final String userId;
  final VoidCallback onEditApplied;

  @override
  State<_AiEditSheet> createState() => _AiEditSheetState();
}

class _AiEditSheetState extends State<_AiEditSheet> {
  final _aiService = AiPhotoEditService();
  String? _selectedEdit;
  String? _previewUrl;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _recommendations;

  @override
  void initState() {
    super.initState();
    _analyzePhoto();
  }

  Future<void> _analyzePhoto() async {
    setState(() => _isAnalyzing = true);
    _recommendations =
        await _aiService.analyzeAndRecommend(widget.photo.photoUrl);
    if (mounted) setState(() => _isAnalyzing = false);
  }

  void _applyEdit(String editType) {
    final result = _aiService.applyCloudinaryEdit(
      imageUrl: widget.photo.photoUrl,
      editType: editType,
    );
    setState(() {
      _selectedEdit = editType;
      _previewUrl = result ?? widget.photo.photoUrl;
    });
  }

  Future<void> _saveEdit() async {
    if (_selectedEdit == null || _previewUrl == null) return;

    await _aiService.saveEditRecord(
      photoId: widget.photo.id,
      userId: widget.userId,
      editType: _selectedEdit!,
      originalUrl: widget.photo.photoUrl,
      resultUrl: _previewUrl,
    );

    // Update the photo URL in profile_photos
    await Supabase.instance.client.from('profile_photos').update({
      'photo_url': _previewUrl,
      'ai_enhanced': true,
      'ai_edit_type': _selectedEdit,
      'original_url': widget.photo.photoUrl,
      'version': widget.photo.version + 1,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', widget.photo.id);

    widget.onEditApplied();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: VesparaColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VesparaColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Photo Editor',
                        style: GoogleFonts.cinzel(
                            fontSize: 18, color: VesparaColors.primary)),
                    if (_selectedEdit != null)
                      ElevatedButton(
                        onPressed: _saveEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VesparaColors.accentViolet,
                        ),
                        child: const Text('Save',
                            style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ),
              // Preview
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _previewUrl ?? widget.photo.photoUrl,
                          fit: BoxFit.contain,
                        ),
                        if (_selectedEdit != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: VesparaColors.accentViolet,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AiPhotoEditService
                                        .editOptions[_selectedEdit]?.label ??
                                    '',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // AI Recommendations
              if (_isAnalyzing)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: VesparaColors.accentViolet)),
                      SizedBox(width: 12),
                      Text('Analyzing your photo...',
                          style: TextStyle(color: VesparaColors.secondary)),
                    ],
                  ),
                ),
              if (_recommendations != null && !_isAnalyzing)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    _recommendations!['analysis'] as String? ??
                        'Try these enhancements:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: VesparaColors.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              // Edit options grid
              Expanded(
                flex: 2,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AiPhotoEditService.editOptions.entries
                          .map((e) => _buildEditChip(e.key, e.value))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEditChip(String key, AiEditOption option) {
    final isSelected = _selectedEdit == key;
    final isRecommended = (_recommendations?['recommendations'] as List?)
            ?.contains(key) ??
        false;

    return GestureDetector(
      onTap: () => _applyEdit(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? VesparaColors.accentViolet.withOpacity(0.3)
              : VesparaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? VesparaColors.accentViolet
                : isRecommended
                    ? VesparaColors.accentGold.withOpacity(0.5)
                    : VesparaColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForEdit(option.icon),
              size: 16,
              color: isSelected
                  ? VesparaColors.accentViolet
                  : VesparaColors.secondary,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(option.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.primary,
                        )),
                    if (isRecommended) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.star,
                          size: 10, color: VesparaColors.accentGold),
                    ],
                  ],
                ),
                Text(option.description,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: VesparaColors.secondary,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForEdit(String iconName) {
    switch (iconName) {
      case 'auto_fix_high':
        return Icons.auto_fix_high;
      case 'face_retouching_natural':
        return Icons.face_retouching_natural;
      case 'blur_on':
        return Icons.blur_on;
      case 'content_cut':
        return Icons.content_cut;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'filter_b_and_w':
        return Icons.filter_b_and_w;
      case 'photo_camera_front':
        return Icons.photo_camera_front;
      case 'crop':
        return Icons.crop;
      default:
        return Icons.edit;
    }
  }
}

/// Time Sensitive Photo Settings Sheet
class _TimeSensitiveSheet extends StatefulWidget {
  const _TimeSensitiveSheet({
    required this.photo,
    required this.userId,
  });
  final ProfilePhoto photo;
  final String userId;

  @override
  State<_TimeSensitiveSheet> createState() => _TimeSensitiveSheetState();
}

class _TimeSensitiveSheetState extends State<_TimeSensitiveSheet> {
  bool _isTimeSensitive = false;
  int _viewLimit = 0; // 0 = unlimited
  Duration _expiresDuration = const Duration(hours: 24);
  bool _isSaving = false;

  static const List<Map<String, dynamic>> _durationOptions = [
    {'label': '1 hour', 'duration': Duration(hours: 1)},
    {'label': '6 hours', 'duration': Duration(hours: 6)},
    {'label': '24 hours', 'duration': Duration(hours: 24)},
    {'label': '3 days', 'duration': Duration(days: 3)},
    {'label': '7 days', 'duration': Duration(days: 7)},
  ];

  static const List<int> _viewLimitOptions = [0, 5, 10, 25, 50, 100];

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final updates = <String, dynamic>{
        'is_time_sensitive': _isTimeSensitive,
        'view_limit': _viewLimit == 0 ? null : _viewLimit,
        'expires_at': _isTimeSensitive
            ? DateTime.now().add(_expiresDuration).toIso8601String()
            : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('profile_photos')
          .update(updates)
          .eq('id', widget.photo.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo settings updated'),
            backgroundColor: VesparaColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Photo Access Controls',
                style: GoogleFonts.cinzel(
                    fontSize: 18, color: VesparaColors.primary)),
            const SizedBox(height: 6),
            Text(
              'Control who can see this photo, for how long, and how many times.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: VesparaColors.secondary),
            ),
            const SizedBox(height: 20),

            // Time-sensitive toggle
            SwitchListTile(
              title: const Text('Time-Sensitive',
                  style: TextStyle(color: VesparaColors.primary)),
              subtitle: const Text('Auto-hide after a set time',
                  style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
              value: _isTimeSensitive,
              onChanged: (v) => setState(() => _isTimeSensitive = v),
              activeColor: VesparaColors.accentGold,
            ),

            // Duration picker
            if (_isTimeSensitive) ...[
              const SizedBox(height: 10),
              Text('Visible for:',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: VesparaColors.secondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _durationOptions.map((opt) {
                  final isSelected =
                      _expiresDuration == opt['duration'] as Duration;
                  return ChoiceChip(
                    label: Text(opt['label'] as String),
                    selected: isSelected,
                    selectedColor: VesparaColors.accentGold.withOpacity(0.3),
                    onSelected: (s) {
                      if (s) {
                        setState(
                            () => _expiresDuration = opt['duration'] as Duration);
                      }
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // View limit
            Text('View limit:',
                style: GoogleFonts.inter(
                    fontSize: 13, color: VesparaColors.secondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _viewLimitOptions.map((limit) {
                final isSelected = _viewLimit == limit;
                return ChoiceChip(
                  label: Text(limit == 0 ? 'Unlimited' : '$limit views'),
                  selected: isSelected,
                  selectedColor: VesparaColors.accentViolet.withOpacity(0.3),
                  onSelected: (s) {
                    if (s) setState(() => _viewLimit = limit);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.accentGold,
                  foregroundColor: VesparaColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Settings',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
}
