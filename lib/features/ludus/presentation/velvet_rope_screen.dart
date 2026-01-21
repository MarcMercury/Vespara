import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/providers/velvet_rope_provider.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// SHARE OR DARE - Spin the Wheel, Pick Your Poison
/// "Celestial Luxury" - Deep Obsidian, Ethereal Blue, Burning Crimson
/// TAG Engine Signature Game
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════

class VelvetColors {
  static const background = Color(0xFF1A1523);      // Deep Obsidian
  static const surface = Color(0xFF2D2438);          // Elevated surface
  static const shareBlue = Color(0xFF4A9EFF);        // Ethereal Blue (Mind)
  static const dareCrimson = Color(0xFFDC143C);      // Burning Crimson (Body)
  static const gold = Color(0xFFFFD700);             // Accent gold
  static const lavender = Color(0xFFE0D8EA);         // Soft text
}

class VelvetRopeScreen extends ConsumerStatefulWidget {
  const VelvetRopeScreen({super.key});

  @override
  ConsumerState<VelvetRopeScreen> createState() => _VelvetRopeScreenState();
}

class _VelvetRopeScreenState extends ConsumerState<VelvetRopeScreen>
    with TickerProviderStateMixin {
  
  // Controllers
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _cardFlipController;
  late AnimationController _glowController;
  
  // Spin physics
  double _spinAngle = 0;
  double _spinVelocity = 0;
  int _lastHapticSlice = -1;
  
  // Player input
  final TextEditingController _nameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_onSpinTick);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _cardFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _cardFlipController.dispose();
    _glowController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  void _onSpinTick() {
    if (_spinVelocity <= 0) return;
    
    final state = ref.read(velvetRopeProvider);
    if (state.players.isEmpty) return;
    
    // Calculate current slice based on angle
    final sliceAngle = 2 * pi / state.players.length;
    final currentSlice = ((_spinAngle % (2 * pi)) / sliceAngle).floor();
    
    // Trigger haptic when crossing slice boundary
    if (currentSlice != _lastHapticSlice) {
      HapticFeedback.selectionClick();
      _lastHapticSlice = currentSlice;
    }
    
    // Apply friction decay
    setState(() {
      _spinAngle += _spinVelocity * 0.016; // ~60fps
      _spinVelocity *= 0.985; // Friction coefficient
      
      // Stop spinning when velocity is negligible
      if (_spinVelocity < 0.1) {
        _spinVelocity = 0;
        _spinController.stop();
        
        // Calculate final selection
        final selectedIndex = _calculateSelectedPlayer(state.players.length);
        HapticFeedback.heavyImpact();
        ref.read(velvetRopeProvider.notifier).spinComplete(selectedIndex);
      }
    });
  }
  
  int _calculateSelectedPlayer(int playerCount) {
    if (playerCount == 0) return 0;
    final sliceAngle = 2 * pi / playerCount;
    // The indicator is at the top (12 o'clock), so we need to adjust
    final normalizedAngle = (2 * pi - (_spinAngle % (2 * pi))) % (2 * pi);
    return (normalizedAngle / sliceAngle).floor() % playerCount;
  }
  
  void _startSpin() {
    final random = Random();
    setState(() {
      _spinVelocity = 15 + random.nextDouble() * 10; // Random initial velocity
      _lastHapticSlice = -1;
    });
    _spinController.repeat();
  }
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(velvetRopeProvider);
    
    return Scaffold(
      backgroundColor: VelvetColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildPhase(state),
        ),
      ),
    );
  }
  
  Widget _buildPhase(VelvetRopeState state) {
    switch (state.phase) {
      case VelvetPhase.lobby:
        return _buildLobby(state);
      case VelvetPhase.spinning:
        return _buildSpinning(state);
      case VelvetPhase.selecting:
        return _buildSelection(state);
      case VelvetPhase.revealing:
      case VelvetPhase.reading:
        return _buildCardReveal(state);
      case VelvetPhase.results:
        return _buildResults(state);
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LOBBY PHASE
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildLobby(VelvetRopeState state) {
    return Container(
      key: const ValueKey('lobby'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(VesparaIcons.back, color: Colors.white70),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Text(
                    '� SHARE OR DARE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            VelvetColors.shareBlue,
                            VelvetColors.dareCrimson,
                          ],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                      shadows: [
                        Shadow(
                          color: VelvetColors.shareBlue.withOpacity(0.3 + _glowController.value * 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Spin the Wheel, Pick Your Poison',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.white54,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // How to Play button
          GestureDetector(
            onTap: _showHowToPlay,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(VesparaIcons.help, color: VelvetColors.lavender, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'How to Play',
                    style: TextStyle(
                      fontSize: 15,
                      color: VelvetColors.lavender,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Heat Level Selection
          _buildHeatSelector(state),
          
          const SizedBox(height: 24),
          
          // Player List
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYERS (${state.players.length}/8)',
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
                        if (state.players.length >= 8) return const SizedBox();
                        return _buildAddPlayerRow();
                      }
                      return _buildPlayerRow(state.players[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Start Button
          if (state.players.length >= 2)
            GestureDetector(
              onTap: state.isLoading ? null : () {
                HapticFeedback.heavyImpact();
                ref.read(velvetRopeProvider.notifier).startGame();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [VelvetColors.shareBlue, VelvetColors.dareCrimson],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: VelvetColors.dareCrimson.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'START GAME',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
            ),
          
          if (state.players.length < 2)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Add at least 2 players to start',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildHeatSelector(VelvetRopeState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VelvetColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HEAT LEVEL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: HeatLevel.values.map((level) {
              final isSelected = state.heatLevel == level;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(velvetRopeProvider.notifier).setHeatLevel(level);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? level.color.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? level.color : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          level == HeatLevel.pg ? '🟢' :
                          level == HeatLevel.pg13 ? '🟡' :
                          level == HeatLevel.r ? '🔴' : '⚫',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          level == HeatLevel.pg ? 'PG' :
                          level == HeatLevel.pg13 ? 'PG-13' :
                          level == HeatLevel.r ? 'R' : 'X',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? level.color : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerRow(VelvetPlayer player, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: VelvetColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: player.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: player.color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: player.color, width: 2),
            ),
            child: Center(
              child: Text(
                player.name[0].toUpperCase(),
                style: TextStyle(
                  color: player.color,
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
              ref.read(velvetRopeProvider.notifier).removePlayer(index);
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
        color: VelvetColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, style: BorderStyle.solid),
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
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Add player name...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  HapticFeedback.lightImpact();
                  ref.read(velvetRopeProvider.notifier).addPlayer(value);
                  _nameController.clear();
                }
              },
            ),
          ),
          IconButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                HapticFeedback.lightImpact();
                ref.read(velvetRopeProvider.notifier).addPlayer(_nameController.text);
                _nameController.clear();
              }
            },
            icon: Icon(VesparaIcons.add, color: VelvetColors.shareBlue),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SPINNING PHASE - THE ORBITAL WHEEL
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildSpinning(VelvetRopeState state) {
    return Container(
      key: const ValueKey('spinning'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive wheel size based on screen
          final wheelSize = (constraints.maxWidth * 0.8).clamp(200.0, 320.0);
          final centerSize = wheelSize * 0.25;
          
          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(velvetRopeProvider.notifier).endGame();
                      },
                      icon: Icon(VesparaIcons.stop, color: Colors.white54),
                    ),
                    Text(
                      'Spin: ${state.totalSpins + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // The Orbital Wheel
              GestureDetector(
                onVerticalDragEnd: _spinVelocity == 0 ? (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() > 100) {
                    _startSpin();
                  }
                } : null,
                onHorizontalDragEnd: _spinVelocity == 0 ? (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() > 100) {
                    _startSpin();
                  }
                } : null,
                child: SizedBox(
                  width: wheelSize,
                  height: wheelSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: wheelSize,
                            height: wheelSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: VelvetColors.shareBlue.withOpacity(0.2 + _pulseController.value * 0.2),
                                  blurRadius: 40 + _pulseController.value * 20,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: VelvetColors.dareCrimson.withOpacity(0.2 + _pulseController.value * 0.2),
                                  blurRadius: 40 + _pulseController.value * 20,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      // The wheel
                      Transform.rotate(
                        angle: _spinAngle,
                        child: CustomPaint(
                          size: Size(wheelSize - 20, wheelSize - 20),
                          painter: OrbitalWheelPainter(players: state.players),
                        ),
                      ),
                      
                      // Center decoration
                      Container(
                        width: centerSize,
                        height: centerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              VelvetColors.surface,
                              VelvetColors.background,
                            ],
                          ),
                          border: Border.all(color: VelvetColors.gold, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: VelvetColors.gold.withOpacity(0.3),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text('🎭', style: TextStyle(fontSize: centerSize * 0.4)),
                        ),
                      ),
                      
                      // Indicator (top)
                      Positioned(
                        top: -5,
                        child: Container(
                          width: 0,
                          height: 0,
                          decoration: const BoxDecoration(),
                          child: CustomPaint(
                            size: const Size(30, 25),
                            painter: IndicatorPainter(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Text(
                _spinVelocity > 0 ? 'Spinning...' : 'Swipe to Spin!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _spinVelocity > 0 ? VelvetColors.gold : Colors.white54,
                ),
              ),
              
              const Spacer(),
            ],
          );
        },
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SELECTION PHASE - SHARE OR DARE
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildSelection(VelvetRopeState state) {
    final player = state.selectedPlayer;
    if (player == null) return const SizedBox();
    
    return Container(
      key: const ValueKey('selection'),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              
              // Selected player
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: player.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: player.color, width: 2),
                ),
                child: Text(
                  player.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: player.color,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              const Text(
                'Choose your fate...',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white54,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // SHARE Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  ref.read(velvetRopeProvider.notifier).selectType(CardType.share);
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
                            VelvetColors.shareBlue.withOpacity(0.8),
                            VelvetColors.shareBlue.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: VelvetColors.shareBlue.withOpacity(0.3 + _pulseController.value * 0.3),
                            blurRadius: 20 + _pulseController.value * 10,
                            spreadRadius: 2 + _pulseController.value * 3,
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Text('🔮', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 6),
                          Text(
                            'SHARE',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Reveal something personal',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // DARE Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  ref.read(velvetRopeProvider.notifier).selectType(CardType.dare);
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
                            VelvetColors.dareCrimson,
                            const Color(0xFFFF4500), // Orange-red fire
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: VelvetColors.dareCrimson.withOpacity(0.3 + _pulseController.value * 0.3),
                            blurRadius: 20 + _pulseController.value * 10,
                            spreadRadius: 2 + _pulseController.value * 3,
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Text('🔥', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 6),
                          Text(
                            'DARE',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Prove your courage',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CARD REVEAL PHASE
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildCardReveal(VelvetRopeState state) {
    final card = state.currentCard;
    final player = state.selectedPlayer;
    if (card == null || player == null) return const SizedBox();
    
    // Start flip animation
    if (state.phase == VelvetPhase.revealing && !_cardFlipController.isAnimating) {
      _cardFlipController.forward().then((_) {
        ref.read(velvetRopeProvider.notifier).cardRevealed();
      });
    }
    
    return Container(
      key: const ValueKey('reveal'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: card.typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(card.typeEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      card.type == CardType.share ? 'SHARE' : 'DARE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: card.typeColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            player.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: player.color,
            ),
          ),
          
          const Spacer(),
          
          // The Card (3D Flip)
          AnimatedBuilder(
            animation: _cardFlipController,
            builder: (context, child) {
              final angle = _cardFlipController.value * pi;
              final showBack = angle < pi / 2;
              
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: showBack
                          ? [VelvetColors.surface, VelvetColors.background]
                          : [card.typeColor.withOpacity(0.2), VelvetColors.surface],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: showBack ? Colors.white24 : card.typeColor.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: card.typeColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: showBack
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                card.typeEmoji,
                                style: const TextStyle(fontSize: 60),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                card.type == CardType.share ? 'SHARE' : 'DARE',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: card.typeColor,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                card.text,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
          
          const Spacer(),
          
          // Action buttons (only after reveal)
          if (state.phase == VelvetPhase.reading)
            Row(
              children: [
                // Skip
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _cardFlipController.reset();
                      ref.read(velvetRopeProvider.notifier).skipCard();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'SKIP ⏭️',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Complete
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      _cardFlipController.reset();
                      ref.read(velvetRopeProvider.notifier).completeCard();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [card.typeColor, card.typeColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'DONE ✅',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // RESULTS PHASE
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildResults(VelvetRopeState state) {
    // Sort players by total completed
    final sortedPlayers = [...state.players]
      ..sort((a, b) => b.totalCompleted.compareTo(a.totalCompleted));
    
    return Container(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          
          const Text('🎭', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          
          const Text(
            'GAME OVER',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: VelvetColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('🔮', 'Shares', state.totalShares, VelvetColors.shareBlue),
                    _buildStatItem('🔥', 'Dares', state.totalDares, VelvetColors.dareCrimson),
                    _buildStatItem('⏭️', 'Skipped', state.totalSkips, Colors.grey),
                  ],
                ),
                const Divider(color: Colors.white12, height: 32),
                Text(
                  '${state.totalSpins} Spins Total',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Leaderboard
          Expanded(
            child: ListView.builder(
              itemCount: sortedPlayers.length,
              itemBuilder: (context, index) {
                final player = sortedPlayers[index];
                final medal = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VelvetColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: index == 0 ? Border.all(color: VelvetColors.gold) : null,
                  ),
                  child: Row(
                    children: [
                      Text(medal, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: player.color,
                          ),
                        ),
                      ),
                      Text(
                        '🔮 ${player.sharesCompleted}  🔥 ${player.daresCompleted}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Play Again
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(velvetRopeProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('EXIT', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    ref.read(velvetRopeProvider.notifier).backToLobby();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [VelvetColors.shareBlue, VelvetColors.dareCrimson],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'PLAY AGAIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String emoji, String label, int value, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HOW TO PLAY MODAL
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _showHowToPlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VelvetColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
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
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [VelvetColors.shareBlue, VelvetColors.dareCrimson],
                ).createShader(bounds),
                child: const Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share or Dare',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 28),
              
              // Game Setup
              _buildRuleSection('🎭', 'SETUP', [
                'Add 2-8 players to join the game',
                'Choose your heat level (PG to X-rated)',
                'Each player gets assigned a unique color',
              ]),
              const SizedBox(height: 20),
              
              // Spin Mechanics
              _buildRuleSection('🎡', 'THE SPIN', [
                'Tap "SPIN" to spin the wheel',
                'The wheel selects a random player',
                'Selected player must choose Share or Dare',
              ]),
              const SizedBox(height: 20),
              
              // Share vs Dare
              _buildRuleSection('🔮', 'SHARE (Blue)', [
                'Reveal something personal about yourself',
                'Share a secret, desire, talent, or memory',
                'Prompts match your heat level',
              ]),
              const SizedBox(height: 20),
              
              _buildRuleSection('🔥', 'DARE (Red)', [
                'Complete a physical or social challenge',
                'Dares match your heat level',
                'Completing earns bonus points',
              ]),
              const SizedBox(height: 20),
              
              // Heat Levels
              _buildRuleSection('🌡️', 'HEAT LEVELS', [
                '🟢 PG - Fun & flirty, keep it clean',
                '🟡 PG-13 - Suggestive, getting warmer',
                '🔴 R - Adult content, things get spicy',
                '⚫ X - Explicit, no limits',
              ]),
              const SizedBox(height: 20),
              
              // Scoring
              _buildRuleSection('🏆', 'SCORING', [
                'Complete prompts to earn points',
                'Track shares and dares completed',
                'Final results show everyone\'s stats',
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRuleSection(String emoji, String title, List<String> rules) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VelvetColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rules.map((rule) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•', style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class OrbitalWheelPainter extends CustomPainter {
  final List<VelvetPlayer> players;
  
  OrbitalWheelPainter({required this.players});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    if (players.isEmpty) return;
    
    final sliceAngle = 2 * pi / players.length;
    
    for (int i = 0; i < players.length; i++) {
      final startAngle = i * sliceAngle - pi / 2;
      
      // Draw slice
      final paint = Paint()
        ..color = players[i].color.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sliceAngle,
          false,
        )
        ..close();
      
      canvas.drawPath(path, paint);
      
      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawPath(path, borderPaint);
      
      // Draw player name
      final textAngle = startAngle + sliceAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);
      
      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + pi / 2);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: players[i].name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      
      canvas.restore();
    }
    
    // Draw outer ring
    final ringPaint = Paint()
      ..color = VelvetColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(center, radius, ringPaint);
  }
  
  @override
  bool shouldRepaint(covariant OrbitalWheelPainter oldDelegate) {
    return oldDelegate.players != players;
  }
}

class IndicatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VelvetColors.gold
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    
    canvas.drawPath(path, paint);
    
    // Shadow
    final shadowPaint = Paint()
      ..color = VelvetColors.gold.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawPath(path, shadowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
