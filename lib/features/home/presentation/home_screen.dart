import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/data/vespara_mock_data.dart';

// Import all 8 module screens
import '../../mirror/presentation/mirror_screen.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../nest/presentation/nest_screen.dart';
import '../../wire/presentation/wire_screen.dart';
import '../../planner/presentation/planner_screen.dart';
import '../../events/presentation/events_home_screen.dart';
import '../../shredder/presentation/shredder_screen.dart';
import '../../ludus/presentation/tags_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// VESPARA HOME SCREEN
/// The Bento Box Dashboard - 8 Interconnected Modules
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
  
  /// The 8 Modules per user specification
  /// Icons carefully curated for allure and mystery
  static const List<Map<String, dynamic>> _modules = [
    {
      'name': 'MIRROR',
      'subtitle': 'Your Reflection ✧',
      'icon': Icons.face_retouching_natural_rounded,
      'emoji': '🪞',
      'color': Color(0xFFBFA6D8), // Glow
      'description': 'Brutal AI feedback',
    },
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
      'name': 'WIRE',
      'subtitle': 'Whispers 🫦',
      'icon': Icons.forum_rounded,
      'emoji': '🫦',
      'color': Color(0xFF64B5F6), // Blue
      'description': 'Secrets exchanged',
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
      'name': 'GROUP',
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
      'subtitle': 'Play Games 🎭',
      'icon': Icons.local_fire_department_rounded,
      'emoji': '🎭',
      'color': Color(0xFFFFD54F), // Yellow
      'description': 'Games for the daring',
    },
  ];

  /// Screens for each module
  static const List<Widget> _screens = [
    MirrorScreen(),      // 0: Mirror - Profile/Analytics
    DiscoverScreen(),    // 1: Discover - Swipe Marketplace
    NestScreen(),        // 2: Nest - CRM Roster
    WireScreen(),        // 3: Wire - Chat
    PlannerScreen(),     // 4: Planner - Calendar
    EventsHomeScreen(),  // 5: Group - Partiful-Style Events
    ShredderScreen(),    // 6: Shredder - AI Cleanup
    TagScreen(),         // 7: TAG - Games
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
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(userAnalyticsProvider);
    final analytics = analyticsAsync.valueOrNull ?? MockDataProvider.analytics;
    
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
            Text(
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
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
        
        // Profile avatar with pulse
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return GestureDetector(
              onTap: () => _navigateToScreen(0), // Go to Mirror
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      VesparaColors.glow.withOpacity(0.7 + _pulseController.value * 0.3),
                      VesparaColors.glow.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VesparaColors.glow.withOpacity(0.2 + _pulseController.value * 0.1),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V',
                    style: TextStyle(
                      color: VesparaColors.background,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildQuickStats(dynamic analytics) {
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
          _buildQuickStat('${analytics.totalMatches}', 'Matches', Icons.favorite),
          Container(width: 1, height: 30, color: VesparaColors.glow.withOpacity(0.2)),
          _buildQuickStat('${analytics.activeConversations}', 'Active', Icons.chat_bubble),
          Container(width: 1, height: 30, color: VesparaColors.glow.withOpacity(0.2)),
          _buildQuickStat('${analytics.datesScheduled}', 'Dates', Icons.calendar_today),
          Container(width: 1, height: 30, color: VesparaColors.glow.withOpacity(0.2)),
          _buildQuickStat('${analytics.matchRate.toInt()}%', 'Rate', Icons.trending_up),
        ],
      ),
    );
  }
  
  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: VesparaColors.glow),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: VesparaColors.primary,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: VesparaColors.secondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildModuleGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 12.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        final tileHeight = tileWidth * 0.75;
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Row 1: Mirror + Discover
              _buildModuleRow([0, 1], tileWidth, tileHeight, spacing),
              SizedBox(height: spacing),
              // Row 2: Nest + Wire
              _buildModuleRow([2, 3], tileWidth, tileHeight, spacing),
              SizedBox(height: spacing),
              // Row 3: Planner + Group
              _buildModuleRow([4, 5], tileWidth, tileHeight, spacing),
              SizedBox(height: spacing),
              // Row 4: Shredder + TAG
              _buildModuleRow([6, 7], tileWidth, tileHeight, spacing),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildModuleRow(List<int> indices, double width, double height, double spacing) {
    return Row(
      children: [
        Expanded(child: _buildModuleTile(indices[0], height)),
        SizedBox(width: spacing),
        Expanded(child: _buildModuleTile(indices[1], height)),
      ],
    );
  }
  
  Widget _buildModuleTile(int index, double height) {
    final module = _modules[index];
    final color = module['color'] as Color;
    
    return AnimatedBuilder(
      animation: _tileAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _tileAnimations[index].value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _tileAnimations[index].value)),
            child: Opacity(
              opacity: _tileAnimations[index].value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToScreen(index),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon
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
                    
                    // Text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module['name'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: VesparaColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          module['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: VesparaColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
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
  
  bool _hasNotification(int index) {
    // Show notifications for certain modules
    switch (index) {
      case 1: return true;  // Discover - new profiles
      case 2: return true;  // Nest - new match
      case 3: return true;  // Wire - unread messages
      case 6: return true;  // Shredder - suggestions
      default: return false;
    }
  }
}
