import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/domain/models/analytics.dart';
import '../../../core/providers/app_providers.dart';
import '../widgets/qr_connect_modal.dart';
import 'edit_profile_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// THE MIRROR - Module 1
/// Profile management, brutal honest AI feedback, settings, analytics
/// "Look at yourself. No, really look."
/// ════════════════════════════════════════════════════════════════════════════

class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});

  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Settings state
  final Map<String, bool> _toggleSettings = {
    'New Matches': true,
    'Messages': true,
    'Date Reminders': true,
    'AI Insights': false,
    'Show Online Status': true,
    'Read Receipts': false,
    'Profile Visible': true,
  };
  
  UserAnalytics? _cachedAnalytics;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Analytics will be loaded via provider
  }
  
  UserAnalytics? get _analytics {
    return _cachedAnalytics;
  }
  
  void _navigateToEditProfile(UserProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profile: profile),
      ),
    ).then((updated) {
      // Refresh profile if changes were made
      if (updated == true) {
        ref.invalidate(userProfileProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load analytics from provider
    final analyticsAsync = ref.watch(userAnalyticsProvider);
    _cachedAnalytics = analyticsAsync.valueOrNull;
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBrutalTruthTab(),  // TRUTH
                  _buildProfileTab(),       // PROFILE
                  _buildBuildTab(),         // BUILD
                  _buildSettingsTab(),      // SETTINGS
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
          ),
          Column(
            children: [
              Text(
                'THE MIRROR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: VesparaColors.primary,
                ),
              ),
              Text(
                'Face yourself',
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => showQrConnectModal(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [VesparaColors.glow, VesparaColors.primary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: VesparaColors.glow,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: VesparaColors.background,
        unselectedLabelColor: VesparaColors.secondary,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        dividerHeight: 0,
        tabs: [
          Tab(icon: Icon(Icons.psychology_outlined, size: 16), text: 'TRUTH'),
          Tab(icon: Icon(Icons.person_outline, size: 16), text: 'PROFILE'),
          Tab(icon: Icon(Icons.auto_awesome, size: 16), text: 'BUILD'),
          Tab(icon: Icon(Icons.settings_outlined, size: 16), text: 'SETTINGS'),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PROFILE TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildProfileTab() {
    final profileAsync = ref.watch(userProfileProvider);
    
    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: VesparaColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load profile', style: TextStyle(color: VesparaColors.secondary)),
            TextButton(
              onPressed: () => ref.invalidate(userProfileProvider),
              child: Text('Retry', style: TextStyle(color: VesparaColors.glow)),
            ),
          ],
        ),
      ),
      data: (profile) => profile != null 
          ? _buildProfileContent(profile)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, color: VesparaColors.secondary, size: 48),
                  const SizedBox(height: 16),
                  Text('No profile found', style: TextStyle(color: VesparaColors.secondary)),
                  TextButton(
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: Text('Retry', style: TextStyle(color: VesparaColors.glow)),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildProfileContent(UserProfile profile) {
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [VesparaColors.glow, VesparaColors.glow.withOpacity(0.5)],
                    ),
                    border: Border.all(color: VesparaColors.glow, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      profile.displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.background,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VesparaColors.surface,
                      border: Border.all(color: VesparaColors.glow),
                    ),
                    child: Icon(Icons.edit, size: 16, color: VesparaColors.glow),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              profile.displayName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: VesparaColors.primary,
              ),
            ),
          ),
          Center(
            child: Text(
              profile.headline ?? 'Add a headline...',
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick stats
          _buildQuickStats(),
          
          const SizedBox(height: 24),
          
          // Profile sections
          _buildProfileSection('About Me', profile.bio ?? 'No bio yet', Icons.person_outline),
          _buildProfileSection('Location', profile.displayLocation.isNotEmpty ? profile.displayLocation : 'Not set', Icons.location_on_outlined),
          _buildProfileSection('Pronouns', profile.pronouns ?? 'Not set', Icons.person_pin_outlined),
          _buildProfileSection('Gender', profile.gender.isNotEmpty ? profile.gender.join(', ') : 'Not set', Icons.face_outlined),
          _buildProfileSection('Orientation', profile.orientation.isNotEmpty ? profile.orientation.join(', ') : 'Not set', Icons.favorite_border),
          _buildProfileSection('Relationship Status', profile.relationshipStatus.isNotEmpty ? profile.relationshipStatus.join(', ') : 'Not set', Icons.people_outline),
          _buildProfileSection('Seeking', profile.seeking.isNotEmpty ? profile.seeking.join(', ') : 'Not set', Icons.search),
          _buildProfileSection('Looking For', profile.lookingFor.isNotEmpty ? profile.lookingFor.join(', ') : 'Not set', Icons.favorite_outline),
          _buildProfileSection('Kinks & Interests', profile.kinks.isNotEmpty ? profile.kinks.join(', ') : 'Not set', Icons.whatshot_outlined),
          _buildProfileSection('Boundaries', profile.boundaries.isNotEmpty ? profile.boundaries.join(', ') : 'Not set', Icons.shield_outlined),
          _buildProfileSection('Love Languages', profile.loveLanguages.isNotEmpty ? profile.loveLanguages.join(', ') : 'Not set', Icons.language),
          _buildProfileSection('Availability', profile.availabilityGeneral.isNotEmpty ? profile.availabilityGeneral.join(', ') : 'Not set', Icons.schedule_outlined),
          _buildProfileSection('Hosting Status', profile.hostingStatus ?? 'Not set', Icons.home_outlined),
          _buildProfileSection('Discretion Level', profile.discretionLevel ?? 'Not set', Icons.visibility_outlined),
          
          const SizedBox(height: 24),
          
          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToEditProfile(profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.glow,
                foregroundColor: VesparaColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          _buildStatColumn(_analytics?.totalMatches.toString() ?? '0', 'Matches'),
          Container(width: 1, height: 40, color: VesparaColors.glow.withOpacity(0.2)),
          _buildStatColumn('${((_analytics?.responseRate ?? 0) * 100).toInt()}%', 'Response'),
          Container(width: 1, height: 40, color: VesparaColors.glow.withOpacity(0.2)),
          _buildStatColumn(_analytics?.activeDays.toString() ?? '0', 'Days Active'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: VesparaColors.glow,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: VesparaColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: VesparaColors.glow, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content.isNotEmpty ? content : 'Not set',
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: VesparaColors.secondary, size: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BRUTAL TRUTH TAB - AI Feedback
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBrutalTruthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBrutalHeader(),
          const SizedBox(height: 24),
          _buildPersonalitySummary(),
          const SizedBox(height: 20),
          _buildDatingStyle(),
          const SizedBox(height: 20),
          _buildBehaviorMetrics(),
          const SizedBox(height: 20),
          _buildImprovementTips(),
          const SizedBox(height: 20),
          _buildRedFlags(),
        ],
      ),
    );
  }

  Widget _buildBrutalHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VesparaColors.error.withOpacity(0.3),
            VesparaColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.psychology, size: 48, color: VesparaColors.error),
          const SizedBox(height: 12),
          Text(
            'The Brutal Truth',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI analysis of your dating behavior. No sugarcoating. No excuses.',
            style: TextStyle(
              fontSize: 13,
              color: VesparaColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: VesparaColors.glow, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Personality Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.glow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _analytics?.aiPersonalitySummary ?? 
            'You\'re charming on the surface but tend to lose interest after the chase. You match with many but commit to few. Your texting game is strong early but fades fast. You like attention more than connection.',
            style: TextStyle(
              fontSize: 14,
              color: VesparaColors.primary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatingStyle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.heart_broken, color: VesparaColors.tagsYellow, size: 18),
              const SizedBox(width: 8),
              Text(
                'Your Dating Style',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.tagsYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _analytics?.aiDatingStyle ?? '"The Collector"',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You enjoy the validation of matching more than the work of connecting. You keep options open even when you find someone good. Classic commitment-phobe behavior disguised as "keeping things casual".',
            style: TextStyle(
              fontSize: 13,
              color: VesparaColors.secondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Behavior Metrics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricRow('Ghost Rate', _analytics?.ghostRate ?? 0, VesparaColors.error),
          _buildMetricRow('Flake Rate', _analytics?.flakeRate ?? 0, VesparaColors.warning),
          _buildMetricRow('Response Rate', _analytics?.responseRate ?? 0, VesparaColors.success),
          _buildMetricRow('Match Rate', _analytics?.matchRate ?? 0, VesparaColors.glow),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, double value, Color color) {
    final percentage = (value * 100).toInt();
    final isGood = label == 'Response Rate' || label == 'Match Rate' ? value > 0.5 : value < 0.3;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: VesparaColors.secondary,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: VesparaColors.background,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementTips() {
    final tips = _analytics?.aiImprovementTips ?? [
      'Stop swiping right on everyone - be selective',
      'Actually follow through on date plans instead of flaking',
      'Reply within 24 hours or don\'t reply at all',
      'Be honest about what you want instead of stringing people along',
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: VesparaColors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'How to Not Suck',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, size: 16, color: VesparaColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 13,
                      color: VesparaColors.primary,
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

  Widget _buildRedFlags() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: VesparaColors.error, size: 18),
              const SizedBox(width: 8),
              Text(
                'Red Flags We\'ve Noticed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRedFlagItem('You ghosted 3 people this month'),
          _buildRedFlagItem('Average conversation dies after 12 messages'),
          _buildRedFlagItem('You only swipe on people 5+ years younger'),
          _buildRedFlagItem('Last 4 dates were cancelled by you'),
        ],
      ),
    );
  }

  Widget _buildRedFlagItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, size: 14, color: VesparaColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: VesparaColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD TAB - Edit Vibes, Interests, Desires from Onboarding
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBuildTab() {
    final profileAsync = ref.watch(userProfileProvider);
    
    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading profile', style: TextStyle(color: VesparaColors.error))),
      data: (profile) => profile == null 
          ? Center(child: Text('No profile found', style: TextStyle(color: VesparaColors.secondary)))
          : _buildBuildContent(profile),
    );
  }

  Widget _buildBuildContent(UserProfile profile) {
    // All vibe options from onboarding
    final allVibes = [
      {'emoji': '🌙', 'label': 'Night Owl'},
      {'emoji': '❄️', 'label': 'Early Riser'},
      {'emoji': '⚡', 'label': 'High Energy'},
      {'emoji': '🧘', 'label': 'Calm & Centered'},
      {'emoji': '🎉', 'label': 'Life of the Party'},
      {'emoji': '🏠', 'label': 'Cozy Homebody'},
      {'emoji': '👥', 'label': 'Small Groups Only'},
      {'emoji': '🦋', 'label': 'Social Butterfly'},
      {'emoji': '😂', 'label': 'Witty & Sarcastic'},
      {'emoji': '💝', 'label': 'Hopeless Romantic'},
      {'emoji': '🔥', 'label': 'Passionate'},
      {'emoji': '😌', 'label': 'Easy Going'},
      {'emoji': '😈', 'label': 'Mischievous'},
      {'emoji': '🏔️', 'label': 'Adventurous'},
      {'emoji': '📚', 'label': 'Intellectual'},
      {'emoji': '🎨', 'label': 'Creative'},
      {'emoji': '🚀', 'label': 'Ambitious'},
      {'emoji': '🎲', 'label': 'Spontaneous'},
      {'emoji': '🧠', 'label': 'Deep Thinker'},
      {'emoji': '🦅', 'label': 'Free Spirit'},
      {'emoji': '👴', 'label': 'Old Soul'},
      {'emoji': '❤️', 'label': 'Young at Heart'},
    ];
    
    final allInterests = [
      {'emoji': '✈️', 'label': 'Travel'},
      {'emoji': '🎵', 'label': 'Music'},
      {'emoji': '🎬', 'label': 'Movies & TV'},
      {'emoji': '📚', 'label': 'Reading'},
      {'emoji': '🎮', 'label': 'Gaming'},
      {'emoji': '🏋️', 'label': 'Fitness'},
      {'emoji': '🍳', 'label': 'Cooking'},
      {'emoji': '🍷', 'label': 'Wine & Spirits'},
      {'emoji': '🎨', 'label': 'Art'},
      {'emoji': '📷', 'label': 'Photography'},
      {'emoji': '🌿', 'label': 'Nature'},
      {'emoji': '🎭', 'label': 'Theater'},
      {'emoji': '💃', 'label': 'Dancing'},
      {'emoji': '🧘', 'label': 'Yoga & Meditation'},
      {'emoji': '🏖️', 'label': 'Beach Life'},
      {'emoji': '⛷️', 'label': 'Winter Sports'},
    ];
    
    // Get current selections from profile
    final selectedVibes = profile.lookingFor;  // This is where onboarding saves vibe traits
    final selectedInterests = profile.interestTags;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [VesparaColors.glow.withOpacity(0.2), VesparaColors.surface],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: VesparaColors.glow, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUILD YOUR EXPERIENCE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: VesparaColors.primary,
                      ),
                    ),
                    Text(
                      'Help AI understand you better',
                      style: TextStyle(fontSize: 12, color: VesparaColors.secondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${selectedVibes.length + selectedInterests.length} selected',
                style: TextStyle(fontSize: 12, color: VesparaColors.glow),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // AI Suggestions Section
        Container(
          padding: const EdgeInsets.all(16),
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
                  Row(
                    children: [
                      Icon(Icons.auto_fix_high, color: VesparaColors.glow, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'CHECK ME',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: VesparaColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'AI POWERED',
                      style: TextStyle(fontSize: 10, color: VesparaColors.glow, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Get personalized suggestions based on your profile, interests, and what others with similar vibes enjoy.',
                style: TextStyle(fontSize: 12, color: VesparaColors.secondary),
              ),
              const SizedBox(height: 12),
              Text('You might also like:', style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSuggestionChip('🏔️', 'Adventurous'),
                  _buildSuggestionChip('🎨', 'Creative'),
                  _buildSuggestionChip('✈️', 'Travel'),
                  _buildSuggestionChip('🎵', 'Music'),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // YOUR VIBE Section
        _buildBuildSection(
          title: 'YOUR VIBE',
          subtitle: 'How would you describe your energy?',
          icon: Icons.mood,
          selectedCount: selectedVibes.length,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allVibes.map((vibe) {
                final isSelected = selectedVibes.any((v) => v.contains(vibe['label']!));
                return _buildVibeChip(vibe['emoji']!, vibe['label']!, isSelected);
              }).toList(),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // YOUR INTERESTS Section
        _buildBuildSection(
          title: 'YOUR INTERESTS',
          subtitle: 'What lights you up?',
          icon: Icons.favorite,
          selectedCount: selectedInterests.length,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allInterests.map((interest) {
                final isSelected = selectedInterests.contains(interest['label']);
                return _buildVibeChip(interest['emoji']!, interest['label']!, isSelected);
              }).toList(),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Heat Level
        if (profile.heatLevel != null)
          Container(
            padding: const EdgeInsets.all(16),
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
                    Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'YOUR HEAT LEVEL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getHeatColor(profile.heatLevel!).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getHeatColor(profile.heatLevel!)),
                  ),
                  child: Text(
                    profile.heatLevel!.toUpperCase(),
                    style: TextStyle(
                      color: _getHeatColor(profile.heatLevel!),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 32),
        
        // Edit button
        ElevatedButton.icon(
          onPressed: () => _navigateToEditProfile(profile),
          style: ElevatedButton.styleFrom(
            backgroundColor: VesparaColors.glow,
            foregroundColor: VesparaColors.background,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.edit),
          label: const Text('Edit Your Experience', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBuildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required int selectedCount,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: VesparaColors.glow, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: VesparaColors.glow,
                  ),
                ),
              ],
            ),
            Text(
              '$selectedCount selected',
              style: TextStyle(fontSize: 12, color: VesparaColors.secondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildVibeChip(String emoji, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? VesparaColors.glow.withOpacity(0.2) : VesparaColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? VesparaColors.glow : VesparaColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? VesparaColors.glow : VesparaColors.primary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (!isSelected) ...[
            const SizedBox(width: 4),
            Icon(Icons.add, size: 14, color: VesparaColors.secondary),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VesparaColors.glow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: VesparaColors.primary),
          ),
          const SizedBox(width: 4),
          Icon(Icons.add, size: 14, color: VesparaColors.glow),
        ],
      ),
    );
  }

  Color _getHeatColor(String heatLevel) {
    switch (heatLevel.toLowerCase()) {
      case 'mild':
        return Colors.pink.shade300;
      case 'medium':
        return Colors.orange.shade400;
      case 'hot':
        return Colors.red.shade400;
      case 'nuclear':
        return Colors.purple.shade400;
      default:
        return VesparaColors.glow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SETTINGS TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsSection('Discovery Preferences', [
          _buildSettingTile('Age Range', '21-45', Icons.cake_outlined, () => _showAgeRangeDialog()),
          _buildSettingTile('Distance', 'Within 25 miles', Icons.location_on_outlined, () => _showDistanceDialog()),
          _buildSettingTile('Show Me', 'Everyone', Icons.people_outline, () => _showGenderPreferenceDialog()),
          _buildSettingTile('Relationship Types', '3 selected', Icons.favorite_outline, () => _showRelationshipTypesDialog()),
        ]),
        const SizedBox(height: 16),
        _buildSettingsSection('Notifications', [
          _buildSettingToggle('New Matches'),
          _buildSettingToggle('Messages'),
          _buildSettingToggle('Date Reminders'),
          _buildSettingToggle('AI Insights'),
        ]),
        const SizedBox(height: 16),
        _buildSettingsSection('Privacy', [
          _buildSettingToggle('Show Online Status'),
          _buildSettingToggle('Read Receipts'),
          _buildSettingToggle('Profile Visible'),
        ]),
        const SizedBox(height: 16),
        _buildSettingsSection('Calendar Sync', [
          _buildSettingTile('Google Calendar', 'Connected', Icons.calendar_today, () => _showCalendarSyncDialog('Google')),
          _buildSettingTile('Apple Calendar', 'Not Connected', Icons.event, () => _showCalendarSyncDialog('Apple')),
        ]),
        const SizedBox(height: 16),
        _buildSettingsSection('Account', [
          _buildSettingTile('Subscription', 'Free', Icons.star_outline, () => _showSubscriptionDialog()),
          _buildSettingTile('Email', ref.watch(userProfileProvider).valueOrNull?.email ?? 'Not set', Icons.email_outlined, () => _showEditEmailDialog()),
          _buildSettingTile('Phone', '+1 555-****', Icons.phone_outlined, () => _showEditPhoneDialog()),
        ]),
        const SizedBox(height: 24),
        _buildDangerZone(),
      ],
    );
  }

  void _showAgeRangeDialog() {
    RangeValues range = const RangeValues(21, 45);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Age Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
              const SizedBox(height: 24),
              Text('${range.start.toInt()} - ${range.end.toInt()} years',
                  style: TextStyle(fontSize: 24, color: VesparaColors.glow)),
              RangeSlider(
                values: range,
                min: 18,
                max: 65,
                divisions: 47,
                activeColor: VesparaColors.glow,
                inactiveColor: VesparaColors.glow.withOpacity(0.2),
                onChanged: (v) => setModalState(() => range = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Age range updated to ${range.start.toInt()}-${range.end.toInt()}')),
                    );
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDistanceDialog() {
    double distance = 25;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Maximum Distance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
              const SizedBox(height: 24),
              Text('${distance.toInt()} miles', style: TextStyle(fontSize: 24, color: VesparaColors.glow)),
              Slider(
                value: distance,
                min: 1,
                max: 100,
                divisions: 99,
                activeColor: VesparaColors.glow,
                inactiveColor: VesparaColors.glow.withOpacity(0.2),
                onChanged: (v) => setModalState(() => distance = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Distance updated to ${distance.toInt()} miles')),
                    );
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGenderPreferenceDialog() {
    String selected = 'Everyone';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Show Me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
              const SizedBox(height: 24),
              ...['Women', 'Men', 'Everyone'].map((option) => RadioListTile<String>(
                title: Text(option, style: TextStyle(color: VesparaColors.primary)),
                value: option,
                groupValue: selected,
                activeColor: VesparaColors.glow,
                onChanged: (v) {
                  setModalState(() => selected = v!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Preference updated to $v')),
                  );
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showRelationshipTypesDialog() {
    final types = ['Long-term', 'Casual', 'Open', 'Friendship', 'Unsure'];
    final selected = {'Long-term', 'Casual', 'Friendship'};
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Relationship Types', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((type) => FilterChip(
                  label: Text(type),
                  selected: selected.contains(type),
                  onSelected: (v) {
                    setModalState(() {
                      v ? selected.add(type) : selected.remove(type);
                    });
                  },
                  selectedColor: VesparaColors.glow.withOpacity(0.3),
                  checkmarkColor: VesparaColors.glow,
                  backgroundColor: VesparaColors.background,
                  labelStyle: TextStyle(color: selected.contains(type) ? VesparaColors.glow : VesparaColors.primary),
                )).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${selected.length} relationship types selected')),
                    );
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCalendarSyncDialog(String provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$provider Calendar', style: TextStyle(color: VesparaColors.primary)),
        content: Text(
          provider == 'Google' 
            ? 'Your Google Calendar is connected. Disconnect?' 
            : 'Connect your Apple Calendar to sync dates automatically.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(provider == 'Google' ? 'Disconnected from Google Calendar' : 'Connecting to Apple Calendar...')),
              );
            },
            child: Text(provider == 'Google' ? 'Disconnect' : 'Connect', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 48, color: VesparaColors.glow),
            const SizedBox(height: 16),
            Text('Vespara Plus', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: VesparaColors.glow)),
            const SizedBox(height: 8),
            Text('You\'re on the Plus plan!', style: TextStyle(color: VesparaColors.secondary)),
            const SizedBox(height: 24),
            _buildSubscriptionFeature('Unlimited swipes'),
            _buildSubscriptionFeature('See who likes you'),
            _buildSubscriptionFeature('AI dating coach'),
            _buildSubscriptionFeature('Priority matching'),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening subscription management...')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: VesparaColors.glow),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Manage Subscription', style: TextStyle(color: VesparaColors.glow)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: VesparaColors.success, size: 20),
          const SizedBox(width: 12),
          Text(feature, style: TextStyle(color: VesparaColors.primary)),
        ],
      ),
    );
  }

  void _showEditEmailDialog() {
    final currentEmail = ref.read(userProfileProvider).valueOrNull?.email ?? '';
    final controller = TextEditingController(text: currentEmail);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Email', style: TextStyle(color: VesparaColors.primary)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.email, color: VesparaColors.glow),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: TextStyle(color: VesparaColors.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Verification email sent to ${controller.text}')),
              );
            },
            child: Text('Save', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Phone', style: TextStyle(color: VesparaColors.primary)),
        content: TextField(
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+1 (555) 000-0000',
            hintStyle: TextStyle(color: VesparaColors.secondary),
            prefixIcon: Icon(Icons.phone, color: VesparaColors.glow),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: TextStyle(color: VesparaColors.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification code sent to your phone')),
              );
            },
            child: Text('Save', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: VesparaColors.secondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: VesparaColors.glow, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: VesparaColors.primary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: VesparaColors.secondary, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSettingToggle(String title) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: VesparaColors.primary,
        ),
      ),
      trailing: Switch.adaptive(
        value: _toggleSettings[title] ?? false,
        onChanged: (v) {
          setState(() => _toggleSettings[title] = v);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title ${v ? 'enabled' : 'disabled'}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        activeColor: VesparaColors.glow,
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      decoration: BoxDecoration(
        color: VesparaColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VesparaColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.pause_circle_outline, color: VesparaColors.warning),
            title: Text('Pause Account', style: TextStyle(color: VesparaColors.primary)),
            onTap: () => _showPauseAccountDialog(),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: VesparaColors.error),
            title: Text('Delete Account', style: TextStyle(color: VesparaColors.error)),
            onTap: () => _showDeleteAccountDialog(),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: VesparaColors.error),
            title: Text('Log Out', style: TextStyle(color: VesparaColors.error)),
            onTap: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  void _showPauseAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pause Your Account?', style: TextStyle(color: VesparaColors.primary)),
        content: Text(
          'Your profile will be hidden and you won\'t receive new matches. You can unpause anytime.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Account paused. Come back when you\'re ready!'),
                  backgroundColor: VesparaColors.warning,
                ),
              );
            },
            child: Text('Pause', style: TextStyle(color: VesparaColors.warning)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Account?', style: TextStyle(color: VesparaColors.error)),
        content: Text(
          'This action cannot be undone. All your data, matches, and messages will be permanently deleted.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Account deleted. We\'re sorry to see you go.'),
                  backgroundColor: VesparaColors.error,
                ),
              );
            },
            child: Text('Delete Forever', style: TextStyle(color: VesparaColors.error)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out?', style: TextStyle(color: VesparaColors.primary)),
        content: Text(
          'You\'ll need to sign in again to access your account.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            child: Text('Log Out', style: TextStyle(color: VesparaColors.error)),
          ),
        ],
      ),
    );
  }
}
