import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/tag_rating.dart';
import '../../../core/providers/lane_of_lust_provider.dart';
import '../../../core/theme/vespara_icons.dart';
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

  int? _hoveredDropIndex;

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
        if (next.success) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.vibrate();
          _shakeController.forward().then((_) => _shakeController.reset());
        }
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

          // Mystery Card area
          Expanded(
            flex: 2,
            child: _buildMysteryCardArea(state),
          ),

          // My Lane
          Expanded(
            flex: 3,
            child: _buildMyLane(state, me),
          ),

          // My stats bar
          _buildMyStatsBar(me, state),
        ],
      ),
    );
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

    return Center(
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

            // The Mystery Card
            Draggable<LaneCard>(
              data: card,
              feedback: Material(
                color: Colors.transparent,
                child:
                    _buildMysteryCard(card, state.isRevealed, isDragging: true),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildMysteryCard(card, state.isRevealed),
              ),
              onDragStarted: HapticFeedback.selectionClick,
              child: _buildMysteryCard(card, state.isRevealed),
            ),

            // Skip button during steal
            if (state.gameState == LaneGameState.stealing &&
                state.isMyTurn &&
                !state.isRevealed)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(laneOfLustProvider.notifier).skipSteal();
                  },
                  icon: const Icon(VesparaIcons.forward, size: 18),
                  label: const Text('Pass'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMysteryCard(LaneCard card, bool isRevealed,
          {bool isDragging = false,}) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isDragging ? 150 : 170,
        height: isDragging ? 220 : 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRevealed ? card.indexColor : LaneColors.mystery,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(2, 4),
            ),
            BoxShadow(
              color: (isRevealed ? card.indexColor : LaneColors.mystery)
                  .withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Card pattern background
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isRevealed
                        ? [
                            card.indexColor.withOpacity(0.15),
                            card.indexColor.withOpacity(0.05),
                          ]
                        : [LaneColors.mystery.withOpacity(0.1), Colors.white],
                  ),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Top corner index
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5,),
                      decoration: BoxDecoration(
                        color:
                            isRevealed ? card.indexColor : LaneColors.mystery,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isRevealed ? '${card.desireIndex}' : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Center icon/emoji based on category
                  Text(
                    _getCategoryEmoji(card.category),
                    style: const TextStyle(fontSize: 36),
                  ),

                  const SizedBox(height: 8),

                  // Card text
                  Text(
                    card.text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isRevealed
                          ? card.indexColor.withOpacity(0.9)
                          : LaneColors.mystery,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Bottom category label
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: card.category.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: card.category.color.withOpacity(0.3),),
                    ),
                    child: Text(
                      card.category.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: card.category.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corner decorations for card feel
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (isRevealed ? card.indexColor : LaneColors.mystery)
                        .withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (isRevealed ? card.indexColor : LaneColors.mystery)
                        .withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildLaneCard(LaneCard card, int index) => Container(
        width: 90,
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: card.indexColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      card.indexColor.withOpacity(0.08),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Index badge at top
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: card.indexColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${card.desireIndex}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Category emoji
                  Text(
                    _getCategoryEmoji(card.category),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  // Text
                  Expanded(
                    child: Text(
                      card.text,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: card.indexColor.withOpacity(0.9),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildDropZone(int index, LaneOfLustState state) {
    if (!state.isMyTurn || state.isRevealed) {
      return const SizedBox(width: 8);
    }

    return DragTarget<LaneCard>(
      onWillAcceptWithDetails: (details) {
        setState(() => _hoveredDropIndex = index);
        HapticFeedback.selectionClick();
        return true;
      },
      onLeave: (data) {
        setState(() => _hoveredDropIndex = null);
      },
      onAcceptWithDetails: (details) {
        setState(() => _hoveredDropIndex = null);
        ref.read(laneOfLustProvider.notifier).attemptPlacement(index);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = _hoveredDropIndex == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isHovered ? 80 : 24,
          height: isHovered ? 120 : 80,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isHovered
                ? LaneColors.success.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(isHovered ? 12 : 8),
            border: Border.all(
              color: isHovered ? LaneColors.success : Colors.white24,
              width: isHovered ? 3 : 1,
              strokeAlign: BorderSide.strokeAlignCenter,
            ),
          ),
          child: isHovered
              ? const Center(
                  child: Icon(VesparaIcons.add,
                      color: LaneColors.success, size: 32,),
                )
              : null,
        );
      },
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
