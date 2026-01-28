import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import '../../../core/theme/vespara_icons.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// FLASH & FREEZE - GAMEPLAY MODE
/// The phone becomes the Signal Controller with automatic photo capture
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════

class FlashColors {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const green = Color(0xFF00FF7F); // FLASH - Move!
  static const red = Color(0xFFFF3366); // FREEZE - Stop!
  static const yellow = Color(0xFFFFD93D); // COVER - Reverse!
  static const electric = Color(0xFF00D4FF);
  static const white = Color(0xFFF5F5F5);
}

// ═══════════════════════════════════════════════════════════════════════════
// SIGNAL TYPES
// ═══════════════════════════════════════════════════════════════════════════

enum SignalType { green, red, yellow }

extension SignalTypeExtension on SignalType {
  Color get color {
    switch (this) {
      case SignalType.green:
        return FlashColors.green;
      case SignalType.red:
        return FlashColors.red;
      case SignalType.yellow:
        return FlashColors.yellow;
    }
  }

  String get label {
    switch (this) {
      case SignalType.green:
        return 'FLASH';
      case SignalType.red:
        return 'FREEZE';
      case SignalType.yellow:
        return 'COVER';
    }
  }

  String get emoji {
    switch (this) {
      case SignalType.green:
        return '⚡';
      case SignalType.red:
        return '🧊';
      case SignalType.yellow:
        return '↩️';
    }
  }

