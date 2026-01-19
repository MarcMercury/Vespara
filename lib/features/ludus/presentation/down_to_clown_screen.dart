import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/tag_rating.dart';
import '../widgets/tag_rating_display.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DOWN TO CLOWN - A Sex-Positive Heads Up-Style Guessing Game
/// "If you know, you know. If you don't—tilt."
/// ════════════════════════════════════════════════════════════════════════════

/// Game state machine
enum DownToClownState {
  home,
  instructions,
  countdown,
  playing,
  results,
}

class DownToClownScreen extends ConsumerStatefulWidget {
  const DownToClownScreen({super.key});

  @override
  ConsumerState<DownToClownScreen> createState() => _DownToClownScreenState();
}

class _DownToClownScreenState extends ConsumerState<DownToClownScreen>
    with TickerProviderStateMixin {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════
  
  DownToClownState _gameState = DownToClownState.home;
  
  // Prompt tracking
  late List<String> _shuffledPrompts;
  int _currentPromptIndex = 0;
  final List<String> _correctPrompts = [];
  final List<String> _passedPrompts = [];
  
  // Timer
  int _timeRemaining = 60;
  Timer? _gameTimer;
  
  // Countdown
  int _countdownValue = 3;
  Timer? _countdownTimer;
  
  // Tilt detection
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double? _calibratedPitch;
  bool _inputLocked = false;
  bool _useMotionControls = true;
  
  // Animation
  late AnimationController _flashController;
  Color _flashColor = Colors.transparent;
  String _flashText = '';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // THE NAUGHTY LIST - Single Deck (50 Prompts)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const List<String> _theNaughtyList = [
    'Flirting with intent',
    'Bedroom eyes',
    'Late-night "you up?" text',
    'Thirst trap',
    'Accidental moan',
    'Situationship',
    'Friends with benefits',
    'Morning-after confidence',
    '"I shouldn\'t be into this"',
    'Sexual tension',
    'Safe word',
    'Aftercare',
    'Praise kink',
    'Power bottom',
    'Brat energy',
    'Switch vibes',
    'Soft dom',
    'Hard limit',
    'Consent check',
    'Negotiation kink',
    'Rope bunny',
    'Impact play',
    'Service top',
    'Exhibitionist',
    'Voyeur',
    'Pet play',
    'Collar moment',
    'Dungeon etiquette',
    'Orgasm control',
    'Edge play',
    'CNC (consensual, not chaotic)',
    'Mommy issues (the fun kind)',
    'Daddy energy',
    'Protocol scene',
    'Subspace',
    'Top drop',
    'Marks with meaning',
    'Public but subtle',
    'Scene negotiation',
    '"Use me" energy',
    'Kink math',
    'Group chat consent',
    'Poly calendar nightmare',
    'Compersion high',
    'Afterparty cuddle puddle',
    'Everyone\'s watching (they aren\'t)',
    'Sex-positive panic',
    'Too many safeties',
    'Emotional aftercare spiral',
    '"That escalated consensually"',
  ];
  
  @override
  void initState() {
    super.initState();
    _shuffledPrompts = List.from(_theNaughtyList)..shuffle();
    
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _checkMotionPermissions();
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _flashController.dispose();
    super.dispose();
  }
  
  Future<void> _checkMotionPermissions() async {
    // On web, motion controls may not be available
    // Will fall back to touch controls if accelerometer fails
    try {
      _accelerometerSubscription = accelerometerEvents.listen((event) {
        // Permissions granted, motion controls available
      });
      await Future.delayed(const Duration(milliseconds: 100));
      if (_accelerometerSubscription != null) {
        setState(() => _useMotionControls = true);
      }
    } catch (e) {
      setState(() => _useMotionControls = false);
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content based on state
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildCurrentState(),
            ),
            
            // Flash overlay for correct/pass feedback
            if (_flashColor != Colors.transparent)
              AnimatedBuilder(
                animation: _flashController,
                builder: (context, child) {
                  return Container(
                    color: _flashColor.withOpacity(
                      0.4 * (1 - _flashController.value),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: 1 - _flashController.value,
                        child: Text(
                          _flashText,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: _flashColor == Colors.green
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentState() {
    switch (_gameState) {
      case DownToClownState.home:
        return _buildHomeScreen();
      case DownToClownState.instructions:
        return _buildInstructionsScreen();
      case DownToClownState.countdown:
        return _buildCountdownScreen();
      case DownToClownState.playing:
        return _buildPlayingScreen();
      case DownToClownState.results:
        return _buildResultsScreen();
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // HOME SCREEN
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildHomeScreen() {
    return Container(
      key: const ValueKey('home'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2D1B4E),
            const Color(0xFF1A0A2E),
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
            ),
          ),
          
          const Spacer(),
          
          // Logo/Title
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Clown emoji with glow
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: VesparaColors.glow.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Text(
                    '🤡',
                    style: TextStyle(fontSize: 80),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      VesparaColors.glow,
                      Colors.pinkAccent,
                      VesparaColors.glow,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'DOWN TO CLOWN',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Tagline
                Text(
                  '"If you know, you know. If you don\'t—tilt."',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // TAG Rating Display
                const TagRatingDisplay(rating: TagRating.downToClown),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Get Naughty button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    setState(() => _gameState = DownToClownState.instructions);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          VesparaColors.glow,
                          Colors.pinkAccent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: VesparaColors.glow.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'GET NAUGHTY 😈',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // How It Works button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showHowItWorks();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Center(
                      child: Text(
                        'How It Works',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
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
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
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
            _buildHowToRow('📱', 'Hold phone to forehead'),
            _buildHowToRow('👀', 'Others see the word'),
            _buildHowToRow('🗣️', 'They give you clues'),
            _buildHowToRow('⬇️', 'Tilt DOWN = Got it!'),
            _buildHowToRow('⬆️', 'Tilt UP = Pass'),
            _buildHowToRow('⏱️', '60 seconds per round'),
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
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // INSTRUCTIONS SCREEN
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildInstructionsScreen() {
    return Container(
      key: const ValueKey('instructions'),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🤡',
            style: TextStyle(fontSize: 60),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'READY?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInstructionItem(
                  '📱',
                  'Hold phone to forehead',
                  'Screen facing out so others can see',
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildInstructionItem(
                  '⬇️',
                  'Tilt DOWN',
                  'You got it right! (Green flash)',
                ),
                const Divider(color: Colors.white12, height: 24),
                _buildInstructionItem(
                  '⬆️',
                  'Tilt UP',
                  'Skip to next prompt (Orange flash)',
                ),
              ],
            ),
          ),
          
          if (!_useMotionControls) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Motion unavailable. Use touch buttons instead.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          
          // Let's Go button
          GestureDetector(
            onTap: _startCountdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [VesparaColors.glow, Colors.pinkAccent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: VesparaColors.glow.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Text(
                "LET'S GO 🔥",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: () => setState(() => _gameState = DownToClownState.home),
            child: const Text(
              'Back',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstructionItem(String emoji, String title, String subtitle) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 16),
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
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // COUNTDOWN SCREEN
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _startCountdown() {
    setState(() {
      _gameState = DownToClownState.countdown;
      _countdownValue = 3;
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      HapticFeedback.lightImpact();
      
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
      } else {
        timer.cancel();
        _startPlaying();
      }
    });
  }
  
  Widget _buildCountdownScreen() {
    return Container(
      key: const ValueKey('countdown'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _countdownValue > 0 ? '$_countdownValue' : 'GO!',
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.w800,
                color: VesparaColors.glow,
                shadows: [
                  Shadow(
                    color: VesparaColors.glow.withOpacity(0.5),
                    blurRadius: 40,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Get that phone up! 📱',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYING SCREEN
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _startPlaying() {
    // Reset state
    _correctPrompts.clear();
    _passedPrompts.clear();
    _currentPromptIndex = 0;
    _shuffledPrompts = List.from(_theNaughtyList)..shuffle();
    _timeRemaining = 60;
    _calibratedPitch = null;
    _inputLocked = false;
    
    setState(() => _gameState = DownToClownState.playing);
    
    // Start timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        _endGame();
      }
    });
    
    // Start accelerometer listening for tilt detection
    if (_useMotionControls) {
      _startTiltDetection();
    }
  }
  
  void _startTiltDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (_gameState != DownToClownState.playing || _inputLocked) return;
      
      // Calculate pitch (forward/backward tilt)
      final pitch = atan2(event.y, sqrt(event.x * event.x + event.z * event.z)) * 180 / pi;
      
      // Calibrate on first reading
      _calibratedPitch ??= pitch;
      
      // Relative pitch from calibrated position
      final relativePitch = pitch - _calibratedPitch!;
      
      // Thresholds
      const tiltThreshold = 35.0; // degrees
      
      if (relativePitch > tiltThreshold) {
        // Tilted UP = Pass
        _registerPass();
      } else if (relativePitch < -tiltThreshold) {
        // Tilted DOWN = Correct
        _registerCorrect();
      }
    });
  }
  
  void _registerCorrect() {
    if (_inputLocked || _gameState != DownToClownState.playing) return;
    
    HapticFeedback.heavyImpact();
    _correctPrompts.add(_shuffledPrompts[_currentPromptIndex]);
    _showFlash(Colors.green, 'Yes, Daddy. 😈');
    _nextPrompt();
  }
  
  void _registerPass() {
    if (_inputLocked || _gameState != DownToClownState.playing) return;
    
    HapticFeedback.lightImpact();
    _passedPrompts.add(_shuffledPrompts[_currentPromptIndex]);
    _showFlash(Colors.orange, 'Not Tonight. 😅');
    _nextPrompt();
  }
  
  void _showFlash(Color color, String text) {
    setState(() {
      _flashColor = color;
      _flashText = text;
    });
    _flashController.forward(from: 0);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _flashColor = Colors.transparent);
      }
    });
  }
  
  void _nextPrompt() {
    _inputLocked = true;
    
    // Lock input for 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _gameState == DownToClownState.playing) {
        setState(() {
          _currentPromptIndex++;
          
          // Reshuffle if we run out
          if (_currentPromptIndex >= _shuffledPrompts.length) {
            _shuffledPrompts.shuffle();
            _currentPromptIndex = 0;
          }
          
          _inputLocked = false;
          _calibratedPitch = null; // Recalibrate
        });
      }
    });
  }
  
  void _endGame() {
    _gameTimer?.cancel();
    _accelerometerSubscription?.cancel();
    HapticFeedback.heavyImpact();
    setState(() => _gameState = DownToClownState.results);
  }
  
  Widget _buildPlayingScreen() {
    final currentPrompt = _shuffledPrompts[_currentPromptIndex];
    
    return Container(
      key: const ValueKey('playing'),
      child: Column(
        children: [
          // Timer bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Score
                Row(
                  children: [
                    const Text('😈', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      '${_correctPrompts.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
                
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _timeRemaining <= 10
                        ? Colors.red.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_timeRemaining}s',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _timeRemaining <= 10 ? Colors.redAccent : Colors.white,
                    ),
                  ),
                ),
                
                // Pass count
                Row(
                  children: [
                    Text(
                      '${_passedPrompts.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('😅', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ],
            ),
          ),
          
          // Main prompt area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  currentPrompt,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          // Touch fallback buttons (always visible for accessibility)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _registerPass,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Center(
                        child: Text(
                          'SKIP IT ⬆️',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _registerCorrect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Center(
                        child: Text(
                          'GOT IT ⬇️',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ),
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
  // RESULTS SCREEN
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildResultsScreen() {
    return Container(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          // Header
          Text(
            'You came up with ${_correctPrompts.length}!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _getResultMessage(),
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Results lists
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nailed It
                  if (_correctPrompts.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text('😈', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          'Nailed It (${_correctPrompts.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _correctPrompts.map((p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.5)),
                        ),
                        child: Text(
                          p,
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Blue-Balled
                  if (_passedPrompts.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text('😅', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          'Blue-Balled (${_passedPrompts.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _passedPrompts.map((p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.withOpacity(0.5)),
                        ),
                        child: Text(
                          p,
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Buttons
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _gameState = DownToClownState.home);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Center(
                      child: Text(
                        'HOME',
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
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    _startCountdown();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [VesparaColors.glow, Colors.pinkAccent],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'GO AGAIN 🔥',
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
  
  String _getResultMessage() {
    final count = _correctPrompts.length;
    if (count >= 15) return 'Absolute deviant. We respect it. 🔥';
    if (count >= 10) return 'You definitely know your kinks. 😏';
    if (count >= 5) return 'Not bad, keep practicing! 😈';
    if (count >= 1) return 'Baby steps into the dark side. 🌙';
    return 'Maybe stick to vanilla? 🍦';
  }
}
