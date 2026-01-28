import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/tag_rating.dart';
import '../../../core/domain/models/tags_game.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vespara_icons.dart';
import '../widgets/tag_rating_display.dart';
import 'dice_breakers_screen.dart';
import 'down_to_clown_screen.dart';
import 'drama_sutra_screen.dart';
import 'flash_freeze_screen.dart';
import 'ice_breakers_screen.dart';
import 'lane_of_lust_screen.dart';
import 'path_of_pleasure_screen.dart';
import 'share_or_dare_screen.dart';

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
  List<TagsGame> _games = [];
  GameCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Populate games - these are core game modes, not mock data
    _games = [
      const TagsGame(
        id: 'dtc',
        title: 'Down to Clown',
        category: GameCategory.downToClown,
        description: 'Charades meets guessing game',
        minPlayers: 4,
        maxPlayers: 20,
      ),
      const TagsGame(
        id: 'icebreakers',
        title: 'Ice Breakers',
        category: GameCategory.icebreakers,
        description: 'Get to know each other with fun prompts',
      ),
      const TagsGame(
        id: 'velvet',
        title: 'Share or Dare',
        category: GameCategory.shareOrDare,
        description: 'Truth or dare with a twist',
        maxPlayers: 8,
      ),
      const TagsGame(
        id: 'pop',
        title: 'Path of Pleasure',
        category: GameCategory.pathOfPleasure,
        description: '1v1 ranking battles',
        maxPlayers: 2,
      ),
      const TagsGame(
        id: 'lol',
        title: 'Lane of Lust',
        category: GameCategory.laneOfLust,
        description: 'Explore desires together',
        maxPlayers: 4,
      ),
      const TagsGame(
        id: 'drama',
        title: 'Drama-Sutra',
        category: GameCategory.dramaSutra,
        description: 'Intimate poses and positions',
        maxPlayers: 2,
      ),
      const TagsGame(
        id: 'flash',
        title: 'Flash Freeze',
        category: GameCategory.flashFreeze,
        description: 'Quick-fire decisions',
        maxPlayers: 6,
      ),
      const TagsGame(
        id: 'dice',
        title: 'Dice Breakers',
        category: GameCategory.diceBreakers,
        description: 'Roll the dice, let fate decide',
        minPlayers: 2,
        maxPlayers: 10,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildGamesList()),
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
              icon: const Icon(VesparaIcons.back, color: VesparaColors.primary),
            ),
            const Column(
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
              onPressed: _showRandomGame,
              icon: const Icon(
                VesparaIcons.random,
                color: VesparaColors.tagsYellow,
              ),
            ),
          ],
        ),
      );

  Widget _buildCategoryFilter() => Container(
        height: 80,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _buildCategoryChip(
              null,
              'All',
              VesparaIcons.games,
              VesparaColors.glow,
            ),
            ...GameCategory.values.map(
              (cat) => _buildCategoryChip(
                cat,
                cat.displayName,
                _getCategoryIcon(cat),
                _getCategoryColor(cat),
              ),
            ),
          ],
        ),
      );

  Widget _buildCategoryChip(
    GameCategory? category,
    String name,
    IconData icon,
    Color color,
  ) {
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
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : VesparaColors.secondary,
            ),
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
            border: Border.all(color: categoryColor.withOpacity(0.4), width: 1.5),
            boxShadow: [
              // Bottom shadow for 3D lifted effect
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              // Ambient shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              // Color accent glow
              BoxShadow(
                color: categoryColor.withOpacity(0.25),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              _getGameIconPath(game.title),
              fit: BoxFit.cover,
              cacheWidth: 300,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image not found
                return Center(
                  child: Text(
                    game.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: VesparaColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
      );
  }

  String _getGameIconPath(String gameTitle) {
    // Map game titles to their new icon file names (version 2)
    switch (gameTitle) {
      case 'Down to Clown':
        return 'assets/images/GAME ICONS/Down to Clown 2.png';
      case 'Ice Breakers':
        return 'assets/images/GAME ICONS/Ice Breakers2.png';
      case 'Share or Dare':
        return 'assets/images/GAME ICONS/Share or Dare 2.png';
      case 'Path of Pleasure':
        return 'assets/images/GAME ICONS/Path of pleasure 2.png';
      case 'Lane of Lust':
        return 'assets/images/GAME ICONS/Lane of Lust  2.png';
      case 'Drama-Sutra':
        return 'assets/images/GAME ICONS/Drama Sutra 2.png';
      case 'Flash Freeze':
        return 'assets/images/GAME ICONS/Flash and Freeze 2.png';
      case 'Dice Breakers':
        return 'assets/images/GAME ICONS/Dice Breakers 2.png';
      default:
        return 'assets/images/GAME ICONS/Down to Clown 2.png';
    }
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              VesparaIcons.games,
              size: 80,
              color: VesparaColors.tagsYellow.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No games in this category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different category',
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );

  IconData _getCategoryIcon(GameCategory category) {
    switch (category) {
      case GameCategory.downToClown:
        return Icons.sentiment_very_satisfied_rounded; // 🤡 Clown/guessing
      case GameCategory.icebreakers:
        return Icons.ac_unit_rounded; // ❄️ Ice
      case GameCategory.shareOrDare:
        return Icons.theater_comedy_rounded; // 🎭 Share or Dare
      case GameCategory.pathOfPleasure:
        return Icons.leaderboard_rounded; // 📊 Ranking game
      case GameCategory.laneOfLust:
        return Icons.whatshot_rounded; // 🔥 Desire intensity
      case GameCategory.dramaSutra:
        return Icons.accessibility_new_rounded; // 🧘 Poses
      case GameCategory.flashFreeze:
        return Icons.flash_on_rounded; // ⚡ Flash
      case GameCategory.diceBreakers:
        return Icons.casino_rounded; // 🎲 Dice
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
      shape: const RoundedRectangleBorder(
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

                // Header - simplified
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: VesparaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description ?? game.category.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: VesparaColors.secondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // TAG Rating Grid
                TagRatingDisplay(rating: _getTagRating(game.category)),

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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(VesparaIcons.play),
                        SizedBox(width: 8),
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

  TagRating _getTagRating(GameCategory category) {
    switch (category) {
      case GameCategory.downToClown:
        return TagRating.downToClown;
      case GameCategory.icebreakers:
        return TagRating.iceBreakers;
      case GameCategory.shareOrDare:
        return TagRating.shareOrDare;
      case GameCategory.pathOfPleasure:
        return TagRating.pathOfPleasure;
      case GameCategory.laneOfLust:
        return TagRating.laneOfLust;
      case GameCategory.dramaSutra:
        return TagRating.dramaSutra;
      case GameCategory.flashFreeze:
        return TagRating.flashFreeze;
      case GameCategory.diceBreakers:
        return TagRating.diceBreakers;
    }
  }

  Widget _buildInfoCard(String label, String value, IconData icon) => Container(
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );

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
      case GameCategory.shareOrDare:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShareOrDareScreen()),
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
      case GameCategory.diceBreakers:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DiceBreakersScreen()),
        );
        break;
    }
  }
}
