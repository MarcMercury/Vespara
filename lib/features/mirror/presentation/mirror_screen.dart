import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/domain/models/analytics.dart';
import '../../../core/domain/models/profile_photo.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/profile_photos_provider.dart';
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
    // Notifications
    'New Matches': true,
    'Messages': true,
    'Date Reminders': true,
    'AI Insights': true,
    'Event Invitations': true,
    'Group Activity': true,
    'Game Requests': false,
    'Weekly Digest': true,
    // Privacy
    'Show Online Status': true,
    'Read Receipts': false,
    'Profile Visible': true,
    'Show Last Active': false,
    'Allow Screenshotting': false,
    'Incognito Browsing': false,
  };
  
  UserAnalytics? _cachedAnalytics;
  
  // Settings state that gets saved to database
  RangeValues _ageRange = const RangeValues(21, 55);
  double _maxDistance = 50;
  String _showMe = 'Everyone';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load saved settings
    _loadSavedSettings();
  }
  
  Future<void> _loadSavedSettings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    try {
      final response = await Supabase.instance.client
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (response != null) {
        setState(() {
          _ageRange = RangeValues(
            (response['min_age'] as num?)?.toDouble() ?? 21,
            (response['max_age'] as num?)?.toDouble() ?? 55,
          );
          _maxDistance = (response['max_distance'] as num?)?.toDouble() ?? 50;
          _showMe = response['show_me'] as String? ?? 'Everyone';
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }
  
  Future<void> _saveSettings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    try {
      await Supabase.instance.client.from('user_settings').upsert({
        'user_id': user.id,
        'min_age': _ageRange.start.toInt(),
        'max_age': _ageRange.end.toInt(),
        'max_distance': _maxDistance.toInt(),
        'show_me': _showMe,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving settings: $e');
    }
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
                  _buildBrutalTruthTab(),       // TRUTH
                  _buildBuildProfileTab(),      // BUILD PROFILE (combined)
                  _buildSettingsTab(),          // SETTINGS
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
          Tab(icon: Icon(Icons.auto_awesome, size: 16), text: 'BUILD'),
          Tab(icon: Icon(Icons.settings_outlined, size: 16), text: 'SETTINGS'),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD PROFILE TAB - Combined Profile + Build (all editable)
  // ════════════════════════════════════════════════════════════════════════════

  // State for editable fields
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isGeneratingBio = false;
  bool _isSaving = false;
  bool _profileInitialized = false;
  
  // Mutable selections for vibes and interests
  Set<String> _selectedVibes = {};
  Set<String> _selectedInterests = {};

  Widget _buildBuildProfileTab() {
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
      data: (profile) {
        if (profile == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, color: VesparaColors.secondary, size: 48),
                const SizedBox(height: 16),
                Text('No profile found', style: TextStyle(color: VesparaColors.secondary)),
              ],
            ),
          );
        }
        
        // Initialize controllers only once
        if (!_profileInitialized) {
          _displayNameController.text = profile.displayName;
          _headlineController.text = profile.headline ?? '';
          _bioController.text = profile.bio ?? '';
          _selectedVibes = Set.from(profile.lookingFor);
          _selectedInterests = Set.from(profile.interestTags);
          _profileInitialized = true;
        }
        
        return _buildBuildProfileContent(profile);
      },
    );
  }
  
  Widget _buildBuildProfileContent(UserProfile profile) {
    // All vibe options
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
    
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Photo Gallery with Rankings
            _buildPhotoGallerySection(),
            
            const SizedBox(height: 24),
            
            // Display Name
            _buildEditableField(
              label: 'DISPLAY NAME',
              controller: _displayNameController,
              icon: Icons.person_outline,
            ),
            
            const SizedBox(height: 16),
            
            // Headline
            _buildEditableField(
              label: 'HEADLINE',
              controller: _headlineController,
              icon: Icons.short_text,
              hint: 'A catchy one-liner about you...',
            ),
            
            const SizedBox(height: 16),
            
            // Bio with AI generation
            _buildBioSection(),
            
            const SizedBox(height: 24),
            
            // CHECK ME - AI Suggestions
            _buildCheckMeSection(),
            
            const SizedBox(height: 24),
            
            // YOUR VIBE Section
            _buildEditableVibeSection(
              title: 'YOUR VIBE',
              subtitle: 'Tap to toggle • How would you describe your energy?',
              icon: Icons.mood,
              allOptions: allVibes,
              selectedOptions: _selectedVibes,
              onToggle: (label) {
                setState(() {
                  if (_selectedVibes.contains(label)) {
                    _selectedVibes.remove(label);
                  } else {
                    _selectedVibes.add(label);
                  }
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // YOUR INTERESTS Section
            _buildEditableVibeSection(
              title: 'YOUR INTERESTS',
              subtitle: 'Tap to toggle • What lights you up?',
              icon: Icons.favorite,
              allOptions: allInterests,
              selectedOptions: _selectedInterests,
              onToggle: (label) {
                setState(() {
                  if (_selectedInterests.contains(label)) {
                    _selectedInterests.remove(label);
                  } else {
                    _selectedInterests.add(label);
                  }
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Editable Profile Fields
            _buildTappableProfileField('Location', profile.displayLocation.isNotEmpty ? profile.displayLocation : 'Tap to set', Icons.location_on_outlined),
            _buildTappableProfileField('Pronouns', profile.pronouns ?? 'Tap to set', Icons.person_pin_outlined),
            _buildTappableProfileField('Gender', profile.gender.isNotEmpty ? profile.gender.join(', ') : 'Tap to set', Icons.face_outlined),
            _buildTappableProfileField('Orientation', profile.orientation.isNotEmpty ? profile.orientation.join(', ') : 'Tap to set', Icons.favorite_border),
            _buildTappableProfileField('Relationship Status', profile.relationshipStatus.isNotEmpty ? profile.relationshipStatus.join(', ') : 'Tap to set', Icons.people_outline),
            _buildTappableProfileField('Seeking', profile.seeking.isNotEmpty ? profile.seeking.join(', ') : 'Tap to set', Icons.search),
            _buildTappableProfileField('Kinks & Interests', profile.kinks.isNotEmpty ? profile.kinks.join(', ') : 'Tap to set', Icons.whatshot_outlined),
            _buildTappableProfileField('Boundaries', profile.boundaries.isNotEmpty ? profile.boundaries.join(', ') : 'Tap to set', Icons.shield_outlined),
            _buildTappableProfileField('Love Languages', profile.loveLanguages.isNotEmpty ? profile.loveLanguages.join(', ') : 'Tap to set', Icons.language),
            _buildTappableProfileField('Availability', profile.availabilityGeneral.isNotEmpty ? profile.availabilityGeneral.join(', ') : 'Tap to set', Icons.schedule_outlined),
            _buildTappableProfileField('Hosting Status', profile.hostingStatus ?? 'Tap to set', Icons.home_outlined),
            _buildTappableProfileField('Discretion Level', profile.discretionLevel ?? 'Tap to set', Icons.visibility_outlined),
            
            const SizedBox(height: 32),
          ],
        ),
        
        // Floating SAVE button
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: ElevatedButton(
            onPressed: _isSaving ? null : () => _saveProfile(profile),
            style: ElevatedButton.styleFrom(
              backgroundColor: VesparaColors.glow,
              foregroundColor: VesparaColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 20),
                      const SizedBox(width: 8),
                      Text('SAVE PROFILE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: VesparaColors.glow, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VesparaColors.secondary, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: VesparaColors.primary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
            filled: true,
            fillColor: VesparaColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: VesparaColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: VesparaColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: VesparaColors.glow),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.article_outlined, color: VesparaColors.glow, size: 16),
                const SizedBox(width: 8),
                Text('BIO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VesparaColors.secondary, letterSpacing: 1)),
              ],
            ),
            GestureDetector(
              onTap: _isGeneratingBio ? null : _generateAiBio,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [VesparaColors.glow, VesparaColors.secondary]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isGeneratingBio)
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: VesparaColors.background, strokeWidth: 2))
                    else
                      Icon(Icons.auto_awesome, size: 14, color: VesparaColors.background),
                    const SizedBox(width: 6),
                    Text('AI GENERATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: VesparaColors.background)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          maxLines: 4,
          style: TextStyle(color: VesparaColors.primary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tell people about yourself...',
            hintStyle: TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
            filled: true,
            fillColor: VesparaColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: VesparaColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: VesparaColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: VesparaColors.glow),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCheckMeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [VesparaColors.glow.withOpacity(0.15), VesparaColors.surface],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
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
                  Text('CHECK ME', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: VesparaColors.primary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('AI POWERED', style: TextStyle(fontSize: 10, color: VesparaColors.glow, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your selections, you might also enjoy:',
            style: TextStyle(fontSize: 12, color: VesparaColors.secondary),
          ),
          const SizedBox(height: 12),
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
    );
  }
  
  Widget _buildEditableVibeSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Map<String, String>> allOptions,
    required Set<String> selectedOptions,
    required Function(String) onToggle,
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
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: VesparaColors.glow)),
              ],
            ),
            Text('${selectedOptions.length} selected', style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 11, color: VesparaColors.secondary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allOptions.map((option) {
            final isSelected = selectedOptions.contains(option['label']);
            return GestureDetector(
              onTap: () => onToggle(option['label']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? VesparaColors.glow.withOpacity(0.2) : VesparaColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? VesparaColors.glow : VesparaColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(option['emoji']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      option['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? VesparaColors.glow : VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildTappableProfileField(String title, String content, IconData icon) {
    return GestureDetector(
      onTap: () => _showFieldEditor(title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VesparaColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: VesparaColors.glow, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VesparaColors.secondary)),
                  const SizedBox(height: 2),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: content.contains('Tap to') ? VesparaColors.secondary.withOpacity(0.6) : VesparaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: VesparaColors.glow.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // PHOTO GALLERY SECTION
  // ════════════════════════════════════════════════════════════════════════════
  
  Widget _buildPhotoGallerySection() {
    final photosState = ref.watch(profilePhotosProvider);
    final photos = photosState.photos;
    final recommendation = photosState.recommendation;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'YOUR PHOTOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: VesparaColors.secondary,
                letterSpacing: 1,
              ),
            ),
            if (photosState.totalRankingsReceived > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 12, color: VesparaColors.glow),
                    const SizedBox(width: 4),
                    Text(
                      '${photosState.totalRankingsReceived} rankings',
                      style: TextStyle(fontSize: 11, color: VesparaColors.glow),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Vespara Recommendation Banner
        if (recommendation != null && recommendation.confidence > 0.6)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [VesparaColors.glow.withOpacity(0.15), VesparaColors.surface],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: VesparaColors.glow, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vespara Recommends',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.glow,
                        ),
                      ),
                      Text(
                        recommendation.insights.isNotEmpty ? recommendation.insights.first : 'Reorder your photos based on community feedback',
                        style: TextStyle(fontSize: 11, color: VesparaColors.secondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _applyRecommendedOrder(),
                  child: Text('Apply', style: TextStyle(color: VesparaColors.glow, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        
        // Photo Grid - Ranked Left to Right
        SizedBox(
          height: 140,
          child: photos.isEmpty
              ? _buildEmptyPhotoGrid()
              : ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length + (5 - photos.length), // Fill remaining slots
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                  onReorder: (oldIndex, newIndex) async {
                    if (oldIndex < photos.length && newIndex <= photos.length) {
                      if (newIndex > oldIndex) newIndex--;
                      // Reorder using the photos list
                      final photoIds = photos.map((p) => p.id).toList();
                      final movedId = photoIds.removeAt(oldIndex);
                      photoIds.insert(newIndex, movedId);
                      await ref.read(profilePhotosProvider.notifier).reorderPhotos(photoIds);
                    }
                  },
                  itemBuilder: (context, index) {
                    if (index < photos.length) {
                      final photo = photos[index];
                      return _buildRankedPhotoSlot(
                        key: ValueKey(photo.id),
                        photo: photo,
                        position: index + 1,
                        isFirst: index == 0,
                      );
                    } else {
                      return _buildEmptyPhotoSlot(
                        key: ValueKey('empty_$index'),
                        position: index + 1,
                      );
                    }
                  },
                ),
        ),
        
        const SizedBox(height: 8),
        
        // Helper text
        Text(
          'Drag to reorder • First photo is your main profile photo',
          style: TextStyle(fontSize: 11, color: VesparaColors.secondary, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildEmptyPhotoGrid() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) => _buildEmptyPhotoSlot(
        key: ValueKey('empty_$index'),
        position: index + 1,
      ),
    );
  }
  
  Widget _buildRankedPhotoSlot({
    required Key key,
    required ProfilePhoto photo,
    required int position,
    bool isFirst = false,
  }) {
    final score = photo.score;
    
    return Container(
      key: key,
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFirst ? VesparaColors.glow : VesparaColors.border,
          width: isFirst ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              photo.photoUrl,
              width: 100,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: VesparaColors.surface,
                child: Icon(Icons.broken_image, color: VesparaColors.secondary),
              ),
            ),
          ),
          
          // Position badge
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isFirst ? VesparaColors.glow : VesparaColors.background.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isFirst ? VesparaColors.background : VesparaColors.primary,
                  ),
                ),
              ),
            ),
          ),
          
          // Score indicator
          if (score != null && score.totalRankings > 0)
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: VesparaColors.background.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      score.averageRank <= 2 ? Icons.thumb_up : Icons.trending_flat,
                      size: 10,
                      color: score.averageRank <= 2 ? VesparaColors.success : VesparaColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '#${score.averageRank.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Primary badge
          if (isFirst)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: VesparaColors.glow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MAIN',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: VesparaColors.background,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyPhotoSlot({required Key key, required int position}) {
    return GestureDetector(
      onTap: () => _uploadPhoto(position),
      child: Container(
        key: key,
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VesparaColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: VesparaColors.glow, size: 28),
            const SizedBox(height: 6),
            Text(
              'Add Photo',
              style: TextStyle(fontSize: 10, color: VesparaColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _uploadPhoto(int position) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200);
    
    if (image == null) return;
    
    final bytes = await image.readAsBytes();
    await ref.read(profilePhotosProvider.notifier).uploadPhoto(bytes, position);
  }
  
  void _applyRecommendedOrder() async {
    await ref.read(profilePhotosProvider.notifier).applyAIRecommendation();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo order updated!'), backgroundColor: VesparaColors.success),
      );
    }
  }
  
  void _showPhotoOptions() {
    // Photo management is handled inline - no modal needed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tap on a photo slot to upload or replace'), backgroundColor: VesparaColors.glow),
    );
  }
  
  void _showFieldEditor(String fieldName) {
    // Navigate to full edit profile screen
    final profileAsync = ref.read(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    if (profile == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profile: profile),
      ),
    ).then((updated) {
      if (updated == true) {
        ref.invalidate(userProfileProvider);
        _profileInitialized = false; // Force reinit on return
      }
    });
  }
  
  Future<void> _generateAiBio() async {
    setState(() => _isGeneratingBio = true);
    
    // Simulate AI generation
    await Future.delayed(const Duration(seconds: 2));
    
    final generatedBio = _selectedVibes.isNotEmpty || _selectedInterests.isNotEmpty
        ? "A ${_selectedVibes.take(2).join(' & ').toLowerCase()} soul who loves ${_selectedInterests.take(3).join(', ').toLowerCase()}. Looking for genuine connections and memorable experiences."
        : "Living life authentically and seeking genuine connections. Open to exploring new experiences with the right people.";
    
    setState(() {
      _bioController.text = generatedBio;
      _isGeneratingBio = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bio generated! Feel free to edit it.'), backgroundColor: VesparaColors.success),
    );
  }
  
  Future<void> _saveProfile(UserProfile profile) async {
    setState(() => _isSaving = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      // Build update map from form fields
      final updates = {
        'display_name': _displayNameController.text.trim(),
        'headline': _headlineController.text.trim(),
        'bio': _bioController.text.trim(),
        'looking_for': _selectedVibes.toList(),
        'interest_tags': _selectedInterests.toList(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved successfully!'), backgroundColor: VesparaColors.success),
      );
      
      ref.invalidate(userProfileProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: VesparaColors.error),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Keep the old method for backwards compatibility but it's no longer used
  Widget _buildProfileTab() {
    return _buildBuildProfileTab();
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
        
        // PHOTOS SECTION - NEW
        _buildPhotosSection(),
        
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
  
  // AI Discovery state
  bool _aiDiscoveryEnabled = true;
  double _aiConfidenceThreshold = 0.7;

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Vespara-Powered Discovery Section
        _buildAIDiscoverySection(),
        const SizedBox(height: 24),
        
        // Manual Discovery Overrides
        _buildSettingsSection('Manual Overrides', [
          _buildSettingTile('Age Range', '${_ageRange.start.toInt()}-${_ageRange.end.toInt()}', Icons.cake_outlined, () => _showAgeRangeDialog()),
          _buildSettingTile('Distance', 'Within ${_maxDistance.toInt()} miles', Icons.location_on_outlined, () => _showDistanceDialog()),
          _buildSettingTile('Show Me', _showMe, Icons.people_outline, () => _showGenderPreferenceDialog()),
        ]),
        const SizedBox(height: 24),
        
        // Notifications - Expanded
        _buildSettingsSection('Notifications', [
          _buildSettingToggle('New Matches'),
          _buildSettingToggle('Messages'),
          _buildSettingToggle('Date Reminders'),
          _buildSettingToggle('AI Insights'),
          _buildSettingToggle('Event Invitations'),
          _buildSettingToggle('Group Activity'),
          _buildSettingToggle('Game Requests'),
          _buildSettingToggle('Weekly Digest'),
          _buildSettingTile('Quiet Hours', '11pm - 7am', Icons.bedtime_outlined, () => _showQuietHoursDialog()),
        ]),
        const SizedBox(height: 24),
        
        // Privacy & Permissions
        _buildSettingsSection('Privacy & Permissions', [
          _buildSettingToggle('Show Online Status'),
          _buildSettingToggle('Read Receipts'),
          _buildSettingToggle('Profile Visible'),
          _buildSettingToggle('Show Last Active'),
          _buildSettingToggle('Allow Screenshotting'),
          _buildSettingToggle('Incognito Browsing'),
          _buildSettingTile('Blocked Users', '0 blocked', Icons.block_outlined, () => _showBlockedUsersDialog()),
          _buildSettingTile('Hidden Profiles', '3 hidden', Icons.visibility_off_outlined, () => _showHiddenProfilesDialog()),
          _buildSettingTile('Data Privacy', 'Manage', Icons.security_outlined, () => _showDataPrivacyDialog()),
        ]),
        const SizedBox(height: 24),
        
        // Integrations
        _buildSettingsSection('Integrations', [
          _buildSettingTile('Google Calendar', 'Connected', Icons.calendar_today, () => _showCalendarSyncDialog('Google')),
          _buildSettingTile('Apple Calendar', 'Not Connected', Icons.event, () => _showCalendarSyncDialog('Apple')),
          _buildSettingTile('Spotify', 'Not Connected', Icons.music_note, () => _showIntegrationDialog('Spotify', 'Share your music taste on your profile')),
          _buildSettingTile('Instagram', 'Not Connected', Icons.camera_alt_outlined, () => _showIntegrationDialog('Instagram', 'Display your latest photos')),
          _buildSettingTile('Location Services', 'Enabled', Icons.location_on_outlined, () => _showLocationServicesDialog()),
          _buildSettingTile('Contacts', 'Not Synced', Icons.contacts_outlined, () => _showContactsSyncDialog()),
        ]),
        const SizedBox(height: 24),
        
        // Data & Storage
        _buildSettingsSection('Data & Storage', [
          _buildSettingTile('Auto-Download Media', 'WiFi Only', Icons.download_outlined, () => _showMediaDownloadDialog()),
          _buildSettingTile('Cache Size', '127 MB', Icons.storage_outlined, () => _showClearCacheDialog()),
          _buildSettingTile('Export My Data', 'Download all', Icons.cloud_download_outlined, () => _showExportDataDialog()),
        ]),
        const SizedBox(height: 24),
        
        // Account
        _buildSettingsSection('Account', [
          _buildSettingTile('Subscription', 'Vespara Plus', Icons.star, () => _showSubscriptionDialog()),
          _buildSettingTile('Email', ref.watch(userProfileProvider).valueOrNull?.email ?? 'Not set', Icons.email_outlined, () => _showEditEmailDialog()),
          _buildSettingTile('Phone', '+1 555-****', Icons.phone_outlined, () => _showEditPhoneDialog()),
          _buildSettingTile('Verification', 'Photo verified ✓', Icons.verified_outlined, () => _showVerificationDialog()),
        ]),
        const SizedBox(height: 24),
        
        // Support
        _buildSettingsSection('Support', [
          _buildSettingTile('Help Center', '', Icons.help_outline, () => _showHelpCenter()),
          _buildSettingTile('Report a Problem', '', Icons.bug_report_outlined, () => _showReportProblem()),
          _buildSettingTile('Community Guidelines', '', Icons.gavel_outlined, () => _showCommunityGuidelines()),
          _buildSettingTile('Terms of Service', '', Icons.description_outlined, () => _showTermsOfService()),
          _buildSettingTile('Privacy Policy', '', Icons.privacy_tip_outlined, () => _showPrivacyPolicy()),
        ]),
        const SizedBox(height: 24),
        
        _buildDangerZone(),
        
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Vespara v2.1.0 • Made with 💜',
            style: TextStyle(fontSize: 12, color: VesparaColors.secondary),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // AI DISCOVERY SECTION
  // ════════════════════════════════════════════════════════════════════════════
  
  Widget _buildAIDiscoverySection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [VesparaColors.glow.withOpacity(0.15), VesparaColors.surface],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VesparaColors.glow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.auto_awesome, color: VesparaColors.glow, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Discovery Engine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: VesparaColors.primary)),
                        Text('Learns from your activity', style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
                      ],
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _aiDiscoveryEnabled,
                  onChanged: (v) => setState(() => _aiDiscoveryEnabled = v),
                  activeColor: VesparaColors.glow,
                ),
              ],
            ),
          ),
          
          if (_aiDiscoveryEnabled) ...[
            Divider(color: VesparaColors.border, height: 1),
            
            // AI Confidence slider
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Match Confidence', style: TextStyle(fontSize: 13, color: VesparaColors.secondary)),
                      Text('${(_aiConfidenceThreshold * 100).toInt()}%+', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VesparaColors.glow)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: _aiConfidenceThreshold,
                      min: 0.3,
                      max: 0.95,
                      activeColor: VesparaColors.glow,
                      inactiveColor: VesparaColors.glow.withOpacity(0.2),
                      onChanged: (v) => setState(() => _aiConfidenceThreshold = v),
                    ),
                  ),
                  Text(
                    _aiConfidenceThreshold > 0.8 
                        ? 'Showing only highly compatible matches'
                        : _aiConfidenceThreshold > 0.6 
                            ? 'Balanced: quality matches with variety'
                            : 'Exploratory: casting a wider net',
                    style: TextStyle(fontSize: 11, color: VesparaColors.secondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            
            Divider(color: VesparaColors.border, height: 1),
            
            // AI-Suggested Preferences
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('AI-SUGGESTED PREFERENCES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VesparaColors.secondary, letterSpacing: 1)),
                      GestureDetector(
                        onTap: () => _refreshAISuggestions(),
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 14, color: VesparaColors.glow),
                            const SizedBox(width: 4),
                            Text('Refresh', style: TextStyle(fontSize: 11, color: VesparaColors.glow)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Vibe Matches
                  _buildAIPreferenceCategory('Vibes You Click With', [
                    'High Energy', 'Adventurous', 'Witty & Sarcastic', 'Mischievous',
                  ], Icons.mood),
                  const SizedBox(height: 12),
                  
                  // Relationship Styles
                  _buildAIPreferenceCategory('Relationship Styles', [
                    'ENM/Open', 'Poly-Curious', 'Casual Dating', 'FWB',
                  ], Icons.favorite_outline),
                  const SizedBox(height: 12),
                  
                  // Seeking Types
                  _buildAIPreferenceCategory('Looking For', [
                    'Ongoing Connections', 'Play Partners', 'Group Experiences', 'Events & Parties',
                  ], Icons.search),
                  const SizedBox(height: 12),
                  
                  // Experience Level
                  _buildAIPreferenceCategory('Experience Compatibility', [
                    'Experienced', 'Open to Teaching', 'Kink-Aware', 'Communication-First',
                  ], Icons.psychology),
                  const SizedBox(height: 12),
                  
                  // Heat Level
                  _buildAIPreferenceCategory('Heat Level Range', [
                    'Medium 🔥', 'Hot 🔥🔥', 'Nuclear 🔥🔥🔥',
                  ], Icons.whatshot),
                  const SizedBox(height: 12),
                  
                  // Availability
                  _buildAIPreferenceCategory('Schedule Compatibility', [
                    'Weekend Evenings', 'Spontaneous', 'Same-Day Plans OK',
                  ], Icons.schedule),
                  const SizedBox(height: 16),
                  
                  // Edit all button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditAIPreferences(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: VesparaColors.glow),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.edit, size: 18, color: VesparaColors.glow),
                      label: Text('Customize AI Preferences', style: TextStyle(color: VesparaColors.glow)),
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(color: VesparaColors.border, height: 1),
            
            // Learning Insights
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WHAT AI LEARNED ABOUT YOU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VesparaColors.secondary, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _buildLearningInsight('You tend to swipe right on profiles with detailed bios', Icons.article_outlined),
                  _buildLearningInsight('Weekend evening availability aligns with your matches', Icons.event_available),
                  _buildLearningInsight('ENM/poly profiles get 3x more engagement from you', Icons.favorite),
                  _buildLearningInsight('You prefer profiles with verified photos', Icons.verified),
                  _buildLearningInsight('Conversation starters with humor get longer replies', Icons.chat_bubble_outline),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAIPreferenceCategory(String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: VesparaColors.glow),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
            ),
            child: Text(item, style: TextStyle(fontSize: 12, color: VesparaColors.glow)),
          )).toList(),
        ),
      ],
    );
  }
  
  Widget _buildLearningInsight(String insight, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: VesparaColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(insight, style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
          ),
        ],
      ),
    );
  }
  
  void _refreshAISuggestions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Text('Analyzing your latest activity...'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: VesparaColors.glow,
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ AI preferences updated!'),
            backgroundColor: VesparaColors.success,
          ),
        );
      }
    });
  }
  
  void _showEditAIPreferences() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
                    ),
                    Text('Edit AI Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Preferences saved!'), backgroundColor: VesparaColors.success),
                        );
                      },
                      child: Text('Save', style: TextStyle(color: VesparaColors.glow, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Tap to add or remove preferences. Vespara will use these as starting points and learn from your activity.',
                        style: TextStyle(fontSize: 13, color: VesparaColors.secondary)),
                    const SizedBox(height: 24),
                    _buildEditablePreferenceSection('Vibes', _allVibeOptions),
                    _buildEditablePreferenceSection('Relationship Styles', _allRelationshipOptions),
                    _buildEditablePreferenceSection('Looking For', _allSeekingOptions),
                    _buildEditablePreferenceSection('Heat Levels', _allHeatOptions),
                    _buildEditablePreferenceSection('Experience', _allExperienceOptions),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Options for AI preferences
  static const List<String> _allVibeOptions = [
    'High Energy', 'Calm & Centered', 'Adventurous', 'Cozy Homebody',
    'Witty & Sarcastic', 'Hopeless Romantic', 'Mischievous', 'Intellectual',
    'Creative', 'Spontaneous', 'Deep Thinker', 'Free Spirit', 'Night Owl', 'Early Riser',
  ];
  
  static const List<String> _allRelationshipOptions = [
    'Single', 'ENM/Open', 'Poly', 'Monogamous', 'Casual Dating',
    'Relationship Anarchist', 'Exploring', 'Divorced', 'Situationship', 'Solo Poly',
  ];
  
  static const List<String> _allSeekingOptions = [
    'Friends', 'FWB', 'Ongoing Connections', 'Play Partners', 'Casual Dates',
    'Serious Relationship', 'Third/Unicorn', 'Couples', 'Group Experiences', 'Events & Parties',
  ];
  
  static const List<String> _allHeatOptions = [
    'Mild 🌸', 'Medium 🔥', 'Hot 🔥🔥', 'Nuclear 🔥🔥🔥',
  ];
  
  static const List<String> _allExperienceOptions = [
    'Beginner', 'Experienced', 'Open to Teaching', 'Learning',
    'Kink-Aware', 'Vanilla+', 'Communication-First',
  ];
  
  Widget _buildEditablePreferenceSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VesparaColors.secondary, letterSpacing: 1)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option.contains('High') || option.contains('ENM') || option.contains('Ongoing') || option.contains('Hot');
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) {},
              selectedColor: VesparaColors.glow.withOpacity(0.3),
              checkmarkColor: VesparaColors.glow,
              backgroundColor: VesparaColors.background,
              labelStyle: TextStyle(fontSize: 12, color: isSelected ? VesparaColors.glow : VesparaColors.secondary),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  
  // ════════════════════════════════════════════════════════════════════════════
  // NEW SETTINGS DIALOGS
  // ════════════════════════════════════════════════════════════════════════════
  
  void _showQuietHoursDialog() {
    TimeOfDay startTime = const TimeOfDay(hour: 23, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 7, minute: 0);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quiet Hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 8),
            Text('No notifications during these hours', style: TextStyle(color: VesparaColors.secondary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimePicker('Start', startTime, (t) => startTime = t),
                Icon(Icons.arrow_forward, color: VesparaColors.secondary),
                _buildTimePicker('End', endTime, (t) => endTime = t),
              ],
            ),
            const SizedBox(height: 24),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quiet hours updated')));
                },
                child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: time);
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: VesparaColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VesparaColors.border),
            ),
            child: Text(time.format(context), style: TextStyle(fontSize: 16, color: VesparaColors.primary)),
          ),
        ),
      ],
    );
  }
  
  void _showBlockedUsersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Blocked Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 24),
            Icon(Icons.block, size: 48, color: VesparaColors.secondary),
            const SizedBox(height: 16),
            Text('No blocked users', style: TextStyle(color: VesparaColors.secondary)),
            const SizedBox(height: 8),
            Text('When you block someone, they\'ll appear here.', style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  void _showHiddenProfilesDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hidden Profiles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 16),
            Text('3 profiles are hidden from your discovery feed', style: TextStyle(color: VesparaColors.secondary)),
            const SizedBox(height: 24),
            ListTile(
              leading: CircleAvatar(backgroundColor: VesparaColors.glow.withOpacity(0.3), child: Text('J')),
              title: Text('JakeFromState...', style: TextStyle(color: VesparaColors.primary)),
              trailing: TextButton(onPressed: () {}, child: Text('Unhide', style: TextStyle(color: VesparaColors.glow))),
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: VesparaColors.glow.withOpacity(0.3), child: Text('S')),
              title: Text('SarahAdven...', style: TextStyle(color: VesparaColors.primary)),
              trailing: TextButton(onPressed: () {}, child: Text('Unhide', style: TextStyle(color: VesparaColors.glow))),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  void _showDataPrivacyDialog() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Privacy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 24),
            _buildPrivacyOption('Share anonymous usage data', 'Help improve Vespara', true),
            _buildPrivacyOption('Personalized AI recommendations', 'Based on your activity', true),
            _buildPrivacyOption('Third-party analytics', 'Anonymized insights', false),
            _buildPrivacyOption('Marketing communications', 'Feature updates & tips', true),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showExportDataDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: VesparaColors.glow),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Export Data', style: TextStyle(color: VesparaColors.glow)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Request submitted. This may take 24-48 hours.'), backgroundColor: VesparaColors.warning),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: VesparaColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Delete All Data', style: TextStyle(color: VesparaColors.error)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrivacyOption(String title, String subtitle, bool value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(color: VesparaColors.primary, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
      trailing: Switch.adaptive(value: value, onChanged: (_) {}, activeColor: VesparaColors.glow),
    );
  }
  
  void _showIntegrationDialog(String service, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Connect $service', style: TextStyle(color: VesparaColors.primary)),
        content: Text(description, style: TextStyle(color: VesparaColors.secondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connecting to $service...'), backgroundColor: VesparaColors.glow));
            },
            child: Text('Connect', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }
  
  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Location Services', style: TextStyle(color: VesparaColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationOption('Always', 'Best for discovery accuracy', true),
            _buildLocationOption('While Using App', 'Standard mode', false),
            _buildLocationOption('Never', 'Location-based features disabled', false),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Done', style: TextStyle(color: VesparaColors.glow))),
        ],
      ),
    );
  }
  
  Widget _buildLocationOption(String title, String subtitle, bool selected) {
    return RadioListTile(
      title: Text(title, style: TextStyle(color: VesparaColors.primary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
      value: selected,
      groupValue: true,
      onChanged: (_) {},
      activeColor: VesparaColors.glow,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  void _showContactsSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sync Contacts', style: TextStyle(color: VesparaColors.primary)),
        content: Text('Sync your contacts to avoid matching with people you know. Contact info is never shared.', style: TextStyle(color: VesparaColors.secondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Not Now', style: TextStyle(color: VesparaColors.secondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contacts synced! 47 contacts hidden from discovery.')));
            },
            child: Text('Sync', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }
  
  void _showMediaDownloadDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Auto-Download Media', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 24),
            ...['WiFi Only', 'WiFi & Cellular', 'Never'].map((opt) => RadioListTile(
              title: Text(opt, style: TextStyle(color: VesparaColors.primary)),
              value: opt == 'WiFi Only',
              groupValue: true,
              onChanged: (_) {},
              activeColor: VesparaColors.glow,
            )),
          ],
        ),
      ),
    );
  }
  
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Cache', style: TextStyle(color: VesparaColors.primary)),
        content: Text('Clear 127 MB of cached data? This won\'t delete your account data.', style: TextStyle(color: VesparaColors.secondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cache cleared! Freed 127 MB'), backgroundColor: VesparaColors.success));
            },
            child: Text('Clear', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }
  
  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Export Your Data', style: TextStyle(color: VesparaColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Download a copy of all your Vespara data including:', style: TextStyle(color: VesparaColors.secondary)),
            const SizedBox(height: 12),
            _buildExportItem('Profile information'),
            _buildExportItem('Matches & conversations'),
            _buildExportItem('Activity history'),
            _buildExportItem('Uploaded photos'),
            const SizedBox(height: 12),
            Text('You\'ll receive an email with a download link within 24 hours.', style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export requested! Check your email.'), backgroundColor: VesparaColors.success));
            },
            child: Text('Request Export', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExportItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: VesparaColors.success),
          const SizedBox(width: 8),
          Text(item, style: TextStyle(fontSize: 13, color: VesparaColors.primary)),
        ],
      ),
    );
  }
  
  void _showVerificationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 48, color: VesparaColors.success),
            const SizedBox(height: 16),
            Text('You\'re Verified!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: VesparaColors.primary)),
            const SizedBox(height: 8),
            Text('Photo verified on Jan 15, 2026', style: TextStyle(color: VesparaColors.secondary)),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: VesparaColors.success),
                const SizedBox(width: 8),
                Text('Photo matches your profile', style: TextStyle(color: VesparaColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: VesparaColors.success),
                const SizedBox(width: 8),
                Text('Blue badge shown on profile', style: TextStyle(color: VesparaColors.primary)),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(side: BorderSide(color: VesparaColors.glow)),
              child: Text('Re-verify', style: TextStyle(color: VesparaColors.glow)),
            ),
          ],
        ),
      ),
    );
  }
  
  // Support dialogs
  void _showHelpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening Help Center...')));
  }
  
  void _showReportProblem() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening Report Form...')));
  }
  
  void _showCommunityGuidelines() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening Community Guidelines...')));
  }
  
  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening Terms of Service...')));
  }
  
  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening Privacy Policy...')));
  }

  void _showAgeRangeDialog() {
    RangeValues range = _ageRange;
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
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() => _ageRange = range);
                    await _saveSettings();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Age range saved: ${range.start.toInt()}-${range.end.toInt()}'), backgroundColor: VesparaColors.success),
                      );
                    }
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
    double distance = _maxDistance;
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
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() => _maxDistance = distance);
                    await _saveSettings();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Distance saved: ${distance.toInt()} miles'), backgroundColor: VesparaColors.success),
                      );
                    }
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
    String selected = _showMe;
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
                onChanged: (v) async {
                  setModalState(() => selected = v!);
                  Navigator.pop(context);
                  setState(() => _showMe = v!);
                  await _saveSettings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Preference saved: $v'), backgroundColor: VesparaColors.success),
                    );
                  }
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

  // ════════════════════════════════════════════════════════════════════════════
  // PHOTOS SECTION - Upload, view, and get AI recommendations
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildPhotosSection() {
    final photosState = ref.watch(profilePhotosProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library, color: VesparaColors.glow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'YOUR PHOTOS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.primary,
                    ),
                  ),
                ],
              ),
              Text(
                '${photosState.photos.length}/5',
                style: TextStyle(fontSize: 12, color: VesparaColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload up to 5 photos. Other users will rank them to help AI recommend your best profile picture.',
            style: TextStyle(fontSize: 12, color: VesparaColors.secondary),
          ),
          const SizedBox(height: 16),
          
          // Photo Grid (5 slots)
          _buildPhotoGrid(photosState),
          
          // AI Recommendation Card
          if (photosState.recommendation != null && photosState.photos.isNotEmpty)
            _buildAIRecommendationCard(photosState),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(ProfilePhotosState photosState) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        final position = index + 1;
        final photo = photosState.photoAtPosition(position);
        final isUploading = photosState.isUploading && photosState.uploadingPosition == position;
        
        return _buildPhotoSlot(position, photo, isUploading);
      },
    );
  }

  Widget _buildPhotoSlot(int position, ProfilePhoto? photo, bool isUploading) {
    if (isUploading) {
      return Container(
        decoration: BoxDecoration(
          color: VesparaColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.5)),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(VesparaColors.glow),
            ),
          ),
        ),
      );
    }
    
    if (photo != null) {
      return GestureDetector(
        onTap: () => _showProfilePhotoOptions(photo),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photo.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: VesparaColors.background,
                  child: Icon(Icons.broken_image, color: VesparaColors.secondary),
                ),
              ),
            ),
            // Primary badge
            if (photo.isPrimary)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: VesparaColors.glow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 12),
                ),
              ),
            // AI recommended badge
            if (photo.score?.aiRecommendedPosition == 1 && !photo.isPrimary)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                ),
              ),
            // Ranking count
            if (photo.score != null && photo.score!.totalRankings > 0)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${photo.score!.totalRankings}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    // Empty slot - add photo
    return GestureDetector(
      onTap: () => _pickAndUploadPhoto(position),
      child: Container(
        decoration: BoxDecoration(
          color: VesparaColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: VesparaColors.glow.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: VesparaColors.glow, size: 24),
            const SizedBox(height: 4),
            Text(
              '#$position',
              style: TextStyle(fontSize: 10, color: VesparaColors.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIRecommendationCard(ProfilePhotosState photosState) {
    final recommendation = photosState.recommendation!;
    final hasRec = recommendation.hasRecommendation;
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasRec 
              ? [Colors.amber.withOpacity(0.2), VesparaColors.surface]
              : [VesparaColors.glow.withOpacity(0.1), VesparaColors.surface],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasRec ? Colors.amber.withOpacity(0.3) : VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRec ? Icons.auto_awesome : Icons.insights,
                color: hasRec ? Colors.amber : VesparaColors.glow,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                hasRec ? 'AI RECOMMENDATION' : 'PHOTO INSIGHTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: hasRec ? Colors.amber : VesparaColors.glow,
                ),
              ),
              const Spacer(),
              if (hasRec)
                Text(
                  recommendation.confidenceLabel,
                  style: TextStyle(fontSize: 10, color: VesparaColors.secondary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Insights
          ...recommendation.insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(fontSize: 12, color: VesparaColors.secondary),
                  ),
                ),
              ],
            ),
          )),
          
          if (hasRec) ...[
            const SizedBox(height: 8),
            Text(
              'Based on ${recommendation.totalRankings} rankings from other users',
              style: TextStyle(fontSize: 10, color: VesparaColors.secondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _applyAIRecommendation(),
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('Apply AI Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(int position) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (picked == null) return;
    
    final bytes = await picked.readAsBytes();
    final extension = picked.path.split('.').last.toLowerCase();
    
    final success = await ref.read(profilePhotosProvider.notifier).uploadPhoto(
      bytes,
      position,
      extension: extension == 'png' ? 'png' : 'jpg',
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Photo uploaded!'),
          backgroundColor: VesparaColors.glow,
        ),
      );
    }
  }

  void _showProfilePhotoOptions(ProfilePhoto photo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VesparaColors.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Photo preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photo.photoUrl,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats
            if (photo.score != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VesparaColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${photo.score!.totalRankings}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: VesparaColors.primary,
                          ),
                        ),
                        Text('Rankings', style: TextStyle(fontSize: 10, color: VesparaColors.secondary)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          photo.score!.averageRank.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: VesparaColors.primary,
                          ),
                        ),
                        Text('Avg Rank', style: TextStyle(fontSize: 10, color: VesparaColors.secondary)),
                      ],
                    ),
                    if (photo.score!.aiRecommendedPosition != null)
                      Column(
                        children: [
                          Text(
                            '#${photo.score!.aiRecommendedPosition}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          Text('AI Rank', style: TextStyle(fontSize: 10, color: VesparaColors.secondary)),
                        ],
                      ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Actions
            if (!photo.isPrimary)
              ListTile(
                leading: Icon(Icons.star, color: VesparaColors.glow),
                title: const Text('Set as Primary'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(profilePhotosProvider.notifier).setAsPrimary(photo.id);
                },
              ),
            ListTile(
              leading: Icon(Icons.swap_horiz, color: VesparaColors.secondary),
              title: const Text('Replace Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(photo.position);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: VesparaColors.error),
              title: Text('Delete', style: TextStyle(color: VesparaColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePhoto(photo);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePhoto(ProfilePhoto photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Photo?', style: TextStyle(color: VesparaColors.primary)),
        content: Text(
          'This will delete the photo and all its rankings. This cannot be undone.',
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
              ref.read(profilePhotosProvider.notifier).deletePhoto(photo.id);
            },
            child: Text('Delete', style: TextStyle(color: VesparaColors.error)),
          ),
        ],
      ),
    );
  }

  void _applyAIRecommendation() async {
    final success = await ref.read(profilePhotosProvider.notifier).applyAIRecommendation();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI recommendation applied!'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }
}
