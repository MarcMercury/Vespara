import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/tag_rating.dart';
import '../../../core/providers/lane_of_lust_provider.dart';
import '../../../core/theme/vespara_icons.dart';
import '../widgets/lane_playing_card.dart';
import '../widgets/tag_rating_display.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// LANE OF LUST - Timeline Style Desire Game
/// "Shit Happens" meets intimate scenarios
/// First to 10 cards wins!
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════

class LaneColors {
  static const background = Color(0xFF1A1523);
  static const surface = Color(0xFF2D2438);
  static const gold = Color(0xFFFFD700);
  static const crimson = Color(0xFFDC143C);
  static const success = Color(0xFF2ECC71);
  static const failure = Color(0xFFE74C3C);
  static const mystery = Color(0xFF9B59B6);
}

class LaneOfLustScreen extends ConsumerStatefulWidget {
  const LaneOfLustScreen({super.key});

  @override
  ConsumerState<LaneOfLustScreen> createState() => _LaneOfLustScreenState();
}

class _LaneOfLustScreenState extends ConsumerState<LaneOfLustScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _glowController;

  final TextEditingController _nameController = TextEditingController();

  // Click-to-place: track where the user wants to drop the card
  int? _selectedDropIndex;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(laneOfLustProvider);

    // Listen for placement results to trigger animations
    ref.listen(laneOfLustProvider.select((s) => s.lastPlacementResult),
        (prev, next) {
      if (next != null) {
        // Clear selection when result comes in
        setState(() => _selectedDropIndex = null);
        if (next.success) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.vibrate();
          _shakeController.forward().then((_) => _shakeController.reset());
        }
      }
    });

    // Clear selection when mystery card changes (new turn)
    ref.listen(laneOfLustProvider.select((s) => s.mysteryCard?.id),
        (prev, next) {
      if (prev != next) {
        setState(() => _selectedDropIndex = null);
      }
    });

    return Scaffold(
      backgroundColor: LaneColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildPhase(state),
        ),
      ),
    );
  }

  Widget _buildPhase(LaneOfLustState state) {
    switch (state.gameState) {
      case LaneGameState.idle:
        return _buildEntryScreen(state);
      case LaneGameState.lobby:
        return _buildLobby(state);
      case LaneGameState.dealing:
        return _buildDealing(state);
      case LaneGameState.playing:
      case LaneGameState.stealing:
        return _buildPlaying(state);
      case LaneGameState.gameOver:
        return _buildGameOver(state);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTRY SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEntryScreen(LaneOfLustState state) => Container(
        key: const ValueKey('entry'),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(VesparaIcons.back, color: Colors.white70),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Logo
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) => Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                LaneColors.crimson.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: LaneColors.crimson.withOpacity(
                                    0.2 + _glowController.value * 0.2,),
                                blurRadius: 40 + _glowController.value * 20,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child:
                              const Text('🛣️', style: TextStyle(fontSize: 80)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [LaneColors.crimson, LaneColors.gold],
                        ).createShader(bounds),
                        child: const Text(
                          'LANE OF LUST',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Build Your Timeline of Desire',
                        style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.white54,),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10,),
                        decoration: BoxDecoration(
                          color: LaneColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(VesparaIcons.trophy,
                                color: LaneColors.gold, size: 20,),
                            SizedBox(width: 8),
                            Text(
                              'First to 10 Cards Wins!',
                              style: TextStyle(
                                  color: LaneColors.gold,
                                  fontWeight: FontWeight.w600,),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // TAG Rating
                      const TagRatingDisplay(rating: TagRating.laneOfLust),

                      const SizedBox(height: 32),

                      // Host Button
                      GestureDetector(
                        onTap: _showHostDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [LaneColors.crimson, Color(0xFFFF6B6B)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: LaneColors.crimson.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(VesparaIcons.add,
                                  color: Colors.white, size: 24,),
                              SizedBox(width: 12),
                              Text(
                                'START GAME',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      GestureDetector(
                        onTap: _showHowToPlay,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Center(
                            child: Text(
                              'How It Works',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70,),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // TAG Rating info
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => const TagRatingInfoSheet(),
                          );
                        },
                        child: const Text(
                          'About TAG Ratings \u2192',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white38,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  void _showHostDialog() {
    _nameController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: LaneColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),),),
            const SizedBox(height: 24),
            const Text('Enter Your Name',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,),),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: LaneColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,),
                prefixIcon:
                    const Icon(VesparaIcons.person, color: LaneColors.crimson),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    HapticFeedback.heavyImpact();
                    ref
                        .read(laneOfLustProvider.notifier)
                        .hostGame(_nameController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LaneColors.crimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),),
                ),
                child: const Text('CREATE GAME',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToPlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: LaneColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),),),),
              const SizedBox(height: 24),
              const Center(
                  child: Text('How to Play',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,),),),
              const SizedBox(height: 24),
              _buildHowToStep('1', 'The Deal',
                  'Each player starts with 3 cards in their Lane, sorted by Desire Index',),
              _buildHowToStep('2', 'Draw a Card',
                  'On your turn, you draw a Mystery Card - you see the scenario but NOT the index!',),
              _buildHowToStep('3', 'Place It',
                  'Drag the card to where you think it belongs in your sorted Lane',),
              _buildHowToStep('4', 'Reveal',
                  'The card flips to reveal its true Desire Index (1-100)',),
              _buildHowToStep('5', 'Success?',
                  'If you placed it correctly, it stays! If not, the next player can steal it',),
              _buildHowToStep('🏆', 'Win',
                  'First player to collect 10 cards in their Lane wins!',),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '💡 Low index = mild desire\n🔥 High index = intense desire',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowToStep(String number, String title, String description) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: LaneColors.crimson,
                  borderRadius: BorderRadius.circular(8),),
              child: Center(
                  child: Text(number,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white,),),),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,),),
                  const SizedBox(height: 2),
                  Text(description,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white54),),
                ],
              ),
            ),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // LOBBY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLobby(LaneOfLustState state) => Container(
        key: const ValueKey('lobby'),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      ref.read(laneOfLustProvider.notifier).exitGame(),
                  icon: const Icon(VesparaIcons.close, color: Colors.white54),
                ),
                const Spacer(),
                const Text('WAITING ROOM',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white70,),),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),

            const SizedBox(height: 24),

            // Room Code
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    LaneColors.crimson.withOpacity(0.2),
                    LaneColors.gold.withOpacity(0.2),
                  ],),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: LaneColors.crimson
                          .withOpacity(0.5 + _pulseController.value * 0.3),
                      width: 2,),
                ),
                child: Column(
                  children: [
                    const Text('ROOM CODE',
                        style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            color: Colors.white54,),),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: state.roomCode ?? ''),);
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Code copied!'),
                                duration: Duration(seconds: 1),),);
                      },
                      child: Text(
                        state.roomCode ?? '----',
                        style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                            color: LaneColors.crimson,),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Players
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLAYERS (${state.players.length}/8)',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: Colors.white54,),),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.players.length + (state.isHost ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.players.length && state.isHost) {
                          return _buildAddPlayerButton();
                        }
                        return _buildPlayerCard(state.players[index], index);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Start Button
            if (state.isHost)
              GestureDetector(
                onTap: state.players.length >= 2
                    ? () {
                        HapticFeedback.heavyImpact();
                        ref.read(laneOfLustProvider.notifier).startGame();
                      }
                    : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: state.players.length >= 2 ? 1.0 : 0.5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [LaneColors.crimson, Color(0xFFFF6B6B)],),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(VesparaIcons.play, color: Colors.white),
                        SizedBox(width: 8),
                        Text('DEAL THE CARDS',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 2,),),
                      ],
                    ),
                  ),
                ),
              ),

            if (state.players.length < 2)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Need at least 2 players',
                    style: TextStyle(color: Colors.white38, fontSize: 14),),
              ),
          ],
        ),
      );

  Widget _buildPlayerCard(LanePlayer player, int index) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: LaneColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: player.isHost
                  ? LaneColors.gold.withOpacity(0.5)
                  : player.avatarColor.withOpacity(0.3),),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: player.avatarColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: player.avatarColor, width: 2),),
              child: Center(
                  child: Text(player.displayName[0].toUpperCase(),
                      style: TextStyle(
                          fontSize: 18,
                          color: player.avatarColor,
                          fontWeight: FontWeight.w700,),),),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.displayName,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,),),
                  if (player.isHost)
                    const Text('HOST',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: LaneColors.gold,
                            letterSpacing: 1,),),
                ],
              ),
            ),
            if (!player.isHost)
              IconButton(
                onPressed: () =>
                    ref.read(laneOfLustProvider.notifier).removePlayer(index),
                icon: const Icon(VesparaIcons.close,
                    color: Colors.white38, size: 20,),
              ),
          ],
        ),
      );

  Widget _buildAddPlayerButton() => GestureDetector(
        onTap: _showAddPlayerDialog,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: LaneColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(VesparaIcons.addMember, color: Colors.white38),
              SizedBox(width: 8),
              Text('Add Player', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      );

  void _showAddPlayerDialog() {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaneColors.surface,
        title: const Text('Add Player', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: 'Player name',
              hintStyle: TextStyle(color: Colors.white38),),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                ref
                    .read(laneOfLustProvider.notifier)
                    .addLocalPlayer(_nameController.text);
                Navigator.pop(context);
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: LaneColors.crimson),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEALING
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDealing(LaneOfLustState state) => Container(
        key: const ValueKey('dealing'),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🃏', style: TextStyle(fontSize: 80)),
              SizedBox(height: 24),
              Text('Dealing Cards...',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,),),
              SizedBox(height: 16),
              SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                      color: LaneColors.crimson,
                      backgroundColor: LaneColors.surface,),),
            ],
          ),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYING - THE MAIN GAME
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlaying(LaneOfLustState state) {
    final me = state.me;
    if (me == null) return const SizedBox();

    return Container(
      key: const ValueKey('playing'),
      child: Column(
        children: [
          // Header with opponents
          _buildOpponentsBar(state),

          // Turn indicator
          _buildTurnIndicator(state),

          // Main game area - use Expanded with a nested Column
          Expanded(
            child: Column(
              children: [
                // Mystery Card area - takes available space
                Expanded(
                  child: _buildMysteryCardArea(state),
                ),

                // Place Card Button - FIXED height, not inside Expanded
                // This ensures it's not overlapped by other widgets
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: (_selectedDropIndex != null && state.isMyTurn && !state.isRevealed) 
                      ? 80 
                      : (state.gameState == LaneGameState.stealing && state.isMyTurn && !state.isRevealed)
                          ? 56
                          : 0,
                  child: _buildPlaceCardButton(state),
                ),

                // My Lane
                Expanded(
                  flex: 2,
                  child: _buildMyLane(state, me),
                ),
              ],
            ),
          ),

          // My stats bar
          _buildMyStatsBar(me, state),
        ],
      ),
    );
  }

  Widget _buildPlaceCardButton(LaneOfLustState state) {
    final hasSelectedSpot = _selectedDropIndex != null;
    
    debugPrint('LANE BUILD: _buildPlaceCardButton called');
    debugPrint('LANE BUILD: isMyTurn=${state.isMyTurn}, isRevealed=${state.isRevealed}, hasSelectedSpot=$hasSelectedSpot, selectedIndex=$_selectedDropIndex');
    
    if (!state.isMyTurn || state.isRevealed) {
      debugPrint('LANE BUILD: Returning shrink - not my turn or revealed');
      return const SizedBox.shrink();
    }

    if (!hasSelectedSpot && state.gameState != LaneGameState.stealing) {
      debugPrint('LANE BUILD: Returning shrink - no spot selected and not stealing');
      return const SizedBox.shrink();
    }

    debugPrint('LANE BUILD: Showing button area');
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.transparent, // Explicit background for hit testing
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Skip/Pass button during steal
          if (state.gameState == LaneGameState.stealing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () {
                  debugPrint('LANE: Pass button pressed');
                  HapticFeedback.lightImpact();
                  setState(() => _selectedDropIndex = null);
                  ref.read(laneOfLustProvider.notifier).skipSteal();
                },
                icon: const Icon(VesparaIcons.forward, size: 18),
                label: const Text('Pass'),
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
              ),
            ),
          
          // Place Card button (only shown when a spot is selected)
          if (hasSelectedSpot)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handlePlaceCard,
                onTapDown: (_) => debugPrint('LANE: onTapDown received'),
                onTapUp: (_) => debugPrint('LANE: onTapUp received'),
                onTapCancel: () => debugPrint('LANE: onTapCancel received'),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [LaneColors.crimson, Color(0xFFE91E63)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: LaneColors.crimson.withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(VesparaIcons.confirm, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'PLACE CARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontSize: 16,
                        ),
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

  void _handlePlaceCard() {
    debugPrint('LANE: _handlePlaceCard called');
    debugPrint('LANE: _selectedDropIndex = $_selectedDropIndex');
    
    final index = _selectedDropIndex;
    if (index == null) {
      debugPrint('LANE: index is null, returning');
      return;
    }
    
    debugPrint('LANE: Attempting placement at index $index');
    HapticFeedback.heavyImpact();
    
    final capturedIndex = index;
    setState(() => _selectedDropIndex = null);
    
    debugPrint('LANE: Calling attemptPlacement($capturedIndex)');
    ref.read(laneOfLustProvider.notifier).attemptPlacement(capturedIndex);
    debugPrint('LANE: attemptPlacement called successfully');
  }

  Widget _buildOpponentsBar(LaneOfLustState state) {
    final opponents =
        state.players.where((p) => p.id != state.currentPlayerId).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: LaneColors.surface,
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          ...opponents.map(
            (p) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: (state.currentPlayer?.id == p.id ||
                          state.stealingPlayer?.id == p.id)
                      ? p.avatarColor.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (state.currentPlayer?.id == p.id ||
                            state.stealingPlayer?.id == p.id)
                        ? p.avatarColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: p.avatarColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          p.displayName[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.displayName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11,),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${p.laneLength} cards',
                            style: TextStyle(
                              color: p.laneLength >= 8
                                  ? LaneColors.gold
                                  : Colors.white38,
                              fontSize: 10,
                              fontWeight: p.laneLength >= 8
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTurnIndicator(LaneOfLustState state) {
    final isMyTurn = state.isMyTurn;
    final isStealing = state.gameState == LaneGameState.stealing;

    String message;
    Color color;

    if (isMyTurn) {
      if (isStealing) {
        message = '🎯 STEAL OPPORTUNITY! Place the card or pass';
        color = LaneColors.gold;
      } else {
        message = '🎯 YOUR TURN - Place the mystery card!';
        color = LaneColors.success;
      }
    } else {
      final activePlayer =
          isStealing ? state.stealingPlayer : state.currentPlayer;
      if (isStealing) {
        message = '⏳ ${activePlayer?.displayName ?? "?"} is trying to steal...';
        color = LaneColors.gold;
      } else {
        message = '⏳ ${activePlayer?.displayName ?? "?"}\'s turn';
        color = Colors.white54;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: color.withOpacity(0.1),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMysteryCardArea(LaneOfLustState state) {
    final card = state.mysteryCard;
    if (card == null) return const SizedBox();

    final result = state.lastPlacementResult;
    final showResult = result != null && state.isRevealed;
    final hasSelectedSpot = _selectedDropIndex != null;

    // Wrap in ClipRect to prevent overflow and ensure proper bounds
    return ClipRect(
      child: Center(
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final shake = sin(_shakeController.value * pi * 4) * 10;
            return Transform.translate(
              offset: Offset(showResult && !result.success ? shake : 0, 0),
              child: child,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Don't expand beyond needed
            children: [
              // Result badge
              if (showResult)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color:
                        result.success ? LaneColors.success : LaneColors.failure,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        result.success
                            ? VesparaIcons.confirm
                            : VesparaIcons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        result.success ? 'CORRECT!' : 'WRONG!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

              // Instruction text when it's my turn
              if (state.isMyTurn && !state.isRevealed && !showResult)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    hasSelectedSpot 
                        ? 'Tap PLACE CARD below'
                        : 'Tap a slot below to place this card',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasSelectedSpot ? LaneColors.gold : Colors.white54,
                      fontWeight: hasSelectedSpot ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),

              // The Mystery Card (no longer draggable)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: hasSelectedSpot ? 0.6 : 1.0,
                child: _buildMysteryCard(card, state.isRevealed),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMysteryCard(LaneCard card, bool isRevealed,
          {bool isDragging = false,}) =>
      LanePlayingCard(
        card: card,
        isRevealed: isRevealed,
        isSmall: false,
        isDragging: isDragging,
        showGlow: true,
      );

  String _getCategoryEmoji(LaneCardCategory category) {
    switch (category) {
      case LaneCardCategory.vanilla:
        return '🍦';
      case LaneCardCategory.kinky:
        return '⛓️';
      case LaneCardCategory.romance:
        return '💕';
      case LaneCardCategory.wild:
        return '🔥';
    }
  }

  Widget _buildMyLane(LaneOfLustState state, LanePlayer me) {
    final cards = me.hand;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text('MY LANE',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: Colors.white54,),),
                const SizedBox(width: 8),
                Text('${cards.length}/${state.winTarget}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: LaneColors.gold,
                        fontWeight: FontWeight.w700,),),
              ],
            ),
          ),

          // Lane cards with drop zones
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Drop zone before first card
                    _buildDropZone(0, state),

                    // Cards with drop zones between
                    for (int i = 0; i < cards.length; i++) ...[
                      _buildLaneCard(cards[i], i),
                      _buildDropZone(i + 1, state),
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

  Widget _buildLaneCard(LaneCard card, int index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: LanePlayingCard(
          card: card,
          isRevealed: true,
          isSmall: true,
          isDragging: false,
          showGlow: false,
        ),
      );

  Widget _buildDropZone(int index, LaneOfLustState state) {
    if (!state.isMyTurn || state.isRevealed) {
      return const SizedBox(width: 8);
    }

    final isSelected = _selectedDropIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          // Toggle selection - tap same spot to deselect, or select new spot
          _selectedDropIndex = isSelected ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: isSelected ? 85 : 32,
        height: isSelected ? 130 : 90,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    LaneColors.success.withOpacity(0.4),
                    LaneColors.success.withOpacity(0.2),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(isSelected ? 14 : 10),
          border: Border.all(
            color: isSelected ? LaneColors.success : Colors.white38,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LaneColors.success.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isSelected
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LaneColors.success.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        VesparaIcons.confirm,
                        color: LaneColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'HERE',
                      style: TextStyle(
                        color: LaneColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                )
              : Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.3),
                    border: Border.all(
                      color: Colors.white54,
                      width: 2,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMyStatsBar(LanePlayer me, LaneOfLustState state) => Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: LaneColors.surface,
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('🃏', '${state.deck.length}', 'Deck'),
            _buildStatItem('🎯', '${state.winTarget}', 'Target'),
            _buildStatItem('📊', '${me.laneLength}', 'My Cards'),
          ],
        ),
      );

  Widget _buildStatItem(String emoji, String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,),),
            ],
          ),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.white38),),
        ],
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME OVER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGameOver(LaneOfLustState state) {
    final winner = state.winner;
    final isWinner = winner?.id == state.currentPlayerId;

    // Sort players by lane length
    final rankings = [...state.players]
      ..sort((a, b) => b.laneLength.compareTo(a.laneLength));

    return Container(
      key: const ValueKey('gameover'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          // Trophy
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LaneColors.gold
                        .withOpacity(0.3 + _glowController.value * 0.3),
                    blurRadius: 40 + _glowController.value * 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Text('🏆', style: TextStyle(fontSize: 80)),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            isWinner ? 'YOU WIN!' : '${winner?.displayName ?? "?"} WINS!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isWinner ? LaneColors.gold : Colors.white,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${winner?.laneLength ?? 0} cards collected',
            style: const TextStyle(fontSize: 16, color: Colors.white54),
          ),

          const SizedBox(height: 32),

          // Leaderboard
          Expanded(
            child: ListView.builder(
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final player = rankings[index];
                final medal = index == 0
                    ? '🥇'
                    : index == 1
                        ? '🥈'
                        : index == 2
                            ? '🥉'
                            : '';
                final isMe = player.id == state.currentPlayerId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? player.avatarColor.withOpacity(0.2)
                        : LaneColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: isMe ? Border.all(color: player.avatarColor) : null,
                  ),
                  child: Row(
                    children: [
                      Text(medal.isNotEmpty ? medal : '${index + 1}',
                          style: const TextStyle(fontSize: 24),),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: player.avatarColor, shape: BoxShape.circle,),
                        child: Center(
                            child: Text(player.displayName[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,),),),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(player.displayName,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isMe
                                      ? player.avatarColor
                                      : Colors.white,),),),
                      Text('${player.laneLength} cards',
                          style: TextStyle(
                              color: index == 0
                                  ? LaneColors.gold
                                  : Colors.white54,),),
                    ],
                  ),
                );
              },
            ),
          ),

          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(laneOfLustProvider.notifier).exitGame();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        color: LaneColors.surface,
                        borderRadius: BorderRadius.circular(16),),
                    child: const Center(
                        child: Text('EXIT',
                            style: TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,),),),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    ref.read(laneOfLustProvider.notifier).playAgain();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [LaneColors.crimson, Color(0xFFFF6B6B)],),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                        child: Text('PLAY AGAIN',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,),),),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
