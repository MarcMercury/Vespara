import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../strategist/presentation/strategist_screen.dart';
import '../../scope/presentation/scope_screen.dart';
import '../../roster/presentation/roster_screen.dart';
import '../../wire/presentation/wire_screen.dart';
import '../../shredder/presentation/shredder_screen.dart';
import '../../ludus/presentation/tags_screen.dart';
import '../../core/presentation/core_screen.dart';
import '../../mirror/presentation/mirror_screen.dart';

/// HomeScreen - The Bento Box Dashboard
/// Beautiful animated tiles that navigate to feature screens
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _staggerController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late List<Animation<double>> _tileAnimations;
  
  // Screens for each tile
  static const List<Widget> _screens = [
    StrategistScreen(),  // 0: The Strategist
    ScopeScreen(),       // 1: The Scope
    RosterScreen(),      // 2: The Roster
    WireScreen(),        // 3: The Wire
    ShredderScreen(),    // 4: The Shredder
    TagsScreen(),        // 5: The Ludus
    CoreScreen(),        // 6: The Core
    MirrorScreen(),      // 7: The Mirror
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Stagger animation for tile entrance
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Pulse animation for tile glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    // Shimmer animation for tile highlights
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    
    // Create staggered animations for each tile
    _tileAnimations = List.generate(8, (index) {
      final startTime = index * 0.1;
      final endTime = startTime + 0.4;
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(startTime, endTime.clamp(0.0, 1.0), curve: Curves.easeOutBack),
      );
    });
    
    _staggerController.forward();
  }
  
  @override
  void dispose() {
    _staggerController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }
  
  void _navigateToScreen(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _screens[index],
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final profile = ref.watch(userProfileProvider);
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════════════
              // HEADER
              // ═══════════════════════════════════════════════════════════════
              _buildHeader(context, user, profile),
              
              const SizedBox(height: 24),
              
              // ═══════════════════════════════════════════════════════════════
              // BENTO GRID - 8 Tiles
              // ═══════════════════════════════════════════════════════════════
              Expanded(
                child: _buildBentoGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, dynamic user, AsyncValue profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VESPARA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 6,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.when(
                data: (p) => 'Welcome back, ${p?.displayName ?? 'Explorer'}',
                loading: () => 'Loading...',
                error: (_, __) => 'Demo Mode',
              ),
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
        
        // Profile avatar with glow
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VesparaColors.surface,
                border: Border.all(
                  color: VesparaColors.glow.withOpacity(0.3 + _pulseController.value * 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: VesparaColors.glow.withOpacity(0.1 + _pulseController.value * 0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user?.email?.substring(0, 1).toUpperCase() ?? 'V',
                  style: TextStyle(
                    color: VesparaColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildBentoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final spacing = 12.0;
        final tileWidth = (totalWidth - spacing) / 2;
        // Uniform height for all tiles - creates clean grid
        final tileHeight = tileWidth * 0.9;
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ═══════════════════════════════════════════════════════════════
              // ROW 1: The Engine (Strategist + Scope)
              // ═══════════════════════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedTile(
                      index: 0,
                      label: 'STRATEGIST',
                      subtitle: 'AI Dating Coach',
                      icon: Icons.psychology,
                      height: tileHeight,
                      accentColor: VesparaColors.glow,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildAnimatedTile(
                      index: 1,
                      label: 'SCOPE',
                      subtitle: 'Profile Analyzer',
                      icon: Icons.explore,
                      height: tileHeight,
                      accentColor: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: spacing),
              
              // ═══════════════════════════════════════════════════════════════
              // ROW 2: The Workflow (Roster + Wire)
              // ═══════════════════════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedTile(
                      index: 2,
                      label: 'ROSTER',
                      subtitle: 'Match Manager',
                      icon: Icons.people,
                      height: tileHeight,
                      accentColor: VesparaColors.success,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildAnimatedTile(
                      index: 3,
                      label: 'WIRE',
                      subtitle: 'Conversations',
                      icon: Icons.message,
                      height: tileHeight,
                      accentColor: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: spacing),
              
              // ═══════════════════════════════════════════════════════════════
              // ROW 3: The Experience (Shredder + Ludus)
              // ═══════════════════════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedTile(
                      index: 4,
                      label: 'SHREDDER',
                      subtitle: 'Ghost Protocol',
                      icon: Icons.delete_sweep,
                      height: tileHeight,
                      accentColor: VesparaColors.warning,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildAnimatedTile(
                      index: 5,
                      label: 'LUDUS',
                      subtitle: 'TAGS Games',
                      icon: Icons.casino,
                      height: tileHeight,
                      accentColor: VesparaColors.tagsYellow,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: spacing),
              
              // ═══════════════════════════════════════════════════════════════
              // ROW 4: The Data (Core + Mirror)
              // ═══════════════════════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedTile(
                      index: 6,
                      label: 'CORE',
                      subtitle: 'Settings',
                      icon: Icons.settings,
                      height: tileHeight,
                      accentColor: VesparaColors.primary,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildAnimatedTile(
                      index: 7,
                      label: 'MIRROR',
                      subtitle: 'Analytics',
                      icon: Icons.analytics,
                      height: tileHeight,
                      accentColor: VesparaColors.glow,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedTile({
    required int index,
    required String label,
    required String subtitle,
    required IconData icon,
    required double height,
    required Color accentColor,
  }) {
    return AnimatedBuilder(
      animation: _tileAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: 0.5 + (_tileAnimations[index].value * 0.5),
          child: Opacity(
            opacity: _tileAnimations[index].value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: _VesparaTile(
        index: index,
        label: label,
        subtitle: subtitle,
        icon: icon,
        height: height,
        accentColor: accentColor,
        pulseAnimation: _pulseController,
        shimmerAnimation: _shimmerController,
        onTap: () => _navigateToScreen(index),
      ),
    );
  }
}

/// Individual animated tile with hover effects and glow
class _VesparaTile extends StatefulWidget {
  final int index;
  final String label;
  final String subtitle;
  final IconData icon;
  final double height;
  final Color accentColor;
  final AnimationController pulseAnimation;
  final AnimationController shimmerAnimation;
  final VoidCallback onTap;

  const _VesparaTile({
    required this.index,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.height,
    required this.accentColor,
    required this.pulseAnimation,
    required this.shimmerAnimation,
    required this.onTap,
  });

  @override
  State<_VesparaTile> createState() => _VesparaTileState();
}

class _VesparaTileState extends State<_VesparaTile> 
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _tapController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _tapController.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _tapController.reverse();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            widget.pulseAnimation,
            widget.shimmerAnimation,
          ]),
          builder: (context, child) {
            final pulseValue = widget.pulseAnimation.value;
            final shimmerValue = widget.shimmerAnimation.value;
            
            return Transform.scale(
              scale: _scaleAnimation.value * (_isHovered ? 1.02 : 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accentColor.withOpacity(0.08 + pulseValue * 0.04),
                      VesparaColors.surface,
                      VesparaColors.surface.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: _isHovered || _isPressed
                        ? widget.accentColor.withOpacity(0.4)
                        : VesparaColors.glow.withOpacity(0.08 + pulseValue * 0.05),
                    width: _isHovered ? 1.5 : 1,
                  ),
                  boxShadow: [
                    // Outer glow
                    BoxShadow(
                      color: widget.accentColor.withOpacity(
                        _isHovered ? 0.15 : 0.05 + pulseValue * 0.03,
                      ),
                      blurRadius: _isHovered ? 20 : 12,
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                    // Inner shadow for depth
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Shimmer effect
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.05,
                          child: Transform.translate(
                            offset: Offset(
                              (shimmerValue - 0.5) * 200,
                              0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    widget.accentColor.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Floating particles effect
                      ...List.generate(3, (i) {
                        final angle = (shimmerValue * 2 * math.pi) + (i * math.pi / 1.5);
                        final radius = 30.0 + i * 15;
                        return Positioned(
                          left: 30 + math.cos(angle) * radius,
                          top: 30 + math.sin(angle) * radius,
                          child: Container(
                            width: 4 - i * 0.5,
                            height: 4 - i * 0.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.accentColor.withOpacity(0.2 - i * 0.05),
                            ),
                          ),
                        );
                      }),
                      
                      // Icon with glow
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.accentColor.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accentColor.withOpacity(0.2 + pulseValue * 0.1),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            size: 28,
                            color: widget.accentColor.withOpacity(0.9),
                          ),
                        ),
                      ),
                      
                      // Labels
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.5,
                                color: VesparaColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: VesparaColors.secondary.withOpacity(0.8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tap ripple indicator
                      if (_isPressed)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: widget.accentColor.withOpacity(0.1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
