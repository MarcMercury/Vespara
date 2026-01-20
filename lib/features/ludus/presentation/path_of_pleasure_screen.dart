import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/path_of_pleasure_provider.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PATH OF PLEASURE - The Compatibility Engine
/// "Timeline/Shit Happens" meets intimate discovery
/// TAG Engine Signature Game
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════

class PleasureColors {
  static const background = Color(0xFF1A1523);      // Deep Obsidian
  static const surface = Color(0xFF2D2438);          // Elevated surface
  static const gold = Color(0xFFFFD700);             // Craving zone / Match
  static const purple = Color(0xFF9B59B6);           // Open zone
  static const darkGrey = Color(0xFF2C2C2C);         // Limit zone
  static const friction = Color(0xFFE74C3C);         // Friction point
  static const lavender = Color(0xFFE0D8EA);         // Soft text
  static const glow = Color(0xFF4A9EFF);             // Ethereal accent
}

class PathOfPleasureScreen extends ConsumerStatefulWidget {
  const PathOfPleasureScreen({super.key});

  @override
  ConsumerState<PathOfPleasureScreen> createState() => _PathOfPleasureScreenState();
}

class _PathOfPleasureScreenState extends ConsumerState<PathOfPleasureScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _glowController;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
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
    _pulseController.dispose();
    _glowController.dispose();
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pathOfPleasureProvider);
    
    return Scaffold(
      backgroundColor: PleasureColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildPhase(state),
        ),
      ),
    );
  }
  
  Widget _buildPhase(PathOfPleasureState state) {
    switch (state.phase) {
      case GamePhase.idle:
        return _buildEntryScreen(state);
      case GamePhase.lobby:
        return _buildLobby(state);
      case GamePhase.sorting:
        return _buildSortingPhase(state);
      case GamePhase.reveal:
        return _buildRevealPhase(state);
      case GamePhase.discussion:
        return _buildDiscussionPhase(state);
      case GamePhase.finished:
        return _buildResultsScreen(state);
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ENTRY SCREEN - Host or Join
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildEntryScreen(PathOfPleasureState state) {
    return Container(
      key: const ValueKey('entry'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
            ),
          ),
          
          const Spacer(),
          
          // Logo
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      PleasureColors.gold.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PleasureColors.gold.withOpacity(0.2 + _glowController.value * 0.2),
                      blurRadius: 40 + _glowController.value * 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Text('🛤️', style: TextStyle(fontSize: 80)),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [PleasureColors.gold, PleasureColors.purple],
            ).createShader(bounds),
            child: const Text(
              'PATH OF PLEASURE',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'The Compatibility Engine',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.white54,
            ),
          ),
          
          const Spacer(),
          
          // Host Game Button
          GestureDetector(
            onTap: () => _showHostDialog(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [PleasureColors.gold, Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: PleasureColors.gold.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: Colors.black87, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'HOST A ROOM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Join Game Button
          GestureDetector(
            onTap: () => _showJoinDialog(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: PleasureColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PleasureColors.purple, width: 2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, color: PleasureColors.purple, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'JOIN A ROOM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: PleasureColors.purple,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // How to play
          GestureDetector(
            onTap: () => _showHowToPlay(),
            child: const Text(
              'How to Play',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white38,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  void _showHostDialog() {
    _nameController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: PleasureColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
              'Create Your Room',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: PleasureColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person, color: PleasureColors.gold),
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
                    ref.read(pathOfPleasureProvider.notifier).hostGame(_nameController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PleasureColors.gold,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CREATE ROOM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showJoinDialog() {
    _nameController.clear();
    _roomCodeController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: PleasureColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
              'Join a Room',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _roomCodeController,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'ROOM CODE',
                hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 4),
                filled: true,
                fillColor: PleasureColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: PleasureColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person, color: PleasureColors.purple),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_roomCodeController.text.trim().isNotEmpty && 
                      _nameController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    HapticFeedback.heavyImpact();
                    ref.read(pathOfPleasureProvider.notifier).joinGame(
                      _roomCodeController.text.trim(),
                      _nameController.text.trim(),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PleasureColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'JOIN ROOM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
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
      backgroundColor: PleasureColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'How to Play',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildHowToStep('1', 'Create or Join', 'One person hosts the room, others join with the code'),
              _buildHowToStep('2', 'Sort the Cards', 'Privately rank 5 cards from "Craving" to "Limit"'),
              _buildHowToStep('3', 'See the Results', 'Discover your Golden Matches and Friction Points'),
              _buildHowToStep('4', 'Discuss', 'Take 30 seconds to talk about the results'),
              _buildHowToStep('5', 'Progress', '3 rounds: Vanilla → Spicy → Edgy'),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '🔥 Golden Match = Both want it\n😬 Friction = Major disagreement',
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
  
  Widget _buildHowToStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: PleasureColors.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LOBBY PHASE - Waiting for Players
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildLobby(PathOfPleasureState state) {
    return Container(
      key: const ValueKey('lobby'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () {
                  ref.read(pathOfPleasureProvider.notifier).exitGame();
                },
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
              const Spacer(),
              const Text(
                'WAITING ROOM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Room Code Display
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      PleasureColors.gold.withOpacity(0.2),
                      PleasureColors.purple.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PleasureColors.gold.withOpacity(0.5 + _pulseController.value * 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PleasureColors.gold.withOpacity(0.2 + _pulseController.value * 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'ROOM CODE',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: state.roomCode ?? ''));
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.roomCode ?? '----',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: PleasureColors.gold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy, color: Colors.white38, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Players List
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
          
          // Deal Cards Button (Host only)
          if (state.isHost)
            GestureDetector(
              onTap: state.players.length >= 2 ? () {
                HapticFeedback.heavyImpact();
                ref.read(pathOfPleasureProvider.notifier).dealCards();
              } : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: state.players.length >= 2 ? 1.0 : 0.5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [PleasureColors.gold, Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: state.players.length >= 2 ? [
                      BoxShadow(
                        color: PleasureColors.gold.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ] : null,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style, color: Colors.black87),
                      SizedBox(width: 12),
                      Text(
                        'DEAL THE CARDS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          if (!state.isHost)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PleasureColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PleasureColors.gold,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Waiting for host to start...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          
          if (state.players.length < 2)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Need at least 2 players',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerCard(PopPlayer player, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PleasureColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: player.isHost 
              ? PleasureColors.gold.withOpacity(0.5) 
              : player.avatarColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: player.avatarColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: player.avatarColor, width: 2),
            ),
            child: Center(
              child: Text(
                player.displayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  color: player.avatarColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (player.isHost)
                  const Text(
                    'HOST',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: PleasureColors.gold,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
          if (player.isLockedIn)
            const Icon(Icons.check_circle, color: Colors.green, size: 24)
          else
            const Icon(Icons.hourglass_empty, color: Colors.white24, size: 24),
        ],
      ),
    );
  }
  
  Widget _buildAddPlayerButton() {
    return GestureDetector(
      onTap: () => _showAddLocalPlayerDialog(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: PleasureColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12, style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, color: Colors.white38),
            SizedBox(width: 8),
            Text(
              'Add Local Player (Pass & Play)',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddLocalPlayerDialog() {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PleasureColors.surface,
        title: const Text('Add Player', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Player name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                ref.read(pathOfPleasureProvider.notifier).addLocalPlayer(_nameController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: PleasureColors.gold),
            child: const Text('Add', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SORTING PHASE - Drag & Drop Cards
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildSortingPhase(PathOfPleasureState state) {
    // Sort rankings by position for display
    final sortedRankings = [...state.myRankings]
      ..sort((a, b) => a.position.compareTo(b.position));
    
    final cards = sortedRankings.map((r) => 
      state.currentCards.firstWhere((c) => c.id == r.cardId)
    ).toList();
    
    return Container(
      key: const ValueKey('sorting'),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: state.currentCategory.color.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: state.currentCategory.color.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  state.currentCategory.displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: state.currentCategory.color,
                  ),
                ),
                const Spacer(),
                Text(
                  'Round ${state.currentRound}/${state.totalRounds}',
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PleasureColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.lockedCount}/${state.players.length} Locked',
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
          
          // Instructions
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Drag cards to rank from CRAVING (top) to LIMIT (bottom)',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Ranking zones + Cards
          Expanded(
            child: Row(
              children: [
                // Zone indicator
                Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      _buildZoneLabel(RankZone.craving, 2),
                      _buildZoneLabel(RankZone.open, 1),
                      _buildZoneLabel(RankZone.limit, 2),
                    ],
                  ),
                ),
                
                // Cards
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    itemCount: cards.length,
                    onReorder: (oldIndex, newIndex) {
                      HapticFeedback.selectionClick();
                      ref.read(pathOfPleasureProvider.notifier).reorderCards(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final ranking = sortedRankings[index];
                      
                      return _buildSortableCard(card, ranking, index);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Lock In Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: state.me?.isLockedIn == true ? null : () {
                HapticFeedback.heavyImpact();
                ref.read(pathOfPleasureProvider.notifier).lockIn();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: state.me?.isLockedIn == true 
                      ? null 
                      : const LinearGradient(colors: [PleasureColors.gold, Color(0xFFFF8C00)]),
                  color: state.me?.isLockedIn == true ? Colors.green.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      state.me?.isLockedIn == true ? Icons.check_circle : Icons.lock,
                      color: state.me?.isLockedIn == true ? Colors.green : Colors.black87,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      state.me?.isLockedIn == true ? 'LOCKED IN!' : 'LOCK IN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: state.me?.isLockedIn == true ? Colors.green : Colors.black87,
                        letterSpacing: 2,
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
  
  Widget _buildZoneLabel(RankZone zone, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              zone.color.withOpacity(0.3),
              zone.color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(zone.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                zone.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: zone.color,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSortableCard(PopCard card, CardRanking ranking, int index) {
    return Container(
      key: ValueKey(card.id),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PleasureColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ranking.zone.color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: ranking.zone.color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: ranking.zone.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ranking.zone.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              card.text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
          const Icon(Icons.drag_handle, color: Colors.white24),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // REVEAL PHASE - Heat Map Results
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildRevealPhase(PathOfPleasureState state) {
    // Get results for current round
    final roundStart = (state.currentRound - 1) * 5;
    final roundResults = state.roundResults.skip(roundStart).take(5).toList();
    
    return Container(
      key: const ValueKey('reveal'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PleasureColors.gold.withOpacity(0.2),
                  PleasureColors.friction.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  'ROUND ${state.currentRound} RESULTS',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Results list
          Expanded(
            child: ListView.builder(
              itemCount: roundResults.length,
              itemBuilder: (context, index) {
                final result = roundResults[index];
                return _buildResultCard(result, state.players);
              },
            ),
          ),
          
          // Loading indicator
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PleasureColors.gold,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Preparing discussion...',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultCard(CardResult result, List<PopPlayer> players) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PleasureColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isGoldenMatch 
              ? PleasureColors.gold 
              : result.isFrictionPoint 
                  ? PleasureColors.friction 
                  : Colors.white24,
          width: 2,
        ),
        boxShadow: result.isGoldenMatch ? [
          BoxShadow(
            color: PleasureColors.gold.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              if (result.isGoldenMatch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PleasureColors.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'GOLDEN MATCH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
              else if (result.isFrictionPoint)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PleasureColors.friction,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('⚡', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'FRICTION POINT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                'Δ${result.maxDelta}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: result.maxDelta >= 3 ? PleasureColors.friction : Colors.white38,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Card text
          Text(
            result.card.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Player rankings
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.playerRankings.entries.map((entry) {
              final player = players.firstWhere(
                (p) => p.id == entry.key,
                orElse: () => PopPlayer(
                  id: entry.key,
                  oduserId: '',
                  displayName: '?',
                  avatarColor: Colors.grey,
                ),
              );
              final zone = _getZoneForPosition(entry.value);
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: zone.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: zone.color.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: player.avatarColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          player.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      zone.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '#${entry.value + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: zone.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  RankZone _getZoneForPosition(int position) {
    if (position <= 1) return RankZone.craving;
    if (position >= 3) return RankZone.limit;
    return RankZone.open;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DISCUSSION PHASE - Timer
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildDiscussionPhase(PathOfPleasureState state) {
    return Container(
      key: const ValueKey('discussion'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          
          // Timer circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: state.discussionSecondsRemaining / 30,
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    state.discussionSecondsRemaining > 10 
                        ? PleasureColors.gold 
                        : PleasureColors.friction,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${state.discussionSecondsRemaining}',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: state.discussionSecondsRemaining > 10 
                          ? PleasureColors.gold 
                          : PleasureColors.friction,
                    ),
                  ),
                  const Text(
                    'SECONDS',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 2,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            '💬 DISCUSSION TIME',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'Talk about the results!\nWhat surprised you? Any friction points to explore?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
          
          const Spacer(),
          
          // Skip button (host only)
          if (state.isHost)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(pathOfPleasureProvider.notifier).skipDiscussion();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: PleasureColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Skip to Next Round →',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // RESULTS SCREEN - Final Compatibility
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildResultsScreen(PathOfPleasureState state) {
    final result = state.finalResult;
    if (result == null) return const SizedBox();
    
    return Container(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          
          // Match percentage
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      PleasureColors.gold.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PleasureColors.gold.withOpacity(0.2 + _glowController.value * 0.2),
                      blurRadius: 40 + _glowController.value * 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${result.matchPercent}%',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: PleasureColors.gold,
                        ),
                      ),
                      const Text(
                        'COMPATIBLE',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 2,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'PLEASURE PROFILE',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '✨',
                  '${result.goldenMatches}',
                  'Golden Matches',
                  PleasureColors.gold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '⚡',
                  '${result.frictionPoints}',
                  'Friction Points',
                  PleasureColors.friction,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Profile summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PleasureColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('💕', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR SWEET SPOT',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              color: Colors.white54,
                            ),
                          ),
                          Text(
                            result.sweetSpot,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: PleasureColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                Row(
                  children: [
                    const Text('🔀', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOU DIFFER ON',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              color: Colors.white54,
                            ),
                          ),
                          Text(
                            result.differOn,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: PleasureColors.friction,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(pathOfPleasureProvider.notifier).exitGame();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: PleasureColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'EXIT',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                    ref.read(pathOfPleasureProvider.notifier).playAgain();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [PleasureColors.gold, Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: PleasureColors.gold.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'PLAY AGAIN',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 1,
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
  
  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
