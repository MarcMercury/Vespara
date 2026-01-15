import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/tags_game.dart';

/// Game Card Widget - High-end tarot card / obsidian tablet aesthetic
/// Used in the TAGS game carousel
class GameCardWidget extends StatelessWidget {
  final GameCategory game;
  final ConsentLevel consentLevel;
  final bool isActive;
  
  const GameCardWidget({
    super.key,
    required this.game,
    required this.consentLevel,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: isActive 
          ? Matrix4.identity()
          : Matrix4.identity()..scale(0.95),
      child: Container(
        decoration: BoxDecoration(
          // Obsidian tablet gradient
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VesparaColors.surfaceElevated,
              VesparaColors.surface,
              VesparaColors.background,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
          border: Border.all(
            color: isActive
                ? VesparaColors.glow.withOpacity(0.5)
                : VesparaColors.border,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: VesparaColors.glow.withOpacity(0.2),
                    blurRadius: 25,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
          child: Stack(
            children: [
              // ═══════════════════════════════════════════════════════════════
              // DECORATIVE PATTERNS (Tarot card feel)
              // ═══════════════════════════════════════════════════════════════
              _buildDecorativePattern(),
              
              // ═══════════════════════════════════════════════════════════════
              // CARD CONTENT
              // ═══════════════════════════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.all(VesparaSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top ornament
                    _buildOrnament(),
                    
                    const Spacer(),
                    
                    // Game icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VesparaColors.background.withOpacity(0.5),
                        border: Border.all(
                          color: VesparaColors.glow.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: VesparaColors.glow.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getGameIcon(game),
                        color: VesparaColors.primary,
                        size: 36,
                      ),
                    ),
                    
                    const SizedBox(height: VesparaSpacing.lg),
                    
                    // Game title
                    Text(
                      game.displayName.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        letterSpacing: 3,
                        color: VesparaColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: VesparaSpacing.sm),
                    
                    // Game description
                    Text(
                      game.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Player count & consent level
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Player count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: VesparaColors.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: VesparaColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 14,
                                color: VesparaColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${game.minPlayers}-${game.maxPlayers}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: VesparaColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: VesparaSpacing.sm),
                        
                        // Minimum consent level
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getConsentColor(game.minimumConsentLevel).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getConsentColor(game.minimumConsentLevel).withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            '${game.minimumConsentLevel.emoji} ${game.minimumConsentLevel.displayName}+',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getConsentColor(game.minimumConsentLevel),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: VesparaSpacing.md),
                    
                    // Bottom ornament
                    _buildOrnament(),
                  ],
                ),
              ),
              
              // ═══════════════════════════════════════════════════════════════
              // GLOWING EDGE (when active)
              // ═══════════════════════════════════════════════════════════════
              if (isActive)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.5,
                        colors: [
                          Colors.transparent,
                          VesparaColors.glow.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build decorative pattern for tarot card feel
  Widget _buildDecorativePattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CardPatternPainter(),
      ),
    );
  }
  
  /// Build ornamental divider
  Widget _buildOrnament() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                VesparaColors.glow.withOpacity(0.5),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VesparaColors.glow.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 30,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VesparaColors.glow.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  IconData _getGameIcon(GameCategory game) {
    switch (game) {
      case GameCategory.truthOrDare:
        return Icons.style_outlined;
      case GameCategory.pathOfPleasure:
        return Icons.route_outlined;
      case GameCategory.theOtherRoom:
        return Icons.meeting_room_outlined;
      case GameCategory.coinTossBoard:
        return Icons.casino_outlined;
      case GameCategory.icebreakers:
        return Icons.ac_unit_outlined;
      case GameCategory.sensoryPlay:
        return Icons.touch_app_outlined;
      case GameCategory.kamaSutra:
        return Icons.favorite_outline;
    }
  }
  
  Color _getConsentColor(ConsentLevel level) {
    switch (level) {
      case ConsentLevel.green:
        return VesparaColors.tagsGreen;
      case ConsentLevel.yellow:
        return VesparaColors.tagsYellow;
      case ConsentLevel.red:
        return VesparaColors.tagsRed;
    }
  }
}

/// Custom painter for decorative card patterns
class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VesparaColors.glow.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Draw corner decorations
    final cornerSize = 30.0;
    
    // Top-left corner
    canvas.drawLine(
      Offset(0, cornerSize),
      const Offset(0, 0),
      paint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(cornerSize, 0),
      paint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(size.width - cornerSize, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerSize),
      paint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width, size.height - cornerSize),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerSize, size.height),
      paint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(cornerSize, size.height),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerSize),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
