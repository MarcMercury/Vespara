import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/data/vespara_mock_data.dart';
import '../../../core/domain/models/tags_game.dart';
import 'ice_breakers_screen.dart';
import 'velvet_rope_screen.dart';
import 'down_to_clown_screen.dart';
import 'path_of_pleasure_screen.dart';
import 'lane_of_lust_screen.dart';
import 'drama_sutra_screen.dart';
import 'flash_freeze_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TAG - Module 8 (Adult Games)
/// Directory of games for 2+ players
/// Ice breakers, conversation starters, and... more 🔥
/// ════════════════════════════════════════════════════════════════════════════

class TagScreen extends ConsumerStatefulWidget {
  const TagScreen({super.key});

  @override
  ConsumerState<TagScreen> createState() => _TagScreenState();
}

class _TagScreenState extends ConsumerState<TagScreen> {
  late List<TagsGame> _games;
  GameCategory? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    _games = MockDataProvider.tagsGames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryFilter(),
            Expanded(child: _buildGamesList()),
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
            icon: const Icon(VesparaIcons.back, color: VesparaColors.primary),
          ),
          Column(
            children: [
              Text(
                'TAG',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: VesparaColors.tagsYellow,
                ),
              ),
              Text(
                "You're It 🎯",
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showRandomGame(),
            icon: const Icon(VesparaIcons.random, color: VesparaColors.tagsYellow),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildCategoryChip(null, 'All', VesparaIcons.games, VesparaColors.glow),
          ...GameCategory.values.map((cat) => _buildCategoryChip(
            cat,
            cat.displayName,
            _getCategoryIcon(cat),
            _getCategoryColor(cat),
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(GameCategory? category, String name, IconData icon, Color color) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : VesparaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : VesparaColors.glow.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : VesparaColors.secondary),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : VesparaColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesList() {
    final filteredGames = _selectedCategory == null
        ? _games
        : _games.where((g) => g.category == _selectedCategory).toList();
    
    if (filteredGames.isEmpty) {
      return _buildEmptyState();
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: smaller screens get taller cards
        final screenWidth = constraints.maxWidth;
        final aspectRatio = screenWidth < 360 ? 0.75 : 0.85;
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredGames.length,
          itemBuilder: (context, index) => _buildGameCard(filteredGames[index]),
        );
      },
    );
  }

  Widget _buildGameCard(TagsGame game) {
    final categoryColor = _getCategoryColor(game.category);
    
    return GestureDetector(
      onTap: () => _showGameDetails(game),
      child: Container(
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.1)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon + Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(game.category),
                          color: categoryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          game.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Rating badges - wrap to handle overflow
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _buildRatingBadge(
                        '🏎️',
                        game.category.velocityLabel,
                        const Color(0xFFFF6B6B),
                      ),
                      _buildRatingBadge(
                        '🔥',
                        game.category.heatRating,
                        const Color(0xFFFF9500),
                      ),
                      _buildRatingBadge(
                        '⏱️',
                        game.category.durationLabel == 'Full Session' ? 'Full' : game.category.durationLabel,
                        const Color(0xFF5AC8FA),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Player count at bottom
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(VesparaIcons.group, size: 10, color: categoryColor),
                        const SizedBox(width: 3),
                        Text(
                          '${game.category.minPlayers}-${game.category.maxPlayers}',
                          style: TextStyle(fontSize: 9, color: categoryColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Category badge
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  game.currentConsentLevel.displayName,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: VesparaColors.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            VesparaIcons.games,
            size: 80,
            color: VesparaColors.tagsYellow.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No games in this category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different category',
            style: TextStyle(
              fontSize: 14,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(GameCategory category) {
    switch (category) {
      case GameCategory.downToClown:
        return Icons.sentiment_very_satisfied_rounded; // 🤡 Clown/guessing
      case GameCategory.icebreakers:
        return Icons.ac_unit_rounded; // ❄️ Ice
      case GameCategory.velvetRope:
        return Icons.theater_comedy_rounded; // 🎭 Share or Dare
      case GameCategory.pathOfPleasure:
        return Icons.leaderboard_rounded; // 📊 Ranking game
      case GameCategory.laneOfLust:
        return Icons.whatshot_rounded; // 🔥 Desire intensity
      case GameCategory.dramaSutra:
        return Icons.accessibility_new_rounded; // 🧘 Poses
      case GameCategory.flashFreeze:
        return Icons.flash_on_rounded; // ⚡ Flash
    }
  }

  Color _getCategoryColor(GameCategory category) {
    switch (category.minimumConsentLevel) {
      case ConsentLevel.green:
        return Colors.lightBlue;
      case ConsentLevel.yellow:
        return Colors.orange;
      case ConsentLevel.red:
        return VesparaColors.error;
    }
  }

  void _showGameDetails(TagsGame game) {
    final categoryColor = _getCategoryColor(game.category);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
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
                const SizedBox(height: 24),
                
                // Header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getCategoryIcon(game.category),
                        color: categoryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: VesparaColors.primary,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  game.category.displayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                game.currentConsentLevel.emoji,
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                game.currentConsentLevel.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: VesparaColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Description
                Text(
                  game.description ?? game.category.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: VesparaColors.primary,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Info cards
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Players',
                        '${game.category.minPlayers}-${game.category.maxPlayers}',
                        VesparaIcons.group,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        'Level',
                        game.currentConsentLevel.displayName,
                        VesparaIcons.fire,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Start button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startGame(game);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: categoryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(VesparaIcons.play),
                        const SizedBox(width: 8),
                        Text(
                          'Start Game',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VesparaColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: VesparaColors.glow),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showRandomGame() {
    if (_games.isEmpty) return;
    final randomGame = _games[DateTime.now().millisecond % _games.length];
    _showGameDetails(randomGame);
  }

  void _startGame(TagsGame game) {
    // Navigate to the appropriate game screen based on category
    switch (game.category) {
      case GameCategory.downToClown:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DownToClownScreen()),
        );
        break;
      case GameCategory.icebreakers:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IceBreakersScreen()),
        );
        break;
      case GameCategory.velvetRope:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VelvetRopeScreen()),
        );
        break;
      case GameCategory.pathOfPleasure:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PathOfPleasureScreen()),
        );
        break;
      case GameCategory.laneOfLust:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LaneOfLustScreen()),
        );
        break;
      case GameCategory.dramaSutra:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DramaSutraScreen()),
        );
        break;
      case GameCategory.flashFreeze:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FlashFreezeScreen()),
        );
        break;
    }
  }
}
