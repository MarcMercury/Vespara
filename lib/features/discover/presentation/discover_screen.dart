import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/models/discoverable_profile.dart';
import '../../../core/providers/connection_state_provider.dart'
    show
        connectionStateProvider,
        metAtEventsProvider,
        VesparaConnectionState,
        EventAttendee;
import '../../../core/providers/match_state_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Supabase client provider for discover screen
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// ════════════════════════════════════════════════════════════════════════════
/// DISCOVER SCREEN - Module 2
/// Swipe-based marketplace for potential matches
/// Features: Strict Match list, Loose Match list, AI wildcards
/// ════════════════════════════════════════════════════════════════════════════

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with TickerProviderStateMixin {
  late List<DiscoverableProfile> _profiles;
  int _currentIndex = 0;
  int _selectedTabIndex = 0; // 0 = Strict, 1 = Explore, 2 = Met IRL
  int _metIrlIndex = 0;

  // Animation controllers
  late AnimationController _cardController;
  late AnimationController _glowController;
  double _dragOffset = 0;
  double _dragRotation = 0;
  bool _isDragging = false;
  SwipeDirection? _pendingSwipe;
  bool _isLoadingProfiles = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _profiles = [];

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Load profiles from database
    _loadDiscoverProfiles();
  }

  Future<void> _loadDiscoverProfiles() async {
    try {
      setState(() {
        _isLoadingProfiles = true;
        _loadError = null;
      });

      final supabase = ref.read(supabaseClientProvider);
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        setState(() {
          _isLoadingProfiles = false;
          _loadError = 'Not logged in';
        });
        return;
      }

      // Get already-swiped profile IDs to exclude them
      final swipesResponse = await supabase
          .from('swipes')
          .select('swiped_id')
          .eq('swiper_id', currentUserId);
      
      final swipedIds = (swipesResponse as List)
          .map((s) => s['swiped_id'] as String)
          .toSet();

      // Fetch discoverable profiles (excluding current user and already swiped)
      final response = await supabase
          .from('profiles')
          .select('*')
          .eq('is_discoverable', true)
          .eq('onboarding_complete', true)
          .neq('id', currentUserId)
          .limit(50);

      final profiles = (response as List)
          .where((json) => !swipedIds.contains(json['id'])) // Filter out swiped profiles
          .map((json) {
            // Add avatar_url to photos array if photos is empty
            final photos = List<String>.from(json['photos'] ?? []);
            if (photos.isEmpty && json['avatar_url'] != null) {
              photos.add(json['avatar_url'] as String);
            }
            json['photos'] = photos;
            return DiscoverableProfile.fromJson(json);
          })
          .toList();

      setState(() {
        _profiles = profiles;
        _isLoadingProfiles = false;
        _currentIndex = 0; // Reset index when reloading
      });

      debugPrint('Discover: Loaded ${profiles.length} profiles (excluded ${swipedIds.length} already swiped)');
    } catch (e) {
      debugPrint('Discover: Error loading profiles: $e');
      setState(() {
        _isLoadingProfiles = false;
        _loadError = e.toString();
      });
    }
  }

  /// Get filtered profiles based on current tab
  /// For now, show all loaded profiles since filtering is done at query level
  List<DiscoverableProfile> get _filteredProfiles => _profiles
      .where(
        (p) => _selectedTabIndex == 1 ? p.isWildcard : p.isStrictMatch,
      )
      .toList();

  @override
  void dispose() {
    _cardController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onSwipe(SwipeDirection direction) async {
    final profiles = _filteredProfiles;
    if (_currentIndex >= profiles.length) return;

    final profile = profiles[_currentIndex];
    final matchNotifier = ref.read(matchStateProvider.notifier);

    // Advance to next card immediately for smooth UX
    setState(() {
      _currentIndex++;
      _dragOffset = 0;
      _dragRotation = 0;
    });

    // Process swipe action - now async and writes to database
    String message;

    switch (direction) {
      case SwipeDirection.left:
        await matchNotifier.passProfile(profile.id);
        message = 'Passed on ${profile.displayName}';
        break;
      case SwipeDirection.right:
        await matchNotifier.likeProfile(
            profile.id,
            profile.displayName ?? 'Someone',
            profile.photos.isNotEmpty ? profile.photos.first : null,
        );
        message = 'Liked ${profile.displayName}! 💜';
        break;
      case SwipeDirection.superLike:
        await matchNotifier.superLikeProfile(
            profile.id,
            profile.displayName ?? 'Someone',
            profile.photos.isNotEmpty ? profile.photos.first : null,
        );
        message = 'Super liked ${profile.displayName}! ⭐';
        break;
    }

    // Check if a match was created (by comparing match count before/after)
    final matchState = ref.read(matchStateProvider);
    final hasNewMatch = matchState.matches.any((m) => m.matchedUserId == profile.id);

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (hasNewMatch) ...[
                const Icon(Icons.favorite, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  hasNewMatch
                hasNewMatch
            ? SnackBarAction(
                label: 'Message',
                textColor: Colors.white,
                onPressed: () {
                  // Dismiss this snackbar and navigate to Wire
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  // TODO: Navigate to Wire with this match conversation
                },
              )
            : null,
        ),
      );
    }         label: 'Message',
                textColor: Colors.white,
                onPressed: () {
                  // Dismiss this snackbar and navigate to Wire
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  // TODO: Navigate to Wire with this match conversation
                },
              )
            : null,
      ),
    );

    setState(() {
      _currentIndex++;
      _dragOffset = 0;
      _dragRotation = 0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dx;
      _dragRotation = _dragOffset / 300 * 0.3; // Max ~17 degrees
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);

    if (_dragOffset.abs() > 100) {
      // Swipe threshold reached
      _onSwipe(_dragOffset > 0 ? SwipeDirection.right : SwipeDirection.left);
    } else {
      // Snap back
      setState(() {
        _dragOffset = 0;
        _dragRotation = 0;
      });
    }
  }

  // Filter state
  RangeValues _ageRange = const RangeValues(21, 45);
  double _maxDistance = 25;
  final Set<String> _selectedRelTypes = {
    'casual',
    'exploring',
    'ethicalNonMonogamy',
  };

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VesparaColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Discovery Filters',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,),),
              const SizedBox(height: 24),

              // Age Range
              Text(
                  'Age Range: ${_ageRange.start.toInt()} - ${_ageRange.end.toInt()}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.secondary,),),
              RangeSlider(
                values: _ageRange,
                min: 18,
                max: 65,
                divisions: 47,
                activeColor: VesparaColors.glow,
                onChanged: (v) {
                  setModalState(() => _ageRange = v);
                  setState(() => _ageRange = v);
                },
              ),

              // Distance
              const SizedBox(height: 16),
              Text('Max Distance: ${_maxDistance.toInt()} miles',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.secondary,),),
              Slider(
                value: _maxDistance,
                min: 1,
                max: 100,
                activeColor: VesparaColors.glow,
                onChanged: (v) {
                  setModalState(() => _maxDistance = v);
                  setState(() => _maxDistance = v);
                },
              ),

              // Relationship Types
              const SizedBox(height: 16),
              const Text('Looking For',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.secondary,),),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'casual',
                  'exploring',
                  'ethicalNonMonogamy',
                  'polyamory',
                  'monogamy',
                ].map((type) {
                  final selected = _selectedRelTypes.contains(type);
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        if (selected) {
                          _selectedRelTypes.remove(type);
                        } else {
                          _selectedRelTypes.add(type);
                        }
                      });
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8,),
                      decoration: BoxDecoration(
                        color: selected
                            ? VesparaColors.glow.withOpacity(0.2)
                            : VesparaColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? VesparaColors.glow
                                : VesparaColors.secondary.withOpacity(0.3),),
                      ),
                      child: Text(_formatType(type),
                          style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? VesparaColors.glow
                                  : VesparaColors.secondary,),),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Filters updated!'),
                        backgroundColor: VesparaColors.success,),);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: VesparaColors.glow,
                      foregroundColor: VesparaColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),),
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatType(String type) {
    switch (type) {
      case 'casual':
        return 'Casual';
      case 'exploring':
        return 'Exploring';
      case 'ethicalNonMonogamy':
        return 'ENM';
      case 'polyamory':
        return 'Poly';
      case 'monogamy':
        return 'Monogamy';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildMatchTypeToggle(),
              Expanded(
                child: _selectedTabIndex == 2
                    ? _buildMetIrlContent()
                    : _buildCardStack(),
              ),
              if (_selectedTabIndex != 2) ...[
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            Column(
              children: [
                const Text(
                  'DISCOVER',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: VesparaColors.primary,
                  ),
                ),
                Text(
                  '${_profiles.length - _currentIndex} profiles nearby',
                  style: const TextStyle(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _showFiltersDialog,
              icon: const Icon(Icons.tune, color: VesparaColors.secondary),
            ),
          ],
        ),
      );

  Widget _buildMatchTypeToggle() {
    final metIrlCount = ref.watch(metAtEventsProvider).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Strict Matches
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? VesparaColors.glow.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STRICT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: _selectedTabIndex == 0
                        ? VesparaColors.primary
                        : VesparaColors.secondary,
                  ),
                ),
              ),
            ),
          ),
          // Explore / AI Wildcards
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? VesparaColors.tagsYellow.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'EXPLORE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: _selectedTabIndex == 1
                            ? VesparaColors.tagsYellow
                            : VesparaColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: _selectedTabIndex == 1
                          ? VesparaColors.tagsYellow
                          : VesparaColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Met IRL
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 2
                      ? VesparaColors.success.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MET IRL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: _selectedTabIndex == 2
                            ? VesparaColors.success
                            : VesparaColors.secondary,
                      ),
                    ),
                    if (metIrlCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2,),
                        decoration: BoxDecoration(
                          color: VesparaColors.success,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$metIrlCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: VesparaColors.background,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    // Show loading state
    if (_isLoadingProfiles) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: VesparaColors.primary),
            SizedBox(height: 16),
            Text(
              'Finding matches...',
              style: TextStyle(color: VesparaColors.secondary),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: VesparaColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading profiles',
              style: const TextStyle(color: VesparaColors.error),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadDiscoverProfiles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredProfiles = _filteredProfiles;

    if (filteredProfiles.isEmpty || _currentIndex >= filteredProfiles.length) {
      return _buildEmptyState();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background cards (preview of next)
        if (_currentIndex + 1 < filteredProfiles.length)
          Transform.scale(
            scale: 0.9,
            child: Opacity(
              opacity: 0.5,
              child: _buildProfileCard(filteredProfiles[_currentIndex + 1],
                  isBackground: true,),
            ),
          ),

        // Current card
        GestureDetector(
          onPanUpdate: _onDragUpdate,
          onPanEnd: _onDragEnd,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Transform.rotate(
              angle: _dragRotation,
              child: Stack(
                children: [
                  _buildProfileCard(filteredProfiles[_currentIndex]),

                  // Swipe indicators
                  if (_dragOffset.abs() > 50)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _dragOffset > 0
                                ? VesparaColors.success
                                : VesparaColors.error,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: _dragOffset > 0 ? -0.3 : 0.3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _dragOffset > 0
                                      ? VesparaColors.success
                                      : VesparaColors.error,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _dragOffset > 0 ? 'LIKE' : 'PASS',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: _dragOffset > 0
                                      ? VesparaColors.success
                                      : VesparaColors.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(DiscoverableProfile profile,
          {bool isBackground = false,}) =>
      Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Photo background
              Positioned.fill(
                child: profile.photos.isNotEmpty
                    ? Image.network(
                        profile.photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholderPhoto(profile),
                      )
                    : _buildPlaceholderPhoto(profile),
              ),

              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        VesparaColors.background.withOpacity(0.8),
                        VesparaColors.background,
                      ],
                      stops: const [0.0, 0.4, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // Wildcard badge
              if (profile.isWildcard)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: VesparaColors.tagsYellow.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: Colors.black),
                        SizedBox(width: 4),
                        Text(
                          'AI PICK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Compatibility score
              Positioned(
                top: 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VesparaColors.surface.withOpacity(0.9),
                      border: Border.all(
                        color: VesparaColors.glow
                            .withOpacity(0.3 + _glowController.value * 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VesparaColors.glow
                              .withOpacity(0.2 + _glowController.value * 0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      '${(profile.compatibilityScore * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ),
                ),
              ),

              // Profile info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and age
                      Row(
                        children: [
                          Text(
                            '${profile.displayName ?? "?"}, ${profile.age ?? "?"}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: VesparaColors.primary,
                            ),
                          ),
                          if (profile.isVerified) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified,
                              color: VesparaColors.glow,
                              size: 24,
                            ),
                          ],
                        ],
                      ),

                      // Headline
                      if (profile.headline != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            profile.headline!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: VesparaColors.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      // Location and distance
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: VesparaColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${profile.location ?? "Unknown"} • ${profile.distanceKm?.toStringAsFixed(1) ?? "?"} km',
                              style: const TextStyle(
                                fontSize: 12,
                                color: VesparaColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Occupation
                      if (profile.occupation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.work_outline,
                                size: 14,
                                color: VesparaColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${profile.occupation}${profile.company != null ? " at ${profile.company}" : ""}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: VesparaColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Relationship types
                      if (profile.relationshipTypes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.relationshipTypes
                                .map(
                                  (type) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          VesparaColors.glow.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            VesparaColors.glow.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _formatRelationshipType(type),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: VesparaColors.glow,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                      // Prompts preview
                      if (profile.prompts.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: VesparaColors.surface.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.prompts.first.question,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: VesparaColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.prompts.first.answer,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: VesparaColors.primary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                      // Wildcard reason
                      if (profile.isWildcard && profile.wildcardReason != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: VesparaColors.tagsYellow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: VesparaColors.tagsYellow.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                size: 14,
                                color: VesparaColors.tagsYellow,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  profile.wildcardReason!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: VesparaColors.tagsYellow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPlaceholderPhoto(DiscoverableProfile profile) => ColoredBox(
        color: VesparaColors.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 80,
                color: VesparaColors.glow.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                profile.displayName?[0].toUpperCase() ?? '?',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: VesparaColors.glow.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildActionButtons() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pass button
            _buildActionButton(
              icon: Icons.close,
              color: VesparaColors.error,
              size: 60,
              onTap: () => _onSwipe(SwipeDirection.left),
            ),

            // Super Like button
            _buildActionButton(
              icon: Icons.star,
              color: VesparaColors.tagsYellow,
              size: 48,
              onTap: () => _onSwipe(SwipeDirection.superLike),
            ),

            // Like button
            _buildActionButton(
              icon: Icons.favorite,
              color: VesparaColors.success,
              size: 60,
              onTap: () => _onSwipe(SwipeDirection.right),
            ),
          ],
        ),
      );

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VesparaColors.surface,
              border: Border.all(
                color: color.withOpacity(0.3 + _glowController.value * 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: size * 0.5,
            ),
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_off,
                size: 80,
                color: VesparaColors.glow.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              const Text(
                'No more profiles',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check back later or adjust your filters to discover more connections.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentIndex = 0);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Start Over'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow,
                  foregroundColor: VesparaColors.background,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  String _formatRelationshipType(String type) {
    switch (type) {
      case 'casual':
        return 'Casual';
      case 'exploring':
        return 'Exploring';
      case 'ethicalNonMonogamy':
        return 'ENM';
      case 'polyamory':
        return 'Poly';
      case 'monogamy':
        return 'Monogamy';
      default:
        return type;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MET IRL TAB - People from shared events
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMetIrlContent() {
    final metIrlAttendees = ref.watch(metAtEventsProvider);
    final connectionState = ref.watch(connectionStateProvider);

    if (metIrlAttendees.isEmpty) {
      return _buildMetIrlEmptyState();
    }

    return Column(
      children: [
        // Header info
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VesparaColors.success.withOpacity(0.1),
                VesparaColors.glow.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: VesparaColors.success.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VesparaColors.success.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people,
                  color: VesparaColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'People you\'ve met',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
                    Text(
                      '${metIrlAttendees.length} from past events',
                      style: const TextStyle(
                        fontSize: 13,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Swipeable cards
        Expanded(
          child: _metIrlIndex < metIrlAttendees.length
              ? _buildMetIrlCard(metIrlAttendees[_metIrlIndex], connectionState)
              : _buildMetIrlDoneState(),
        ),

        // Action buttons
        if (_metIrlIndex < metIrlAttendees.length)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetIrlActionButton(
                  icon: Icons.close,
                  label: 'Skip',
                  color: VesparaColors.secondary,
                  onTap: () {
                    setState(() => _metIrlIndex++);
                  },
                ),
                _buildMetIrlActionButton(
                  icon: Icons.waving_hand,
                  label: 'Say Hi',
                  color: VesparaColors.success,
                  isPrimary: true,
                  onTap: () {
                    final attendee = metIrlAttendees[_metIrlIndex];
                    // Find the event they attended
                    String? eventName;
                    String? eventId;
                    for (final event in connectionState.events) {
                      if (event.attendees
                          .any((a) => a.userId == attendee.userId)) {
                        eventName = event.title;
                        eventId = event.id;
                        break;
                      }
                    }

                    ref.read(connectionStateProvider.notifier).connectViaEvent(
                          attendee.userId,
                          attendee.name,
                          attendee.avatar,
                          eventId ?? '',
                          eventName,
                        );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.favorite,
                                color: VesparaColors.success,),
                            const SizedBox(width: 12),
                            Text('Connected with ${attendee.name}!'),
                          ],
                        ),
                        backgroundColor: VesparaColors.surface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );

                    setState(() => _metIrlIndex++);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMetIrlCard(
      EventAttendee attendee, VesparaConnectionState connectionState,) {
    // Find event details for this attendee
    String? eventName;
    DateTime? eventDate;
    for (final event in connectionState.events) {
      if (event.attendees.any((a) => a.userId == attendee.userId)) {
        eventName = event.title;
        eventDate = event.startTime;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: VesparaColors.success.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: VesparaColors.success.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VesparaColors.glow.withOpacity(0.3),
                    VesparaColors.primary.withOpacity(0.3),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar placeholder
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VesparaColors.background,
                        border: Border.all(
                          color: VesparaColors.success,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: VesparaColors.success.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          attendee.name.isNotEmpty
                              ? attendee.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: VesparaColors.success,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      attendee.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Event info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: VesparaColors.background.withOpacity(0.5),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Column(
              children: [
                // Met at badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: VesparaColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: VesparaColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event,
                        color: VesparaColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Met at ${eventName ?? "an event"}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: VesparaColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                if (eventDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatEventDate(eventDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetIrlActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: isPrimary ? 72 : 56,
              height: isPrimary ? 72 : 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPrimary ? color : VesparaColors.surface,
                border: isPrimary
                    ? null
                    : Border.all(
                        color: color.withOpacity(0.3),
                        width: 2,
                      ),
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isPrimary ? VesparaColors.background : color,
                size: isPrimary ? 32 : 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _buildMetIrlEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: VesparaColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available,
                  size: 64,
                  color: VesparaColors.glow.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No event connections yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Attend events to meet people IRL!\nAfter the event, you can connect with\npeople you\'ve met here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Would navigate to events/group screen
                },
                icon: const Icon(Icons.search),
                label: const Text('Find Events'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.success,
                  foregroundColor: VesparaColors.background,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMetIrlDoneState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [VesparaColors.success, VesparaColors.glow],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 48,
                  color: VesparaColors.background,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'All caught up!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You\'ve reviewed everyone from your events.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  setState(() => _metIrlIndex = 0);
                },
                child: const Text(
                  'Start Over',
                  style: TextStyle(
                    color: VesparaColors.glow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else {
      return '${(diff.inDays / 30).floor()} months ago';
    }
  }
}
