import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/providers/path_of_pleasure_provider.dart';
import '../../../core/domain/models/tag_rating.dart';
import '../widgets/tag_rating_display.dart';

/// Path of Pleasure - Family Feud Style
/// Predict what's popular! Rank cards by global popularity and score points.
class PathOfPleasureScreen extends ConsumerStatefulWidget {
  const PathOfPleasureScreen({super.key});

  @override
  ConsumerState<PathOfPleasureScreen> createState() => _PathOfPleasureScreenState();
}

class _PathOfPleasureScreenState extends ConsumerState<PathOfPleasureScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _revealController;
  late Animation<double> _pulseAnimation;
  
  // For drag-and-drop ranking
  int? _draggedIndex;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pathOfPleasureProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: _buildPhaseContent(state),
      ),
    );
  }

  Widget _buildPhaseContent(PathOfPleasureState state) {
    switch (state.phase) {
      case GamePhase.idle:
        return _buildEntryScreen();
      case GamePhase.lobby:
        return _buildLobbyScreen(state);
      case GamePhase.ranking:
        return _buildRankingScreen(state);
      case GamePhase.reveal:
        return _buildRevealScreen(state);
      case GamePhase.roundScore:
        return _buildRoundScoreScreen(state);
      case GamePhase.leaderboard:
        return _buildLeaderboardScreen(state);
      case GamePhase.finished:
        return _buildFinishedScreen(state);
    }
  }

  // ============================================================
  // ENTRY SCREEN - Host or Join
  // ============================================================
  Widget _buildEntryScreen() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game logo/icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.pink.shade400,
                        Colors.purple.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    VesparaIcons.fire,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Path of Pleasure',
                  style: AppTheme.headlineLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Tagline
                Text(
                  'Predict what\'s popular!',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Rank scenarios by what everyone loves most',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // TAG Rating
                const TagRatingDisplay(rating: TagRating.pathOfPleasure),
                
                const Spacer(),
                
                // How to Play button
                TextButton.icon(
                  onPressed: () => _showHowToPlay(context),
                  icon: const Icon(VesparaIcons.help, color: Colors.white70),
                  label: Text(
                    'How to Play',
                    style: AppTheme.labelLarge.copyWith(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Host Game button
                _buildPrimaryButton(
                  label: 'Host Game',
                  icon: VesparaIcons.add,
                  onTap: () {
                    Haptics.light();
                    ref.read(pathOfPleasureProvider.notifier).hostGame('Player');
                  },
                ),
                const SizedBox(height: 16),
                
                // Join Game button
                _buildSecondaryButton(
                  label: 'Join Game',
                  icon: VesparaIcons.forward,
                  onTap: () => _showJoinDialog(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOBBY SCREEN - Configure & Wait for Players
  // ============================================================
  Widget _buildLobbyScreen(PathOfPleasureState state) {
    final isHost = state.isHost;
    
    return Column(
      children: [
        _buildHeader(showBack: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Session Code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tag_rounded, color: Colors.white70),
                      const SizedBox(width: 12),
                      Text(
                        state.roomCode ?? '',
                        style: AppTheme.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(VesparaIcons.copy, color: Colors.white70),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: state.roomCode ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Heat Level Selection (Host only)
                if (isHost) ...[
                  Text(
                    'Select Heat Level',
                    style: AppTheme.titleMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  _buildHeatLevelSelector(state),
                  const SizedBox(height: 32),
                ],
                
                // Players List
                Text(
                  'Players (${state.players.length})',
                  style: AppTheme.titleMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.players.length,
                    itemBuilder: (context, index) {
                      final player = state.players[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: player.isHost 
                                ? Colors.amber.withOpacity(0.5)
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: player.avatarColor,
                              child: Text(
                                player.displayName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                player.displayName,
                                style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                              ),
                            ),
                            if (player.isHost)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'HOST',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Start Game button (Host only)
                if (isHost && state.players.length >= 2)
                  _buildPrimaryButton(
                    label: 'Start Game',
                    icon: VesparaIcons.play,
                    onTap: () {
                      Haptics.medium();
                      ref.read(pathOfPleasureProvider.notifier).startGame();
                    },
                  )
                else if (isHost)
                  Text(
                    'Need at least 2 players to start',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.white54),
                  )
                else
                  Text(
                    'Waiting for host to start...',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.white54),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatLevelSelector(PathOfPleasureState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: HeatLevel.values.map((level) {
        final isSelected = state.heatLevel == level;
        return GestureDetector(
          onTap: () {
            Haptics.light();
            ref.read(pathOfPleasureProvider.notifier).setHeatLevel(level);
          },
          child: AnimatedContainer(
            duration: Motion.fast,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: _getHeatLevelColors(level),
                    )
                  : null,
              color: isSelected ? null : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? Colors.transparent 
                    : Colors.white24,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _getHeatLevelColors(level).first.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  _getHeatLevelIcon(level),
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  _getHeatLevelName(level),
                  style: AppTheme.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // RANKING SCREEN - Drag to rank by predicted popularity
  // ============================================================
  Widget _buildRankingScreen(PathOfPleasureState state) {
    final timeLeft = state.timeRemaining;
    final isLowTime = timeLeft <= 10;
    
    return Column(
      children: [
        _buildGameHeader(state),
        
        // Timer bar
        Container(
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: timeLeft / 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLowTime
                      ? [Colors.red, Colors.orange]
                      : [Colors.pink, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Timer text
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isLowTime ? _pulseAnimation.value : 1.0,
              child: Text(
                '${timeLeft}s',
                style: AppTheme.headlineSmall.copyWith(
                  color: isLowTime ? Colors.red : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // Instructions
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(VesparaIcons.trending, color: Colors.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rank from MOST popular (#1) to LEAST popular',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Rankable cards
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.playerRanking.length,
            onReorder: (oldIndex, newIndex) {
              Haptics.light();
              ref.read(pathOfPleasureProvider.notifier)
                  .reorderCards(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final animValue = Curves.easeInOut.transform(animation.value);
                  final scale = 1.0 + (animValue * 0.05);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final card = state.playerRanking[index];
              return _buildRankableCard(
                key: ValueKey(card.id),
                card: card,
                rank: index + 1,
              );
            },
          ),
        ),
        
        // Submit button
        Padding(
          padding: const EdgeInsets.all(24),
          child: _buildPrimaryButton(
            label: (state.me?.isLockedIn ?? false) ? 'Submitted!' : 'Lock In Rankings',
            icon: (state.me?.isLockedIn ?? false) ? VesparaIcons.check : VesparaIcons.lock,
            onTap: (state.me?.isLockedIn ?? false)
                ? null
                : () {
                    Haptics.heavy();
                    ref.read(pathOfPleasureProvider.notifier).lockIn();
                  },
            disabled: state.me?.isLockedIn ?? false,
          ),
        ),
      ],
    );
  }

  Widget _buildRankableCard({
    required Key key,
    required PopCard card,
    required int rank,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getRankColors(rank),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: AppTheme.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Card content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.text,
                      style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    _buildHeatBadge(HeatLevel.values[(card.heatLevel - 1).clamp(0, 2)]),
                  ],
                ),
              ),
              
              // Drag handle
              const Icon(
                Icons.drag_handle_rounded,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REVEAL SCREEN - Animated reveal of correct order
  // ============================================================
  Widget _buildRevealScreen(PathOfPleasureState state) {
    return Column(
      children: [
        _buildGameHeader(state),
        const SizedBox(height: 24),
        
        // Title
        Text(
          'The Real Rankings!',
          style: AppTheme.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Based on what players love most',
          style: AppTheme.bodyMedium.copyWith(color: Colors.white54),
        ),
        const SizedBox(height: 24),
        
        // Revealed cards with animation
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.roundCards.length,
            itemBuilder: (context, index) {
              final card = state.roundCards[index];
              // Sort by actual global rank for reveal
              final sortedCards = List<PopCard>.from(state.roundCards)
                ..sort((a, b) => a.globalRank.compareTo(b.globalRank));
              final actualRank = sortedCards.indexOf(card) + 1;
              final playerRank = index + 1;
              final isCorrect = actualRank == playerRank;
              
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset((1 - value) * 100, 0),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildRevealCard(card, actualRank, playerRank, isCorrect),
              );
            },
          ),
        ),
        
        // Continue button
        Padding(
          padding: const EdgeInsets.all(24),
          child: _buildPrimaryButton(
            label: 'See Your Score',
            icon: VesparaIcons.forward,
            onTap: () {
              Haptics.medium();
              // Auto-transitions handled by provider
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRevealCard(PopCard card, int actualRank, int playerRank, bool isCorrect) {
    final difference = (actualRank - playerRank).abs();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCorrect
              ? [Colors.green.shade700, Colors.green.shade900]
              : difference == 1
                  ? [Colors.orange.shade700, Colors.orange.shade900]
                  : [Colors.grey.shade800, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? Colors.green.shade400
              : difference == 1
                  ? Colors.orange.shade400
                  : Colors.white12,
          width: isCorrect ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Actual rank (big)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _getRankColors(actualRank)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getRankColors(actualRank).first.withOpacity(0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '#$actualRank',
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Card text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.text,
                    style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildHeatBadge(HeatLevel.values[(card.heatLevel - 1).clamp(0, 2)]),
                      const Spacer(),
                      // Trend indicator
                      if (card.rankChange != 0)
                        Row(
                          children: [
                            Icon(
                              card.rankChange > 0
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 16,
                              color: card.rankChange > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              card.rankChange.abs().toString(),
                              style: AppTheme.labelSmall.copyWith(
                                color: card.rankChange > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Your guess vs actual
            Column(
              children: [
                Text(
                  'You: #$playerRank',
                  style: AppTheme.labelSmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  isCorrect
                      ? VesparaIcons.confirm
                      : difference == 1
                          ? Icons.remove_circle_rounded
                          : VesparaIcons.close,
                  color: isCorrect
                      ? Colors.green
                      : difference == 1
                          ? Colors.orange
                          : Colors.red.shade300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ROUND SCORE SCREEN
  // ============================================================
  Widget _buildRoundScoreScreen(PathOfPleasureState state) {
    final roundResult = state.lastRoundResult;
    if (roundResult == null) return const SizedBox();
    
    return Column(
      children: [
        _buildGameHeader(state),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Round complete title
                Text(
                  'Round ${state.currentRound} Complete!',
                  style: AppTheme.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Score display with animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0, end: roundResult.roundScore.toDouble()),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Column(
                      children: [
                        Text(
                          '+${value.toInt()}',
                          style: AppTheme.displayLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 72,
                          ),
                        ),
                        Text(
                          'points',
                          style: AppTheme.titleLarge.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                // Breakdown
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildScoreRow(
                        'Exact matches',
                        roundResult.cardResults.where((r) => r.pointsEarned == 100).length,
                        VesparaIcons.confirm,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildScoreRow(
                        'Off by 1',
                        roundResult.cardResults.where((r) => r.pointsEarned == 50).length,
                        Icons.remove_circle_rounded,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildScoreRow(
                        'Off by 2',
                        roundResult.cardResults.where((r) => r.pointsEarned == 25).length,
                        Icons.radio_button_unchecked_rounded,
                        Colors.yellow,
                      ),
                      if (roundResult.correctCount == state.cardsPerRound) ...[
                        const Divider(color: Colors.white24, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(VesparaIcons.achievement, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'PERFECT ROUND! +200 Bonus',
                              style: AppTheme.titleMedium.copyWith(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(VesparaIcons.achievement, color: Colors.amber),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Next round / Finish button
                _buildPrimaryButton(
                  label: state.currentRound >= state.totalRounds
                      ? 'See Final Results'
                      : 'Next Round',
                  icon: VesparaIcons.forward,
                  onTap: () {
                    Haptics.medium();
                    ref.read(pathOfPleasureProvider.notifier).skipToNextRound();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(String label, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
          ),
        ),
        Text(
          'x$count',
          style: AppTheme.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LEADERBOARD SCREEN
  // ============================================================
  Widget _buildLeaderboardScreen(PathOfPleasureState state) {
    final sortedPlayers = List<PopPlayer>.from(state.players)
      ..sort((a, b) => b.score.compareTo(a.score));
    
    return Column(
      children: [
        _buildGameHeader(state),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Leaderboard',
                  style: AppTheme.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedPlayers.length,
                    itemBuilder: (context, index) {
                      final player = sortedPlayers[index];
                      final isWinner = index == 0;
                      
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: isWinner
                                ? LinearGradient(
                                    colors: [
                                      Colors.amber.shade700,
                                      Colors.orange.shade800,
                                    ],
                                  )
                                : null,
                            color: isWinner ? null : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isWinner
                                  ? Colors.amber.shade400
                                  : Colors.white12,
                              width: isWinner ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Position
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getPositionColor(index),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: index < 3
                                      ? Icon(
                                          VesparaIcons.trophy,
                                          color: index == 0
                                              ? Colors.amber
                                              : index == 1
                                                  ? Colors.grey.shade300
                                                  : Colors.brown.shade400,
                                          size: 24,
                                        )
                                      : Text(
                                          '${index + 1}',
                                          style: AppTheme.titleMedium.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Player info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.displayName,
                                      style: AppTheme.titleMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (player.bestStreak > 0)
                                      Row(
                                        children: [
                                          const Icon(
                                            VesparaIcons.fire,
                                            size: 14,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${player.bestStreak} streak',
                                            style: AppTheme.labelSmall.copyWith(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Score
                              Text(
                                '${player.score}',
                                style: AppTheme.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Play again / Exit buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSecondaryButton(
                        label: 'Exit',
                        icon: VesparaIcons.leave,
                        onTap: () {
                          ref.read(pathOfPleasureProvider.notifier).reset();
                          context.pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPrimaryButton(
                        label: 'Play Again',
                        icon: VesparaIcons.restart,
                        onTap: () {
                          Haptics.medium();
                          ref.read(pathOfPleasureProvider.notifier).backToLobby();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FINISHED SCREEN (same as leaderboard but with exit focus)
  // ============================================================
  Widget _buildFinishedScreen(PathOfPleasureState state) {
    return _buildLeaderboardScreen(state);
  }

  // ============================================================
  // HELPER WIDGETS
  // ============================================================
  Widget _buildHeader({bool showBack = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(VesparaIcons.back, color: Colors.white),
              onPressed: () {
                ref.read(pathOfPleasureProvider.notifier).reset();
                context.pop();
              },
            )
          else
            IconButton(
              icon: const Icon(VesparaIcons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(VesparaIcons.help, color: Colors.white70),
            onPressed: () => _showHowToPlay(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader(PathOfPleasureState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Round indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Round ${state.currentRound}/${state.totalRounds}',
              style: AppTheme.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          
          // Score
          Row(
            children: [
              const Icon(VesparaIcons.achievement, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${state.players.firstWhere((p) => p.id == state.currentPlayerId, orElse: () => state.players.first).score}',
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                ),
          color: disabled ? Colors.grey.shade800 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: disabled ? Colors.white38 : Colors.white),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTheme.titleMedium.copyWith(
                color: disabled ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTheme.titleMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatBadge(HeatLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getHeatLevelColors(level),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getHeatLevelIcon(level),
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            _getHeatLevelName(level),
            style: AppTheme.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOGS
  // ============================================================
  void _showJoinDialog(BuildContext context) {
    final codeController = TextEditingController();
    final nameController = TextEditingController(text: 'Player');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join Game',
                  style: AppTheme.headlineSmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: codeController,
                  style: const TextStyle(color: Colors.white, letterSpacing: 4),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Game Code',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final code = codeController.text.trim().toUpperCase();
                      final name = nameController.text.trim();
                      if (code.length >= 4 && name.isNotEmpty) {
                        Navigator.pop(context);
                        ref.read(pathOfPleasureProvider.notifier)
                            .joinGame(code, name);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Join'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.pink.shade400, Colors.purple.shade600],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(VesparaIcons.fire, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'How to Play',
                                    style: AppTheme.headlineSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Path of Pleasure',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // The Concept
                        _buildHowToSection(
                          icon: VesparaIcons.suggestionOutline,
                          title: 'The Concept',
                          content: 'Think Family Feud, but spicy! Each round, you\'ll see '
                              'a set of intimate scenarios and rank them from MOST to LEAST '
                              'popular. Your ranking is compared against what ALL players '
                              'across the app have voted - the global popularity!',
                        ),
                        
                        // How to Score
                        _buildHowToSection(
                          icon: VesparaIcons.trophy,
                          title: 'Scoring',
                          content: '',
                          child: Column(
                            children: [
                              _buildScoringRow('Exact match', '100 pts', Colors.green),
                              _buildScoringRow('Off by 1', '50 pts', Colors.orange),
                              _buildScoringRow('Off by 2', '25 pts', Colors.yellow.shade700),
                              _buildScoringRow('Perfect round bonus', '+200 pts', Colors.amber),
                            ],
                          ),
                        ),
                        
                        // Heat Levels
                        _buildHowToSection(
                          icon: VesparaIcons.fire,
                          title: 'Heat Levels',
                          content: '',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeatLevelRow(
                                'Mild',
                                'Romantic & sweet scenarios',
                                [Colors.pink.shade300, Colors.pink.shade400],
                              ),
                              const SizedBox(height: 8),
                              _buildHeatLevelRow(
                                'Spicy',
                                'Things are heating up!',
                                [Colors.orange.shade400, Colors.red.shade400],
                              ),
                              const SizedBox(height: 8),
                              _buildHeatLevelRow(
                                'Sizzle',
                                'No holds barred - explicit content',
                                [Colors.red.shade600, Colors.purple.shade800],
                              ),
                            ],
                          ),
                        ),
                        
                        // Dynamic Rankings
                        _buildHowToSection(
                          icon: VesparaIcons.trending,
                          title: 'Living Rankings',
                          content: 'Card popularity isn\'t static! As more players vote, '
                              'rankings shift. You\'ll see trending indicators showing '
                              'which scenarios are rising 🔥 or falling in popularity. '
                              'Stay tuned to the zeitgeist!',
                        ),
                        
                        // Tips
                        _buildHowToSection(
                          icon: VesparaIcons.suggestion,
                          title: 'Pro Tips',
                          content: '• Don\'t just rank by YOUR preference - think about '
                              'what MOST people would enjoy!\n'
                              '• Watch the trends - rising cards might indicate '
                              'shifting tastes\n'
                              '• The timer is 60 seconds - trust your gut!\n'
                              '• Perfect rounds give massive bonus points',
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Close button
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Got it!'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHowToSection({
    required IconData icon,
    required String title,
    required String content,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.pink, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (content.isNotEmpty)
            Text(
              content,
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildScoringRow(String label, String points, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
            ),
          ),
          Text(
            points,
            style: AppTheme.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatLevelRow(String name, String description, List<Color> colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            name,
            style: AppTheme.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: AppTheme.bodySmall.copyWith(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // UTILITY FUNCTIONS
  // ============================================================
  List<Color> _getHeatLevelColors(HeatLevel level) {
    switch (level) {
      case HeatLevel.mild:
        return [Colors.pink.shade300, Colors.pink.shade400];
      case HeatLevel.spicy:
        return [Colors.orange.shade400, Colors.red.shade400];
      case HeatLevel.sizzle:
        return [Colors.red.shade600, Colors.purple.shade800];
    }
  }

  IconData _getHeatLevelIcon(HeatLevel level) {
    switch (level) {
      case HeatLevel.mild:
        return VesparaIcons.like;
      case HeatLevel.spicy:
        return VesparaIcons.fire;
      case HeatLevel.sizzle:
        return VesparaIcons.fire;
    }
  }

  String _getHeatLevelName(HeatLevel level) {
    switch (level) {
      case HeatLevel.mild:
        return 'Mild';
      case HeatLevel.spicy:
        return 'Spicy';
      case HeatLevel.sizzle:
        return 'Sizzle';
    }
  }

  List<Color> _getRankColors(int rank) {
    if (rank == 1) return [Colors.amber, Colors.orange];
    if (rank == 2) return [Colors.grey.shade400, Colors.grey.shade500];
    if (rank == 3) return [Colors.brown.shade300, Colors.brown.shade400];
    return [Colors.purple.shade400, Colors.pink.shade400];
  }

  Color _getPositionColor(int index) {
    if (index == 0) return Colors.amber.shade800;
    if (index == 1) return Colors.grey.shade700;
    if (index == 2) return Colors.brown.shade700;
    return Colors.grey.shade800;
  }
}
