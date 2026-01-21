import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:math';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/drama_sutra_provider.dart';
import '../../../core/widgets/drama_sutra_card.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DRAMA-SUTRA - "Pose with Purpose"
/// Kama Sutra meets Improv Comedy
/// The Director's Monitor
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════

class DramaColors {
  static const background = Color(0xFF1A0A1F);
  static const surface = Color(0xFF2D1B35);
  static const gold = Color(0xFFFFD700);
  static const crimson = Color(0xFFDC143C);
  static const spotlight = Color(0xFFFFF8DC);
  static const action = Color(0xFFE53935);
  static const cut = Color(0xFF4CAF50);
}

class DramaSutraScreen extends ConsumerStatefulWidget {
  const DramaSutraScreen({super.key});

  @override
  ConsumerState<DramaSutraScreen> createState() => _DramaSutraScreenState();
}

class _DramaSutraScreenState extends ConsumerState<DramaSutraScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _spotlightController;
  
  final TextEditingController _nameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _spotlightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _spotlightController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dramaSutraProvider);
    
    return Scaffold(
      backgroundColor: DramaColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildPhase(state),
        ),
      ),
    );
  }
  
  Widget _buildPhase(DramaSutraState state) {
    switch (state.gameState) {
      case DramaGameState.idle:
        return _buildEntryScreen(state);
      case DramaGameState.lobby:
        return _buildLobby(state);
      case DramaGameState.casting:
        return _buildCasting(state);
      case DramaGameState.script:
        return _buildScript(state);
      case DramaGameState.action:
        return _buildAction(state);
      case DramaGameState.scoring:
        return _buildScoring(state);
      case DramaGameState.results:
        return _buildResults(state);
      case DramaGameState.gameOver:
        return _buildGameOver(state);
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ENTRY SCREEN
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildEntryScreen(DramaSutraState state) {
    return Container(
      key: const ValueKey('entry'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(VesparaIcons.back, color: Colors.white70),
            ),
          ),
          
          const Spacer(),
          
          // Logo with spotlight effect
          AnimatedBuilder(
            animation: _spotlightController,
            builder: (context, child) {
              final angle = _spotlightController.value * 2 * pi;
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(cos(angle) * 0.3, sin(angle) * 0.3),
                    colors: [
                      DramaColors.spotlight.withOpacity(0.3),
                      DramaColors.crimson.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DramaColors.crimson.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Text('🎬', style: TextStyle(fontSize: 80)),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [DramaColors.gold, DramaColors.crimson],
            ).createShader(bounds),
            child: const Text(
              'DRAMA-SUTRA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Pose with Purpose',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: DramaColors.gold,
              letterSpacing: 2,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: DramaColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🎭 Position + Drama + Judgement',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          
          const Spacer(),
          
          // Start Button
          GestureDetector(
            onTap: () => _showHostDialog(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DramaColors.crimson, Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: DramaColors.crimson.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(VesparaIcons.videoCall, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'DIRECTOR\'S CHAIR',
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
          
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () => _showHowToPlay(),
            child: const Text(
              'How to Play',
              style: TextStyle(fontSize: 14, color: Colors.white38, decoration: TextDecoration.underline),
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
      backgroundColor: DramaColors.surface,
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Enter Your Name', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('The Director always gets named first', style: TextStyle(fontSize: 14, color: Colors.white54)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Your name',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: DramaColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: Icon(VesparaIcons.person, color: DramaColors.gold),
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
                    ref.read(dramaSutraProvider.notifier).hostGame(_nameController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DramaColors.crimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('TAKE THE CHAIR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
      backgroundColor: DramaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75, maxChildSize: 0.9, minChildSize: 0.5, expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Center(child: Text('How to Play', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white))),
              const SizedBox(height: 24),
              _buildHowToStep('🎬', 'Casting', 'Each round, one player is the JUDGE. Everyone else is TALENT.'),
              _buildHowToStep('📜', 'The Script', 'The Judge sees: a POSITION + a SCENARIO + a GENRE.'),
              _buildHowToStep('🎭', 'The Performance', 'The Judge reads the scenario, then reveals the position. Talent has 60 seconds!'),
              _buildHowToStep('✂️', 'The Cut', 'When time\'s up (or Judge calls CUT), it\'s scoring time.'),
              _buildHowToStep('⭐', 'The Scores', 'Judge rates TECHNIQUE (the pose) and DRAMA (the acting) from 0-10.'),
              _buildHowToStep('🔄', 'Rotation', 'Judge role rotates. After all rounds, highest score wins!'),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '💡 The key is COMMITMENT.\nSell that drama like your Oscar depends on it!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DramaColors.gold, height: 1.6, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHowToStep(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LOBBY
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildLobby(DramaSutraState state) {
    return Container(
      key: const ValueKey('lobby'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => ref.read(dramaSutraProvider.notifier).exitGame(),
                icon: Icon(VesparaIcons.close, color: Colors.white54),
              ),
              const Spacer(),
              const Text('CASTING CALL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2, color: Colors.white70)),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Room Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [DramaColors.crimson.withOpacity(0.2), DramaColors.gold.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DramaColors.gold.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Text('PRODUCTION CODE', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white54)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: state.roomCode ?? ''));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!'), duration: Duration(seconds: 1)));
                  },
                  child: Text(
                    state.roomCode ?? '----',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 6, color: DramaColors.gold),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Settings
          if (state.isHost) ...[
            Row(
              children: [
                Expanded(
                  child: _buildSettingTile(
                    'Difficulty',
                    '${state.maxDifficulty} ★',
                    () => _showDifficultyPicker(state),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSettingTile(
                    'Rounds',
                    '${state.maxRounds}',
                    () => _showRoundsPicker(state),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Cast list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THE CAST (${state.players.length}/8)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1, color: Colors.white54)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.players.length + (state.isHost ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.players.length && state.isHost) {
                        return _buildAddPlayerButton();
                      }
                      return _buildPlayerCard(state.players[index], index, state);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Start Button
          if (state.isHost)
            GestureDetector(
              onTap: state.players.length >= 2 ? () {
                HapticFeedback.heavyImpact();
                ref.read(dramaSutraProvider.notifier).startGame();
              } : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: state.players.length >= 2 ? 1.0 : 0.4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [DramaColors.action, Color(0xFFFF7043)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(VesparaIcons.videoCall, color: Colors.white),
                      SizedBox(width: 8),
                      Text('START PRODUCTION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ),
          
          if (state.players.length < 2)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Need at least 2 actors', style: TextStyle(color: Colors.white38, fontSize: 13)),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSettingTile(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DramaColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            Text(value, style: const TextStyle(color: DramaColors.gold, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
  
  void _showDifficultyPicker(DramaSutraState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DramaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Max Position Difficulty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 16),
            ...List.generate(5, (i) {
              final level = i + 1;
              final labels = ['Beginner', 'Easy', 'Intermediate', 'Advanced', 'Gymnast'];
              return ListTile(
                leading: Text(List.generate(5, (j) => j < level ? '★' : '☆').join(), style: const TextStyle(color: DramaColors.gold, fontSize: 16)),
                title: Text(labels[i], style: const TextStyle(color: Colors.white)),
                trailing: state.maxDifficulty == level ? Icon(VesparaIcons.check, color: DramaColors.gold) : null,
                onTap: () {
                  ref.read(dramaSutraProvider.notifier).setMaxDifficulty(level);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
  
  void _showRoundsPicker(DramaSutraState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DramaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Number of Rounds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [3, 5, 7, 10].map((r) {
                final isSelected = state.maxRounds == r;
                return GestureDetector(
                  onTap: () {
                    ref.read(dramaSutraProvider.notifier).setMaxRounds(r);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? DramaColors.gold : DramaColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$r', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isSelected ? Colors.black : Colors.white)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlayerCard(DramaPlayer player, int index, DramaSutraState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DramaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: player.isHost ? Border.all(color: DramaColors.gold.withOpacity(0.5)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: player.avatarColor.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: player.avatarColor, width: 2)),
            child: Center(child: Text(player.displayName[0].toUpperCase(), style: TextStyle(fontSize: 16, color: player.avatarColor, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                if (player.isHost) const Text('DIRECTOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DramaColors.gold, letterSpacing: 1)),
              ],
            ),
          ),
          if (!player.isHost && state.isHost)
            IconButton(
              onPressed: () => ref.read(dramaSutraProvider.notifier).removePlayer(index),
              icon: Icon(VesparaIcons.close, color: Colors.white38, size: 18),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
  
  Widget _buildAddPlayerButton() {
    return GestureDetector(
      onTap: () => _showAddPlayerDialog(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DramaColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(VesparaIcons.addMember, color: Colors.white38, size: 20),
            SizedBox(width: 8),
            Text('Add Actor', style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
  
  void _showAddPlayerDialog() {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DramaColors.surface,
        title: const Text('Add Actor', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Actor name', hintStyle: TextStyle(color: Colors.white38)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                ref.read(dramaSutraProvider.notifier).addLocalPlayer(_nameController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: DramaColors.gold),
            child: const Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CASTING (Role Assignment)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildCasting(DramaSutraState state) {
    return Container(
      key: const ValueKey('casting'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎬', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              'ROUND ${state.currentRound}',
              style: const TextStyle(fontSize: 14, color: Colors.white54, letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            const Text(
              'CASTING...',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DramaColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎥 JUDGE: ', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      Text(
                        state.judge?.displayName ?? '?',
                        style: TextStyle(color: state.judge?.avatarColor ?? Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎭 TALENT: ', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      Text(
                        state.talent.map((t) => t.displayName).join(', '),
                        style: const TextStyle(color: DramaColors.gold, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(width: 80, child: LinearProgressIndicator(color: DramaColors.crimson, backgroundColor: DramaColors.surface)),
          ],
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT (Judge sees position + scenario)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildScript(DramaSutraState state) {
    final position = state.currentPosition;
    final scenario = state.currentScenario;
    if (position == null || scenario == null) return const SizedBox();
    
    return Container(
      key: const ValueKey('script'),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: DramaColors.surface,
            child: Row(
              children: [
                Text('ROUND ${state.currentRound}/${state.maxRounds}', style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: DramaColors.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(state.isJudge ? '👁️ JUDGE VIEW' : '🎭 TALENT', style: TextStyle(color: DramaColors.gold, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Position Card with Blur Toggle
                  _buildPositionCard(position, state.isImageRevealed, state.isJudge),
                  
                  const SizedBox(height: 20),
                  
                  // Scenario Card
                  _buildScenarioCard(scenario),
                  
                  const SizedBox(height: 24),
                  
                  // Instructions
                  if (state.isJudge)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DramaColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Column(
                        children: [
                          Icon(VesparaIcons.suggestion, color: DramaColors.gold, size: 28),
                          SizedBox(height: 8),
                          Text('DIRECTOR\'S NOTES', style: TextStyle(color: DramaColors.gold, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                          SizedBox(height: 8),
                          Text(
                            '1. Read the SCENARIO aloud\n2. Tap the position to REVEAL it\n3. Press ACTION when ready!',
                            style: TextStyle(color: Colors.white70, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DramaColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text('🎬', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 8),
                          Text('GET READY ON SET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('Wait for the Director to reveal the scene...', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Action Button (Judge only)
          if (state.isJudge)
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  ref.read(dramaSutraProvider.notifier).startAction();
                },
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: DramaColors.action,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: DramaColors.action.withOpacity(0.3 + _pulseController.value * 0.3),
                            blurRadius: 20 + _pulseController.value * 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(VesparaIcons.play, color: Colors.white, size: 28),
                          SizedBox(width: 10),
                          Text('ACTION!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPositionCard(DramaPosition position, bool isRevealed, bool isJudge) {
    // Use the standardized DramaSutraCard widget with actual position images
    return Center(
      child: DramaSutraCard(
        position: position,
        width: MediaQuery.of(context).size.width - 48,
        height: 380,
        showDetails: isRevealed,
        isBlurred: !isRevealed,
        canReveal: isJudge,
        onTap: isJudge ? () {
          HapticFeedback.lightImpact();
          ref.read(dramaSutraProvider.notifier).toggleImageReveal();
        } : null,
      ),
    );
  }
  
  Widget _buildScenarioCard(DramaScenario scenario) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scenario.genre.color.withOpacity(0.2), DramaColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scenario.genre.color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(scenario.genre.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scenario.genre.color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scenario.genre.displayName.toUpperCase(),
                  style: TextStyle(color: scenario.genre.color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('THE SCENARIO:', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(
            '"${scenario.text}"',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic, height: 1.4),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION (Timer Running)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildAction(DramaSutraState state) {
    final position = state.currentPosition;
    final scenario = state.currentScenario;
    if (position == null || scenario == null) return const SizedBox();
    
    final progress = state.timerRemaining / state.timerSeconds;
    final isLow = state.timerRemaining <= 10;
    
    return Container(
      key: const ValueKey('action'),
      child: Column(
        children: [
          // Timer Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: DramaColors.surface,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLow 
                        ? [DramaColors.action, const Color(0xFFFF9800)]
                        : [DramaColors.cut, const Color(0xFF8BC34A)],
                  ),
                ),
              ),
            ),
          ),
          
          // Timer Display
          Container(
            padding: const EdgeInsets.all(16),
            color: isLow ? DramaColors.action.withOpacity(0.1) : Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(VesparaIcons.timer, color: isLow ? DramaColors.action : Colors.white54),
                const SizedBox(width: 8),
                Text(
                  '${state.timerRemaining}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: isLow ? DramaColors.action : Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('sec', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          
          // Reference (Position + Scenario)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Mini Position Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: DramaColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(position.intensity.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(position.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                              if (position.description != null)
                                Text(position.description!, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Mini Scenario Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scenario.genre.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scenario.genre.color.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(scenario.genre.emoji),
                            const SizedBox(width: 6),
                            Text(scenario.genre.displayName, style: TextStyle(color: scenario.genre.color, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('"${scenario.text}"', style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // "FILMING" indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: DramaColors.action,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: DramaColors.action.withOpacity(0.5), blurRadius: 8)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('FILMING', style: TextStyle(color: DramaColors.action, letterSpacing: 4, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          
          // CUT Button (Judge only)
          if (state.isJudge)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  ref.read(dramaSutraProvider.notifier).cutAction();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: DramaColors.cut,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(VesparaIcons.stop, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text('CUT!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SCORING (Judge rates)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildScoring(DramaSutraState state) {
    return Container(
      key: const ValueKey('scoring'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('✂️ CUT!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
          const SizedBox(height: 8),
          Text(
            state.isJudge ? 'Rate the performance' : 'Awaiting judgement...',
            style: const TextStyle(color: Colors.white54),
          ),
          
          const SizedBox(height: 32),
          
          if (state.isJudge) ...[
            // Technique Slider
            _buildScoreSlider(
              label: 'TECHNIQUE',
              emoji: '🎯',
              description: 'Did they nail the physical pose?',
              value: state.pendingTechniqueScore,
              onChanged: (v) => ref.read(dramaSutraProvider.notifier).updateTechniqueScore(v),
            ),
            
            const SizedBox(height: 24),
            
            // Drama Slider
            _buildScoreSlider(
              label: 'DRAMA',
              emoji: '🎭',
              description: 'Did they sell the emotion?',
              value: state.pendingDramaScore,
              onChanged: (v) => ref.read(dramaSutraProvider.notifier).updateDramaScore(v),
            ),
            
            const Spacer(),
            
            // Total Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DramaColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('TOTAL: ', style: TextStyle(color: Colors.white54)),
                  Text(
                    '${(state.pendingTechniqueScore + state.pendingDramaScore).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: DramaColors.gold),
                  ),
                  const Text(' / 20', style: TextStyle(color: Colors.white38)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Submit Button
            GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                ref.read(dramaSutraProvider.notifier).submitScores();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [DramaColors.gold, Color(0xFFFFB300)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.balance_rounded, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('SUBMIT VERDICT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Waiting view for talent
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: DramaColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text('⏳', style: TextStyle(fontSize: 60)),
                  SizedBox(height: 16),
                  Text('The judge is deliberating...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildScoreSlider({
    required String label,
    required String emoji,
    required String description,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const Spacer(),
            Text(value.toStringAsFixed(1), style: const TextStyle(color: DramaColors.gold, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            activeTrackColor: DramaColors.gold,
            inactiveTrackColor: DramaColors.surface,
            thumbColor: DramaColors.gold,
            overlayColor: DramaColors.gold.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // RESULTS (Round complete)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildResults(DramaSutraState state) {
    final lastScore = state.roundHistory.isNotEmpty ? state.roundHistory.last : null;
    if (lastScore == null) return const SizedBox();
    
    return Container(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🎬', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          
          // Rating Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DramaColors.gold.withOpacity(0.3), DramaColors.crimson.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              lastScore.ratingLabel,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: DramaColors.gold,
                letterSpacing: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Score Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreBox('🎯', 'Technique', lastScore.techniqueScore),
              const SizedBox(width: 12),
              const Text('+', style: TextStyle(color: Colors.white38, fontSize: 24)),
              const SizedBox(width: 12),
              _buildScoreBox('🎭', 'Drama', lastScore.dramaScore),
              const SizedBox(width: 12),
              const Text('=', style: TextStyle(color: Colors.white38, fontSize: 24)),
              const SizedBox(width: 12),
              _buildScoreBox('⭐', 'Total', lastScore.totalScore, isTotal: true),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Current Standings
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CURRENT STANDINGS', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.leaderboard.length,
                    itemBuilder: (context, index) {
                      final player = state.leaderboard[index];
                      final medal = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DramaColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(medal.isNotEmpty ? medal : '${index + 1}', style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: player.avatarColor, shape: BoxShape.circle),
                              child: Center(child: Text(player.displayName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(player.displayName, style: const TextStyle(color: Colors.white))),
                            Text(player.totalScore.toStringAsFixed(1), style: TextStyle(color: index == 0 ? DramaColors.gold : Colors.white70, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Next Round Button
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              ref.read(dramaSutraProvider.notifier).nextRound();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [DramaColors.crimson, Color(0xFFFF6B6B)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(state.currentRound >= state.maxRounds ? VesparaIcons.trophy : VesparaIcons.forward, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    state.currentRound >= state.maxRounds ? 'FINAL RESULTS' : 'NEXT SCENE',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreBox(String emoji, String label, double score, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTotal ? DramaColors.gold.withOpacity(0.2) : DramaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isTotal ? Border.all(color: DramaColors.gold) : null,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: isTotal ? 24 : 18,
              fontWeight: FontWeight.w900,
              color: isTotal ? DramaColors.gold : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // GAME OVER
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildGameOver(DramaSutraState state) {
    final winner = state.leaderboard.isNotEmpty ? state.leaderboard.first : null;
    
    return Container(
      key: const ValueKey('gameover'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          
          // Trophy
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DramaColors.gold.withOpacity(0.3 + _glowController.value * 0.3),
                      blurRadius: 40 + _glowController.value * 20,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 80)),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          const Text('AND THE OSCAR GOES TO...', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 8),
          
          if (winner != null)
            Text(
              winner.displayName.toUpperCase(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: DramaColors.gold,
                letterSpacing: 2,
              ),
            ),
          
          const SizedBox(height: 8),
          
          if (winner != null)
            Text(
              'Total Score: ${winner.totalScore.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          
          const SizedBox(height: 32),
          
          // Final Leaderboard
          Expanded(
            child: ListView.builder(
              itemCount: state.leaderboard.length,
              itemBuilder: (context, index) {
                final player = state.leaderboard[index];
                final medal = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '';
                final isMe = player.id == state.currentPlayerId;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isMe ? player.avatarColor.withOpacity(0.2) : DramaColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: isMe ? Border.all(color: player.avatarColor) : null,
                  ),
                  child: Row(
                    children: [
                      Text(medal.isNotEmpty ? medal : '${index + 1}', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: player.avatarColor, shape: BoxShape.circle),
                        child: Center(child: Text(player.displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isMe ? player.avatarColor : Colors.white)),
                            Text('${player.roundsAsTalent} performances', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(player.totalScore.toStringAsFixed(1), style: TextStyle(color: index == 0 ? DramaColors.gold : Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                          Text('avg ${player.averageScore.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
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
                    ref.read(dramaSutraProvider.notifier).exitGame();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: DramaColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text('WRAP', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    ref.read(dramaSutraProvider.notifier).playAgain();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [DramaColors.crimson, Color(0xFFFF6B6B)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text('SEQUEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
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
