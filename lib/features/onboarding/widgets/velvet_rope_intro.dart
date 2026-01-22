import 'dart:math' as math;
import 'package:flutter/material.dart';

/// VelvetRopeIntro - The Exclusive Entry Animation
/// A dramatic, sensual curtain reveal that makes users feel special
class VelvetRopeIntro extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration duration;
  
  const VelvetRopeIntro({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 4500),
  });
  
  @override
  State<VelvetRopeIntro> createState() => _VelvetRopeIntroState();
}

class _VelvetRopeIntroState extends State<VelvetRopeIntro>
    with TickerProviderStateMixin {
  
  late AnimationController _mainController;
  late AnimationController _glowController;
  late AnimationController _textController;
  
  // Animation phases
  late Animation<double> _leftCurtainAnim;
  late Animation<double> _rightCurtainAnim;
  late Animation<double> _ropeDropAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _fadeOutAnim;
  late Animation<double> _titleFadeAnim;
  late Animation<double> _subtitleFadeAnim;
  late Animation<double> _welcomeFadeAnim;
  
  bool _showTapPrompt = false;
  bool _hasBeenTapped = false;
  
  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    // Glow pulsing effect
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Text reveal controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Set up animations
    _setupAnimations();
    
    // Start the sequence
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textController.forward();
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() => _showTapPrompt = true);
          }
        });
      }
    });
  }
  
  void _setupAnimations() {
    // Glow animation (ambient pulsing)
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Rope drop animation (0-15% of timeline)
    _ropeDropAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.15, curve: Curves.easeOutBack),
      ),
    );
    
    // Left curtain opens (15-70%)
    _leftCurtainAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.70, curve: Curves.easeInOutCubic),
      ),
    );
    
    // Right curtain opens (15-70%)
    _rightCurtainAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.70, curve: Curves.easeInOutCubic),
      ),
    );
    
    // Fade out to reveal next screen (85-100%)
    _fadeOutAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Text animations
    _titleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    
    _subtitleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _welcomeFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Trigger completion callback when animation ends
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }
  
  void _triggerEntry() {
    if (_hasBeenTapped) return;
    setState(() {
      _hasBeenTapped = true;
      _showTapPrompt = false;
    });
    _mainController.forward();
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to ensure we have valid constraints before building
    return LayoutBuilder(
      builder: (context, constraints) {
        // Guard against zero constraints which can cause shader/rendering issues
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return Container(
            color: const Color(0xFF0A0A0F),
          );
        }
        
        return GestureDetector(
          onTap: _triggerEntry,
          child: AnimatedBuilder(
            animation: Listenable.merge([_mainController, _glowController, _textController]),
            builder: (context, child) {
              return Opacity(
                opacity: _fadeOutAnim.value,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A0A0F),
                  ),
                  child: Stack(
                    children: [
                      // Background ambient glow
                      _buildAmbientGlow(),
                      
                      // The exclusive inner world (glimpse through curtains)
                      _buildInnerWorld(),
                      
                      // Left velvet curtain
                      _buildCurtain(isLeft: true),
                      
                      // Right velvet curtain
                      _buildCurtain(isLeft: false),
                      
                      // Velvet rope
                      _buildVelvetRope(),
                      
                      // Gold stanchions
                      _buildStanchions(),
                      
                      // Text overlay
                      _buildTextOverlay(),
                      
                      // Tap prompt
                      if (_showTapPrompt && !_hasBeenTapped)
                        _buildTapPrompt(),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildAmbientGlow() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _AmbientGlowPainter(
          glowIntensity: _glowAnim.value,
          curtainProgress: _leftCurtainAnim.value,
        ),
      ),
    );
  }
  
  Widget _buildInnerWorld() {
    // The glimpse of the exclusive world behind the curtains
    return Positioned.fill(
      child: Opacity(
        opacity: _leftCurtainAnim.value * 0.8,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                const Color(0xFF2D1B4E), // Deep purple
                const Color(0xFF1A0A2E), // Darker purple
                const Color(0xFF0A0510), // Almost black
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Floating particles (stars/sparkles)
              ..._buildFloatingParticles(),
              
              // Central glow (the heart of Vespara)
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFD4AF37).withOpacity(0.3 * _leftCurtainAnim.value),
                        const Color(0xFFD4AF37).withOpacity(0.1 * _leftCurtainAnim.value),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.2 * _leftCurtainAnim.value),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildFloatingParticles() {
    final screenSize = MediaQuery.of(context).size;
    // Guard against invalid screen size
    if (screenSize.width <= 0 || screenSize.height <= 0) {
      return [];
    }
    
    final random = math.Random(42);
    return List.generate(20, (index) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final size = 2.0 + random.nextDouble() * 4;
      final delay = random.nextDouble() * 2;
      
      return Positioned(
        left: screenSize.width * x,
        top: screenSize.height * y,
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 500 + (delay * 1000).toInt()),
          opacity: _leftCurtainAnim.value * (0.3 + random.nextDouble() * 0.5),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index.isEven 
                  ? const Color(0xFFD4AF37) 
                  : const Color(0xFFF5E6D3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.5),
                  blurRadius: size * 2,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
  
  Widget _buildCurtain({required bool isLeft}) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Guard against invalid screen width
    if (screenWidth <= 0) {
      return const SizedBox.shrink();
    }
    
    final progress = isLeft ? _leftCurtainAnim.value : _rightCurtainAnim.value;
    
    // Calculate curtain position (opening from center)
    final xOffset = isLeft 
        ? -screenWidth * 0.5 * progress
        : screenWidth * 0.5 * progress;
    
    return Positioned(
      left: isLeft ? xOffset : null,
      right: isLeft ? null : -xOffset,
      top: 0,
      bottom: 0,
      width: screenWidth * 0.55, // Slight overlap in center
      child: CustomPaint(
        painter: _VelvetCurtainPainter(
          isLeft: isLeft,
          foldProgress: progress,
        ),
        child: Container(),
      ),
    );
  }
  
  Widget _buildVelvetRope() {
    final screenHeight = MediaQuery.of(context).size.height;
    // Guard against invalid screen height
    if (screenHeight <= 0) {
      return const SizedBox.shrink();
    }
    
    final dropProgress = _ropeDropAnim.value;
    final openProgress = _leftCurtainAnim.value;
    
    return Positioned(
      left: 0,
      right: 0,
      top: screenHeight * 0.5 - 40,
      child: Transform.translate(
        offset: Offset(0, -100 * (1 - dropProgress)), // Drop from above
        child: Opacity(
          opacity: dropProgress * (1 - openProgress * 0.5),
          child: Center(
            child: Container(
              width: 200 + openProgress * 100, // Stretch as curtains open
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B0000),
                    const Color(0xFFDC143C),
                    const Color(0xFF8B0000),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC143C).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rope texture (subtle horizontal lines)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomPaint(
                      size: const Size(300, 8),
                      painter: _RopeTexturePainter(),
                    ),
                  ),
                  // Gold accents on ends
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFD700),
                            const Color(0xFFD4AF37),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFD700),
                            const Color(0xFFD4AF37),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStanchions() {
    final screenHeight = MediaQuery.of(context).size.height;
    // Guard against invalid screen height
    if (screenHeight <= 0) {
      return const SizedBox.shrink();
    }
    
    final dropProgress = _ropeDropAnim.value;
    final openProgress = _leftCurtainAnim.value;
    final separation = 100 + openProgress * 80;
    
    return Positioned(
      left: 0,
      right: 0,
      top: screenHeight * 0.5 - 100,
      child: Opacity(
        opacity: dropProgress * (1 - openProgress * 0.7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSingleStanchion(),
            SizedBox(width: separation),
            _buildSingleStanchion(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSingleStanchion() {
    return Container(
      width: 20,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFD700),
            const Color(0xFFD4AF37),
            const Color(0xFFB8860B),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top ornament
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFD700),
                  const Color(0xFFD4AF37),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Base
          Container(
            width: 35,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFFB8860B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextOverlay() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          
          // Main title
          Opacity(
            opacity: _titleFadeAnim.value * (1 - _leftCurtainAnim.value * 0.8),
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _titleFadeAnim.value)),
              child: Text(
                'VESPARA',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 16,
                  color: const Color(0xFFD4AF37),
                  shadows: [
                    Shadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Opacity(
            opacity: _subtitleFadeAnim.value * (1 - _leftCurtainAnim.value * 0.8),
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _subtitleFadeAnim.value)),
              child: Text(
                'WHERE DESIRE MEETS DISCRETION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 4,
                  color: const Color(0xFFF5E6D3).withOpacity(0.8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 120),
          
          // Welcome message
          Opacity(
            opacity: _welcomeFadeAnim.value * (1 - _leftCurtainAnim.value),
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _welcomeFadeAnim.value)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'YOU\'VE BEEN INVITED',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 6,
                    color: Color(0xFFF5E6D3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTapPrompt() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: 1.0,
        child: Column(
          children: [
            // Pulsing ring
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 60 + (_glowAnim.value * 10),
                  height: 60 + (_glowAnim.value * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(_glowAnim.value),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.touch_app,
                      color: Color(0xFFD4AF37),
                      size: 28,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'TAP TO ENTER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 4,
                color: const Color(0xFFF5E6D3).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _AmbientGlowPainter extends CustomPainter {
  final double glowIntensity;
  final double curtainProgress;
  
  _AmbientGlowPainter({
    required this.glowIntensity,
    required this.curtainProgress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Guard against zero or invalid size to prevent shader issues
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    
    // Top corner glows
    final cornerRadius = size.width * 0.5;
    if (cornerRadius > 0) {
      final topGlowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.1 * glowIntensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(0, 0),
          radius: cornerRadius,
        ));
      
      canvas.drawCircle(Offset(0, 0), cornerRadius, topGlowPaint);
      canvas.drawCircle(Offset(size.width, 0), cornerRadius, topGlowPaint);
    }
    
    // Center glow (increases as curtains open)
    final centerRadius = size.width * 0.6;
    if (centerRadius > 0 && curtainProgress > 0) {
      final centerGlowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.15 * curtainProgress),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: centerRadius,
        ));
      
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        centerRadius,
        centerGlowPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.curtainProgress != curtainProgress;
  }
}

class _VelvetCurtainPainter extends CustomPainter {
  final bool isLeft;
  final double foldProgress;
  
  _VelvetCurtainPainter({
    required this.isLeft,
    required this.foldProgress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Guard against zero or invalid size to prevent shader issues
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    
    final rect = Offset.zero & size;
    
    // Base velvet gradient (deep crimson)
    final velvetGradient = LinearGradient(
      begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      colors: const [
        Color(0xFF4A0E1C), // Dark wine
        Color(0xFF8B1538), // Rich crimson
        Color(0xFF5C0E1F), // Deep burgundy
        Color(0xFF3A0A14), // Almost black red
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    
    final paint = Paint()..shader = velvetGradient.createShader(rect);
    canvas.drawRect(rect, paint);
    
    // Vertical fold lines (velvet draping)
    final foldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final foldCount = 8;
    for (var i = 0; i < foldCount; i++) {
      final x = size.width * (i + 1) / (foldCount + 1);
      final waveAmplitude = 3.0 + (i.isEven ? 2.0 : 0.0);
      
      // Create wavy fold line
      final path = Path()..moveTo(x, 0);
      
      for (var y = 0.0; y < size.height; y += 20) {
        final wave = math.sin(y / 50 + i) * waveAmplitude;
        path.lineTo(x + wave, y);
      }
      path.lineTo(x, size.height);
      
      // Shadow side of fold
      foldPaint.color = const Color(0xFF2A0510).withOpacity(0.3);
      canvas.drawPath(path.shift(const Offset(2, 0)), foldPaint);
      
      // Highlight side of fold
      foldPaint.color = const Color(0xFFB8294A).withOpacity(0.15);
      canvas.drawPath(path, foldPaint);
    }
    
    // Gold trim on inner edge
    final trimRect = isLeft 
        ? Rect.fromLTWH(size.width - 4, 0, 4, size.height)
        : Rect.fromLTWH(0, 0, 4, size.height);
    
    final trimGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFD4AF37).withOpacity(0.6),
        const Color(0xFFFFD700).withOpacity(0.8),
        const Color(0xFFD4AF37).withOpacity(0.6),
      ],
    );
    
    final trimPaint = Paint()..shader = trimGradient.createShader(trimRect);
    canvas.drawRect(trimRect, trimPaint);
    
    // Gathered effect at top
    final topGatherPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2A0510),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 80));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 80), topGatherPaint);
  }
  
  @override
  bool shouldRepaint(covariant _VelvetCurtainPainter oldDelegate) {
    return oldDelegate.foldProgress != foldProgress;
  }
}

class _RopeTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Guard against zero or invalid size
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    
    final linePaint = Paint()
      ..color = const Color(0xFF5C0E1F).withOpacity(0.4)
      ..strokeWidth = 0.5;
    
    // Subtle braided texture lines
    for (var i = 0; i < size.width; i += 4) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble() + 2, size.height),
        linePaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
