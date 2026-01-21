import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/domain/models/analytics.dart';
import '../../../core/domain/models/user_profile.dart';
import 'app_settings_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// THE MIRROR - Redesigned with Tabs
/// 1. Brutal Truth (Analytics) - Now FIRST
/// 2. My Profile (What others see, editable)
/// 3. Build Experience (Vibe/Interests/Desires - 20+ options each)
/// ════════════════════════════════════════════════════════════════════════════

class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});

  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BrutalTruthTab(),
                  _MyProfileTab(),
                  _BuildExperienceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              VesparaHaptics.lightTap();
              // FIX: Use Navigator.pop for proper back navigation
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/home');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VesparaColors.border),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: VesparaColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: VesparaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE MIRROR',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Know yourself, build yourself',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              VesparaHaptics.lightTap();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AppSettingsScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VesparaColors.border),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: VesparaColors.primary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: VesparaColors.background,
        unselectedLabelColor: VesparaColors.secondary,
        indicator: BoxDecoration(
          color: VesparaColors.glow,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology, size: 16),
                SizedBox(width: 4),
                Text('TRUTH'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 16),
                SizedBox(width: 4),
                Text('PROFILE'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 16),
                SizedBox(width: 4),
                Text('BUILD'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// TAB 1: BRUTAL TRUTH - Analytics Dashboard (NOW FIRST)
/// ════════════════════════════════════════════════════════════════════════════

class _BrutalTruthTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(userAnalyticsProvider);
    
    return analytics.when(
      data: (data) => data != null 
        ? _buildContent(context, data)
        : _buildEmptyState(context),
      loading: () => const Center(
        child: CircularProgressIndicator(color: VesparaColors.glow),
      ),
      error: (e, _) => Center(
        child: Text('Unable to load analytics', 
          style: TextStyle(color: VesparaColors.error)),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 64, color: VesparaColors.glow.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No analytics yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Start using the app to see your data',
            style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, UserAnalytics analytics) {
    final insights = _generateInsights(analytics);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BRUTAL TRUTH SECTION - NOW FIRST!
          _buildBrutalTruthCard(context, insights),
          const SizedBox(height: VesparaSpacing.lg),
          
          // Overall score
          _buildOverviewCard(context, analytics),
          const SizedBox(height: VesparaSpacing.md),
          
          // Metrics grid
          _buildMetricsGrid(context, analytics),
          const SizedBox(height: VesparaSpacing.md),
          
          // Activity breakdown
          _buildActivityBreakdown(context, analytics),
          const SizedBox(height: VesparaSpacing.xl),
        ],
      ),
    );
  }
  
  Widget _buildBrutalTruthCard(BuildContext context, List<Map<String, dynamic>> insights) {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VesparaColors.tagsYellow.withOpacity(0.15),
            VesparaColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VesparaColors.tagsYellow.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VesparaColors.tagsYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: VesparaColors.tagsYellow,
                  size: 28,
                ),
              ),
              const SizedBox(width: VesparaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE BRUTAL TRUTH',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        letterSpacing: 2,
                        color: VesparaColors.tagsYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'AI-powered insights from your behavior',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: VesparaSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (insight['color'] as Color).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    insight['icon'] as IconData,
                    color: insight['color'] as Color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: VesparaSpacing.sm),
                Expanded(
                  child: Text(
                    insight['text'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildOverviewCard(BuildContext context, UserAnalytics analytics) {
    final overallScore = _calculateOverallScore(analytics);
    final scoreColor = _getScoreColor(overallScore);
    
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: overallScore / 100,
                  strokeWidth: 6,
                  backgroundColor: VesparaColors.background,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
                Text(
                  '${overallScore.toInt()}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: VesparaSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getScoreLabel(overallScore),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scoreColor,
                  ),
                ),
                Text(
                  _getScoreDescription(overallScore),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricsGrid(BuildContext context, UserAnalytics analytics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard(context, 
              icon: Icons.visibility_off,
              label: 'GHOST RATE', 
              value: analytics.ghostRate,
              isNegative: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricCard(context,
              icon: Icons.event_busy,
              label: 'FLAKE RATE',
              value: analytics.flakeRate,
              isNegative: true)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMetricCard(context,
              icon: Icons.swap_horiz,
              label: 'SWIPE RATIO',
              value: analytics.swipeRatio,
              isNegative: false)),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricCard(context,
              icon: Icons.reply,
              label: 'RESPONSE',
              value: analytics.responseRate,
              isNegative: false)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required bool isNegative,
  }) {
    final color = isNegative
        ? (value < 20 ? VesparaColors.tagsGreen : 
           (value < 50 ? VesparaColors.tagsYellow : VesparaColors.tagsRed))
        : (value > 70 ? VesparaColors.tagsGreen : 
           (value > 40 ? VesparaColors.tagsYellow : VesparaColors.tagsRed));
    
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                '${value.toInt()}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: VesparaColors.background,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 3,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityBreakdown(BuildContext context, UserAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTIVITY', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2)),
          const SizedBox(height: 16),
          _buildStatRow(context, 'Messages Sent', analytics.messagesSent, VesparaColors.glow),
          _buildStatRow(context, 'Messages Received', analytics.messagesReceived, VesparaColors.secondary),
          _buildStatRow(context, 'Matches Total', analytics.totalMatches, VesparaColors.tagsYellow),
          _buildStatRow(context, 'Dates Scheduled', analytics.datesScheduled, VesparaColors.tagsGreen),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(BuildContext context, String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$value',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  double _calculateOverallScore(UserAnalytics analytics) {
    final responseWeight = analytics.responseRate * 0.3;
    final ghostPenalty = (100 - analytics.ghostRate) * 0.25;
    final flakePenalty = (100 - analytics.flakeRate) * 0.25;
    final activityBonus = math.min(analytics.swipeRatio * 0.2, 20);
    return (responseWeight + ghostPenalty + flakePenalty + activityBonus).clamp(0, 100);
  }
  
  Color _getScoreColor(double score) {
    if (score >= 75) return VesparaColors.tagsGreen;
    if (score >= 50) return VesparaColors.tagsYellow;
    return VesparaColors.tagsRed;
  }
  
  String _getScoreLabel(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Strong';
    if (score >= 50) return 'Average';
    if (score >= 30) return 'Needs Work';
    return 'Critical';
  }
  
  String _getScoreDescription(double score) {
    if (score >= 85) return 'You\'re crushing it. Keep the momentum.';
    if (score >= 70) return 'Solid performance with room to grow.';
    if (score >= 50) return 'Middle of the pack. Time to step up.';
    if (score >= 30) return 'Your metrics need serious attention.';
    return 'Major changes needed. Let\'s fix this.';
  }
  
  List<Map<String, dynamic>> _generateInsights(UserAnalytics analytics) {
    final insights = <Map<String, dynamic>>[];
    
    if (analytics.ghostRate > 50) {
      insights.add({
        'icon': Icons.visibility_off,
        'text': 'You\'re ghosting over half your matches. Either engage meaningfully or clean up your roster.',
        'color': VesparaColors.tagsRed,
      });
    } else if (analytics.ghostRate > 25) {
      insights.add({
        'icon': Icons.visibility_off,
        'text': 'Your ghost rate is creeping up. Consider using The Shredder for graceful exits.',
        'color': VesparaColors.tagsYellow,
      });
    }
    
    if (analytics.responseRate < 40) {
      insights.add({
        'icon': Icons.reply,
        'text': 'Your response rate is low. Try the Conversation Resuscitator in The Wire.',
        'color': VesparaColors.tagsRed,
      });
    } else if (analytics.responseRate > 80) {
      insights.add({
        'icon': Icons.reply,
        'text': 'Excellent response rate! You\'re keeping conversations alive.',
        'color': VesparaColors.tagsGreen,
      });
    }
    
    if (analytics.flakeRate > 40) {
      insights.add({
        'icon': Icons.event_busy,
        'text': 'Too many plans falling through. Only confirm dates you\'ll actually keep.',
        'color': VesparaColors.tagsRed,
      });
    }
    
    if (analytics.firstMessagesSent < analytics.totalMatches * 0.3) {
      insights.add({
        'icon': Icons.send,
        'text': 'You\'re waiting for others to message first. Take initiative.',
        'color': VesparaColors.tagsYellow,
      });
    }
    
    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.star,
        'text': 'Your metrics look healthy. Keep doing what you\'re doing.',
        'color': VesparaColors.tagsGreen,
      });
    }
    
    return insights;
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// TAB 2: MY PROFILE - What others see, editable
/// ════════════════════════════════════════════════════════════════════════════

