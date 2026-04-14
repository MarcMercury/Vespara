import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vespara_gradients.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/page_transitions.dart';
import '../../../core/widgets/premium_effects.dart';
import '../../browse/presentation/browse_screen.dart';
import '../../events/presentation/events_home_screen.dart';
import '../../ludus/presentation/tags_screen.dart';
import '../../minis/presentation/minis_screen.dart';
import '../../mirror/presentation/mirror_screen.dart';
import '../../nest/presentation/nest_screen.dart';
import '../../travel/presentation/travel_hub_screen.dart';
import '../../wire/presentation/wire_entry_screen.dart';
import 'welcome_tutorial.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// VESPARA HOME SCREEN — Redesigned
/// Bottom nav with 5 primary sections + Bento dashboard
/// Alluring dark luxury UI for the members-only community
/// ════════════════════════════════════════════════════════════════════════════

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _staggerController;
  late AnimationController _pulseController;
  late List<Animation<double>> _tileAnimations;
  bool _showTutorial = false;
  bool _tutorialChecked = false;

  // Bottom nav destinations
  static const List<_NavItem> _navItems = [
    _NavItem('Home', Icons.dashboard_rounded, VesparaColors.primary),
    _NavItem('Browse', Icons.travel_explore_rounded, Color(0xFFFF6B9D)),
    _NavItem('Wire', Icons.chat_bubble_rounded, Color(0xFF7C4DFF)),
    _NavItem('Events', Icons.event_rounded, Color(0xFF00BFA6)),
    _NavItem('Mirror', Icons.account_circle_rounded, VesparaColors.glow),
  ];

  /// The 6 Dashboard Modules (shown on Home tab)
  static const List<Map<String, dynamic>> _modules = [
    {
      'name': 'BROWSE',
      'subtitle': 'Explore Members',
      'icon': Icons.travel_explore_rounded,
      'emoji': '🔮',
      'color': Color(0xFFFF6B9D),
      'description': 'Discover the community',
    },
    {
      'name': 'SANCTUM',
      'subtitle': 'Inner Circle',
      'icon': Icons.diamond_rounded,
      'emoji': '💎',
      'color': Color(0xFF4ECDC4),
      'description': 'Full member access',
    },
    {
      'name': 'WIRE',
      'subtitle': 'Messages',
      'icon': Icons.chat_bubble_rounded,
      'emoji': '💬',
      'color': Color(0xFF7C4DFF),
      'description': 'Chat & connections',
    },
    {
      'name': 'TAG',
      'subtitle': 'Adult Games',
      'icon': Icons.local_fire_department_rounded,
      'emoji': '🎭',
      'color': Color(0xFFFFD54F),
      'description': 'Games for the bold',
    },
    {
      'name': 'MINIS',
      'subtitle': 'Quick Hits',
      'icon': Icons.auto_awesome_rounded,
      'emoji': '🎯',
      'color': Color(0xFFFF7F6B),
      'description': 'Solo mini-games',
    },
    {
      'name': 'VOYAGER',
      'subtitle': 'Travel & Events',
      'icon': Icons.flight_takeoff_rounded,
      'emoji': '✈️',
      'color': Color(0xFF00BFA6),
      'description': 'Trip sharing & meetups',
    },
  ];

  static final List<Widget> _moduleScreens = [
    const BrowseScreen(),
    const NestScreen(),
    WireEntryScreen(),
    const TagScreen(),
    const MinisScreen(),
    const TravelHubScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _tileAnimations = List.generate(_modules.length, (index) {
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
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final seen = await WelcomeTutorial.hasSeenTutorial();
    if (mounted && !seen) {
      setState(() {
        _showTutorial = true;
        _tutorialChecked = true;
      });
    } else if (mounted) {
      setState(() => _tutorialChecked = true);
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showTutorial) {
      return WelcomeTutorial(
        onComplete: () => setState(() => _showTutorial = false),
      );
    }

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildDashboard(),
          const BrowseScreen(),
          WireEntryScreen(),
          const EventsHomeScreen(),
          const MirrorScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAV
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomNav() => Container(
        decoration: BoxDecoration(
          color: VesparaColors.surface.withOpacity(0.95),
          border: Border(
            top: BorderSide(color: VesparaColors.glow.withOpacity(0.1)),
          ),
          boxShadow: [
            BoxShadow(
              color: VesparaColors.glow.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final isActive = _currentTab == i;

                    return GestureDetector(
                      onTap: () => setState(() => _currentTab = i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: isActive
                            ? BoxDecoration(
                                color: item.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              )
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 24,
                              color: isActive
                                  ? item.color
                                  : VesparaColors.inactive,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? item.color
                                    : VesparaColors.inactive,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD (Home Tab)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDashboard() {
    final analyticsAsync = ref.watch(userAnalyticsProvider);
    final analytics = analyticsAsync.valueOrNull;

    return VesparaAnimatedBackground(
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
            VesparaNeonText(
              text: 'VESPARA',
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

        // Notifications bell + Avatar
        Row(
          children: [
            // Notification bell
            GestureDetector(
              onTap: () => _showNotifications(),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VesparaColors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: VesparaColors.border),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: VesparaColors.secondary, size: 22),
                  ),
                  // Unread badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VesparaColors.accentRose,
                        boxShadow: [
                          BoxShadow(
                            color: VesparaColors.accentRose.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Profile orb
            _buildProfileOrb(displayName),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileOrb(String displayName) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        return GestureDetector(
          onTap: () => setState(() => _currentTab = 4),
          child: Container(
            width: 48,
            height: 48,
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
                  color: VesparaColors.glow.withOpacity(0.2 + pulse * 0.1),
                  blurRadius: 15 + pulse * 8,
                  spreadRadius: 1 + pulse * 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V',
                style: GoogleFonts.cinzel(
                  color: VesparaColors.background,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(dynamic analytics) {
    final stats = analytics == null
        ? [
            _StatData('—', 'Members', Icons.people_rounded),
            _StatData('—', 'Chats', Icons.chat_bubble_rounded),
            _StatData('—', 'Events', Icons.event_rounded),
            _StatData('—', 'Games', Icons.local_fire_department_rounded),
          ]
        : [
            _StatData('${analytics.totalMatches}', 'Members',
                Icons.people_rounded),
            _StatData('${analytics.activeConversations}', 'Chats',
                Icons.chat_bubble_rounded),
            _StatData('${analytics.datesScheduled}', 'Events',
                Icons.event_rounded),
            _StatData('${analytics.matchRate.toInt()}%', 'Active',
                Icons.trending_up_rounded),
          ];

    return ClipRRect(
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
                _buildStatItem(stats[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(_StatData stat) => Column(
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
          final rows = <Widget>[];

          for (var i = 0; i < _modules.length; i += 2) {
            final rightIndex = i + 1 < _modules.length ? i + 1 : null;
            rows.add(_buildModuleRow(i, rightIndex, tileHeight, spacing));
            if (i + 2 < _modules.length) {
              rows.add(const SizedBox(height: spacing));
            }
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                ...rows,
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );

  Widget _buildModuleRow(
          int leftIndex, int? rightIndex, double height, double spacing) =>
      Row(
        children: [
          Expanded(child: _buildModuleTile(leftIndex, height)),
          SizedBox(width: spacing),
          Expanded(
            child: rightIndex != null
                ? _buildModuleTile(rightIndex, height)
                : const SizedBox.shrink(),
          ),
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
        onTap: () => _navigateToModule(index),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFF1E1830),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Gradient accent wash
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

              // Bottom glow
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

              // Module tile icon
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

              // Top shine line
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
                border: Border.all(color: color.withOpacity(0.3)),
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
            Text(
              module['name'] as String,
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
                letterSpacing: 2,
              ),
            ),
            Text(
              module['subtitle'] as String,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToModule(int index) {
    final module = _modules[index];
    final color = module['color'] as Color;
    context.pushPortal(_moduleScreens[index], color: color);
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationsSheet(),
    );
  }

  String _getModuleIconPath(String moduleName) {
    switch (moduleName) {
      case 'BROWSE':
        return 'assets/Main Page Tile Icons/Discover1.png';
      case 'SANCTUM':
        return 'assets/Main Page Tile Icons/Sanctum1.png';
      case 'TAG':
        return 'assets/Main Page Tile Icons/TAG1.png';
      case 'MINIS':
        return 'assets/Main Page Tile Icons/Minis.png';
      case 'VOYAGER':
        return 'assets/Main Page Tile Icons/Voyager.png';
      default:
        return 'assets/Main Page Tile Icons/Discover1.png';
    }
  }

  bool _hasNotification(int index) => false;
}

class _StatData {
  const _StatData(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// In-App Notifications Panel
class _NotificationsSheet extends StatefulWidget {
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId).eq('is_read', false);

      _loadNotifications();
    } catch (e) {
      debugPrint('Error marking notifications read: $e');
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: VesparaColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VesparaColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notifications',
                        style: GoogleFonts.cinzel(
                            fontSize: 18, color: VesparaColors.primary)),
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text('Mark all read',
                          style:
                              TextStyle(color: VesparaColors.accentRose, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: VesparaColors.glow))
                    : _notifications.isEmpty
                        ? _buildEmptyNotifications()
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) =>
                                _buildNotificationItem(_notifications[index]),
                          ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyNotifications() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_rounded,
                size: 48, color: VesparaColors.glow.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text("You're all caught up!",
                style: TextStyle(color: VesparaColors.secondary, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('No new notifications',
                style: TextStyle(color: VesparaColors.inactive, fontSize: 12)),
          ],
        ),
      );

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    final isRead = notif['is_read'] as bool? ?? true;
    final type = notif['type'] as String? ?? 'system';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead
            ? VesparaColors.surface.withOpacity(0.3)
            : VesparaColors.accentViolet.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: isRead
            ? null
            : Border.all(color: VesparaColors.accentViolet.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getNotifColor(type).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getNotifIcon(type),
                size: 18, color: _getNotifColor(type)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif['title'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                    color: VesparaColors.primary,
                  ),
                ),
                if (notif['body'] != null)
                  Text(
                    notif['body'] as String,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: VesparaColors.secondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VesparaColors.accentRose,
              ),
            ),
        ],
      ),
    );
  }

  Color _getNotifColor(String type) {
    switch (type) {
      case 'message':
        return VesparaColors.accentViolet;
      case 'photo_view':
        return VesparaColors.accentRose;
      case 'event':
        return VesparaColors.accentCyan;
      case 'game_invite':
        return VesparaColors.accentGold;
      case 'travel':
        return VesparaColors.accentTeal;
      default:
        return VesparaColors.secondary;
    }
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'photo_view':
        return Icons.visibility_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'game_invite':
        return Icons.local_fire_department_rounded;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