  String get instruction {
    switch (this) {
      case SignalType.green:
        return 'MOVE! Remove a layer!';
      case SignalType.red:
        return 'STOP! Don\'t move!';
      case SignalType.yellow:
        return 'PUT ONE BACK ON!';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FREEZE CAPTURE - Photo taken during red light
// ═══════════════════════════════════════════════════════════════════════════

class FreezeCapture {
  FreezeCapture({
    required this.imageData,
    required this.timestamp,
    required this.roundNumber,
  });
  final Uint8List imageData;
  final DateTime timestamp;
  final int roundNumber;
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME STATE
// ═══════════════════════════════════════════════════════════════════════════

enum GamePhase { setup, playing, paused, gallery, ended }

// ═══════════════════════════════════════════════════════════════════════════
// MAIN GAME SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class FlashFreezeGameScreen extends StatefulWidget {
  const FlashFreezeGameScreen({super.key});

  @override
  State<FlashFreezeGameScreen> createState() => _FlashFreezeGameScreenState();
}

class _FlashFreezeGameScreenState extends State<FlashFreezeGameScreen>
    with TickerProviderStateMixin {
  // Game state
  GamePhase _phase = GamePhase.setup;
  SignalType _currentSignal = SignalType.green;
  int _roundNumber = 0;
  bool _isTransitioning = false;

  // Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasCameraPermission = false;
  bool _isTakingPhoto = false;

  // Captured photos
  final List<FreezeCapture> _captures = [];

  // Timers
  Timer? _signalTimer;
  Timer? _photoTimer;
  final Random _random = Random();

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _flashController;

  // Game settings
  int _gameDurationMinutes = 3;
  DateTime? _gameStartTime;
  int _totalRounds = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    _photoTimer?.cancel();
    _cameraController?.dispose();
    _pulseController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMERA SETUP
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      // Find front-facing camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _hasCameraPermission = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasCameraPermission = false;
        });
        _showCameraError();
      }
    }
  }

  void _showCameraError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(VesparaIcons.camera, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Camera access needed for freeze photos. Game will continue without photo capture.',),
            ),
          ],
        ),
        backgroundColor: FlashColors.red.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME CONTROL
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _startGame() async {
    setState(() {
      _phase = GamePhase.setup;
    });

    // Initialize camera
    await _initializeCamera();

    setState(() {
      _phase = GamePhase.playing;
      _gameStartTime = DateTime.now();
      _roundNumber = 0;
      _captures.clear();
    });

    // Start the signal sequence
    _scheduleNextSignal();

    // Haptic feedback for game start
    HapticFeedback.heavyImpact();
  }

  void _scheduleNextSignal() {
    if (_phase != GamePhase.playing) return;

    // Check if game time is up
    if (_gameStartTime != null) {
      final elapsed = DateTime.now().difference(_gameStartTime!);
      if (elapsed.inMinutes >= _gameDurationMinutes) {
        _endGame();
        return;
      }
    }

    // Random duration: 3-6 seconds for each signal
    final durationSeconds = 3 + _random.nextInt(4);

    _signalTimer = Timer(Duration(seconds: durationSeconds), () {
      if (_phase == GamePhase.playing) {
        _transitionToNextSignal();
      }
    });
  }

  void _transitionToNextSignal() {
    if (_isTransitioning) return;
    _isTransitioning = true;

    // Flash transition effect
    _flashController.forward().then((_) {
      _flashController.reverse();
    });

    setState(() {
      _totalRounds++;

      // Generate next signal - never repeat the same signal back-to-back
      // Get available signals (excluding current signal)
      final availableSignals =
          SignalType.values.where((s) => s != _currentSignal).toList();

      // Weighted random selection from available signals:
      // Base weights: Green: 50%, Red: 35%, Yellow: 15%
      // Redistribute weights among available signals proportionally
      final roll = _random.nextDouble();
      SignalType newSignal;

      if (_currentSignal == SignalType.green) {
        // Available: Red (35%) and Yellow (15%) -> normalize to Red: 70%, Yellow: 30%
        newSignal = roll < 0.70 ? SignalType.red : SignalType.yellow;
      } else if (_currentSignal == SignalType.red) {
        // Available: Green (50%) and Yellow (15%) -> normalize to Green: 77%, Yellow: 23%
        newSignal = roll < 0.77 ? SignalType.green : SignalType.yellow;
      } else {
        // Current is Yellow - Available: Green (50%) and Red (35%) -> normalize to Green: 59%, Red: 41%
        newSignal = roll < 0.59 ? SignalType.green : SignalType.red;
      }

      _currentSignal = newSignal;
      _roundNumber++;
    });

    // Haptic feedback for signal change
    HapticFeedback.heavyImpact();

    // If RED signal, schedule photo capture after 1 second delay
    if (_currentSignal == SignalType.red && _isCameraInitialized) {
      _photoTimer?.cancel();
      _photoTimer = Timer(const Duration(milliseconds: 1000), _captureFreeze);
    }

    _isTransitioning = false;
    _scheduleNextSignal();
  }

  Future<void> _captureFreeze() async {
    if (!_isCameraInitialized || _cameraController == null || _isTakingPhoto) {
      return;
    }
    if (_phase != GamePhase.playing) return;

    _isTakingPhoto = true;

    try {
      // Visual feedback - flash effect
      _flashController.forward().then((_) => _flashController.reverse());

      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      final capture = FreezeCapture(
        imageData: imageBytes,
        timestamp: DateTime.now(),
        roundNumber: _roundNumber,
      );

      setState(() {
        _captures.add(capture);
      });

      // Light haptic to indicate photo taken
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    } finally {
      _isTakingPhoto = false;
    }
  }

  void _pauseGame() {
    _signalTimer?.cancel();
    _photoTimer?.cancel();
    setState(() {
      _phase = GamePhase.paused;
    });
  }

  void _resumeGame() {
    setState(() {
      _phase = GamePhase.playing;
    });
    _scheduleNextSignal();
  }

  void _endGame() {
    _signalTimer?.cancel();
    _photoTimer?.cancel();

    setState(() {
      _phase = _captures.isNotEmpty ? GamePhase.gallery : GamePhase.ended;
    });

    HapticFeedback.heavyImpact();
  }

  void _viewGallery() {
    setState(() {
      _phase = GamePhase.gallery;
    });
  }

  Future<void> _savePhoto(FreezeCapture capture) async {
    try {
      final result = await ImageGallerySaver.saveImage(
        capture.imageData,
        quality: 90,
        name: 'flash_freeze_${capture.timestamp.millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(VesparaIcons.confirm, color: FlashColors.green),
                SizedBox(width: 8),
                Text('Photo saved! 📸'),
              ],
            ),
            backgroundColor: FlashColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save photo'),
            backgroundColor: FlashColors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAllPhotos() async {
    for (final capture in _captures) {
      await ImageGallerySaver.saveImage(
        capture.imageData,
        quality: 90,
        name: 'flash_freeze_${capture.timestamp.millisecondsSinceEpoch}',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(VesparaIcons.confirm, color: FlashColors.green),
              const SizedBox(width: 8),
              Text('All ${_captures.length} photos saved! 📸'),
            ],
          ),
          backgroundColor: FlashColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetGame() {
    _cameraController?.dispose();
    _cameraController = null;

    setState(() {
      _phase = GamePhase.setup;
      _currentSignal = SignalType.green;
      _roundNumber = 0;
      _captures.clear();
      _isCameraInitialized = false;
      _gameStartTime = null;
      _totalRounds = 0;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: FlashColors.background,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildPhase(),
          ),
        ),
      );

  Widget _buildPhase() {
    switch (_phase) {
      case GamePhase.setup:
        return _buildSetupScreen();
      case GamePhase.playing:
        return _buildGameScreen();
      case GamePhase.paused:
        return _buildPausedScreen();
      case GamePhase.gallery:
        return _buildGalleryScreen();
      case GamePhase.ended:
        return _buildEndScreen();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETUP SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSetupScreen() => Container(
        key: const ValueKey('setup'),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Game icon
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                FlashColors.green.withOpacity(0.3),
                                FlashColors.electric.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: FlashColors.green.withOpacity(
                                    0.2 + _pulseController.value * 0.2,),
                                blurRadius: 40 + _pulseController.value * 20,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('⚡', style: TextStyle(fontSize: 60)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [FlashColors.green, FlashColors.electric],
                        ).createShader(bounds),
                        child: const Text(
                          'FLASH & FREEZE',
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
                        'Signal Controller Mode',
                        style: TextStyle(
                          fontSize: 16,
                          color: FlashColors.electric,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Duration selector
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: FlashColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'GAME DURATION',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildDurationOption(2),
                                const SizedBox(width: 12),
                                _buildDurationOption(3),
                                const SizedBox(width: 12),
                                _buildDurationOption(4),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Camera permission note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FlashColors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: FlashColors.red.withOpacity(0.3),),
                        ),
                        child: const Row(
                          children: [
                            Icon(VesparaIcons.camera,
                                color: FlashColors.red, size: 24,),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Camera will capture freeze moments automatically during RED lights!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Start button
                      GestureDetector(
                        onTap: _startGame,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [FlashColors.green, FlashColors.electric],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: FlashColors.green.withOpacity(0.4),
                                blurRadius: 20,
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
                                'START GAME',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
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

  Widget _buildDurationOption(int minutes) {
    final isSelected = _gameDurationMinutes == minutes;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _gameDurationMinutes = minutes);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? FlashColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? FlashColors.green : Colors.white24,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$minutes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
            Text(
              'min',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.black54 : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME SCREEN - FULLSCREEN SIGNAL
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGameScreen() => GestureDetector(
        onTap: _pauseGame,
        child: AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) => AnimatedContainer(
            key: const ValueKey('playing'),
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: Color.lerp(
                _currentSignal.color,
                Colors.white,
                _flashController.value * 0.5,
              ),
            ),
            child: Stack(
              children: [
                // Main signal display
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Signal emoji
                      Text(
                        _currentSignal.emoji,
                        style: const TextStyle(fontSize: 120),
                      ),

                      const SizedBox(height: 24),

                      // Signal label
                      Text(
                        _currentSignal.label,
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: _getContrastColor(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Instruction
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12,),
                        decoration: BoxDecoration(
                          color: _getContrastColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          _currentSignal.instruction,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _getContrastColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top bar with stats
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Round counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8,),
                          decoration: BoxDecoration(
                            color: _getContrastColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Round $_roundNumber',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _getContrastColor(),
                            ),
                          ),
                        ),

                        // Photo counter
                        if (_captures.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8,),
                            decoration: BoxDecoration(
                              color: _getContrastColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  VesparaIcons.camera,
                                  size: 16,
                                  color: _getContrastColor(),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_captures.length}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _getContrastColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Camera preview (small, in corner)
                if (_isCameraInitialized && _cameraController != null)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getContrastColor().withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  ),

                // Tap to pause hint
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10,),
                      decoration: BoxDecoration(
                        color: _getContrastColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tap anywhere to pause',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getContrastColor().withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Color _getContrastColor() {
    switch (_currentSignal) {
      case SignalType.green:
      case SignalType.yellow:
        return Colors.black;
      case SignalType.red:
        return Colors.white;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAUSED SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPausedScreen() => Container(
        key: const ValueKey('paused'),
        padding: const EdgeInsets.all(24),
        color: FlashColors.background,
        child: Column(
          children: [
            _buildHeader(),
            const Spacer(),

            const Text('⏸️', style: TextStyle(fontSize: 80)),

            const SizedBox(height: 24),

            const Text(
              'GAME PAUSED',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Round $_roundNumber • ${_captures.length} photos captured',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),

            const Spacer(),

            // Resume button
            GestureDetector(
              onTap: _resumeGame,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [FlashColors.green, FlashColors.electric],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'RESUME',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // End game button
            GestureDetector(
              onTap: _endGame,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: FlashColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FlashColors.red.withOpacity(0.5)),
                ),
                child: const Center(
                  child: Text(
                    'END GAME',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FlashColors.red,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // GALLERY SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGalleryScreen() => ColoredBox(
        key: const ValueKey('gallery'),
        color: FlashColors.background,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _phase = GamePhase.ended),
                    icon: const Icon(VesparaIcons.back, color: Colors.white70),
                  ),
                  const Expanded(
                    child: Text(
                      'FREEZE MOMENTS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: _saveAllPhotos,
                    icon: const Icon(VesparaIcons.download,
                        color: FlashColors.green,),
                    tooltip: 'Save All',
                  ),
                ],
              ),
            ),

            // Photo count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_captures.length} hilarious freeze captures',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Photo grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _captures.length,
                itemBuilder: (context, index) {
                  final capture = _captures[index];
                  return _buildPhotoCard(capture, index);
                },
              ),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _saveAllPhotos,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [FlashColors.green, FlashColors.electric],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(VesparaIcons.download, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'SAVE ALL',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _phase = GamePhase.ended),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: FlashColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Center(
                          child: Text(
                            'DONE',
                            style: TextStyle(
                              fontSize: 14,
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
            ),
          ],
        ),
      );

  Widget _buildPhotoCard(FreezeCapture capture, int index) => GestureDetector(
        onTap: () => _showPhotoDetail(capture),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: FlashColors.red.withOpacity(0.5), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo
                Image.memory(
                  capture.imageData,
                  fit: BoxFit.cover,
                ),

                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Round ${capture.roundNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _savePhoto(capture),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: FlashColors.green.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              VesparaIcons.download,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Freeze badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FlashColors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🧊 FREEZE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  void _showPhotoDetail(FreezeCapture capture) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                capture.imageData,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    _savePhoto(capture);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12,),
                    decoration: BoxDecoration(
                      color: FlashColors.green,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      children: [
                        Icon(VesparaIcons.download, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12,),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // END SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEndScreen() => Container(
        key: const ValueKey('ended'),
        padding: const EdgeInsets.all(24),
        color: FlashColors.background,
        child: Column(
          children: [
            _buildHeader(),
            const Spacer(),

            const Text('🎮', style: TextStyle(fontSize: 80)),

            const SizedBox(height: 24),

            const Text(
              'GAME OVER!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 32),

            // Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FlashColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('🔄', 'Rounds', _totalRounds),
                  _buildStatItem('📸', 'Photos', _captures.length),
                  _buildStatItem('⏱️', 'Duration', _gameDurationMinutes,
                      suffix: 'min',),
                ],
              ),
            ),

            const Spacer(),

            // View photos button (if any)
            if (_captures.isNotEmpty) ...[
              GestureDetector(
                onTap: _viewGallery,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [FlashColors.red, FlashColors.yellow],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(VesparaIcons.gallery, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'VIEW ${_captures.length} FREEZE PHOTOS',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Play again button
            GestureDetector(
              onTap: _resetGame,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [FlashColors.green, FlashColors.electric],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'PLAY AGAIN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Exit button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: FlashColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Text(
                    'EXIT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildStatItem(String emoji, String label, int value,
          {String? suffix,}) =>
      Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            suffix != null ? '$value $suffix' : '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMON WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() => Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(VesparaIcons.back, color: Colors.white70),
          ),
          const Spacer(),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [FlashColors.green, FlashColors.electric],
            ).createShader(bounds),
            child: const Text(
              'FLASH & FREEZE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      );
}