class _MyProfileTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MyProfileTab> createState() => _MyProfileTabState();
}

class _MyProfileTabState extends ConsumerState<_MyProfileTab> {
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Controllers for editable fields
  late TextEditingController _displayNameController;
  late TextEditingController _headlineController;
  late TextEditingController _bioController;
  late TextEditingController _occupationController;
  late TextEditingController _cityController;
  
  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _headlineController = TextEditingController();
    _bioController = TextEditingController();
    _occupationController = TextEditingController();
    _cityController = TextEditingController();
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _occupationController.dispose();
    _cityController.dispose();
    super.dispose();
  }
  
  void _loadProfileData(UserProfile profile) {
    _displayNameController.text = profile.displayName ?? '';
    _headlineController.text = profile.headline ?? '';
    _bioController.text = profile.bio ?? '';
    _occupationController.text = profile.occupation ?? '';
    _cityController.text = profile.city ?? '';
  }
  
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      await Supabase.instance.client.from('profiles').update({
        'display_name': _displayNameController.text.trim(),
        'headline': _headlineController.text.trim(),
        'bio': _bioController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'city': _cityController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      ref.invalidate(userProfileProvider);
      
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: VesparaColors.success),
                const SizedBox(width: 8),
                Text('Profile updated!'),
              ],
            ),
            backgroundColor: VesparaColors.surface,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    
    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: VesparaColors.secondary),
                const SizedBox(height: 16),
                Text('Profile not found'),
              ],
            ),
          );
        }
        
        // Load initial data when not editing
        if (!_isEditing && _displayNameController.text.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadProfileData(profile);
          });
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(VesparaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with edit toggle
              _buildProfileHeader(context, profile),
              const SizedBox(height: VesparaSpacing.lg),
              
              // Preview card (what others see)
              _buildProfilePreviewCard(context, profile),
              const SizedBox(height: VesparaSpacing.lg),
              
              // Editable sections
              if (_isEditing) ...[
                _buildEditableFields(context, profile),
                const SizedBox(height: VesparaSpacing.lg),
                _buildSaveButton(context),
              ] else ...[
                _buildProfileDetails(context, profile),
              ],
              
              const SizedBox(height: VesparaSpacing.xl),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: VesparaColors.glow),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
  
  Widget _buildProfileHeader(BuildContext context, UserProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MY PROFILE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
                color: VesparaColors.secondary,
              ),
            ),
            Text(
              'What others see',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (_isEditing) {
              // Cancel editing
              _loadProfileData(profile);
            }
            setState(() => _isEditing = !_isEditing);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _isEditing 
                  ? VesparaColors.error.withOpacity(0.15)
                  : VesparaColors.glow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isEditing 
                    ? VesparaColors.error.withOpacity(0.3)
                    : VesparaColors.glow.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isEditing ? Icons.close : Icons.edit,
                  size: 16,
                  color: _isEditing ? VesparaColors.error : VesparaColors.glow,
                ),
                const SizedBox(width: 6),
                Text(
                  _isEditing ? 'Cancel' : 'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isEditing ? VesparaColors.error : VesparaColors.glow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfilePreviewCard(BuildContext context, UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VesparaColors.glow.withOpacity(0.1),
            VesparaColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VesparaColors.glow.withOpacity(0.2),
              border: Border.all(color: VesparaColors.glow.withOpacity(0.5), width: 3),
            ),
            child: profile.avatarUrl != null
                ? ClipOval(child: Image.network(profile.avatarUrl!, fit: BoxFit.cover))
                : Icon(Icons.person, size: 50, color: VesparaColors.glow),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            profile.displayName ?? 'Anonymous',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Age & Location
          if (profile.city != null || profile.age != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (profile.age != null) '${profile.age}',
                  if (profile.city != null) profile.city,
                ].join(' • '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: VesparaColors.secondary,
                ),
              ),
            ),
          
          // Headline
          if (profile.headline != null && profile.headline!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                profile.headline!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: VesparaColors.glow,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildProfileDetails(BuildContext context, UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bio section
        if (profile.bio != null && profile.bio!.isNotEmpty)
          _buildDetailSection(
            context,
            title: 'ABOUT ME',
            icon: Icons.person_outline,
            child: Text(profile.bio!, style: Theme.of(context).textTheme.bodyMedium),
          ),
        
        // Looking for
        if (profile.seeking.isNotEmpty)
          _buildDetailSection(
            context,
            title: 'LOOKING FOR',
            icon: Icons.search,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.seeking.map((s) => _buildChip(s)).toList(),
            ),
          ),
        
        // Traits
        if (profile.lookingFor.isNotEmpty)
          _buildDetailSection(
            context,
            title: 'MY VIBE',
            icon: Icons.auto_awesome,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.lookingFor.map((t) => _buildChip(t)).toList(),
            ),
          ),
      ],
    );
  }
  
  Widget _buildDetailSection(BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: VesparaSpacing.md),
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: VesparaColors.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
  
  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: VesparaColors.glow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: VesparaColors.glow,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildEditableFields(BuildContext context, UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EDIT YOUR PROFILE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
            color: VesparaColors.glow,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _displayNameController,
          label: 'Display Name',
          hint: 'What should we call you?',
          icon: Icons.badge,
        ),
        const SizedBox(height: 12),
        
        _buildTextField(
          controller: _headlineController,
          label: 'Headline',
          hint: 'A catchy one-liner about you',
          icon: Icons.format_quote,
        ),
        const SizedBox(height: 12),
        
        _buildTextField(
          controller: _bioController,
          label: 'About Me',
          hint: 'Tell others about yourself...',
          icon: Icons.person_outline,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        
        _buildTextField(
          controller: _occupationController,
          label: 'Occupation',
          hint: 'What do you do?',
          icon: Icons.work_outline,
        ),
        const SizedBox(height: 12),
        
        _buildTextField(
          controller: _cityController,
          label: 'City',
          hint: 'Where are you based?',
          icon: Icons.location_on_outlined,
        ),
        
        const SizedBox(height: 16),
        
        // AI helper button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.tagsYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VesparaColors.tagsYellow.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: VesparaColors.tagsYellow),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Bio Helper',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.tagsYellow,
                      ),
                    ),
                    Text(
                      'Let AI craft a bio from your profile',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: AI bio generation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('AI bio generation coming soon!')),
                  );
                },
                child: Text('Generate', style: TextStyle(color: VesparaColors.tagsYellow)),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: VesparaColors.primary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: VesparaColors.secondary),
          hintStyle: TextStyle(color: VesparaColors.inactive),
          prefixIcon: Icon(icon, color: VesparaColors.secondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
  
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: VesparaColors.glow,
          foregroundColor: VesparaColors.background,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VesparaColors.background,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check),
                  const SizedBox(width: 8),
                  Text('Save Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// TAB 3: BUILD EXPERIENCE - Vibe, Interests, Desires (20+ options each)
/// ════════════════════════════════════════════════════════════════════════════

class _BuildExperienceTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BuildExperienceTab> createState() => _BuildExperienceTabState();
}

