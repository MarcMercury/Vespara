import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/providers/ice_breakers_provider.dart';
import '../../../core/domain/models/tag_rating.dart';
import '../widgets/tag_rating_display.dart';
import 'velvet_rope_screen.dart';
import 'down_to_clown_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// ICE BREAKERS - The Gateway Game to Vespara
/// "Kill awkward silence without jumping into heavy intimacy"
/// 
/// TAG Rating: 40mph / PG-13 / Quickie (15 min)
/// Vibe: High-end cocktail lounge. Relaxed, slightly buzzed, low stakes.
/// Goal: Move a group from "polite conversation" to "flirty connection"
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE (Cocktail Lounge Vibe)
// ═══════════════════════════════════════════════════════════════════════════

class IceColors {
  static const background = Color(0xFF1A1523);       // Deep Obsidian
  static const primary = Color(0xFF00E5FF);          // Electric Cyan
  static const secondary = Color(0xFFE0D8EA);        // Soft Lavender
  static const cardFront = Color(0xFF2D2438);        // Dark Purple
  static const cardBack = Color(0xFF00B8CC);         // Ice Cyan
  static const wildCard = Color(0xFFFF6B9D);         // Hot Pink (for wild cards)
  static const timerWarning = Color(0xFFFF4757);     // Red warning
  static const success = Color(0xFF2ECC71);          // Green
  static const skip = Color(0xFFFF9F43);             // Orange
}

class IceBreakersScreen extends ConsumerStatefulWidget {
  const IceBreakersScreen({super.key});

  @override
  ConsumerState<IceBreakersScreen> createState() => _IceBreakersScreenState();
}

