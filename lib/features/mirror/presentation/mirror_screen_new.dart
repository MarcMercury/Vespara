import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/data/vespara_mock_data.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/domain/models/analytics.dart';

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
  late UserAnalytics _analytics;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _analytics = MockDataProvider.analytics;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildProfileTab(),
                  _buildBrutalTruthTab(),
                  _buildSettingsTab(),
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
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: VesparaColors.secondary),
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
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerHeight: 0,
        tabs: [
          Tab(text: 'Profile'),
          Tab(text: 'Brutal Truth'),
          Tab(text: 'Settings'),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PROFILE TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildProfileTab() {
    final profile = MockDataProvider.currentUserProfile;
    
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
          _buildProfileSection('Looking For', profile.relationshipTypes.join(', '), Icons.favorite_outline),
          _buildProfileSection('Kinks & Interests', profile.kinks.join(', '), Icons.whatshot_outlined),
          _buildProfileSection('Boundaries', profile.boundaries.join(', '), Icons.shield_outlined),
          _buildProfileSection('Love Languages', profile.loveLanguages.join(', '), Icons.language),
          
          const SizedBox(height: 24),
          
          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
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
          _buildStatColumn(_analytics.totalMatches.toString(), 'Matches'),
          Container(width: 1, height: 40, color: VesparaColors.glow.withOpacity(0.2)),
          _buildStatColumn('${(_analytics.responseRate * 100).toInt()}%', 'Response'),
          Container(width: 1, height: 40, color: VesparaColors.glow.withOpacity(0.2)),
          _buildStatColumn(_analytics.activeDays.toString(), 'Days Active'),
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
            _analytics.aiPersonalitySummary ?? 
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
            _analytics.aiDatingStyle ?? '"The Collector"',
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
          _buildMetricRow('Ghost Rate', _analytics.ghostRate, VesparaColors.error),
          _buildMetricRow('Flake Rate', _analytics.flakeRate, VesparaColors.warning),
          _buildMetricRow('Response Rate', _analytics.responseRate, VesparaColors.success),
          _buildMetricRow('Match Rate', _analytics.matchRate, VesparaColors.glow),
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
    final tips = _analytics.aiImprovementTips ?? [
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
  // SETTINGS TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsSection('Discovery Preferences', [
          _buildSettingTile('Age Range', '21-45', Icons.cake_outlined),
          _buildSettingTile('Distance', 'Within 25 miles', Icons.location_on_outlined),
          _buildSettingTile('Show Me', 'Everyone', Icons.people_outline),
          _buildSettingTile('Relationship Types', '3 selected', Icons.favorite_outline),
        ]),
        const SizedBox(height: 16),
        _buildSettingsSection('Notifications', [
          _buildSettingToggle('New Matches', true),
          _buildSettingToggle('Messages', true),
          _buildSettingToggle('Date Reminders', true),
          _buildSettingToggle('AI Insights', false),
        ]),
        const SizedBox(height: 16),
        _buildSettingsSection('Privacy', [
          _buildSettingToggle('Show Online Status', true),
          _buildSettingToggle('Read Receipts', false),
          _buildSettingToggle('Profile Visible', true),
        ]),
        const SizedBox(height: 16),
        _buildSettingsSection('Calendar Sync', [
          _buildSettingTile('Google Calendar', 'Connected', Icons.calendar_today),
          _buildSettingTile('Apple Calendar', 'Not Connected', Icons.event),
        ]),
        const SizedBox(height: 16),
        _buildSettingsSection('Account', [
          _buildSettingTile('Subscription', 'Vespara Plus', Icons.star_outline),
          _buildSettingTile('Email', 'demo@vespara.app', Icons.email_outlined),
          _buildSettingTile('Phone', '+1 555-****', Icons.phone_outlined),
        ]),
        const SizedBox(height: 24),
        _buildDangerZone(),
      ],
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

  Widget _buildSettingTile(String title, String value, IconData icon) {
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
      onTap: () {},
    );
  }

  Widget _buildSettingToggle(String title, bool value) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: VesparaColors.primary,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: (v) {},
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
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: VesparaColors.error),
            title: Text('Delete Account', style: TextStyle(color: VesparaColors.error)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.logout, color: VesparaColors.error),
            title: Text('Log Out', style: TextStyle(color: VesparaColors.error)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