class _BuildExperienceTabState extends ConsumerState<_BuildExperienceTab> {
  final Set<String> _selectedVibes = {};
  final Set<String> _selectedInterests = {};
  final Set<String> _selectedDesires = {};
  bool _isSaving = false;
  
  // 20+ VIBE OPTIONS
  static const List<Map<String, dynamic>> _vibeOptions = [
    {'id': 'night_owl', 'emoji': '🌙', 'label': 'Night Owl'},
    {'id': 'early_riser', 'emoji': '☀️', 'label': 'Early Riser'},
    {'id': 'high_energy', 'emoji': '⚡', 'label': 'High Energy'},
    {'id': 'calm_centered', 'emoji': '🧘', 'label': 'Calm & Centered'},
    {'id': 'life_of_party', 'emoji': '🎉', 'label': 'Life of the Party'},
    {'id': 'cozy_homebody', 'emoji': '🏠', 'label': 'Cozy Homebody'},
    {'id': 'small_groups', 'emoji': '👥', 'label': 'Small Groups Only'},
    {'id': 'social_butterfly', 'emoji': '🦋', 'label': 'Social Butterfly'},
    {'id': 'witty_sarcastic', 'emoji': '😂', 'label': 'Witty & Sarcastic'},
    {'id': 'hopeless_romantic', 'emoji': '💝', 'label': 'Hopeless Romantic'},
    {'id': 'passionate', 'emoji': '🔥', 'label': 'Passionate'},
    {'id': 'easy_going', 'emoji': '😌', 'label': 'Easy Going'},
    {'id': 'mischievous', 'emoji': '😈', 'label': 'Mischievous'},
    {'id': 'adventurous', 'emoji': '🏔️', 'label': 'Adventurous'},
    {'id': 'intellectual', 'emoji': '📚', 'label': 'Intellectual'},
    {'id': 'creative', 'emoji': '🎨', 'label': 'Creative'},
    {'id': 'ambitious', 'emoji': '🚀', 'label': 'Ambitious'},
    {'id': 'spontaneous', 'emoji': '🎲', 'label': 'Spontaneous'},
    {'id': 'deep_thinker', 'emoji': '🧠', 'label': 'Deep Thinker'},
    {'id': 'free_spirit', 'emoji': '🌊', 'label': 'Free Spirit'},
    {'id': 'old_soul', 'emoji': '🕰️', 'label': 'Old Soul'},
    {'id': 'young_at_heart', 'emoji': '🎈', 'label': 'Young at Heart'},
  ];
  
