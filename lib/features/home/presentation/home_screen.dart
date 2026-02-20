import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vespara_gradients.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/page_transitions.dart';
import '../../../core/widgets/premium_effects.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../events/presentation/events_home_screen.dart';
import '../../ludus/presentation/tags_screen.dart';
// Import module screens
import '../../mirror/presentation/mirror_screen.dart';
import '../../nest/presentation/nest_screen.dart';
import '../../planner/presentation/planner_screen.dart';
import '../../shredder/presentation/shredder_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// VESPARA HOME SCREEN
/// The Bento Box Dashboard - 6 Interconnected Modules
/// Now with aurora backgrounds, 3D tilt tiles, glassmorphism, and neon glow
/// ════════════════════════════════════════════════════════════════════════════

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

  /// The 6 Modules — richer accent colors matching VesparaGradients
  static const List<Map<String, dynamic>> _modules = [
    {
      'name': 'DISCOVER',
      'subtitle': 'The Hunt',
      'icon': Icons.travel_explore_rounded,
      'emoji': '🔮',
      'color': Color(0xFFFF6B9D), // Electric rose
      'description': 'Find your next obsession',
    },
    {
      'name': 'CULT',
      'subtitle': 'Your Conquests',
      'icon': Icons.favorite_rounded,
      'emoji': '💜',
      'color': Color(0xFF4ECDC4), // Vibrant teal
      'description': 'CRM for connections',
    },
    {
      'name': 'PLANNER',
      'subtitle': 'Rendezvous',
      'icon': Icons.event_available_rounded,
      'emoji': '🌙',
      'color': Color(0xFFCE93D8), // Soft violet
      'description': 'Schedule encounters',
    },
    {
      'name': 'EXPERIENCES',
      'subtitle': 'The Scene',
      'icon': Icons.local_fire_department_rounded,
      'emoji': '🥂',
      'color': Color(0xFFFFB74D), // Warm amber
      'description': 'Curate gatherings',
    },
    {
      'name': 'SHREDDER',
      'subtitle': 'Clean Slate',
      'icon': Icons.auto_delete_rounded,
      'emoji': '🥀',
      'color': Color(0xFFEF5350), // Vivid crimson
      'description': 'AI cleanup crew',
    },
    {
      'name': 'TAG',
      'subtitle': 'Adult Games',
      'icon': Icons.local_fire_department_rounded,
      'emoji': '🎭',
      'color': Color(0xFFFFD54F), // Bright gold
      'description': 'Games for the daring',
    },
  ];

  /// Screens for each module
  static const List<Widget> _screens = [
    DiscoverScreen(), // 0: Discover
    NestScreen(), // 1: Nest/Sanctum
    PlannerScreen(), // 2: Planner
    EventsHomeScreen(), // 3: Experiences
    ShredderScreen(), // 4: Shredder
    TagScreen(), // 5: TAG
  ];

  @override
  void initState() {
    super.initState();

    // Stagger animation for tile entrance — slightly longer for drama
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Pulse animation for avatar glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Shimmer sweep for stats bar
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Staggered tile entrance with elastic overshoot
    _tileAnimations = List.generate(6, (index) {
      final startTime = index * 0.12;
      final endTime = startTime + 0.45;
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          startTime,
          endTime.clamp(0.0, 1.0),
          curve: Curves.easeOutBack,
        ),
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
    final module = _modules[index];
    final color = module['color'] as Color;

    // Use portal transition with accent color glow
    context.pushPortal(_screens[index], color: color);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(userAnalyticsProvider);
    final analytics = analyticsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: VesparaAnimatedBackground(
        enableAurora: true,
        enableParticles: true,
        particleCount: 20,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 16),
                _buildQuickStats(analytics),
                const SizedBox(height: 20),
                Expanded(child: _buildModuleGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    final displayName = profile?.displayName ?? 'there';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Neon glow title
            VesparaNeonText(
              text: 'KULT',
              style: GoogleFonts.cinzel(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                color: VesparaColors.primary,
              ),
              glowColor: VesparaColors.glow,
              glowRadius: 15,
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back, $displayName',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.secondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        // Mirror link — animated orb with gradient ring
        _buildMirrorOrb(displayName),
      ],
    );
  }

  Widget _buildMirrorOrb(String displayName) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        return GestureDetector(
          onTap: () => context.pushCelestial(const MirrorScreen()),
          child: Row(
            children: [
              Text(
                'Mirror',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: VesparaColors.secondary.withOpacity(0.7 + pulse * 0.3),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      VesparaColors.glow.withOpacity(0.8 + pulse * 0.2),
                      const Color(0xFFFF6B9D).withOpacity(0.5),
                      VesparaColors.glow.withOpacity(0.4),
                    ],
                    begin: Alignment(-1 + pulse, -1),
                    end: Alignment(1 - pulse, 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VesparaColors.glow.withOpacity(0.25 + pulse * 0.15),
                      blurRadius: 20 + pulse * 10,
                      spreadRadius: 2 + pulse * 3,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF6B9D).withOpacity(0.1 + pulse * 0.05),
                      blurRadius: 30,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
                    style: GoogleFonts.cinzel(
                      color: VesparaColors.background,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(dynamic analytics) {
    final stats = analytics == null
        ? [
            _StatData('—', 'Matches', Icons.favorite_rounded),
            _StatData('—', 'Active', Icons.chat_bubble_rounded),
            _StatData('—', 'Dates', Icons.calendar_today_rounded),
            _StatData('—', 'Rate', Icons.trending_up_rounded),
          ]
        : [
            _StatData('${analytics.totalMatches}', 'Matches', Icons.favorite_rounded),
            _StatData('${analytics.activeConversations}', 'Active', Icons.chat_bubble_rounded),
            _StatData('${analytics.datesScheduled}', 'Dates', Icons.calendar_today_rounded),
            _StatData('${analytics.matchRate.toInt()}%', 'Rate', Icons.trending_up_rounded),
          ];

    return VesparaShimmerSweep(
      duration: const Duration(seconds: 5),
      sweepOpacity: 0.06,
      borderRadius: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VesparaColors.surface.withOpacity(0.3),
                  VesparaColors.surface.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: VesparaColors.glow.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < stats.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            VesparaColors.glow.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  _buildQuickStat(stats[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(_StatData stat) => Column(
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 12, color: VesparaColors.glow),
              const SizedBox(width: 4),
              Text(
                stat.value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: VesparaColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: VesparaColors.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );

  Widget _buildModuleGrid() => LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 14.0;
          final tileHeight = (constraints.maxWidth - spacing) / 2 * 0.72;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildModuleRow([0, 1], tileHeight, spacing),
                SizedBox(height: spacing),
                _buildModuleRow([2, 3], tileHeight, spacing),
                SizedBox(height: spacing),
                _buildModuleRow([4, 5], tileHeight, spacing),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );

  Widget _buildModuleRow(List<int> indices, double height, double spacing) =>
      Row(
        children: [
          Expanded(child: _buildModuleTile(indices[0], height)),
          SizedBox(width: spacing),
          Expanded(child: _buildModuleTile(indices[1], height)),
        ],
      );

  Widget _buildModuleTile(int index, double height) {
    final module = _modules[index];
    final color = module['color'] as Color;
    final moduleName = module['name'] as String;
    final gradient = VesparaGradients.forModule(index);

    return AnimatedBuilder(
      animation: _tileAnimations[index],
      builder: (context, child) {
        final value = _tileAnimations[index].value;
        return Transform.scale(
          scale: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: Vespara3DTiltCard(
        maxTiltDegrees: 6,
        borderRadius: 22,
        glowColor: color,
        onTap: () => _navigateToScreen(index),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            // Darker, richer background
            color: const Color(0xFF1E1830),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Gradient accent wash — subtle color in corner
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.25),
                        color.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom gradient accent
              Positioned(
                bottom: -30,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Full tile icon image
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      _getModuleIconPath(moduleName),
                      fit: BoxFit.contain,
                      cacheWidth: 400,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackTile(module, color, gradient),
                    ),
                  ),
                ),
              ),

              // Top-left glass shine accent line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Notification badge
              if (_hasNotification(index))
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
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

  Widget _buildFallbackTile(
    Map<String, dynamic> module,
    Color color,
    LinearGradient gradient,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1830),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            Colors.transparent,
            color.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon with gradient background
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(
                module['icon'] as IconData,
                color: color,
                size: 24,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  String _getModuleIconPath(String moduleName) {
    switch (moduleName) {
      case 'DISCOVER':
        return 'assets/Main Page Tile Icons/Discover1.png';
      case 'CULT':
        return 'assets/Main Page Tile Icons/Cult.png';
      case 'PLANNER':
        return 'assets/Main Page Tile Icons/Planner1.png';
      case 'EXPERIENCES':
        return 'assets/Main Page Tile Icons/Experiences1.png';
      case 'SHREDDER':
        return 'assets/Main Page Tile Icons/Shredder1.png';
      case 'TAG':
        return 'assets/Main Page Tile Icons/TAG1.png';
      default:
        return 'assets/Main Page Tile Icons/Discover1.png';
    }
  }

  bool _hasNotification(int index) => false;
}

/// Simple data class for stats
class _StatData {
  const _StatData(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;
}
