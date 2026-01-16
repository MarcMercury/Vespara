import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/domain/models/tags_game.dart';
import '../../../core/providers/app_providers.dart';
import '../widgets/consent_meter.dart';
import '../widgets/game_card_widget.dart';

/// The TAGS Screen - Trusted Adult Games System
/// A consent-forward interactive game engine with luxury tarot card aesthetics
/// 
/// Web-safe version using PageView instead of CardSwiper
class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentGameIndex = 0;
  bool _consentConfirmed = false;
  
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the consent level from providers
    final consentLevel = ref.watch(consentLevelProvider);
    final gamesAsync = ref.watch(filteredGamesProvider);
    
    // Convert consent string to ConsentLevel enum for UI
    final consentEnum = _stringToConsentLevel(consentLevel);
    
    // Get available games from provider (already returns GameCategory list)
    final availableGames = gamesAsync.when(
      data: (games) => games,
      loading: () => <GameCategory>[],
      error: (_, __) => <GameCategory>[],
    );
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════════════════════
            // HEADER
            // ═══════════════════════════════════════════════════════════════════
            _buildHeader(context),
            
            // ═══════════════════════════════════════════════════════════════════
            // CONSENT METER (TOP)
            // ═══════════════════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.all(VesparaSpacing.md),
              child: ConsentMeter(
                currentLevel: consentEnum,
                onLevelChanged: (level) {
                  VesparaHaptics.selectionClick();
                  // PHASE 2: Update consent level which triggers game reload
                  ref.read(consentLevelProvider.notifier).state = _consentLevelToString(level);
                  setState(() {
                    _consentConfirmed = false;
                    _currentGameIndex = 0;
                  });
                },
              ),
            ),
            
            // ═══════════════════════════════════════════════════════════════════
            // CONSENT CONFIRMATION
            // ═══════════════════════════════════════════════════════════════════
            if (!_consentConfirmed)
              _buildConsentConfirmation(context, consentEnum),
            
            // ═══════════════════════════════════════════════════════════════════
            // GAME CARD CAROUSEL (CENTER)
            // ═══════════════════════════════════════════════════════════════════
            if (_consentConfirmed)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VesparaSpacing.md,
                  ),
                  child: _buildGameCarousel(context, availableGames),
                ),
              ),
            
            // ═══════════════════════════════════════════════════════════════════
            // LAUNCH GAME BUTTON (BOTTOM)
            // ═══════════════════════════════════════════════════════════════════
            if (_consentConfirmed && availableGames.isNotEmpty)
              _buildLaunchButton(context, availableGames[_currentGameIndex]),
            
            const SizedBox(height: VesparaSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  /// Build the header with back button and title
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              VesparaHaptics.lightTap();
              context.go('/home');
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: VesparaColors.border,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: VesparaColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: VesparaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE LUDUS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Trusted Adult Games',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Arcade icon
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(
                    0.1 + (_glowController.value * 0.1),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: VesparaColors.glow.withOpacity(
                      0.3 + (_glowController.value * 0.2),
                    ),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VesparaColors.glow.withOpacity(
                        0.1 + (_glowController.value * 0.1),
                      ),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.casino,
                  color: VesparaColors.primary,
                  size: 24,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Build consent confirmation dialog
  Widget _buildConsentConfirmation(BuildContext context, ConsentLevel level) {
    return Expanded(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(VesparaSpacing.lg),
          padding: const EdgeInsets.all(VesparaSpacing.lg),
          decoration: VesparaGlass.elevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji and title
              Text(
                level.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: VesparaSpacing.md),
              Text(
                'VIBE CHECK',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: VesparaSpacing.sm),
              
              // Level description
              Text(
                level.description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VesparaSpacing.lg),
              
              // Agreement text
              Container(
                padding: const EdgeInsets.all(VesparaSpacing.md),
                decoration: BoxDecoration(
                  color: VesparaColors.background.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: VesparaColors.border,
                  ),
                ),
                child: Text(
                  _getConsentText(level),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: VesparaSpacing.lg),
              
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    VesparaHaptics.success();
                    setState(() {
                      _consentConfirmed = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getConsentColor(level),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'I UNDERSTAND & CONSENT',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: VesparaColors.background,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the game carousel using PageView (web-safe)
  Widget _buildGameCarousel(BuildContext context, List<GameCategory> games) {
    if (games.isEmpty) {
      return Center(
        child: Text(
          'No games available at this consent level',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    
    return Column(
      children: [
        // Progress dots
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(games.length, (index) {
              return Container(
                width: _currentGameIndex == index ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentGameIndex == index 
                    ? VesparaColors.glow 
                    : VesparaColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: games.length,
            onPageChanged: (index) {
              VesparaHaptics.carouselSnap();
              setState(() {
                _currentGameIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: GameCardWidget(
                  game: games[index],
                  consentLevel: ref.watch(tagsConsentLevelProvider),
                  isActive: index == _currentGameIndex,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  /// Build the launch game button
  Widget _buildLaunchButton(BuildContext context, GameCategory game) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VesparaSpacing.lg),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VesparaBorderRadius.button),
              boxShadow: [
                BoxShadow(
                  color: VesparaColors.glow.withOpacity(
                    0.2 + (_glowController.value * 0.1),
                  ),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _launchGame(context, game),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'LAUNCH ${game.displayName.toUpperCase()}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: VesparaColors.background,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Launch the selected game
  void _launchGame(BuildContext context, GameCategory game) {
    VesparaHaptics.heavyTap();
    
    // Show game launch animation / navigate to game screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.casino,
              color: VesparaColors.primary,
            ),
            const SizedBox(width: 12),
            Text('Launching ${game.displayName}...'),
          ],
        ),
        backgroundColor: VesparaColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Navigate to specific game screen
    // context.go('/home/ludus/${game.name}');
  }
  
  String _getConsentText(ConsentLevel level) {
    switch (level) {
      case ConsentLevel.green:
        return 'All activities at this level are social and flirtatious. '
               'No physical contact or nudity is required. '
               'This is a safe space for playful conversation.';
      case ConsentLevel.yellow:
        return 'Activities may include light touch and suggestive content. '
               'All participants must actively consent to each activity. '
               'You can opt out at any time without judgment.';
      case ConsentLevel.red:
        return 'This level includes explicit adult content. '
               'All participants must be consenting adults. '
               'Boundaries are respected. Safe words are honored. '
               'What happens in the Ludus stays in the Ludus.';
    }
  }
  
  Color _getConsentColor(ConsentLevel level) {
    switch (level) {
      case ConsentLevel.green:
        return VesparaColors.tagsGreen;
      case ConsentLevel.yellow:
        return VesparaColors.tagsYellow;
      case ConsentLevel.red:
        return VesparaColors.tagsRed;
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS FOR CONSENT LEVEL CONVERSION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Convert string consent level to enum
  ConsentLevel _stringToConsentLevel(String level) {
    switch (level) {
      case 'red':
        return ConsentLevel.red;
      case 'yellow':
        return ConsentLevel.yellow;
      default:
        return ConsentLevel.green;
    }
  }
  
  /// Convert enum consent level to string
  String _consentLevelToString(ConsentLevel level) {
    switch (level) {
      case ConsentLevel.red:
        return 'red';
      case ConsentLevel.yellow:
        return 'yellow';
      case ConsentLevel.green:
        return 'green';
    }
  }
}
