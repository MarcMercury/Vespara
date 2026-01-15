import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';

/// HomeScreen - The Bento Box Dashboard
/// Simplified version that works on web without complex packages
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedTile;
  
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    // If a tile is selected, show that feature screen
    if (_selectedTile != null) {
      return _buildFeatureScreen(_selectedTile!);
    }
    
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VESPARA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 4,
                      color: VesparaColors.primary,
                    ),
                  ),
                  
                  // Profile avatar / sign out
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'signout') {
                        await Supabase.instance.client.auth.signOut();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'signout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: VesparaColors.error, size: 20),
                            SizedBox(width: 8),
                            Text('Sign Out'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VesparaColors.surface,
                        border: Border.all(
                          color: VesparaColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
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
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              Text(
                user?.email ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
              
              SizedBox(height: 24),
              
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
  
  Widget _buildBentoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tileSpacing = 12.0;
        final tileWidth = (width - tileSpacing) / 2;
        final smallTileHeight = tileWidth * 0.6;
        final largeTileHeight = tileWidth * 1.2;
        
        return SingleChildScrollView(
          child: Column(
            children: [
              // ═══════════════════════════════════════════════════════════════
              // ROW 1: The Engine (Strategist + Scope)
              // ═══════════════════════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: _buildTile(
                      index: 0,
                      title: 'THE STRATEGIST',
                      subtitle: 'AI Planning',
                      icon: Icons.psychology,
                      height: largeTileHeight,
                      color: VesparaColors.glow,
                    ),
                  ),
                  SizedBox(width: tileSpacing),
                  Expanded(
                    child: _buildTile(
                      index: 1,
                      title: 'THE SCOPE',
                      subtitle: 'Discovery',
                      icon: Icons.explore,
                      height: largeTileHeight,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: tileSpacing),
              
              // ═══════════════════════════════════════════════════════════════
              // ROW 2: The Workflow (Roster + Wire)
              // ═══════════════════════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: _buildTile(
                      index: 2,
                      title: 'THE ROSTER',
                      subtitle: 'Your CRM',
                      icon: Icons.people,
                      height: smallTileHeight,
                      color: VesparaColors.tagsGreen,
                    ),
                  ),
                  SizedBox(width: tileSpacing),
                  Expanded(
                    child: _buildTile(
                      index: 3,
                      title: 'THE WIRE',
                      subtitle: 'Messages',
                      icon: Icons.message,
                      height: smallTileHeight,
                      color: VesparaColors.primary,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: tileSpacing),
              
              // ═══════════════════════════════════════════════════════════════
              // ROW 3: The Experience (Shredder + Ludus)
              // ═══════════════════════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildTile(
                      index: 4,
                      title: 'SHREDDER',
                      subtitle: 'Ghost Protocol',
                      icon: Icons.delete_sweep,
                      height: smallTileHeight,
                      color: VesparaColors.error,
                    ),
                  ),
                  SizedBox(width: tileSpacing),
                  Expanded(
                    flex: 2,
                    child: _buildTile(
                      index: 5,
                      title: 'THE LUDUS',
                      subtitle: 'TAGS Games',
                      icon: Icons.casino,
                      height: smallTileHeight,
                      color: VesparaColors.tagsYellow,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: tileSpacing),
              
              // ═══════════════════════════════════════════════════════════════
              // ROW 4: The Data (Core + Mirror)
              // ═══════════════════════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildTile(
                      index: 6,
                      title: 'CORE',
                      subtitle: 'Settings',
                      icon: Icons.settings,
                      height: smallTileHeight,
                      color: VesparaColors.secondary,
                    ),
                  ),
                  SizedBox(width: tileSpacing),
                  Expanded(
                    flex: 2,
                    child: _buildTile(
                      index: 7,
                      title: 'THE MIRROR',
                      subtitle: 'Analytics',
                      icon: Icons.analytics,
                      height: smallTileHeight,
                      color: VesparaColors.glow,
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
  
  Widget _buildTile({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required double height,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTile = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with glow
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              
              Spacer(),
              
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: VesparaColors.primary,
                ),
              ),
              
              SizedBox(height: 4),
              
              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureScreen(int index) {
    final titles = [
      'The Strategist',
      'The Scope', 
      'The Roster',
      'The Wire',
      'The Shredder',
      'The Ludus',
      'The Core',
      'The Mirror',
    ];
    
    final descriptions = [
      'AI-powered planning and Tonight Mode for spontaneous meetups.',
      'Discover curated matches using vector similarity.',
      'Your personal CRM - manage connections from Incoming to Legacy.',
      'Priority messaging with Conversation Resuscitator.',
      'Ghost Protocol - graceful exits with AI-drafted messages.',
      'TAGS consent-forward games with the Consent Meter.',
      'Your identity, settings, and Vouch Chain.',
      'Brutal analytics on your behavior patterns.',
    ];
    
    final icons = [
      Icons.psychology,
      Icons.explore,
      Icons.people,
      Icons.message,
      Icons.delete_sweep,
      Icons.casino,
      Icons.settings,
      Icons.analytics,
    ];
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      appBar: AppBar(
        backgroundColor: VesparaColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: VesparaColors.primary),
          onPressed: () {
            setState(() {
              _selectedTile = null;
            });
          },
        ),
        title: Text(
          titles[index].toUpperCase(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: VesparaColors.primary,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: VesparaColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: VesparaColors.glow.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  icons[index],
                  color: VesparaColors.primary,
                  size: 48,
                ),
              ),
              
              SizedBox(height: 32),
              
              // Title
              Text(
                titles[index],
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: VesparaColors.primary,
                ),
              ),
              
              SizedBox(height: 16),
              
              // Description
              Text(
                descriptions[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: VesparaColors.secondary,
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: 48),
              
              // Coming soon badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: VesparaColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: VesparaColors.glow.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'COMING SOON',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: VesparaColors.glow,
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
