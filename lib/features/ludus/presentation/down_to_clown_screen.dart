import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/domain/models/tag_rating.dart';
import '../../../core/providers/dtc_game_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/utils/web_orientation.dart';
import '../widgets/tag_rating_display.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DOWN TO CLOWN - A Sex-Positive Heads Up-Style Guessing Game
/// "If you know, you know. If you don't—tilt."
/// ════════════════════════════════════════════════════════════════════════════

/// Game state machine - now includes heat selection
enum DownToClownState {
  home,
  heatSelect,
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
  late AnimationController _pulseController;
  Color _flashColor = Colors.transparent;
  String _flashText = '';

  @override
  void initState() {
    super.initState();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _checkMotionPermissions();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _flashController.dispose();
    _pulseController.dispose();
    // Restore portrait orientation on exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Also restore web orientation in case user leaves mid-game
    if (kIsWeb) unlockWebOrientation();
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
    final gameState = ref.watch(dtcGameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A2E),
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2D1B4E),
                    Color(0xFF1A0A2E),
                    Colors.black,
                  ],
                ),
              ),
            ),

            // Main content based on state
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildCurrentState(gameState),
            ),

            // Flash overlay for correct/pass feedback
            if (_flashColor != Colors.transparent)
              AnimatedBuilder(
                animation: _flashController,
                builder: (context, child) => ColoredBox(
                  color: _flashColor.withOpacity(
                    0.5 * (1 - _flashController.value),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 1 - _flashController.value,
                      child: Text(
                        _flashText,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _flashColor == Colors.green
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Loading overlay
            if (gameState.isLoading)
              const ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentState(DtcGameState gameState) {
    switch (_gameState) {
      case DownToClownState.home:
        return _buildHomeScreen(gameState);
      case DownToClownState.heatSelect:
        return _buildHeatSelectScreen(gameState);
      case DownToClownState.instructions:
        return _buildInstructionsScreen();
      case DownToClownState.countdown:
        return _buildCountdownScreen();
      case DownToClownState.playing:
        return _buildPlayingScreen(gameState);
      case DownToClownState.results:
        return _buildResultsScreen(gameState);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOME SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHomeScreen(DtcGameState gameState) => Container(
        key: const ValueKey('home'),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(VesparaIcons.back, color: Colors.white70),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Clown emoji with animated glow
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: VesparaColors.glow.withOpacity(
                                  0.3 + (_pulseController.value * 0.3),
                                ),
                                blurRadius: 40 + (_pulseController.value * 20),
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/GAME ICONS/Down to clown title page.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
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
                      const Text(
                        '"If you know, you know. If you don\'t—tilt."',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.white60,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Stats badge (if has games)
                      if (gameState.userStats != null &&
                          gameState.userStats!.totalGamesPlayed > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8,),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(VesparaIcons.trophy,
                                  color: Colors.amber, size: 18,),
                              const SizedBox(width: 8),
                              Text(
                                'High Score: ${gameState.userStats!.highScore}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${gameState.userStats!.totalGamesPlayed} games',
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Demo mode indicator
                      if (gameState.isDemoMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6,),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(VesparaIcons.play,
                                  color: Colors.orange, size: 16,),
                              SizedBox(width: 8),
                              Text(
                                'Demo Mode • 100 Prompts',
                                style: TextStyle(
                                    color: Colors.orange, fontSize: 12,),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // TAG Rating Display
                      const TagRatingDisplay(rating: TagRating.downToClown),

                      const SizedBox(height: 32),

                      // Buttons
                      // Get Naughty button -> now goes to heat select
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          setState(
                              () => _gameState = DownToClownState.heatSelect,);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [VesparaColors.glow, Colors.pinkAccent],
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
                          'About TAG Ratings →',
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
            _buildHowToRow('🔥', 'Choose your heat level'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEAT SELECT SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeatSelectScreen(DtcGameState gameState) => Container(
        key: const ValueKey('heat-select'),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            const Text(
              '🔥 SELECT YOUR HEAT 🔥',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'How spicy do you want it?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 32),

            Expanded(
              child: ListView(
                children: HeatFilter.values.map((filter) {
                  final isSelected = gameState.heatFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(dtcGameProvider.notifier)
                            .setHeatFilter(filter);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    _getHeatColor(filter).withOpacity(0.3),
                                    _getHeatColor(filter).withOpacity(0.1),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? _getHeatColor(filter)
                                : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _getHeatEmoji(filter),
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    filter.label,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? _getHeatColor(filter)
                                          : Colors.white,
                                    ),
                                  ),
                                  Text(
                                    filter.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                VesparaIcons.confirm,
                                color: _getHeatColor(filter),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Continue button
            GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                setState(() => _gameState = DownToClownState.instructions);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getHeatColor(gameState.heatFilter),
                      _getHeatColor(gameState.heatFilter).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'CONTINUE WITH ${gameState.heatFilter.label.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () =>
                  setState(() => _gameState = DownToClownState.home),
              child:
                  const Text('Back', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );

  Color _getHeatColor(HeatFilter filter) {
    switch (filter) {
      case HeatFilter.mild:
        return Colors.green;
      case HeatFilter.spicy:
        return Colors.orange;
      case HeatFilter.all:
        return VesparaColors.glow;
    }
  }

  String _getHeatEmoji(HeatFilter filter) {
    switch (filter) {
      case HeatFilter.mild:
        return '🌸';
      case HeatFilter.spicy:
        return '🌶️';
      case HeatFilter.all:
        return '🎲';
    }
  }

  Widget _buildHowToRow(String emoji, String text) => Padding(
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

  // ═══════════════════════════════════════════════════════════════════════════
  // INSTRUCTIONS SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInstructionsScreen() => Container(
        key: const ValueKey('instructions'),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/GAME ICONS/Down to clown title page.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
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
                child: const Row(
                  children: [
                    Icon(Icons.touch_app_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
              onPressed: () =>
                  setState(() => _gameState = DownToClownState.home),
              child: const Text(
                'Back',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      );

  Widget _buildInstructionItem(String emoji, String title, String subtitle) =>
      Row(
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

  // ═══════════════════════════════════════════════════════════════════════════
  // COUNTDOWN SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _startCountdown() async {
    // Lock to landscape immediately when the user taps "Let's Go"
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // On web/mobile browsers, use the Screen Orientation API + fullscreen
    if (kIsWeb) await lockWebLandscape();

    // Start a new game in the provider (shuffles deck with Fisher-Yates)
    await ref.read(dtcGameProvider.notifier).startNewGame();

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

  Widget _buildCountdownScreen() => Container(
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYING SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  void _startPlaying() {
    // Timer state
    _timeRemaining = 60;
    _calibratedPitch = null;
    _inputLocked = false;

    // Landscape was already locked in _startCountdown —
    // no need to set it again here.

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

      // In landscape mode, we use X axis for forward/backward tilt
      // (phone is held horizontally with screen facing away from player)
      // X axis: positive = tilted right, negative = tilted left
      // In landscape-left, tilting "forward" (pass) uses positive X
      // Tilting "backward" (correct) uses negative X
      final tiltValue = event.x;

      // Calibrate on first reading
      _calibratedPitch ??= tiltValue;

      // Relative tilt from calibrated position
      final relativeTilt = tiltValue - _calibratedPitch!;

      // Thresholds (in m/s², gravity is ~9.8)
      const tiltThreshold = 5.0;

      if (relativeTilt > tiltThreshold) {
        // Tilted "forward" (top of phone tips away) = Pass
        _registerPass();
      } else if (relativeTilt < -tiltThreshold) {
        // Tilted "backward" (top of phone tips toward) = Correct
        _registerCorrect();
      }
    });
  }

  void _registerCorrect() {
    if (_inputLocked || _gameState != DownToClownState.playing) return;

    HapticFeedback.heavyImpact();
    ref.read(dtcGameProvider.notifier).markCorrect();
    _showFlash(Colors.green, 'Yes, Daddy. 😈');
    _lockInput();
  }

  void _registerPass() {
    if (_inputLocked || _gameState != DownToClownState.playing) return;

    HapticFeedback.lightImpact();
    ref.read(dtcGameProvider.notifier).markPassed();
    _showFlash(Colors.orange, 'Not Tonight. 😅');
    _lockInput();
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

  void _lockInput() {
    _inputLocked = true;

    // Lock input for 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _gameState == DownToClownState.playing) {
        _inputLocked = false;
        _calibratedPitch = null; // Recalibrate
      }
    });
  }

  Future<void> _endGame() async {
    _gameTimer?.cancel();
    _accelerometerSubscription?.cancel();
    HapticFeedback.heavyImpact();

    // Restore portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // On web, unlock orientation and exit fullscreen
    if (kIsWeb) await unlockWebOrientation();

    // Save game session to database
    await ref.read(dtcGameProvider.notifier).endGame();

    setState(() => _gameState = DownToClownState.results);
  }

  Widget _buildPlayingScreen(DtcGameState gameState) {
    final currentPrompt = gameState.currentPrompt;

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
                      '${gameState.correctPrompts.length}',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      color: _timeRemaining <= 10
                          ? Colors.redAccent
                          : Colors.white,
                    ),
                  ),
                ),

                // Pass count
                Row(
                  children: [
                    Text(
                      '${gameState.passedPrompts.length}',
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentPrompt?.prompt ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (currentPrompt != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6,),
                        decoration: BoxDecoration(
                          color: _getPromptHeatColor(currentPrompt.heatLevel)
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          currentPrompt.heatLevel,
                          style: TextStyle(
                            color: _getPromptHeatColor(currentPrompt.heatLevel),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
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

  Widget _buildResultsScreen(DtcGameState gameState) => Container(
        key: const ValueKey('results'),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Header
            Text(
              'You came up with ${gameState.correctPrompts.length}!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              ref.read(dtcGameProvider.notifier).getResultMessage(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Results lists
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nailed It
                    if (gameState.correctPrompts.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('😈', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            'Nailed It (${gameState.correctPrompts.length})',
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
                        children: gameState.correctPrompts
                            .map(
                              (p) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8,),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.green.withOpacity(0.5),),
                                ),
                                child: Text(
                                  p.prompt,
                                  style: const TextStyle(
                                      color: Colors.greenAccent,),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Blue-Balled
                    if (gameState.passedPrompts.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('😅', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            'Blue-Balled (${gameState.passedPrompts.length})',
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
                        children: gameState.passedPrompts
                            .map(
                              (p) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8,),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.orange.withOpacity(0.5),),
                                ),
                                child: Text(
                                  p.prompt,
                                  style: const TextStyle(
                                      color: Colors.orangeAccent,),
                                ),
                              ),
                            )
                            .toList(),
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
                      ref.read(dtcGameProvider.notifier).reset();
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
                        gradient: const LinearGradient(
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

  Color _getPromptHeatColor(String heat) {
    switch (heat) {
      case 'PG':
        return Colors.green;
      case 'PG-13':
        return Colors.lime;
      case 'R':
        return Colors.orange;
      case 'X':
        return Colors.deepOrange;
      case 'XXX':
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}