  // 20+ INTEREST OPTIONS
  static const List<Map<String, dynamic>> _interestOptions = [
    {'id': 'travel', 'emoji': '✈️', 'label': 'Travel'},
    {'id': 'fitness', 'emoji': '💪', 'label': 'Fitness'},
    {'id': 'music', 'emoji': '🎵', 'label': 'Music'},
    {'id': 'art', 'emoji': '🎨', 'label': 'Art & Design'},
    {'id': 'food', 'emoji': '🍷', 'label': 'Fine Dining'},
    {'id': 'cooking', 'emoji': '👨‍🍳', 'label': 'Cooking'},
    {'id': 'movies', 'emoji': '🎬', 'label': 'Movies'},
    {'id': 'reading', 'emoji': '📖', 'label': 'Reading'},
    {'id': 'gaming', 'emoji': '🎮', 'label': 'Gaming'},
    {'id': 'hiking', 'emoji': '🥾', 'label': 'Hiking'},
    {'id': 'yoga', 'emoji': '🧘‍♀️', 'label': 'Yoga'},
    {'id': 'dancing', 'emoji': '💃', 'label': 'Dancing'},
    {'id': 'photography', 'emoji': '📸', 'label': 'Photography'},
    {'id': 'podcasts', 'emoji': '🎙️', 'label': 'Podcasts'},
    {'id': 'concerts', 'emoji': '🎤', 'label': 'Live Music'},
    {'id': 'wine', 'emoji': '🍷', 'label': 'Wine Tasting'},
    {'id': 'festivals', 'emoji': '🎪', 'label': 'Festivals'},
    {'id': 'beach', 'emoji': '🏖️', 'label': 'Beach Life'},
    {'id': 'camping', 'emoji': '⛺', 'label': 'Camping'},
    {'id': 'sports', 'emoji': '⚽', 'label': 'Sports'},
    {'id': 'fashion', 'emoji': '👗', 'label': 'Fashion'},
    {'id': 'tech', 'emoji': '💻', 'label': 'Technology'},
    {'id': 'spirituality', 'emoji': '🔮', 'label': 'Spirituality'},
    {'id': 'meditation', 'emoji': '🕉️', 'label': 'Meditation'},
  ];
  
