import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/profile_photo.dart';
import '../providers/profile_photos_provider.dart';
import '../theme/app_theme.dart';

/// Shows a bottom sheet for ranking another user's photos
/// Users drag photos to reorder them from 1 (best) to N (least preferred)
class PhotoRankingSheet extends ConsumerStatefulWidget {
  const PhotoRankingSheet({
    super.key,
    required this.userId,
    required this.userName,
    required this.photos,
  });
  final String userId;
  final String userName;
  final List<ProfilePhoto> photos;

  /// Show the photo ranking sheet and return true if ranking was submitted
  static Future<bool> show(
    BuildContext context, {
    required String userId,
    required String userName,
    required List<ProfilePhoto> photos,
  }) async {
    if (photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This user has no photos to rank')),
      );
      return false;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhotoRankingSheet(
        userId: userId,
        userName: userName,
        photos: photos,
      ),
    );

    return result ?? false;
  }

  @override
  ConsumerState<PhotoRankingSheet> createState() => _PhotoRankingSheetState();
}

class _PhotoRankingSheetState extends ConsumerState<PhotoRankingSheet> {
  late List<ProfilePhoto> _rankedPhotos;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing rankings if available, or original order
    _rankedPhotos = List.from(widget.photos);
    _loadExistingRanking();
  }

  Future<void> _loadExistingRanking() async {
    final existing =
        await ref.read(existingRankingProvider(widget.userId).future);
    if (existing != null && mounted) {
      // Reorder photos based on existing ranking
      final rankings = Map.fromEntries(
        existing.rankings.entries.map((e) => MapEntry(e.key, e.value)),
      );

      setState(() {
        _rankedPhotos.sort((a, b) {
          final rankA = rankings[a.id] ?? 99;
          final rankB = rankings[b.id] ?? 99;
          return rankA.compareTo(rankB);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VesparaColors.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Rank ${widget.userName}\'s Photos',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Drag to reorder from best (1) to least preferred',
                    style: TextStyle(
                      fontSize: 14,
                      color: VesparaColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Ranking instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates,
                      color: VesparaColors.glow, size: 20,),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your ranking helps ${widget.userName} choose their best profile photo!',
                      style: const TextStyle(
                        fontSize: 12,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reorderable photo list
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _rankedPhotos.length,
                onReorder: _onReorder,
                proxyDecorator: (child, index, animation) => _AnimatedProxy(
                  animation: animation,
                  child: child,
                ),
                itemBuilder: (context, index) {
                  final photo = _rankedPhotos[index];
                  final rank = index + 1;

                  return _buildRankablePhotoTile(photo, rank,
                      key: ValueKey(photo.id),);
                },
              ),
            ),

            // Submit button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRanking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VesparaColors.glow,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Ranking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildRankablePhotoTile(ProfilePhoto photo, int rank,
      {required Key key,}) {
    final color = _getRankColor(rank);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: VesparaColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 48,
            height: 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Icon(
                  rank == 1
                      ? Icons.emoji_events
                      : (rank <= 3 ? Icons.thumb_up : Icons.thumbs_up_down),
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),

          // Photo
          Padding(
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photo.photoUrl,
                width: 80,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 84,
                  color: VesparaColors.surface,
                  child: const Icon(Icons.broken_image,
                      color: VesparaColors.secondary,),
                ),
              ),
            ),
          ),

          // Drag handle
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _getRankLabel(rank),
                style: const TextStyle(
                  fontSize: 13,
                  color: VesparaColors.secondary,
                ),
              ),
            ),
          ),

          // Drag indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.drag_handle,
              color: VesparaColors.secondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.blueGrey[300]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return VesparaColors.secondary;
    }
  }

  String _getRankLabel(int rank) {
    switch (rank) {
      case 1:
        return 'Best photo';
      case 2:
        return 'Great photo';
      case 3:
        return 'Good photo';
      case 4:
        return 'Okay photo';
      case 5:
        return 'Least preferred';
      default:
        return 'Rank $rank';
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _rankedPhotos.removeAt(oldIndex);
      _rankedPhotos.insert(newIndex, item);
    });
  }

  Future<void> _submitRanking() async {
    setState(() => _isSubmitting = true);

    // Build rankings map: photoId -> rank (1-based)
    final rankings = <String, int>{};
    final photoVersions = <String, int>{};
    for (var i = 0; i < _rankedPhotos.length; i++) {
      final photo = _rankedPhotos[i];
      rankings[photo.id] = i + 1;
      photoVersions[photo.id] = photo.version;
    }

    final success =
        await ref.read(profilePhotosProvider.notifier).submitRanking(
              rankedUserId: widget.userId,
              rankedPhotoIds: _rankedPhotos.map((p) => p.id).toList(),
              photoVersions: photoVersions,
            );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ranking submitted! Thanks for helping.'),
          backgroundColor: VesparaColors.glow,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit ranking. Please try again.'),
          backgroundColor: VesparaColors.error,
        ),
      );
    }
  }
}

/// Helper widget for animated proxy decorator
class _AnimatedProxy extends StatelessWidget {
  const _AnimatedProxy({
    required this.animation,
    this.child,
  });
  final Animation<double> animation;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final elevation = Tween<double>(begin: 0, end: 8).evaluate(animation);
    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(16),
      child: child,
    );
  }
}
