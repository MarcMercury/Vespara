import 'package:flutter/material.dart';
import 'dart:ui';

import '../providers/drama_sutra_provider.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DRAMA SUTRA POSITION CARD
/// Standardized card design for all position cards in the game
/// ════════════════════════════════════════════════════════════════════════════

class DramaSutraCard extends StatelessWidget {
  final DramaPosition position;
  final double width;
  final double height;
  final bool showDetails;
  final bool isBlurred;
  final bool canReveal;
  final VoidCallback? onTap;

  const DramaSutraCard({
    super.key,
    required this.position,
    this.width = 280,
    this.height = 400,
    this.showDetails = true,
    this.isBlurred = false,
    this.canReveal = false,
    this.onTap,
  });

  // Card color palette
  static const Color cardBackground = Color(0xFF1A0A1F);
  static const Color cardSurface = Color(0xFF2D1B35);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color crimsonAccent = Color(0xFFDC143C);
  static const Color textPrimary = Color(0xFFFFF8DC);
  static const Color textSecondary = Color(0xFFBFA6D8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cardSurface,
              cardBackground,
            ],
          ),
          border: Border.all(
            color: goldAccent.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: crimsonAccent.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Background pattern
              _buildBackgroundPattern(),
              
              // Main content
              Column(
                children: [
                  // Top header with intensity badge
                  _buildHeader(),
                  
                  // Position image area (main content)
                  Expanded(
                    child: _buildImageArea(),
                  ),
                  
                  // Bottom section with name and details
                  _buildFooter(),
                ],
              ),
              
              // Corner decorations
              _buildCornerDecorations(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CardPatternPainter(
          color: goldAccent.withOpacity(0.03),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Intensity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getIntensityColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getIntensityColor().withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  position.intensity.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  position.intensity.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _getIntensityColor(),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Difficulty stars
          Row(
            children: List.generate(5, (i) {
              final isActive = i < position.difficulty;
              return Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  isActive ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 16,
                  color: isActive ? goldAccent : goldAccent.withOpacity(0.3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Actual image
            position.imageUrl != null && position.imageUrl!.isNotEmpty
                ? Image.asset(
                    position.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
            
            // Blur overlay when hidden
            if (isBlurred)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      color: cardBackground.withOpacity(0.7),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              canReveal ? Icons.touch_app_rounded : Icons.visibility_off_rounded,
                              color: goldAccent.withOpacity(0.6),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              canReveal ? 'TAP TO REVEAL' : 'HIDDEN',
                              style: TextStyle(
                                color: goldAccent.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            position.intensity.emoji,
            style: const TextStyle(fontSize: 60),
          ),
          const SizedBox(height: 8),
          Text(
            '🎭',
            style: TextStyle(
              fontSize: 32,
              color: goldAccent.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            cardBackground.withOpacity(0.8),
            cardBackground,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Position name - STANDARDIZED PLACEMENT
          Text(
            position.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          
          if (showDetails && position.description != null) ...[
            const SizedBox(height: 8),
            Text(
              position.description!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: textSecondary.withOpacity(0.8),
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCornerDecorations() {
    return Stack(
      children: [
        // Top left corner flourish
        Positioned(
          top: 4,
          left: 4,
          child: _buildCornerFlourish(),
        ),
        // Top right corner flourish
        Positioned(
          top: 4,
          right: 4,
          child: Transform.scale(
            scaleX: -1,
            child: _buildCornerFlourish(),
          ),
        ),
        // Bottom left
        Positioned(
          bottom: 4,
          left: 4,
          child: Transform.scale(
            scaleY: -1,
            child: _buildCornerFlourish(),
          ),
        ),
        // Bottom right
        Positioned(
          bottom: 4,
          right: 4,
          child: Transform.scale(
            scaleX: -1,
            scaleY: -1,
            child: _buildCornerFlourish(),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerFlourish() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _CornerFlourishPainter(color: goldAccent.withOpacity(0.4)),
      ),
    );
  }

  Color _getIntensityColor() {
    switch (position.intensity) {
      case PositionIntensity.romantic:
        return const Color(0xFFE91E63); // Pink
      case PositionIntensity.acrobatic:
        return const Color(0xFF00BCD4); // Cyan
      case PositionIntensity.intimate:
        return const Color(0xFF9C27B0); // Purple
    }
  }
}

/// Custom painter for the background pattern
class _CardPatternPainter extends CustomPainter {
  final Color color;

  _CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw decorative lines
    const spacing = 30.0;
    for (var i = 0.0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(0, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for corner flourishes
class _CornerFlourishPainter extends CustomPainter {
  final Color color;

  _CornerFlourishPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.6, 0);

    canvas.drawPath(path, paint);

    // Small decorative dot
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.15),
      2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact card variant for selection grids
class DramaSutraCardCompact extends StatelessWidget {
  final DramaPosition position;
  final bool isSelected;
  final VoidCallback? onTap;

  const DramaSutraCardCompact({
    super.key,
    required this.position,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2D1B35),
              const Color(0xFF1A0A1F),
            ],
          ),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFFD700) 
                : const Color(0xFFFFD700).withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            children: [
              // Image
              if (position.imageUrl != null)
                Positioned.fill(
                  child: Image.asset(
                    position.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Name at bottom
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  position.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFF8DC),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              
              // Difficulty indicator
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '★' * position.difficulty,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
              ),
              
              // Selection check
              if (isSelected)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Color(0xFF1A0A1F),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
