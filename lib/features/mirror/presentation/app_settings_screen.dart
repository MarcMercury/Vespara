import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/providers/app_providers.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// APP SETTINGS SCREEN - "Build Your Experience"
/// Comprehensive settings for permissions, notifications, preferences,
/// desires, and AI-powered personalization
/// ════════════════════════════════════════════════════════════════════════════

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PermissionService _permissionService = PermissionService();
  
  // Permission states
  bool _locationEnabled = false;
  bool _notificationsEnabled = false;
  bool _cameraEnabled = false;
  bool _photosEnabled = false;
  
  // Notification preferences
  bool _matchNotifications = true;
  bool _messageNotifications = true;
  bool _experienceNotifications = true;
  bool _rsvpNotifications = true;
  bool _reminderNotifications = true;
  bool _nudgeNotifications = true;
  bool _weeklyDigest = true;
  bool _specialOffers = false;
  
  // Discovery preferences
  String _discoveryMode = 'balanced';
  double _maxDistance = 25.0;
  RangeValues _ageRange = const RangeValues(21, 45);
  bool _showVerifiedOnly = false;
  bool _showActiveRecently = true;
  
  // Experience preferences
  String _experienceStyle = 'curated';
  List<String> _selectedVibes = ['Intimate', 'Adventurous'];
  List<String> _selectedDesires = [];
  String _pacePreference = 'medium';
  
  // AI personalization
  bool _aiSuggestionsEnabled = true;
  bool _aiMatchInsights = true;
  bool _aiConversationTips = true;
  bool _aiExperienceRecommendations = true;
  String _aiPersonality = 'playful';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkPermissions();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _checkPermissions() async {
    final locationStatus = await _permissionService.checkLocationPermission();
    setState(() {
      _locationEnabled = locationStatus == VesparaPermissionStatus.granted;
    });
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
                  _buildPermissionsTab(),
                  _buildNotificationsTab(),
                  _buildDiscoveryTab(),
                  _buildExperienceTab(),
                  _buildAITab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: VesparaColors.primary),
              ),
              const Spacer(),
              TextButton(
                onPressed: _saveSettings,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: VesparaColors.glow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.md),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [VesparaColors.glow, VesparaColors.accent],
            ).createShader(bounds),
            child: Text(
              'Build Your Experience',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: VesparaSpacing.xs),
          Text(
            'Craft a hyper-personal journey tailored to your desires',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: VesparaColors.secondary,
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
        borderRadius: BorderRadius.circular(VesparaRadius.lg),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: VesparaColors.glow.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(VesparaRadius.md),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: VesparaColors.glow,
        unselectedLabelColor: VesparaColors.secondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(icon: Icon(Icons.security, size: 18), text: 'Access'),
          Tab(icon: Icon(Icons.notifications, size: 18), text: 'Alerts'),
          Tab(icon: Icon(Icons.explore, size: 18), text: 'Discovery'),
          Tab(icon: Icon(Icons.favorite, size: 18), text: 'Desires'),
          Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'AI'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISSIONS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'App Permissions',
            'Enable features by granting access',
            Icons.lock_open_rounded,
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          _buildPermissionCard(
            icon: Icons.location_on_rounded,
            title: 'Location',
            subtitle: 'Find nearby matches, events, and enable Tonight Mode',
            isEnabled: _locationEnabled,
            onToggle: _requestLocationPermission,
            features: ['Nearby matches', 'Local experiences', 'Tonight Mode', 'Distance filtering'],
          ),
          
          const SizedBox(height: VesparaSpacing.md),
          
          _buildPermissionCard(
            icon: Icons.notifications_active_rounded,
            title: 'Notifications',
            subtitle: 'Stay updated on matches, messages, and experiences',
            isEnabled: _notificationsEnabled,
            onToggle: _requestNotificationPermission,
            features: ['Match alerts', 'Message notifications', 'Experience reminders', 'AI nudges'],
          ),
          
          const SizedBox(height: VesparaSpacing.md),
          
          _buildPermissionCard(
            icon: Icons.camera_alt_rounded,
            title: 'Camera',
            subtitle: 'Take photos for your profile and verify your identity',
            isEnabled: _cameraEnabled,
            onToggle: _requestCameraPermission,
            features: ['Profile photos', 'Verification', 'In-app capture'],
          ),
          
          const SizedBox(height: VesparaSpacing.md),
          
          _buildPermissionCard(
            icon: Icons.photo_library_rounded,
            title: 'Photo Library',
            subtitle: 'Access your photos for profile and experience media',
            isEnabled: _photosEnabled,
            onToggle: _requestPhotosPermission,
            features: ['Profile gallery', 'Experience photos', 'Chat media'],
          ),
          
          const SizedBox(height: VesparaSpacing.xl),
          
          _buildPrivacyNote(),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onToggle,
    required List<String> features,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaRadius.lg),
        border: Border.all(
          color: isEnabled ? VesparaColors.glow.withValues(alpha: 0.3) : VesparaColors.border,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEnabled 
                    ? VesparaColors.glow.withValues(alpha: 0.2)
                    : VesparaColors.background,
                borderRadius: BorderRadius.circular(VesparaRadius.md),
              ),
              child: Icon(
                icon,
                color: isEnabled ? VesparaColors.glow : VesparaColors.secondary,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: VesparaColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
            ),
            trailing: Switch(
              value: isEnabled,
              onChanged: (_) => onToggle(),
              activeColor: VesparaColors.glow,
            ),
          ),
          if (!isEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features.map((feature) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: VesparaColors.background,
                    borderRadius: BorderRadius.circular(VesparaRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 12, color: VesparaColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        feature,
                        style: TextStyle(color: VesparaColors.secondary, fontSize: 11),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.glow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VesparaRadius.md),
        border: Border.all(color: VesparaColors.glow.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: VesparaColors.glow),
          const SizedBox(width: VesparaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    color: VesparaColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'We only access what you allow. Location is never shared without consent.',
                  style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Notification Preferences',
            'Control what alerts you receive',
            Icons.notifications_active_rounded,
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          _buildNotificationSection(
            'Connections',
            Icons.favorite_rounded,
            [
              _NotificationOption(
                title: 'New Matches',
                subtitle: 'When someone swipes right on you',
                value: _matchNotifications,
                onChanged: (v) => setState(() => _matchNotifications = v),
              ),
              _NotificationOption(
                title: 'Messages',
                subtitle: 'New messages from your connections',
                value: _messageNotifications,
                onChanged: (v) => setState(() => _messageNotifications = v),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          _buildNotificationSection(
            'Experiences',
            Icons.local_fire_department_rounded,
            [
              _NotificationOption(
                title: 'Experience Updates',
                subtitle: 'New experiences and updates to ones you\'re attending',
                value: _experienceNotifications,
                onChanged: (v) => setState(() => _experienceNotifications = v),
              ),
              _NotificationOption(
                title: 'RSVP Responses',
                subtitle: 'When someone RSVPs to your experience',
                value: _rsvpNotifications,
                onChanged: (v) => setState(() => _rsvpNotifications = v),
              ),
              _NotificationOption(
                title: 'Reminders',
                subtitle: 'Upcoming experience reminders',
                value: _reminderNotifications,
                onChanged: (v) => setState(() => _reminderNotifications = v),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          _buildNotificationSection(
            'AI Assistant',
            Icons.auto_awesome_rounded,
            [
              _NotificationOption(
                title: 'Smart Nudges',
                subtitle: 'AI-powered suggestions to boost your connections',
                value: _nudgeNotifications,
                onChanged: (v) => setState(() => _nudgeNotifications = v),
              ),
              _NotificationOption(
                title: 'Weekly Digest',
                subtitle: 'Summary of your activity and insights',
                value: _weeklyDigest,
                onChanged: (v) => setState(() => _weeklyDigest = v),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          _buildNotificationSection(
            'Other',
            Icons.more_horiz_rounded,
            [
              _NotificationOption(
                title: 'Special Offers',
                subtitle: 'Exclusive deals and premium features',
                value: _specialOffers,
                onChanged: (v) => setState(() => _specialOffers = v),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.xl),
          
          _buildQuietHoursCard(),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(String title, IconData icon, List<_NotificationOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: VesparaColors.glow, size: 20),
            const SizedBox(width: VesparaSpacing.sm),
            Text(
              title,
              style: TextStyle(
                color: VesparaColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: VesparaSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(VesparaRadius.lg),
          ),
          child: Column(
            children: options.map((option) => SwitchListTile(
              title: Text(option.title, style: TextStyle(color: VesparaColors.primary)),
              subtitle: Text(option.subtitle, style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
              value: option.value,
              onChanged: option.onChanged,
              activeColor: VesparaColors.glow,
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuietHoursCard() {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaRadius.lg),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bedtime_rounded, color: VesparaColors.glow),
              const SizedBox(width: VesparaSpacing.sm),
              Text(
                'Quiet Hours',
                style: TextStyle(
                  color: VesparaColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: false,
                onChanged: (v) {},
                activeColor: VesparaColors.glow,
              ),
            ],
          ),
          Text(
            'Pause all notifications during set hours',
            style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISCOVERY TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDiscoveryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Discovery Preferences',
            'Fine-tune who you see and who sees you',
            Icons.explore_rounded,
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          // Discovery Mode
          _buildSelectionCard(
            title: 'Discovery Mode',
            subtitle: 'How aggressively should we match you?',
            options: [
              _SelectionOption(
                value: 'conservative',
                label: 'Selective',
                icon: Icons.diamond_outlined,
                description: 'Fewer, higher quality matches',
              ),
              _SelectionOption(
                value: 'balanced',
                label: 'Balanced',
                icon: Icons.balance_rounded,
                description: 'Best of both worlds',
              ),
              _SelectionOption(
                value: 'aggressive',
                label: 'Open',
                icon: Icons.open_with_rounded,
                description: 'Cast a wider net',
              ),
            ],
            selectedValue: _discoveryMode,
            onChanged: (v) => setState(() => _discoveryMode = v),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Distance
          _buildSliderCard(
            title: 'Maximum Distance',
            value: '${_maxDistance.round()} miles',
            icon: Icons.near_me_rounded,
            child: Slider(
              value: _maxDistance,
              min: 5,
              max: 100,
              divisions: 19,
              activeColor: VesparaColors.glow,
              inactiveColor: VesparaColors.border,
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Age Range
          _buildSliderCard(
            title: 'Age Range',
            value: '${_ageRange.start.round()} - ${_ageRange.end.round()}',
            icon: Icons.cake_rounded,
            child: RangeSlider(
              values: _ageRange,
              min: 18,
              max: 99,
              divisions: 81,
              activeColor: VesparaColors.glow,
              inactiveColor: VesparaColors.border,
              onChanged: (v) => setState(() => _ageRange = v),
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Filters
          Container(
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(VesparaRadius.lg),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Verified Only', style: TextStyle(color: VesparaColors.primary)),
                  subtitle: Text('Only show verified profiles', style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
                  secondary: Icon(Icons.verified_rounded, color: VesparaColors.glow),
                  value: _showVerifiedOnly,
                  onChanged: (v) => setState(() => _showVerifiedOnly = v),
                  activeColor: VesparaColors.glow,
                ),
                Divider(height: 1, color: VesparaColors.border),
                SwitchListTile(
                  title: Text('Recently Active', style: TextStyle(color: VesparaColors.primary)),
                  subtitle: Text('Prioritize people active in the last 24 hours', style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
                  secondary: Icon(Icons.access_time_rounded, color: VesparaColors.glow),
                  value: _showActiveRecently,
                  onChanged: (v) => setState(() => _showActiveRecently = v),
                  activeColor: VesparaColors.glow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String value,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: VesparaColors.glow, size: 20),
              const SizedBox(width: VesparaSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  color: VesparaColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(VesparaRadius.sm),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: VesparaColors.glow,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required List<_SelectionOption> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: VesparaColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
          ),
          const SizedBox(height: VesparaSpacing.md),
          Row(
            children: options.map((option) {
              final isSelected = option.value == selectedValue;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(option.value);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(VesparaSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? VesparaColors.glow.withValues(alpha: 0.2) : VesparaColors.background,
                      borderRadius: BorderRadius.circular(VesparaRadius.md),
                      border: Border.all(
                        color: isSelected ? VesparaColors.glow : VesparaColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          option.icon,
                          color: isSelected ? VesparaColors.glow : VesparaColors.secondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.label,
                          style: TextStyle(
                            color: isSelected ? VesparaColors.glow : VesparaColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          option.description,
                          style: TextStyle(
                            color: VesparaColors.secondary,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPERIENCE/DESIRES TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildExperienceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Your Desires',
            'Tell us what you\'re looking for',
            Icons.favorite_rounded,
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          // Experience Style
          _buildSelectionCard(
            title: 'Experience Style',
            subtitle: 'How do you like your encounters?',
            options: [
              _SelectionOption(
                value: 'spontaneous',
                label: 'Spontaneous',
                icon: Icons.flash_on_rounded,
                description: 'Go with the flow',
              ),
              _SelectionOption(
                value: 'curated',
                label: 'Curated',
                icon: Icons.auto_awesome_rounded,
                description: 'Thoughtfully planned',
              ),
              _SelectionOption(
                value: 'adventurous',
                label: 'Adventurous',
                icon: Icons.explore_rounded,
                description: 'Push boundaries',
              ),
            ],
            selectedValue: _experienceStyle,
            onChanged: (v) => setState(() => _experienceStyle = v),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Vibes
          _buildChipsSection(
            title: 'Your Vibe',
            subtitle: 'What energy are you bringing?',
            icon: Icons.music_note_rounded,
            options: ['Intimate', 'Adventurous', 'Romantic', 'Playful', 'Mysterious', 'Bold', 'Sensual', 'Wild', 'Sophisticated', 'Casual'],
            selectedValues: _selectedVibes,
            onChanged: (values) => setState(() => _selectedVibes = values),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Desires
          _buildChipsSection(
            title: 'Desires & Interests',
            subtitle: 'What excites you? (Private)',
            icon: Icons.local_fire_department_rounded,
            options: ['Dating', 'Casual', 'Long-term', 'Friends first', 'Exploration', 'Kink-friendly', 'Travel buddy', 'Networking', 'Open relationship', 'Polyamory'],
            selectedValues: _selectedDesires,
            onChanged: (values) => setState(() => _selectedDesires = values),
            isPrivate: true,
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Pace
          Container(
            padding: const EdgeInsets.all(VesparaSpacing.md),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(VesparaRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Pace',
                  style: TextStyle(
                    color: VesparaColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'How fast do you like things to move?',
                  style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
                ),
                const SizedBox(height: VesparaSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPaceOption('slow', '🐢', 'Slow'),
                    _buildPaceOption('medium', '🦊', 'Medium'),
                    _buildPaceOption('fast', '🚀', 'Fast'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaceOption(String value, String emoji, String label) {
    final isSelected = _pacePreference == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _pacePreference = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? VesparaColors.glow.withValues(alpha: 0.2) : VesparaColors.background,
          borderRadius: BorderRadius.circular(VesparaRadius.md),
          border: Border.all(
            color: isSelected ? VesparaColors.glow : VesparaColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? VesparaColors.glow : VesparaColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipsSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> options,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
    bool isPrivate = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: VesparaColors.glow, size: 20),
              const SizedBox(width: VesparaSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  color: VesparaColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (isPrivate) ...[
                const SizedBox(width: VesparaSpacing.sm),
                Icon(Icons.lock_outline, size: 14, color: VesparaColors.secondary),
              ],
            ],
          ),
          Text(
            subtitle,
            style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
          ),
          const SizedBox(height: VesparaSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedValues.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  HapticFeedback.selectionClick();
                  final newValues = List<String>.from(selectedValues);
                  if (selected) {
                    newValues.add(option);
                  } else {
                    newValues.remove(option);
                  }
                  onChanged(newValues);
                },
                selectedColor: VesparaColors.glow.withValues(alpha: 0.3),
                checkmarkColor: VesparaColors.glow,
                labelStyle: TextStyle(
                  color: isSelected ? VesparaColors.glow : VesparaColors.primary,
                  fontSize: 12,
                ),
                backgroundColor: VesparaColors.background,
                side: BorderSide(
                  color: isSelected ? VesparaColors.glow : VesparaColors.border,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAITab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'AI Personalization',
            'Let AI craft your perfect experience',
            Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          // AI Master Toggle
          Container(
            padding: const EdgeInsets.all(VesparaSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VesparaColors.glow.withValues(alpha: 0.2),
                  VesparaColors.accent.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(VesparaRadius.lg),
              border: Border.all(color: VesparaColors.glow.withValues(alpha: 0.5)),
            ),
            child: SwitchListTile(
              title: Text(
                'AI Suggestions',
                style: TextStyle(
                  color: VesparaColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Enable AI-powered recommendations across Vespara',
                style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
              ),
              secondary: Icon(Icons.psychology_rounded, color: VesparaColors.glow, size: 32),
              value: _aiSuggestionsEnabled,
              onChanged: (v) => setState(() => _aiSuggestionsEnabled = v),
              activeColor: VesparaColors.glow,
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // AI Features
          if (_aiSuggestionsEnabled) ...[
            Container(
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(VesparaRadius.lg),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Match Insights', style: TextStyle(color: VesparaColors.primary)),
                    subtitle: Text('AI analysis of compatibility', style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
                    secondary: Icon(Icons.insights_rounded, color: VesparaColors.glow),
                    value: _aiMatchInsights,
                    onChanged: (v) => setState(() => _aiMatchInsights = v),
                    activeColor: VesparaColors.glow,
                  ),
                  Divider(height: 1, color: VesparaColors.border),
                  SwitchListTile(
                    title: Text('Conversation Tips', style: TextStyle(color: VesparaColors.primary)),
                    subtitle: Text('Suggestions to keep conversations flowing', style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
                    secondary: Icon(Icons.chat_bubble_outline_rounded, color: VesparaColors.glow),
                    value: _aiConversationTips,
                    onChanged: (v) => setState(() => _aiConversationTips = v),
                    activeColor: VesparaColors.glow,
                  ),
                  Divider(height: 1, color: VesparaColors.border),
                  SwitchListTile(
                    title: Text('Experience Recommendations', style: TextStyle(color: VesparaColors.primary)),
                    subtitle: Text('Personalized experience suggestions', style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
                    secondary: Icon(Icons.local_fire_department_rounded, color: VesparaColors.glow),
                    value: _aiExperienceRecommendations,
                    onChanged: (v) => setState(() => _aiExperienceRecommendations = v),
                    activeColor: VesparaColors.glow,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: VesparaSpacing.lg),
            
            // AI Personality
            Container(
              padding: const EdgeInsets.all(VesparaSpacing.md),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(VesparaRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.face_rounded, color: VesparaColors.glow, size: 20),
                      const SizedBox(width: VesparaSpacing.sm),
                      Text(
                        'AI Personality',
                        style: TextStyle(
                          color: VesparaColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'How should the AI communicate with you?',
                    style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
                  ),
                  const SizedBox(height: VesparaSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPersonalityChip('playful', '😏 Playful'),
                      _buildPersonalityChip('professional', '💼 Professional'),
                      _buildPersonalityChip('supportive', '🤗 Supportive'),
                      _buildPersonalityChip('direct', '💪 Direct'),
                      _buildPersonalityChip('mysterious', '🌙 Mysterious'),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: VesparaSpacing.xl),
          
          // Data & Learning
          Container(
            padding: const EdgeInsets.all(VesparaSpacing.md),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(VesparaRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school_rounded, color: VesparaColors.glow),
                    const SizedBox(width: VesparaSpacing.sm),
                    Text(
                      'AI Learning',
                      style: TextStyle(
                        color: VesparaColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VesparaSpacing.sm),
                Text(
                  'The AI learns from your behavior to provide better recommendations. Your data is encrypted and never shared.',
                  style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
                ),
                const SizedBox(height: VesparaSpacing.md),
                OutlinedButton.icon(
                  onPressed: _resetAIData,
                  icon: Icon(Icons.refresh_rounded, color: VesparaColors.error),
                  label: Text('Reset AI Data', style: TextStyle(color: VesparaColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: VesparaColors.error.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityChip(String value, String label) {
    final isSelected = _aiPersonality == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          HapticFeedback.selectionClick();
          setState(() => _aiPersonality = value);
        }
      },
      selectedColor: VesparaColors.glow.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: isSelected ? VesparaColors.glow : VesparaColors.primary,
        fontSize: 12,
      ),
      backgroundColor: VesparaColors.background,
      side: BorderSide(
        color: isSelected ? VesparaColors.glow : VesparaColors.border,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [VesparaColors.glow, VesparaColors.accent],
            ),
            borderRadius: BorderRadius.circular(VesparaRadius.md),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: VesparaSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: VesparaColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISSION HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _requestLocationPermission() async {
    HapticFeedback.mediumImpact();
    final result = await _permissionService.requestLocationPermission(
      context: context,
      showRationale: true,
    );
    setState(() => _locationEnabled = result.isGranted);
    
    if (result.isPermanentlyDenied && mounted) {
      _showOpenSettingsDialog('Location');
    }
  }

  Future<void> _requestNotificationPermission() async {
    HapticFeedback.mediumImpact();
    // For now, just toggle since we don't have push notification setup
    setState(() => _notificationsEnabled = !_notificationsEnabled);
    
    if (_notificationsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notifications enabled! 🔔'),
          backgroundColor: VesparaColors.success,
        ),
      );
    }
  }

  Future<void> _requestCameraPermission() async {
    HapticFeedback.mediumImpact();
    final file = await _permissionService.takeCameraPhoto(context: context);
    setState(() => _cameraEnabled = file != null);
  }

  Future<void> _requestPhotosPermission() async {
    HapticFeedback.mediumImpact();
    final file = await _permissionService.pickImageFromGallery(context: context);
    setState(() => _photosEnabled = file != null);
  }

  void _showOpenSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: Text('$permissionName Permission Required'),
        content: Text(
          '$permissionName access was denied. Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: VesparaColors.glow),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    HapticFeedback.heavyImpact();
    // TODO: Persist to Supabase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved! ✨'),
        backgroundColor: VesparaColors.success,
      ),
    );
    Navigator.pop(context);
  }

  void _resetAIData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: Text('Reset AI Data?', style: TextStyle(color: VesparaColors.primary)),
        content: Text(
          'This will clear all AI learning data. The AI will need to relearn your preferences.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('AI data reset'),
                  backgroundColor: VesparaColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: VesparaColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// Helper classes
class _NotificationOption {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  _NotificationOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}

class _SelectionOption {
  final String value;
  final String label;
  final IconData icon;
  final String description;

  _SelectionOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.description,
  });
}
