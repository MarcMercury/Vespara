import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/tag_rating.dart';
import '../../../core/providers/drama_sutra_provider.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/widgets/drama_sutra_card.dart';
import '../widgets/tag_rating_display.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DRAMA-SUTRA v2 - SIMPLIFIED
/// "Strike a Pose!" - Director describes, group poses, camera captures
/// ════════════════════════════════════════════════════════════════════════════

class DramaColors {
  static const background = Color(0xFF1A0A1F);
  static const surface = Color(0xFF2D1B35);
  static const gold = Color(0xFFFFD700);
  static const crimson = Color(0xFFDC143C);
  static const spotlight = Color(0xFFFFF8DC);
}

class DramaSutraScreen extends ConsumerStatefulWidget {
  const DramaSutraScreen({super.key});

  @override
  ConsumerState<DramaSutraScreen> createState() => _DramaSutraScreenState();
}

class _DramaSutraScreenState extends ConsumerState<DramaSutraScreen>
    with TickerProviderStateMixin {
  // Animation
  late AnimationController _pulseController;
  late AnimationController _countdownController;

  // Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isTakingPhoto = false;

  // Timer
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize with 2 players
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dramaSutraProvider.notifier).setPlayerCount(2);
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _cameraController?.dispose();
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMERA
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Prefer back camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<Uint8List?> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isTakingPhoto) {
      return null;
    }

    try {
      setState(() => _isTakingPhoto = true);
      HapticFeedback.heavyImpact();

      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();

      setState(() => _isTakingPhoto = false);
      return bytes;
    } catch (e) {
      debugPrint('Photo capture error: $e');
      setState(() => _isTakingPhoto = false);
      return null;
    }
  }

  void _disposeCamera() {
    _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMER
  // ═══════════════════════════════════════════════════════════════════════════

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final state = ref.read(dramaSutraProvider);

      if (state.timerRemaining > 1) {
        ref.read(dramaSutraProvider.notifier).tickTimer();

        // Vibrate at 10, 5, 4, 3, 2, 1
        if (state.timerRemaining <= 10) {
          HapticFeedback.lightImpact();
        }
      } else {
        // Timer hit 0 - auto capture!
        timer.cancel();

        final photoData = await _capturePhoto();
        if (photoData != null) {
          ref.read(dramaSutraProvider.notifier).setPhoto(photoData);
        } else {
          ref.read(dramaSutraProvider.notifier).skipToReview();
        }

        _disposeCamera();
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onActionPressed() async {
    HapticFeedback.heavyImpact();

    // Initialize camera
    await _initializeCamera();

    // Start the round
    ref.read(dramaSutraProvider.notifier).startAction();

    // Start timer
    _startTimer();
  }

  void _onScoreSubmitted(ThumbsScore score) {
    HapticFeedback.mediumImpact();
    ref.read(dramaSutraProvider.notifier).submitScore(score);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

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
        return _buildIdleScreen(state);
      case DramaGameState.action:
        return _buildActionScreen(state);
      case DramaGameState.review:
        return _buildReviewScreen(state);
      case DramaGameState.gameOver:
        return _buildGameOverScreen(state);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IDLE SCREEN - Ready to start
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildIdleScreen(DramaSutraState state) => Container(
        key: const ValueKey('idle'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(VesparaIcons.back, color: Colors.white70),
                  ),
                  const Spacer(),
                  if (state.currentRound > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DramaColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Round ${state.currentRound}/${state.maxRounds}',
                        style: const TextStyle(
                          color: DramaColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 24),

              // Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [DramaColors.crimson, DramaColors.gold],
                ).createShader(bounds),
                child: const Text(
                  'DRAMA SUTRA',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Strike a Pose!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 20),

              // TAG Rating
              const TagRatingDisplay(rating: TagRating.dramaSutra),

              const SizedBox(height: 32),

              // Director indicator
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DramaColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DramaColors.gold.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎬 DIRECTOR',
                      style: TextStyle(
                        fontSize: 14,
                        color: DramaColors.gold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Player ${state.directorNumber}',
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pass the phone to this player',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Actor count selector (2 or 3 only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DramaColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Actors:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    // Only 2 or 3 actors allowed
                    ...[2, 3].map((count) {
                      final isSelected = state.playerCount == count;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(dramaSutraProvider.notifier)
                              .setPlayerCount(count);
                        },
                        child: Container(
                          width: 60,
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? DramaColors.gold
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? DramaColors.gold
                                  : Colors.white24,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ACTION button
              GestureDetector(
                onTap: _onActionPressed,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DramaColors.crimson,
                          DramaColors.crimson.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: DramaColors.crimson.withOpacity(
                            0.4 + _pulseController.value * 0.3,
                          ),
                          blurRadius: 20 + _pulseController.value * 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '🎬',
                          style: TextStyle(fontSize: 24),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'ACTION!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // How It Works button
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
      );

  void _showHowItWorks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DramaColors.surface,
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
            _buildHowToRow('1️⃣', 'One player is the Director'),
            _buildHowToRow(
                '2️⃣', 'Director chooses to work with 2 or 3 actors'),
            _buildHowToRow('3️⃣', 'Director presses ACTION'),
            _buildHowToRow('4️⃣',
                'Without using the name of sexual positions, body parts, touching players, or demonstrating the image - get your actors into the pose displayed'),
            _buildHowToRow('5️⃣',
                'When you believe they are in the correct position, aim your phone at the actors and press CUT'),
            _buildHowToRow('',
                'Alternately, point your camera at the actors as time expires'),
            _buildHowToRow('6️⃣',
                'The camera will capture your masterpiece - as a group, rate the Director\'s skills using the thumbs up and down buttons'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToRow(String emoji, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION SCREEN - Timer running, describing
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionScreen(DramaSutraState state) {
    final position = state.currentPosition;
    if (position == null) return const SizedBox();

    final isUrgent = state.timerRemaining <= 10;

    return Container(
      key: const ValueKey('action'),
      child: Column(
        children: [
          // Timer bar
          Container(
            height: 8,
            color: DramaColors.surface,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: state.timerRemaining / state.timerSeconds,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUrgent
                        ? [Colors.red, Colors.orange]
                        : [DramaColors.gold, DramaColors.crimson],
                  ),
                ),
              ),
            ),
          ),

          // Timer display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: isUrgent ? Colors.red.withOpacity(0.2) : DramaColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  VesparaIcons.timer,
                  color: isUrgent ? Colors.red : DramaColors.gold,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${state.timerRemaining}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: isUrgent ? Colors.red : DramaColors.gold,
                  ),
                ),
              ],
            ),
          ),

          // Position card
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DramaSutraCard(
                position: position,
                showDetails: false,
                height: double.infinity,
              ),
            ),
          ),

          // Position name (visible to director)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              position.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: DramaColors.gold,
                letterSpacing: 3,
              ),
            ),
          ),

          // Camera preview
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUrgent ? Colors.red : DramaColors.gold,
                  width: isUrgent ? 3 : 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _isCameraInitialized && _cameraController != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController!),
                          if (isUrgent)
                            Container(
                              color: Colors.red.withOpacity(0.2),
                            ),
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Text(
                              isUrgent
                                  ? '📸 GET READY!'
                                  : '📸 Point at players!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isUrgent ? Colors.red : Colors.white,
                                fontWeight: FontWeight.w700,
                                shadows: const [
                                  Shadow(blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(VesparaIcons.camera,
                                color: Colors.white38, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'Camera loading...',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),

          // CUT button - instantly stops timer and captures photo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _onCutPressed,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade700,
                      Colors.red.shade900,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade400, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cut, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'CUT!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: DramaColors.crimson.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🚫 No name • No body parts • No touching • No demonstrating',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Called when the CUT button is pressed - instantly stops timer and captures photo
  Future<void> _onCutPressed() async {
    HapticFeedback.heavyImpact();

    // Cancel the timer immediately
    _gameTimer?.cancel();

    // Take the photo
    final photoData = await _capturePhoto();
    if (photoData != null) {
      ref.read(dramaSutraProvider.notifier).setPhoto(photoData);
    } else {
      ref.read(dramaSutraProvider.notifier).skipToReview();
    }

    // Dispose camera
    _disposeCamera();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REVIEW SCREEN - Compare and score
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildReviewScreen(DramaSutraState state) {
    final position = state.currentPosition;
    if (position == null) return const SizedBox();

    return Container(
      key: const ValueKey('review'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          const Text(
            '📸 COMPARE!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: DramaColors.gold,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            position.name,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 16),

          // Side by side comparison
          Expanded(
            child: Row(
              children: [
                // Original position
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'THE POSE',
                        style: TextStyle(
                          fontSize: 12,
                          color: DramaColors.gold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: DramaColors.gold, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: position.imageUrl != null
                                ? Image.asset(
                                    position.imageUrl!,
                                    fit: BoxFit.contain,
                                  )
                                : Center(
                                    child: Text(
                                      position.intensity.emoji,
                                      style: const TextStyle(fontSize: 60),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Captured photo
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'YOUR ATTEMPT',
                        style: TextStyle(
                          fontSize: 12,
                          color: DramaColors.crimson,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: DramaColors.crimson, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: state.capturedPhoto != null
                                ? Image.memory(
                                    state.capturedPhoto!,
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          VesparaIcons.camera,
                                          color: Colors.white38,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'No photo captured',
                                          style:
                                              TextStyle(color: Colors.white38),
                                        ),
                                      ],
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
          ),

          const SizedBox(height: 24),

          // Score prompt
          const Text(
            'How did they do?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 16),

          // Thumbs voting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ThumbsScore.values
                .map(
                  (score) => GestureDetector(
                    onTap: () => _onScoreSubmitted(score),
                    child: Container(
                      width: 72,
                      height: 90,
                      decoration: BoxDecoration(
                        color: score.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: score.color, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            score.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${score.points}',
                            style: TextStyle(
                              color: score.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME OVER SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGameOverScreen(DramaSutraState state) => Container(
        key: const ValueKey('gameOver'),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Title
            const Text(
              '🏆 GAME OVER!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: DramaColors.gold,
              ),
            ),

            const SizedBox(height: 32),

            // Scoreboard
            Expanded(
              child: ListView.builder(
                itemCount: state.playerCount,
                itemBuilder: (context, index) {
                  final score =
                      index < state.scores.length ? state.scores[index] : 0;
                  final isWinner = index == state.winnerIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isWinner
                          ? DramaColors.gold.withOpacity(0.2)
                          : DramaColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isWinner ? DramaColors.gold : Colors.white12,
                        width: isWinner ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isWinner ? DramaColors.gold : Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              isWinner ? '👑' : '${index + 1}',
                              style: TextStyle(
                                fontSize: isWinner ? 24 : 18,
                                fontWeight: FontWeight.w700,
                                color: isWinner ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Player ${index + 1}',
                            style: TextStyle(
                              fontSize: 18,
                              color: isWinner ? DramaColors.gold : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$score pts',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isWinner ? DramaColors.gold : Colors.white70,
                          ),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: DramaColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Center(
                        child: Text(
                          'EXIT',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      ref.read(dramaSutraProvider.notifier).resetGame();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [DramaColors.crimson, DramaColors.gold],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'PLAY AGAIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