class _IceBreakersScreenState extends ConsumerState<IceBreakersScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _cardFlipController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _cardFlipAnimation;
  
  // Countdown
  int _countdownValue = 3;
  Timer? _countdownTimer;
  
  // Card timer
  Timer? _cardTimer;
  
  // Player name input
  final TextEditingController _playerNameController = TextEditingController();
  final FocusNode _playerNameFocus = FocusNode();
  
  @override
  void initState() {
    super.initState();
    
    _cardFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _cardFlipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardFlipController, curve: Curves.easeInOutBack),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _cardFlipController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _countdownTimer?.cancel();
    _cardTimer?.cancel();
    _playerNameController.dispose();
    _playerNameFocus.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iceBreakersProvider);
    
    return Scaffold(
      backgroundColor: IceColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _buildPhase(state),
        ),
      ),
    );
  }
  
  Widget _buildPhase(IceBreakersState state) {
    switch (state.phase) {
      case IceGamePhase.discovery:
        return _buildDiscoveryPhase(state);
      case IceGamePhase.lobby:
        return _buildLobbyPhase(state);
      case IceGamePhase.countdown:
        return _buildCountdownPhase();
      case IceGamePhase.playing:
      case IceGamePhase.cardReveal:
      case IceGamePhase.timer:
        return _buildPlayingPhase(state);
      case IceGamePhase.results:
        return _buildResultsPhase(state);
      case IceGamePhase.escalation:
        return _buildEscalationPhase(state);
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 1: DISCOVERY (Home Screen)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildDiscoveryPhase(IceBreakersState state) {
    return Container(
      key: const ValueKey('discovery'),
      child: Column(
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(VesparaIcons.back, color: Colors.white70),
                ),
                const Spacer(),
                // Demo mode badge
                if (state.isDemoMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(VesparaIcons.play, color: Colors.orange, size: 16),
                        SizedBox(width: 6),
                        Text('Demo', style: TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Ice emoji with glow
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: IceColors.primary.withOpacity(0.3 + (_glowController.value * 0.3)),
                      blurRadius: 50 + (_glowController.value * 30),
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: const Text('🧊', style: TextStyle(fontSize: 80)),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [IceColors.primary, IceColors.secondary],
            ).createShader(bounds),
            child: const Text(
              'ICE BREAKERS',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tagline
          const Text(
            '"Kill awkward silence without\njumping into heavy intimacy"',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.white60,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // TAG Rating
          const TagRatingDisplay(
            rating: TagRating(
              velocity: VelocityRating.flirty,
              heat: HeatRating.pg13,
              duration: DurationRating.quickie,
            ),
          ),
          
          const Spacer(),
          
          // Play button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    ref.read(iceBreakersProvider.notifier).enterLobby();
                  },
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              IceColors.primary,
                              IceColors.primary.withOpacity(0.7 + (_pulseController.value * 0.3)),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: IceColors.primary.withOpacity(0.4),
                              blurRadius: 20 + (_pulseController.value * 10),
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'BREAK THE ICE 🧊',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // How it works
                GestureDetector(
                  onTap: _showHowItWorks,
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
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  void _showHowItWorks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: IceColors.cardFront,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'HOW TO PLAY',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildHowToRow('👥', 'Add players or play as a couple'),
            _buildHowToRow('📱', 'Place phone in center of table'),
            _buildHowToRow('👆', 'Tap to reveal the card'),
            _buildHowToRow('🎯', 'Complete the prompt in real life'),
            _buildHowToRow('👉', 'Swipe right = Done'),
            _buildHowToRow('👈', 'Swipe left = Skip'),
            _buildHowToRow('⏱️', 'Some cards are timed!'),
            _buildHowToRow('🌟', 'Wild cards affect everyone'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHowToRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 15, color: Colors.white70)),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 2: LOBBY (Player Setup)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildLobbyPhase(IceBreakersState state) {
    return Container(
      key: const ValueKey('lobby'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ref.read(iceBreakersProvider.notifier).reset();
                },
                icon: Icon(VesparaIcons.back, color: Colors.white70),
              ),
              const Spacer(),
              const Text(
                '🧊 WHO\'S PLAYING?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Mode selection
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  icon: '💑',
                  label: 'Just Us Two',
                  isSelected: state.gameMode == IceGameMode.couple,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(iceBreakersProvider.notifier).setGameMode(IceGameMode.couple);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeButton(
                  icon: '👥',
                  label: 'Group Mode',
                  isSelected: state.gameMode == IceGameMode.group,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(iceBreakersProvider.notifier).setGameMode(IceGameMode.group);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Player list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYERS (${state.players.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 12),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: state.players.length + 1,
                    itemBuilder: (context, index) {
                      if (index == state.players.length) {
                        // Add player button
                        if (state.players.length >= 12) return const SizedBox();
                        return _buildAddPlayerRow();
                      }
                      return _buildPlayerRow(state.players[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Start button
          if (state.players.isNotEmpty)
            GestureDetector(
              onTap: state.isLoading ? null : () {
                HapticFeedback.heavyImpact();
                ref.read(iceBreakersProvider.notifier).startGame();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: state.players.length >= 2 
                      ? LinearGradient(colors: [IceColors.primary, IceColors.primary.withOpacity(0.7)])
                      : null,
                  color: state.players.length < 2 ? Colors.white24 : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          'START GAME',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: state.players.length >= 2 ? Colors.black : Colors.white38,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
            ),
          
          if (state.players.length < 2)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Add at least 2 players to start',
                style: TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildModeButton({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [IceColors.primary.withOpacity(0.3), IceColors.primary.withOpacity(0.1)])
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? IceColors.primary : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? IceColors.primary : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlayerRow(IcePlayer player, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: IceColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: IceColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(iceBreakersProvider.notifier).removePlayer(index);
            },
            icon: Icon(VesparaIcons.close, color: Colors.white38, size: 20),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddPlayerRow() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(VesparaIcons.addMember, color: Colors.white38, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _playerNameController,
              focusNode: _playerNameFocus,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Add player...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  HapticFeedback.lightImpact();
                  ref.read(iceBreakersProvider.notifier).addPlayer(value);
                  _playerNameController.clear();
                  _playerNameFocus.requestFocus();
                }
              },
            ),
          ),
          IconButton(
            onPressed: () {
              if (_playerNameController.text.trim().isNotEmpty) {
                HapticFeedback.lightImpact();
                ref.read(iceBreakersProvider.notifier).addPlayer(_playerNameController.text);
                _playerNameController.clear();
                _playerNameFocus.requestFocus();
              }
            },
            icon: Icon(VesparaIcons.add, color: IceColors.primary),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 3: COUNTDOWN
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildCountdownPhase() {
    // Start countdown on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_countdownTimer == null || !_countdownTimer!.isActive) {
        _countdownValue = 3;
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          HapticFeedback.lightImpact();
          setState(() {
            _countdownValue--;
            if (_countdownValue <= 0) {
              timer.cancel();
              ref.read(iceBreakersProvider.notifier).beginPlaying();
            }
          });
        });
      }
    });
    
    return Container(
      key: const ValueKey('countdown'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _countdownValue > 0 ? '$_countdownValue' : 'GO!',
              style: TextStyle(
                fontSize: 140,
                fontWeight: FontWeight.w800,
                color: IceColors.primary,
                shadows: [
                  Shadow(
                    color: IceColors.primary.withOpacity(0.5),
                    blurRadius: 60,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Place phone in center of table 📱',
              style: TextStyle(fontSize: 18, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 4: PLAYING
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildPlayingPhase(IceBreakersState state) {
    final card = state.currentCard;
    if (card == null) return const SizedBox();
    
    // Start timer if needed - cancel existing timer first to prevent multiple timers
    if (state.phase == IceGamePhase.timer && (_cardTimer == null || !_cardTimer!.isActive)) {
      _cardTimer?.cancel();
      _cardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        HapticFeedback.lightImpact();
        ref.read(iceBreakersProvider.notifier).tickTimer();
        if (ref.read(iceBreakersProvider).timerSecondsRemaining <= 0) {
          timer.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    }
    
    return Container(
      key: const ValueKey('playing'),
      child: Column(
        children: [
          // Status bar
          _buildStatusBar(state),
          
          // Current player indicator
          if (state.currentPlayer != null && state.phase != IceGamePhase.playing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: card.isWild ? IceColors.wildCard.withOpacity(0.2) : IceColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.isWild ? '🌟 Everyone' : '${state.currentPlayer!.name}\'s Turn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: card.isWild ? IceColors.wildCard : IceColors.primary,
                    ),
                  ),
                  if (card.targetType == TargetType.pair && state.nextPlayer != null) ...[
                    const Text(' → ', style: TextStyle(color: Colors.white38)),
                    Text(
                      state.nextPlayer!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Card area
          Expanded(
            child: GestureDetector(
              onTap: state.isCardRevealed ? null : () {
                HapticFeedback.heavyImpact();
                _cardFlipController.forward();
                ref.read(iceBreakersProvider.notifier).revealCard();
              },
              onHorizontalDragEnd: state.isCardRevealed ? (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity > 200) {
                  // Swipe right - complete
                  HapticFeedback.heavyImpact();
                  _cardFlipController.reset();
                  _cardTimer?.cancel();
                  ref.read(iceBreakersProvider.notifier).completeCard();
                } else if (velocity < -200) {
                  // Swipe left - skip
                  HapticFeedback.lightImpact();
                  _cardFlipController.reset();
                  _cardTimer?.cancel();
                  ref.read(iceBreakersProvider.notifier).skipCard();
                }
              } : null,
              child: AnimatedBuilder(
                animation: _cardFlipAnimation,
                builder: (context, child) {
                  final angle = _cardFlipAnimation.value * pi;
                  final isFront = angle < pi / 2;
                  
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isFront
                              ? [IceColors.cardBack, IceColors.cardBack.withOpacity(0.8)]
                              : card.isWild
                                  ? [IceColors.wildCard.withOpacity(0.3), IceColors.cardFront]
                                  : [IceColors.cardFront, IceColors.background],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isFront
                              ? IceColors.primary.withOpacity(0.5)
                              : card.isWild
                                  ? IceColors.wildCard.withOpacity(0.5)
                                  : Colors.white12,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isFront ? IceColors.primary : card.isWild ? IceColors.wildCard : IceColors.primary).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: isFront
                          ? _buildCardBack()
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _buildCardFront(state, card),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Swipe hints
          if (state.isCardRevealed)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(VesparaIcons.skip, color: IceColors.skip.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text('Skip', style: TextStyle(color: IceColors.skip.withOpacity(0.7))),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Done', style: TextStyle(color: IceColors.success.withOpacity(0.7))),
                      const SizedBox(width: 8),
                      Icon(VesparaIcons.like, color: IceColors.success.withOpacity(0.7)),
                    ],
                  ),
                ],
              ),
            ),
          
          if (!state.isCardRevealed)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Tap to reveal',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatusBar(IceBreakersState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cards completed
          Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                '${state.completedCards.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: IceColors.success,
                ),
              ),
            ],
          ),
          
          // Card number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${state.currentCardIndex + 1}/${min(state.deck.length, 20)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          
          // Cards skipped
          Row(
            children: [
              Text(
                '${state.skippedCards.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: IceColors.skip,
                ),
              ),
              const SizedBox(width: 6),
              const Text('⏭️', style: TextStyle(fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCardBack() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🧊',
            style: TextStyle(
              fontSize: 80,
              shadows: [
                Shadow(
                  color: IceColors.primary.withOpacity(0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'TAP TO REVEAL',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCardFront(IceBreakersState state, IceCard card) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Card type badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: card.isWild ? IceColors.wildCard.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  card.isWild ? '🌟 WILD' : card.category.emoji,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: card.isWild ? IceColors.wildCard : Colors.white70,
                  ),
                ),
              ),
              if (card.hasTimer)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.timerSecondsRemaining <= 5
                        ? IceColors.timerWarning.withOpacity(0.3)
                        : IceColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        VesparaIcons.timer,
                        size: 16,
                        color: state.timerSecondsRemaining <= 5 ? IceColors.timerWarning : IceColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${state.timerSecondsRemaining}s',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: state.timerSecondsRemaining <= 5 ? IceColors.timerWarning : IceColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          // Prompt text
          Expanded(
            child: Center(
              child: Text(
                card.prompt,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                  fontFamily: 'Playfair Display',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Target indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              card.targetType == TargetType.everyone
                  ? 'Everyone participates'
                  : card.targetType == TargetType.pair
                      ? 'With your partner'
                      : 'Your turn',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 5: RESULTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildResultsPhase(IceBreakersState state) {
    return Container(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          
          const Text('🧊', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          
          const Text(
            'ICE BROKEN!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: IceColors.primary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Stats
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildStatRow('Cards Completed', '${state.completedCards.length}', IceColors.success),
                const Divider(color: Colors.white12, height: 24),
                _buildStatRow('Cards Skipped', '${state.skippedCards.length}', IceColors.skip),
                const Divider(color: Colors.white12, height: 24),
                _buildStatRow('Time Played', '${(state.gameDurationSeconds / 60).toStringAsFixed(1)} min', IceColors.primary),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Play again
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              ref.read(iceBreakersProvider.notifier).enterLobby();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [IceColors.primary, IceColors.primary.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'PLAY AGAIN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextButton(
            onPressed: () {
              ref.read(iceBreakersProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('Back to Arcade', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.white70)),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 6: ESCALATION (Upsell)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildEscalationPhase(IceBreakersState state) {
    return Container(
      key: const ValueKey('escalation'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          
          // Fire emoji with glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3 + (_pulseController.value * 0.3)),
                      blurRadius: 50 + (_pulseController.value * 30),
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 80)),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'The ice is broken.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Ready to turn up the heat?',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white60,
            ),
          ),
          
          const Spacer(),
          
          // Escalation options
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              ref.read(iceBreakersProvider.notifier).escalateTo('truth_or_dare');
              // Navigate to Share or Dare (Truth or Dare evolved)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const VelvetRopeScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'PLAY TRUTH OR DARE 🟡',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              ref.read(iceBreakersProvider.notifier).escalateTo('down_to_clown');
              // Navigate to Down to Clown
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DownToClownScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [VesparaColors.glow, Colors.pinkAccent]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'PLAY DOWN TO CLOWN 🤡',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextButton(
            onPressed: () {
              ref.read(iceBreakersProvider.notifier).escalateTo('finished');
              // Go to results
            },
            child: const Text('Finish Game', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
