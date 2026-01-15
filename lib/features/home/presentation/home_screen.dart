import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/motion.dart';
import '../../../core/utils/haptics.dart';
import '../widgets/strategist_tile.dart';
import '../widgets/scope_tile.dart';
import '../widgets/roster_tile.dart';
import '../widgets/wire_tile.dart';
import '../widgets/shredder_tile.dart';
import '../widgets/ludus_tile.dart';
import '../widgets/core_tile.dart';
import '../widgets/mirror_tile.dart';

// Import feature screens for OpenContainer transitions
import '../../strategist/presentation/strategist_screen.dart';
import '../../scope/presentation/scope_screen.dart';
import '../../roster/presentation/roster_screen.dart';
import '../../wire/presentation/wire_screen.dart';
import '../../shredder/presentation/shredder_screen.dart';
import '../../ludus/presentation/tags_screen.dart';
import '../../core/presentation/core_screen.dart';
import '../../mirror/presentation/mirror_screen.dart';

/// The Home Screen - The Bento Box Dashboard
/// A staggered grid of 8 tiles representing the Vespara Social OS
/// 
/// PHASE 5: Staggered entrance animations + OpenContainer tile expansion
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VesparaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════════════
              // HEADER
              // ═══════════════════════════════════════════════════════════════
              _buildHeader(),
              
              const SizedBox(height: VesparaSpacing.lg),
              
              // ═══════════════════════════════════════════════════════════════
              // BENTO GRID
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
  
  /// Build the app header with logo and profile
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo / App Name
        Text(
          'VESPARA',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            letterSpacing: 4,
          ),
        ),
        
        // Profile avatar
        GestureDetector(
          onTap: () {
            VesparaHaptics.lightTap();
            context.go('/home/core');
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: VesparaColors.primary.withOpacity(0.3),
                width: 2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VesparaColors.surface,
                  VesparaColors.background,
                ],
              ),
            ),
            child: const Icon(
              Icons.person_outline,
              color: VesparaColors.primary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build the 8-tile Bento Grid using StaggeredGridView
  /// PHASE 5: Staggered entrance + OpenContainer expansion
  Widget _buildBentoGrid() {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: VesparaSpacing.md,
      crossAxisSpacing: VesparaSpacing.md,
      children: [
        // ═══════════════════════════════════════════════════════════════════
        // ROW 1: THE ENGINE (Intelligence & Discovery)
        // ═══════════════════════════════════════════════════════════════════
        
        // Tile 1: The Strategist (Large - 2x2)
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          child: _buildExpandingTile(
            index: 0,
            closedBuilder: (context, openContainer) => StrategistTile(
              onTap: openContainer,
            ),
            openBuilder: (context, _) => const StrategistScreen(),
          ),
        ),
        
        // Tile 2: The Scope (Vertical - 1x2)
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 2,
          child: _buildExpandingTile(
            index: 1,
            closedBuilder: (context, openContainer) => ScopeTile(
              onTap: openContainer,
            ),
            openBuilder: (context, _) => const ScopeScreen(),
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════════════
        // ROW 2: THE WORKFLOW (Management & Communication)
        // ═══════════════════════════════════════════════════════════════════
        
        // Tile 3: The Roster (Medium - 2x1)
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1.5,
          child: _buildExpandingTile(
            index: 2,
            closedBuilder: (context, openContainer) => RosterTile(
              onTap: openContainer,
            ),
            openBuilder: (context, _) => const RosterScreen(),
          ),
        ),
        
        // Tile 4: The Wire (Medium - 2x1)
        StaggeredGridTile.count(
          crossAxisCellCount: 2,
          mainAxisCellCount: 1.5,
          child: _buildExpandingTile(
            index: 3,
            closedBuilder: (context, openContainer) => WireTile(
              onTap: openContainer,
            ),
            openBuilder: (context, _) => const WireScreen(),
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════════════
        // ROW 3: THE EXPERIENCE (The Pivot)
        // ═══════════════════════════════════════════════════════════════════
        
        // Tile 5: The Shredder (Small - 1x1)
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1,
          child: _buildExpandingTile(
            index: 4,
            closedBuilder: (context, openContainer) => ShredderTile(
              onTap: openContainer,
            ),
            openBuilder: (context, _) => const ShredderScreen(),
          ),
        ),
        
        // Tile 6: The Ludus (Large - 3x2)
        StaggeredGridTile.count(
          crossAxisCellCount: 3,
          mainAxisCellCount: 2,
          child: _buildExpandingTile(
            index: 5,
            closedBuilder: (context, openContainer) => LudusTile(
              onTap: openContainer,
            ),
            openBuilder: (context, _) => const TagsScreen(),
          ),
        ),
        
        // ═══════════════════════════════════════════════════════════════════
        // ROW 4: THE DATA (Identity & Reflection)
        // ═══════════════════════════════════════════════════════════════════
        
        // Tile 7: The Core (Small - 1x1)
        StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1,
          child: _buildExpandingTile(
            index: 6,
            closedBuilder: (context, openContainer) => CoreTile(
              onTap: openContainer,
            ),
            openBuilder: (context, _) => const CoreScreen(),
          ),
        ),
        
        // Tile 8: The Mirror (Medium - 3x1)
        StaggeredGridTile.count(
          crossAxisCellCount: 3,
          mainAxisCellCount: 1,
          child: _buildExpandingTile(
            index: 7,
            closedBuilder: (context, openContainer) => MirrorTile(
              onTap: openContainer,
            ),
            openBuilder: (context, _) => const MirrorScreen(),
          ),
        ),
      ],
    );
  }
  
  /// Build an expanding tile with OpenContainer animation and staggered entrance
  /// PHASE 5: Tile expands to fill screen (luxury transition)
  Widget _buildExpandingTile({
    required int index,
    required Widget Function(BuildContext, VoidCallback) closedBuilder,
    required Widget Function(BuildContext, VoidCallback) openBuilder,
  }) {
    // Staggered entrance animation using flutter_animate
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: VesparaMotion.emphasized,
      openColor: VesparaColors.background,
      closedColor: Colors.transparent,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
      ),
      openShape: const RoundedRectangleBorder(),
      closedBuilder: (context, openContainer) {
        return TileSpringWidget(
          onTap: () {
            VesparaHaptics.tilePress();
            openContainer();
          },
          child: closedBuilder(context, () {}),
        );
      },
      openBuilder: openBuilder,
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 * index),
          duration: VesparaMotion.standard,
          curve: VesparaMotion.standard_,
        )
        .slideY(
          delay: Duration(milliseconds: 100 * index),
          begin: 0.1,
          end: 0,
          duration: VesparaMotion.standard,
          curve: VesparaMotion.standard_,
        );
  }
}