  // 20+ DESIRE OPTIONS
  static const List<Map<String, dynamic>> _desireOptions = [
    {'id': 'deep_connection', 'emoji': '💫', 'label': 'Deep Connection'},
    {'id': 'adventure', 'emoji': '🌋', 'label': 'Adventure'},
    {'id': 'romance', 'emoji': '🌹', 'label': 'Romance'},
    {'id': 'passion', 'emoji': '🔥', 'label': 'Passion'},
    {'id': 'intimacy', 'emoji': '💋', 'label': 'Intimacy'},
    {'id': 'exploration', 'emoji': '🗺️', 'label': 'Exploration'},
    {'id': 'trust', 'emoji': '🤝', 'label': 'Trust Building'},
    {'id': 'communication', 'emoji': '💬', 'label': 'Open Communication'},
    {'id': 'spontaneity', 'emoji': '🎲', 'label': 'Spontaneity'},
    {'id': 'chemistry', 'emoji': '⚗️', 'label': 'Chemistry'},
    {'id': 'vulnerability', 'emoji': '💎', 'label': 'Vulnerability'},
    {'id': 'playfulness', 'emoji': '🎭', 'label': 'Playfulness'},
    {'id': 'sensuality', 'emoji': '🌸', 'label': 'Sensuality'},
    {'id': 'dominance', 'emoji': '👑', 'label': 'Taking Control'},
    {'id': 'submission', 'emoji': '🦋', 'label': 'Letting Go'},
    {'id': 'switch', 'emoji': '🔄', 'label': 'Switching Roles'},
    {'id': 'roleplay', 'emoji': '🎪', 'label': 'Roleplay'},
    {'id': 'experimentation', 'emoji': '🧪', 'label': 'Experimentation'},
    {'id': 'consistency', 'emoji': '📅', 'label': 'Consistency'},
    {'id': 'variety', 'emoji': '🌈', 'label': 'Variety'},
    {'id': 'slow_build', 'emoji': '🌅', 'label': 'Slow Build'},
    {'id': 'instant_spark', 'emoji': '⚡', 'label': 'Instant Spark'},
  ];
  
