import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/models/discoverable_profile.dart';
import '../../../core/providers/match_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/premium_effects.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// BROWSE SCREEN — Member Directory
/// Grid-based member browsing for the members-only community.
/// Replaces the swipe-based Discover screen.
/// ════════════════════════════════════════════════════════════════════════════

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  List<DiscoverableProfile> _members = [];
  bool _isLoading = true;
  String? _error;
  bool _isGridView = true;

  // Filters
  RangeValues _ageRange = const RangeValues(21, 55);
  double _maxDistance = 50;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Not logged in';
        });
        return;
      }

      // Fetch approved member profiles
      final response = await supabase
          .from('profiles')
          .select('*')
          .eq('onboarding_complete', true)
          .neq('id', currentUserId)
          .order('created_at', ascending: false)
          .limit(200);

      final members = (response as List).map((json) {
        final photos = List<String>.from(json['photos'] ?? []);
        if (photos.isEmpty && json['avatar_url'] != null) {
          photos.add(json['avatar_url'] as String);
        }
        json['photos'] = photos;
        return DiscoverableProfile.fromJson(json);
      }).toList();

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Browse: Error loading members: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  List<DiscoverableProfile> get _filteredMembers {
    var results = _members;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((m) {
        final name = (m.displayName ?? '').toLowerCase();
        final location = (m.location ?? '').toLowerCase();
        final headline = (m.headline ?? '').toLowerCase();
        return name.contains(query) ||
            location.contains(query) ||
            headline.contains(query);
      }).toList();
    }

    // Apply age filter
    results = results.where((m) {
      if (m.age == null) return true;
      return m.age! >= _ageRange.start && m.age! <= _ageRange.end;
    }).toList();

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: VesparaAnimatedBackground(
        enableParticles: true,
        particleCount: 14,
        auroraIntensity: 0.6,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            Expanded(
              child: Column(
                children: [
                  VesparaNeonText(
                    text: 'BROWSE',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: VesparaColors.primary,
                    ),
                    glowColor: const Color(0xFFFF6B9D),
                    glowRadius: 12,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_filteredMembers.length} members',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  icon: Icon(
                    _isGridView ? Icons.view_list : Icons.grid_view,
                    color: VesparaColors.secondary,
                  ),
                ),
                IconButton(
                  onPressed: _showFiltersDialog,
                  icon:
                      const Icon(Icons.tune, color: VesparaColors.secondary),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: VesparaColors.primary),
          decoration: InputDecoration(
            hintText: 'Search members...',
            hintStyle: TextStyle(
              color: VesparaColors.secondary.withOpacity(0.5),
            ),
            prefixIcon: const Icon(Icons.search, color: VesparaColors.secondary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(Icons.clear, color: VesparaColors.secondary),
                  )
                : null,
            filled: true,
            fillColor: VesparaColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VesparaColors.glow),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: VesparaColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Error loading members',
                style: const TextStyle(color: VesparaColors.error)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadMembers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final members = _filteredMembers;

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: VesparaColors.glow.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'No members found',
              style: TextStyle(
                fontSize: 18,
                color: VesparaColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Try a different search',
                style: TextStyle(color: VesparaColors.secondary),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: VesparaColors.glow,
      child: _isGridView ? _buildGrid(members) : _buildList(members),
    );
  }

  Widget _buildGrid(List<DiscoverableProfile> members) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) => _buildGridCard(members[index]),
    );
  }

  Widget _buildGridCard(DiscoverableProfile member) => GestureDetector(
        onTap: () => _showMemberProfile(member),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo with swipeable carousel for multiple photos
                if (member.photos.length > 1)
                  _MiniPhotoCarousel(photos: member.photos)
                else if (member.photos.isNotEmpty)
                  Image.network(
                    member.photos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildPlaceholder(member),
                  )
                else
                  _buildPlaceholder(member),

                // Gradient overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        VesparaColors.background.withOpacity(0.65),
                        VesparaColors.background.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),

                // Like button
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildLikeButton(member),
                ),

                // Photo count indicator
                if (member.photos.length > 1)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: VesparaColors.background.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library, size: 10, color: Colors.white70),
                          const SizedBox(width: 3),
                          Text('${member.photos.length}',
                              style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),

                // Info overlay
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${member.displayName ?? "?"}, ${member.age ?? "?"}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: VesparaColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.isVerified)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified,
                                  color: VesparaColors.glow, size: 15),
                            ),
                        ],
                      ),
                      if (member.headline != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            member.headline!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: VesparaColors.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (member.location != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 10, color: VesparaColors.accentCyan),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  member.location!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: VesparaColors.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Tags preview
                      if (member.relationshipTypes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            children: member.relationshipTypes.take(2).map((t) =>
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: VesparaColors.glow.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(t,
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      color: VesparaColors.glow,
                                    )),
                              ),
                            ).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildList(List<DiscoverableProfile> members) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) => _buildListTile(members[index]),
    );
  }

  Widget _buildListTile(DiscoverableProfile member) => GestureDetector(
        onTap: () => _showMemberProfile(member),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VesparaColors.glow.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: member.photos.isNotEmpty
                      ? Image.network(member.photos.first, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(member))
                      : _buildPlaceholder(member),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${member.displayName ?? "?"}, ${member.age ?? "?"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.primary,
                          ),
                        ),
                        if (member.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              color: VesparaColors.glow, size: 16),
                        ],
                      ],
                    ),
                    if (member.headline != null)
                      Text(
                        member.headline!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: VesparaColors.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (member.location != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: VesparaColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              member.location!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: VesparaColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              _buildLikeButton(member),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: VesparaColors.secondary),
            ],
          ),
        ),
      );

  Widget _buildPlaceholder(DiscoverableProfile member) => ColoredBox(
        color: VesparaColors.surface,
        child: Center(
          child: Text(
            (member.displayName ?? '?')[0].toUpperCase(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: VesparaColors.glow.withOpacity(0.5),
            ),
          ),
        ),
      );

  Widget _buildLikeButton(DiscoverableProfile member) {
    final matchState = ref.watch(matchStateProvider);
    final isLiked = matchState.likedProfiles.contains(member.id) ||
        matchState.superLikedProfiles.contains(member.id);
    final isMatched = matchState.matches.any((m) => m.matchedUserId == member.id);

    return GestureDetector(
      onTap: isLiked || isMatched
          ? null
          : () {
              ref.read(matchStateProvider.notifier).likeProfile(
                    member.id,
                    member.displayName ?? 'Unknown',
                    member.photos.isNotEmpty ? member.photos.first : null,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Liked ${member.displayName ?? "member"}!'),
                  backgroundColor: VesparaColors.accentRose,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isMatched
              ? VesparaColors.glow.withOpacity(0.2)
              : isLiked
                  ? VesparaColors.accentRose.withOpacity(0.2)
                  : VesparaColors.background.withOpacity(0.6),
          border: Border.all(
            color: isMatched
                ? VesparaColors.glow.withOpacity(0.5)
                : isLiked
                    ? VesparaColors.accentRose.withOpacity(0.5)
                    : VesparaColors.secondary.withOpacity(0.3),
          ),
        ),
        child: Icon(
          isMatched
              ? Icons.people
              : isLiked
                  ? Icons.favorite
                  : Icons.favorite_border,
          size: 18,
          color: isMatched
              ? VesparaColors.glow
              : isLiked
                  ? VesparaColors.accentRose
                  : VesparaColors.secondary,
        ),
      ),
    );
  }

  void _showMemberProfile(DiscoverableProfile member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: VesparaColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Pull handle
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

              // Photo
              if (member.photos.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 0.8,
                    child: Image.network(
                      member.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: VesparaColors.surface,
                        child: const Icon(Icons.person,
                            size: 80, color: VesparaColors.secondary),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Name & age
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${member.displayName ?? "?"}, ${member.age ?? "?"}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ),
                  if (member.isVerified)
                    const Icon(Icons.verified,
                        color: VesparaColors.glow, size: 24),
                ],
              ),

              // Headline
              if (member.headline != null) ...[
                const SizedBox(height: 4),
                Text(
                  member.headline!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: VesparaColors.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Location & occupation
              const SizedBox(height: 12),
              if (member.location != null)
                _profileDetailRow(Icons.location_on, member.location!),
              if (member.occupation != null)
                _profileDetailRow(
                  Icons.work_outline,
                  '${member.occupation}${member.company != null ? " at ${member.company}" : ""}',
                ),
              if (member.education != null)
                _profileDetailRow(Icons.school, member.education!),

              // Bio
              if (member.bio != null) ...[
                const SizedBox(height: 20),
                Text(
                  member.bio!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: VesparaColors.primary,
                    height: 1.5,
                  ),
                ),
              ],

              // Prompts
              if (member.prompts.isNotEmpty) ...[
                const SizedBox(height: 24),
                ...member.prompts.map((prompt) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VesparaColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prompt.question,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            prompt.answer,
                            style: const TextStyle(
                              fontSize: 15,
                              color: VesparaColors.primary,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              // Relationship types
              if (member.relationshipTypes.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: member.relationshipTypes
                      .map((type) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: VesparaColors.glow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: VesparaColors.glow.withOpacity(0.3)),
                            ),
                            child: Text(
                              _formatType(type),
                              style: const TextStyle(
                                fontSize: 12,
                                color: VesparaColors.glow,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],

              // Gallery
              if (member.photos.length > 1) ...[
                const SizedBox(height: 24),
                const Text(
                  'Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: member.photos.length - 1,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          member.photos[index + 1],
                          width: 100,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            color: VesparaColors.surface,
                            child: const Icon(Icons.image,
                                color: VesparaColors.secondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Like action button
              const SizedBox(height: 24),
              _buildProfileSheetLikeButton(member),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSheetLikeButton(DiscoverableProfile member) {
    final matchState = ref.watch(matchStateProvider);
    final isLiked = matchState.likedProfiles.contains(member.id) ||
        matchState.superLikedProfiles.contains(member.id);
    final isMatched = matchState.matches.any((m) => m.matchedUserId == member.id);

    if (isMatched) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: VesparaColors.glow.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, color: VesparaColors.glow, size: 20),
            SizedBox(width: 8),
            Text(
              'In Your Sanctum',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: VesparaColors.glow,
              ),
            ),
          ],
        ),
      );
    }

    if (isLiked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: VesparaColors.accentRose.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.accentRose.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: VesparaColors.accentRose, size: 20),
            SizedBox(width: 8),
            Text(
              'Like Sent — Waiting for them',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: VesparaColors.accentRose,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ref.read(matchStateProvider.notifier).likeProfile(
                member.id,
                member.displayName ?? 'Unknown',
                member.photos.isNotEmpty ? member.photos.first : null,
              );
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Liked ${member.displayName ?? "member"}!'),
              backgroundColor: VesparaColors.accentRose,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.favorite, size: 20),
        label: const Text('Like This Person'),
        style: ElevatedButton.styleFrom(
          backgroundColor: VesparaColors.accentRose,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _profileDetailRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: VesparaColors.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
            ),
          ],
        ),
      );

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
              Text(
                'Browse Filters',
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),

              // Age Range
              Text(
                'Age Range: ${_ageRange.start.toInt()} - ${_ageRange.end.toInt()}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.secondary,
                ),
              ),
              RangeSlider(
                values: _ageRange,
                min: 18,
                max: 65,
                divisions: 47,
                activeColor: VesparaColors.accentRose,
                onChanged: (v) {
                  setModalState(() => _ageRange = v);
                  setState(() => _ageRange = v);
                },
              ),

              // Distance
              const SizedBox(height: 16),
              Text(
                'Max Distance: ${_maxDistance.toInt()} miles',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.secondary,
                ),
              ),
              Slider(
                value: _maxDistance,
                min: 1,
                max: 200,
                activeColor: VesparaColors.accentRose,
                onChanged: (v) {
                  setModalState(() => _maxDistance = v);
                  setState(() => _maxDistance = v);
                },
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadMembers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.accentRose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini Photo Carousel for Browse grid cards
class _MiniPhotoCarousel extends StatefulWidget {
  const _MiniPhotoCarousel({required this.photos});
  final List<String> photos;

  @override
  State<_MiniPhotoCarousel> createState() => _MiniPhotoCarouselState();
}

class _MiniPhotoCarouselState extends State<_MiniPhotoCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < 0 &&
              _currentIndex < widget.photos.length - 1) {
            setState(() => _currentIndex++);
          } else if (details.primaryVelocity! > 0 && _currentIndex > 0) {
            setState(() => _currentIndex--);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Image.network(
                widget.photos[_currentIndex],
                key: ValueKey(_currentIndex),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: VesparaColors.surface,
                  child: const Icon(Icons.broken_image,
                      color: VesparaColors.inactive),
                ),
              ),
            ),
            // Photo indicators at top
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              child: Row(
                children: List.generate(
                  widget.photos.length.clamp(0, 6),
                  (i) => Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: i == _currentIndex
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
