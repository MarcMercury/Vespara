import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';
import '../../../core/data/vespara_mock_data.dart';
import '../../../core/domain/models/discoverable_profile.dart';
import '../../../core/providers/match_state_provider.dart';

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
  bool _showLooseMatches = false;
  
  // Animation controllers
  late AnimationController _cardController;
  late AnimationController _glowController;
  double _dragOffset = 0;
  double _dragRotation = 0;
  bool _isDragging = false;
  SwipeDirection? _pendingSwipe;

  @override
  void initState() {
    super.initState();
    _profiles = MockDataProvider.discoverProfiles;
    
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onSwipe(SwipeDirection direction) {
    if (_currentIndex >= _profiles.length) return;
    
    final profile = _profiles[_currentIndex];
    final matchNotifier = ref.read(matchStateProvider.notifier);
    
    // Process swipe action and update global state
    String message;
    bool isMatch = false;
    
    switch (direction) {
      case SwipeDirection.left:
        matchNotifier.passProfile(profile.id);
        message = 'Passed on ${profile.displayName}';
        break;
      case SwipeDirection.right:
        // Check for mutual match (simulated - 50% chance)
        isMatch = DateTime.now().millisecond % 2 == 0;
        matchNotifier.likeProfile(profile.id, profile.displayName, profile.photos.isNotEmpty ? profile.photos.first : null);
        message = isMatch 
            ? "It's a match with ${profile.displayName}! 💜" 
            : 'Liked ${profile.displayName}! 💜';
        break;
      case SwipeDirection.superLike:
        matchNotifier.superLikeProfile(profile.id, profile.displayName, profile.photos.isNotEmpty ? profile.photos.first : null);
        message = "Super Match with ${profile.displayName}! ⭐";
        isMatch = true;
        break;
    }
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isMatch) ...[
              const Icon(Icons.favorite, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: isMatch ? 3 : 1),
        backgroundColor: isMatch 
            ? VesparaColors.success 
            : (direction == SwipeDirection.left ? VesparaColors.surface : VesparaColors.glow.withOpacity(0.9)),
        action: isMatch ? SnackBarAction(
          label: 'Message',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to chat
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening chat...'), duration: Duration(seconds: 1)),
            );
          },
        ) : null,
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
  Set<String> _selectedRelTypes = {'casual', 'exploring', 'ethicalNonMonogamy'};

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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: VesparaColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Discovery Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
              const SizedBox(height: 24),
              
              // Age Range
              Text('Age Range: ${_ageRange.start.toInt()} - ${_ageRange.end.toInt()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: VesparaColors.secondary)),
              RangeSlider(
                values: _ageRange,
                min: 18, max: 65,
                divisions: 47,
                activeColor: VesparaColors.glow,
                onChanged: (v) { setModalState(() => _ageRange = v); setState(() => _ageRange = v); },
              ),
              
              // Distance
              const SizedBox(height: 16),
              Text('Max Distance: ${_maxDistance.toInt()} miles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: VesparaColors.secondary)),
              Slider(
                value: _maxDistance,
                min: 1, max: 100,
                activeColor: VesparaColors.glow,
                onChanged: (v) { setModalState(() => _maxDistance = v); setState(() => _maxDistance = v); },
              ),
              
              // Relationship Types
              const SizedBox(height: 16),
              Text('Looking For', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: VesparaColors.secondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ['casual', 'exploring', 'ethicalNonMonogamy', 'polyamory', 'monogamy'].map((type) {
                  final selected = _selectedRelTypes.contains(type);
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        if (selected) { _selectedRelTypes.remove(type); } else { _selectedRelTypes.add(type); }
                      });
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? VesparaColors.glow.withOpacity(0.2) : VesparaColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? VesparaColors.glow : VesparaColors.secondary.withOpacity(0.3)),
                      ),
                      child: Text(_formatType(type), style: TextStyle(fontSize: 13, color: selected ? VesparaColors.glow : VesparaColors.secondary)),
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Filters updated!'), backgroundColor: VesparaColors.success));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: VesparaColors.glow, foregroundColor: VesparaColors.background, padding: const EdgeInsets.symmetric(vertical: 16)),
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
      case 'casual': return 'Casual';
      case 'exploring': return 'Exploring';
      case 'ethicalNonMonogamy': return 'ENM';
      case 'polyamory': return 'Poly';
      case 'monogamy': return 'Monogamy';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMatchTypeToggle(),
            Expanded(child: _buildCardStack()),
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
              Text(
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
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showFiltersDialog(),
            icon: const Icon(Icons.tune, color: VesparaColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTypeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showLooseMatches = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showLooseMatches 
                      ? VesparaColors.glow.withOpacity(0.2) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'STRICT MATCHES',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: !_showLooseMatches 
                        ? VesparaColors.primary 
                        : VesparaColors.secondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showLooseMatches = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showLooseMatches 
                      ? VesparaColors.tagsYellow.withOpacity(0.2) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'EXPLORE ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: _showLooseMatches 
                            ? VesparaColors.tagsYellow 
                            : VesparaColors.secondary,
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: _showLooseMatches 
                          ? VesparaColors.tagsYellow 
                          : VesparaColors.secondary,
                    ),
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
    final filteredProfiles = _profiles.where((p) => 
        _showLooseMatches ? p.isWildcard : p.isStrictMatch
    ).toList();
    
    if (_currentIndex >= _profiles.length) {
      return _buildEmptyState();
    }
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background cards (preview of next)
        if (_currentIndex + 1 < _profiles.length)
          Transform.scale(
            scale: 0.9,
            child: Opacity(
              opacity: 0.5,
              child: _buildProfileCard(_profiles[_currentIndex + 1], isBackground: true),
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
                  _buildProfileCard(_profiles[_currentIndex]),
                  
                  // Swipe indicators
                  if (_dragOffset.abs() > 50)
                    Positioned.fill(
                      child: Container(
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

  Widget _buildProfileCard(DiscoverableProfile profile, {bool isBackground = false}) {
    return Container(
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
                      errorBuilder: (_, __, ___) => _buildPlaceholderPhoto(profile),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: VesparaColors.tagsYellow.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: Colors.black),
                      const SizedBox(width: 4),
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
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VesparaColors.surface.withOpacity(0.9),
                      border: Border.all(
                        color: VesparaColors.glow.withOpacity(0.3 + _glowController.value * 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VesparaColors.glow.withOpacity(0.2 + _glowController.value * 0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      '${(profile.compatibilityScore * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: VesparaColors.primary,
                      ),
                    ),
                  );
                },
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
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: VesparaColors.primary,
                          ),
                        ),
                        if (profile.isVerified) ...[
                          const SizedBox(width: 8),
                          Icon(
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
                          style: TextStyle(
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
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: VesparaColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.location ?? "Unknown"} • ${profile.distanceKm?.toStringAsFixed(1) ?? "?"} km',
                            style: TextStyle(
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
                            Icon(
                              Icons.work_outline,
                              size: 14,
                              color: VesparaColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${profile.occupation}${profile.company != null ? " at ${profile.company}" : ""}',
                              style: TextStyle(
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
                          children: profile.relationshipTypes.map((type) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, 
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: VesparaColors.glow.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: VesparaColors.glow.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _formatRelationshipType(type),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: VesparaColors.glow,
                                ),
                              ),
                            );
                          }).toList(),
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
                              style: TextStyle(
                                fontSize: 11,
                                color: VesparaColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.prompts.first.answer,
                              style: TextStyle(
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
                            Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color: VesparaColors.tagsYellow,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                profile.wildcardReason!,
                                style: TextStyle(
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
  }

  Widget _buildPlaceholderPhoto(DiscoverableProfile profile) {
    return Container(
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
  }

  Widget _buildActionButtons() {
    return Padding(
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
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
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
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            Text(
              'No more profiles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