  @override
  void initState() {
    super.initState();
    _loadExistingSelections();
  }
  
  void _loadExistingSelections() {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      // Load from profile.lookingFor or similar field
      // For now, start fresh
    }
  }
  
  Future<void> _saveExperience() async {
    setState(() => _isSaving = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      await Supabase.instance.client.from('profiles').update({
        'vibe_tags': _selectedVibes.toList(),
        'interest_tags': _selectedInterests.toList(),
        'desire_tags': _selectedDesires.toList(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      ref.invalidate(userProfileProvider);
      
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: VesparaColors.success),
                const SizedBox(width: 8),
                Text('Experience saved!'),
              ],
            ),
            backgroundColor: VesparaColors.surface,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: VesparaColors.error),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: VesparaSpacing.lg),
          
          // Vibe Section
          _buildSection(
            context,
            title: 'YOUR VIBE',
            subtitle: 'How would you describe your energy?',
            icon: Icons.mood,
            color: VesparaColors.tagsYellow,
            options: _vibeOptions,
            selected: _selectedVibes,
            onToggle: (id) => setState(() {
              _selectedVibes.contains(id) 
                  ? _selectedVibes.remove(id) 
                  : _selectedVibes.add(id);
            }),
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          // Interests Section
          _buildSection(
            context,
            title: 'YOUR INTERESTS',
            subtitle: 'What lights you up?',
            icon: Icons.favorite,
            color: VesparaColors.glow,
            options: _interestOptions,
            selected: _selectedInterests,
            onToggle: (id) => setState(() {
              _selectedInterests.contains(id) 
                  ? _selectedInterests.remove(id) 
                  : _selectedInterests.add(id);
            }),
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          // Desires Section
          _buildSection(
            context,
            title: 'YOUR DESIRES',
            subtitle: 'What are you seeking?',
            icon: Icons.auto_awesome,
            color: VesparaColors.tagsRed,
            options: _desireOptions,
            selected: _selectedDesires,
            onToggle: (id) => setState(() {
              _selectedDesires.contains(id) 
                  ? _selectedDesires.remove(id) 
                  : _selectedDesires.add(id);
            }),
          ),
          const SizedBox(height: VesparaSpacing.xl),
          
          // Save Button
          _buildSaveButton(context),
          const SizedBox(height: VesparaSpacing.xl),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    final totalSelected = _selectedVibes.length + _selectedInterests.length + _selectedDesires.length;
    
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VesparaColors.glow.withOpacity(0.15),
            VesparaColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.auto_awesome, color: VesparaColors.glow, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUILD YOUR EXPERIENCE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Help AI understand you better',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: totalSelected > 0 
                  ? VesparaColors.tagsGreen.withOpacity(0.2)
                  : VesparaColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalSelected selected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: totalSelected > 0 
                    ? VesparaColors.tagsGreen 
                    : VesparaColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> options,
    required Set<String> selected,
    required Function(String) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 1,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              '${selected.length} selected',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: VesparaColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option['id']);
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onToggle(option['id']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? color.withOpacity(0.2)
                      : VesparaColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? color 
                        : VesparaColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(option['emoji'], style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      option['label'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? color : VesparaColors.primary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check, size: 14, color: color),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSaveButton(BuildContext context) {
    final totalSelected = _selectedVibes.length + _selectedInterests.length + _selectedDesires.length;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: totalSelected == 0 || _isSaving ? null : _saveExperience,
        style: ElevatedButton.styleFrom(
          backgroundColor: VesparaColors.glow,
          foregroundColor: VesparaColors.background,
          disabledBackgroundColor: VesparaColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VesparaColors.background,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save),
                  const SizedBox(width: 8),
                  Text(
                    'Save Experience ($totalSelected)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
