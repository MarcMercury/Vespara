import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
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
/// Mirror accessible via header, Wire merged into Sanctum (Nest)
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
  late List<Animation<double>> _tileAnimations;

  /// The 6 Modules per user specification (Mirror accessed via header, Wire merged into Sanctum)
  /// Icons carefully curated for allure and mystery
  static const List<Map<String, dynamic>> _modules = [
    {
      'name': 'DISCOVER',
      'subtitle': 'The Hunt 🔮',
      'icon': Icons.travel_explore_rounded,
      'emoji': '🔮',
      'color': Color(0xFFE57373), // Pink/Red
      'description': 'Find your next obsession',
    },
    {
      'name': 'NEST',
      'subtitle': 'Your Conquests 💜',
      'icon': Icons.favorite_rounded,
      'emoji': '💜',
      'color': Color(0xFF4DB6AC), // Teal
      'description': 'CRM for connections',
    },
    {
      'name': 'PLANNER',
      'subtitle': 'Rendezvous 🌙',
      'icon': Icons.event_available_rounded,
      'emoji': '🌙',
      'color': Color(0xFFBA68C8), // Purple
      'description': 'Schedule encounters',
    },
    {
      'name': 'EXPERIENCES',
      'subtitle': 'The Scene 🥂',
      'icon': Icons.local_fire_department_rounded,
      'emoji': '🥂',
      'color': Color(0xFFFFB74D), // Orange
      'description': 'Curate gatherings',
    },
    {
      'name': 'SHREDDER',
      'subtitle': 'Clean Slate 🥀',
      'icon': Icons.auto_delete_rounded,
      'emoji': '🥀',
      'color': Color(0xFFE57373), // Red
      'description': 'AI cleanup crew',
    },
    {
      'name': 'TAG',
      'subtitle': 'Trusted Adult Games 🎭',
      'icon': Icons.local_fire_department_rounded,
      'emoji': '🎭',
      'color': Color(0xFFFFD54F), // Yellow
      'description': 'Games for the daring',
    },
  ];

  /// Screens for each module (Mirror via header, Wire merged into Sanctum)
  static const List<Widget> _screens = [
    DiscoverScreen(), // 0: Discover - Swipe Marketplace
    NestScreen(), // 1: Nest/Sanctum - CRM Roster + Wire Chats
    PlannerScreen(), // 2: Planner - Calendar
    EventsHomeScreen(), // 3: Group - Partiful-Style Events
    ShredderScreen(), // 4: Shredder - AI Cleanup
    TagScreen(), // 5: TAG - Games
  ];

  @override
  void initState() {
    super.initState();

    // Stagger animation for tile entrance
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Pulse animation for highlights
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Create staggered animations for each tile
    _tileAnimations = List.generate(6, (index) {
      final startTime = index * 0.1;
      final endTime = startTime + 0.4;
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(startTime, endTime.clamp(0.0, 1.0),
            curve: Curves.easeOutBack,),
      );
    });

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToScreen(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _screens[index],
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(userAnalyticsProvider);
    final analytics = analyticsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildQuickStats(analytics),
              const SizedBox(height: 20),
              Expanded(child: _buildModuleGrid()),
            ],
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
            const Text(
              'VESPARA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Welcome back, $displayName',
              style: const TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),

        // Mirror link with avatar and label
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) => GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MirrorScreen()),
            ),
            child: Row(
              children: [
                const Text(
                  'Mirror',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: VesparaColors.secondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        VesparaColors.glow
                            .withOpacity(0.7 + _pulseController.value * 0.3),
                        VesparaColors.glow.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: VesparaColors.glow
                            .withOpacity(0.2 + _pulseController.value * 0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
                      style: const TextStyle(
                        color: VesparaColors.background,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(dynamic analytics) {
    if (analytics == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VesparaColors.glow.withOpacity(0.15),
              VesparaColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickStat('—', 'Matches', Icons.favorite),
            Container(width: 1, height: 30, color: VesparaColors.glow.withOpacity(0.2)),
            _buildQuickStat('—', 'Active', Icons.chat_bubble),
            Container(width: 1, height: 30, color: VesparaColors.glow.withOpacity(0.2)),
            _buildQuickStat('—', 'Dates', Icons.calendar_today),
            Container(width: 1, height: 30, color: VesparaColors.glow.withOpacity(0.2)),
            _buildQuickStat('—', 'Rate', Icons.trending_up),
          ],
        ),
      );
    }
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VesparaColors.glow.withOpacity(0.15),
              VesparaColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickStat(
                '${analytics.totalMatches}', 'Matches', Icons.favorite,),
            Container(
                width: 1,
                height: 30,
                color: VesparaColors.glow.withOpacity(0.2),),
            _buildQuickStat('${analytics.activeConversations}', 'Active',
                Icons.chat_bubble,),
            Container(
                width: 1,
                height: 30,
                color: VesparaColors.glow.withOpacity(0.2),),
            _buildQuickStat(
                '${analytics.datesScheduled}', 'Dates', Icons.calendar_today,),
            Container(
                width: 1,
                height: 30,
                color: VesparaColors.glow.withOpacity(0.2),),
            _buildQuickStat(
                '${analytics.matchRate.toInt()}%', 'Rate', Icons.trending_up,),
          ],
        ),
      );
  }

  Widget _buildQuickStat(String value, String label, IconData icon) => Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: VesparaColors.glow),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: VesparaColors.primary,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      );

  Widget _buildModuleGrid() => LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final tileWidth = (constraints.maxWidth - spacing) / 2;
          final tileHeight = tileWidth * 0.65;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Row 1: Discover + Nest
                _buildModuleRow([0, 1], tileWidth, tileHeight * 1.1, spacing),
                const SizedBox(height: spacing),
                // Row 2: Planner + Experiences
                _buildModuleRow([2, 3], tileWidth, tileHeight * 1.1, spacing),
                const SizedBox(height: spacing),
                // Row 3: Shredder + TAG
                _buildModuleRow([4, 5], tileWidth, tileHeight * 1.1, spacing),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );

  Widget _buildModuleRow(
          List<int> indices, double width, double height, double spacing,) =>
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

    return AnimatedBuilder(
      animation: _tileAnimations[index],
      builder: (context, child) => Transform.scale(
        scale: _tileAnimations[index].value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _tileAnimations[index].value)),
          child: Opacity(
            opacity: _tileAnimations[index].value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () => _navigateToScreen(index),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            boxShadow: [
              // Bottom shadow for 3D lifted effect
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              // Ambient shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              // Color accent glow
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Full tile icon image - scaled down to fit within tile
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      _getModuleIconPath(moduleName),
                      fit: BoxFit.contain,
                      cacheWidth: 400,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                      // Fallback to gradient + icon if image not found
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: VesparaColors.surface,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  module['icon'] as IconData,
                                  color: color,
                                  size: 22,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    moduleName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: VesparaColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    module['subtitle'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: VesparaColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    ),
                  ),
                ),
              ),

              // Notification badge (example for some modules)
              if (_hasNotification(index))
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 4,
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

  String _getModuleIconPath(String moduleName) {
    // Map module names to their icon file names
    switch (moduleName) {
      case 'DISCOVER':
        return 'assets/Main Page Tile Icons/Discover1.png';
      case 'NEST':
        return 'assets/Main Page Tile Icons/Sanctum1.png';
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

  bool _hasNotification(int index) {
    // Notification dots disabled for now
    return false;
  }
}
