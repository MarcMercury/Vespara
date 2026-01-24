import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flash_freeze_game_screen.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/domain/models/tag_rating.dart';
import '../widgets/tag_rating_display.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// FLASH & FREEZE - "Exposure requires endurance"
/// The playground classic, evolved.
/// Rules & How to Play screen with animations
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════

class FlashColors {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const green = Color(0xFF00FF7F); // Spring green - FLASH
  static const red = Color(0xFFFF3366); // Hot pink-red - FREEZE
  static const yellow = Color(0xFFFFD93D); // REVERSE
  static const electric = Color(0xFF00D4FF); // Electric blue accents
  static const white = Color(0xFFF5F5F5);
}

class FlashFreezeScreen extends StatefulWidget {
  const FlashFreezeScreen({super.key});

  @override
  State<FlashFreezeScreen> createState() => _FlashFreezeScreenState();
}

class _FlashFreezeScreenState extends State<FlashFreezeScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _signalController;
  
  int _currentSignal = 0; // 0=green, 1=red, 2=yellow
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _signalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Cycle through signals for demo
    _signalController.addListener(() {
      final newSignal = (_signalController.value * 3).floor() % 3;
      if (newSignal != _currentSignal) {
        setState(() => _currentSignal = newSignal);
        HapticFeedback.lightImpact();
      }
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _signalController.dispose();
    super.dispose();
  }
  
  Color get _currentColor {
    switch (_currentSignal) {
      case 0: return FlashColors.green;
      case 1: return FlashColors.red;
      case 2: return FlashColors.yellow;
      default: return FlashColors.green;
    }
  }
  
  String get _currentLabel {
    switch (_currentSignal) {
      case 0: return 'FLASH';
      case 1: return 'FREEZE';
      case 2: return 'COVER';
      default: return 'FLASH';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlashColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildSimpleHeroSection(),
                    const SizedBox(height: 32),
                    _buildStartSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(VesparaIcons.back, color: Colors.white70),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
  
  Widget _buildSimpleHeroSection() {
    return Column(
      children: [
        // Animated Signal Light
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentColor.withOpacity(0.2),
                border: Border.all(color: _currentColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: _currentColor.withOpacity(0.3 + _glowController.value * 0.4),
                    blurRadius: 40 + _glowController.value * 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _currentSignal == 0 ? '⚡' : _currentSignal == 1 ? '🧊' : '↩️',
                    key: ValueKey(_currentSignal),
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Title
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [FlashColors.electric, FlashColors.green, FlashColors.red],
          ).createShader(bounds),
          child: const Text(
            'FLASH & FREEZE',
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
          'Exposure requires endurance.',
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: FlashColors.electric,
            letterSpacing: 1,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // TAG Rating
        const TagRatingDisplay(rating: TagRating.flashFreeze),
        
        const SizedBox(height: 24),
        
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
                Icon(VesparaIcons.help, color: FlashColors.electric, size: 18),
                const SizedBox(width: 8),
                Text(
                  'How to Play',
                  style: TextStyle(
                    fontSize: 15,
                    color: FlashColors.electric,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
      ],
    );
  }
  
  void _showHowToPlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlashColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
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
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSignalsSection(),
              const SizedBox(height: 24),
              _buildEliminationSection(),
              const SizedBox(height: 24),
              _buildWinSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        // Animated Signal Light
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentColor.withOpacity(0.2),
                border: Border.all(color: _currentColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: _currentColor.withOpacity(0.3 + _glowController.value * 0.4),
                    blurRadius: 40 + _glowController.value * 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _currentSignal == 0 ? '⚡' : _currentSignal == 1 ? '🧊' : '↩️',
                    key: ValueKey(_currentSignal),
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Current signal label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(_currentLabel),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _currentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _currentColor.withOpacity(0.5)),
            ),
            child: Text(
              _currentLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _currentColor,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Title
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [FlashColors.electric, FlashColors.green, FlashColors.red],
          ).createShader(bounds),
          child: const Text(
            'FLASH & FREEZE',
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
          'Exposure requires endurance.',
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: FlashColors.electric,
            letterSpacing: 1,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // TAG Rating
        const TagRatingDisplay(rating: TagRating.flashFreeze),
        
        const SizedBox(height: 20),
        
        // Premise
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FlashColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: const Column(
            children: [
              Text(
                'Red Light, Green Light... but make it spicy.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '📸 Camera captures freeze moments!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSignalsSection() {
    return Column(
      children: [
        const Row(
          children: [
            Text('🚦', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(
              'THE SIGNALS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // GREEN LIGHT
        _buildSignalCard(
          emoji: '🟢',
          title: 'GREEN',
          subtitle: 'FLASH',
          color: FlashColors.green,
          description: 'Remove a layer.',
          note: '',
        ),
        
        const SizedBox(height: 12),
        
        // RED LIGHT
        _buildSignalCard(
          emoji: '🔴',
          title: 'RED',
          subtitle: 'FREEZE',
          color: FlashColors.red,
          description: 'Stop instantly. Don\'t move.',
          note: '',
        ),
        
        const SizedBox(height: 12),
        
        // REVERSE
        _buildSignalCard(
          emoji: '↩️',
          title: 'YELLOW',
          subtitle: 'COVER',
          color: FlashColors.yellow,
          description: 'Put one item back on.',
          note: '',
        ),
      ],
    );
  }
  
  Widget _buildSignalCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required String description,
    required String note,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), FlashColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEliminationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FlashColors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FlashColors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('❌', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'YOU\'RE OUT IF YOU...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: FlashColors.red,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEliminationItem('💀', 'Move'),
              _buildEliminationItem('🫠', 'Fall'),
              _buildEliminationItem('😱', 'Fail to Cover'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEliminationItem(String emoji, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
  
  Widget _buildWinSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FlashColors.green.withOpacity(0.1),
            FlashColors.electric.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FlashColors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🏆', style: TextStyle(fontSize: 28)),
              SizedBox(width: 8),
              Text(
                'HOW TO WIN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: FlashColors.green,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Option A
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FlashColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: FlashColors.electric.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🏃', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Option A: The Sprinter',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: FlashColors.electric,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Be the first person to get completely naked and strike a final "Victory Pose" without getting caught moving.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Option B
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FlashColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: FlashColors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🗿', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Option B: The Survivor',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: FlashColors.green,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Simply remain standing while everyone else topples over from poor planning.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Last one standing (or first one bare) takes the glory.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStartSection() {
    return Column(
      children: [
        // Sexy silhouette hint
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                FlashColors.red.withOpacity(0.2),
                FlashColors.background,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Play Button - Navigate to Game
        GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FlashFreezeGameScreen(),
              ),
            );
          },
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [FlashColors.green, FlashColors.electric],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: FlashColors.green.withOpacity(0.3 + _glowController.value * 0.2),
                      blurRadius: 20 + _glowController.value * 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('⚡', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Text(
                      'START',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        const Text(
          'Phone flashes signals • Camera captures freeze moments',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }
}
