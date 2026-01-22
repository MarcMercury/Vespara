import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/providers/app_providers.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// EDIT PROFILE SCREEN (BUILD)
/// Complete profile editor matching ALL onboarding interview categories
/// Now includes the full intimate preferences from The Interview
/// ════════════════════════════════════════════════════════════════════════════

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile? profile;
  
  const EditProfileScreen({super.key, this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // Text controllers
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _hookController;
  late TextEditingController _headlineController;
  late TextEditingController _occupationController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  
  // Selected traits from THE INTERVIEW (stored in looking_for array)
  Set<String> _selectedTraits = {};
  
  // Identity
  String? _selectedPronouns;
  List<String> _selectedGender = [];
  List<String> _selectedOrientation = [];
  
  // Relationship
  List<String> _selectedRelationshipStatus = [];
  
  // Availability & Logistics
  String? _selectedHostingStatus;
  String? _selectedDiscretionLevel;
  int _travelRadius = 25;
  
  // THE INTERVIEW fields
  double _bandwidth = 0.5;
  
  bool _isSaving = false;
  bool _isLoaded = false;
  int _currentSection = 0; // For navigation between sections
  
  // ═══════════════════════════════════════════════════════════════════════════
  // THE INTERVIEW TRAIT CATEGORIES (EXACT MATCH WITH ONBOARDING)
  // ═══════════════════════════════════════════════════════════════════════════
  
  final Map<String, List<String>> _allTraits = {
    // PERSONALITY
    '⚡ Energy': [
      '🌙 Night Owl',
      '☀️ Early Riser', 
      '⚡ High Energy',
      '🧘 Calm & Centered',
      '🔋 Selectively Social',
    ],
    '🎭 Social Style': [
      '🎉 Life of the Party',
      '🏠 Cozy Homebody',
      '👥 Small Groups Only',
      '🎭 Social Chameleon',
      '🐺 Lone Wolf',
    ],
    '💫 Spirit': [
      '😂 Witty & Sarcastic',
      '💝 Hopeless Romantic',
      '🔥 Passionate',
      '😌 Easy Going',
      '🖤 Dark Humor',
      '😈 Mischievous',
    ],
    
    // DESIRES & CONNECTION
    '💕 Looking For': [
      '💕 Something Real',
      '🌶️ Spicy Adventures',
      '🤝 New Connections',
      '💫 Go With the Flow',
      '🔐 Discreet Encounters',
      '👫 Third for Couples',
      '💑 Couples Welcome',
      '🔄 Open to Anything',
    ],
    '💬 Connection Style': [
      '💬 Deep Conversations',
      '🎲 Spontaneous',
      '🔗 No Strings',
      '🎯 Direct & Honest',
      '🔥 Chemistry First',
      '💋 Flirty',
      '🌡️ Slow Tease',
    ],
    
    // INTIMATE PREFERENCES
    '🔥 In The Bedroom': [
      '👑 Dominant',
      '🦋 Submissive',
      '🔄 Switch',
      '🎭 Roleplay',
      '👀 Voyeur',
      '🎪 Exhibitionist',
      '💪 Rough',
      '🌸 Gentle & Sensual',
      '🎲 Spontaneous',
      '📝 Planned & Intentional',
    ],
    '🌶️ Turn Ons': [
      '💋 Kissing',
      '🗣️ Dirty Talk',
      '📱 Sexting',
      '📸 Pics & Vids',
      '👙 Lingerie',
      '🎭 Costumes',
      '🕯️ Wax Play',
      '❄️ Temperature Play',
      '👁️ Eye Contact',
      '🔊 Being Vocal',
      '🤫 Being Quiet',
      '💆 Massage',
    ],
    '⛓️ Kinks & Fetishes': [
      '⛓️ Bondage',
      '👋 Spanking',
      '🎀 BDSM Light',
      '⛓️ BDSM Heavy',
      '🦶 Feet',
      '🧥 Leather',
      '✨ Latex',
      '🎭 Power Exchange',
      '🚫 Denial & Edging',
      '💦 Praise Kink',
      '😈 Degradation',
      '🐾 Pet Play',
      '👔 Uniforms',
      '🪢 Rope/Shibari',
      '🍑 Anal',
      '👥 Group Play',
      '👀 Watching Others',
      '🎪 Being Watched',
    ],
    '🛏️ Experience Level': [
      '🌱 Curious Beginner',
      '📚 Still Learning',
      '✅ Experienced',
      '🎓 Very Experienced',
      '👨‍🏫 Happy to Teach',
      '📖 Eager to Learn',
    ],
    '💫 Situationships': [
      '🌙 One Night Stands',
      '🔄 FWB',
      '💕 Regular Thing',
      '🏠 Hosting',
      '🚗 Can Travel',
      '🏨 Hotels',
      '🌳 Outdoors',
      '⚡ Quickies',
      '🌅 All Night',
      '☀️ Daytime Fun',
    ],
    '👥 Group Dynamics': [
      '👤 1-on-1 Only',
      '👥 Threesomes',
      '👥 Moresomes',
      '🎉 Party Vibes',
      '👫 Couple Looking',
      '🦄 Unicorn',
      '🐂 Bull',
      '👀 Cuckold/Cuckquean',
      '💑 Hotwife/Stag',
      '🔄 Full Swap',
      '🙈 Soft Swap',
      '👁️ Watch Only',
    ],
    '🚫 Boundaries': [
      '📱 Verification Required',
      '🗓️ Meet First',
      '💬 Chat First',
      '📸 No Face Pics',
      '🔐 Very Discreet',
      '💍 Partner Knows',
      '🤫 Partner Doesn\'t Know',
      '🚭 Sober Only',
      '🥂 420 Friendly',
      '✨ DDF Required',
      '💊 On PrEP',
    ],
  };
  
  // Section navigation
  final List<String> _sectionNames = [
    'Basics',
    'Identity', 
    'The Interview',
    'Logistics',
  ];
  
  static const List<String> _pronounOptions = [
    'He/Him', 'She/Her', 'They/Them', 'He/They', 'She/They', 'Any pronouns', 'Ask me'
  ];
  
  static const List<String> _genderOptions = [
    'Man', 'Woman', 'Non-binary', 'Trans man', 'Trans woman', 'Genderqueer', 
    'Genderfluid', 'Agender', 'Two-spirit', 'Other'
  ];
  
  static const List<String> _orientationOptions = [
    'Straight', 'Gay', 'Lesbian', 'Bisexual', 'Pansexual', 'Queer', 
    'Asexual', 'Demisexual', 'Heteroflexible', 'Homoflexible', 'Questioning'
  ];
  
  static const List<String> _relationshipStatusOptions = [
    'Single', 'Partnered', 'Married', 'Open relationship', 'Polyamorous',
    'Divorced', 'Widowed', 'It\'s complicated'
  ];
  
  static const List<String> _hostingOptions = [
    'Can host', 'Can\'t host', 'Can travel', 'Can host sometimes', 'Prefer to travel'
  ];
  
  static const List<String> _discretionOptions = [
    'Very discreet', 'Somewhat discreet', 'Open', 'Doesn\'t matter'
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _hookController = TextEditingController();
    _headlineController = TextEditingController();
    _occupationController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipCodeController = TextEditingController();
    
    if (widget.profile != null) {
      _populateFromProfile(widget.profile!);
    }
  }

  void _populateFromProfile(UserProfile profile) {
    _displayNameController.text = profile.displayName;
    _bioController.text = profile.bio ?? '';
    _hookController.text = profile.hook ?? '';
    _headlineController.text = profile.headline ?? '';
    _occupationController.text = profile.occupation ?? '';
    _cityController.text = profile.city ?? '';
    _stateController.text = profile.state ?? '';
    _zipCodeController.text = profile.zipCode ?? '';
    
    _selectedPronouns = profile.pronouns;
    _selectedGender = List.from(profile.gender);
    _selectedOrientation = List.from(profile.orientation);
    _selectedRelationshipStatus = List.from(profile.relationshipStatus);
    _selectedHostingStatus = profile.hostingStatus;
    _selectedDiscretionLevel = profile.discretionLevel;
    _travelRadius = profile.travelRadius;
    _bandwidth = profile.bandwidth;
    
    // Load traits from looking_for array
    _selectedTraits = Set.from(profile.lookingFor);
    
    _isLoaded = true;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _hookController.dispose();
    _headlineController.dispose();
    _occupationController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }
      
      final updates = {
        // Basic Info
        'display_name': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'hook': _hookController.text.trim(),
        'headline': _headlineController.text.trim(),
        'occupation': _occupationController.text.trim(),
        
        // Location
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zip_code': _zipCodeController.text.trim(),
        
        // Identity
        'pronouns': _selectedPronouns,
        'gender': _selectedGender,
        'orientation': _selectedOrientation,
        
        // Relationship
        'relationship_status': _selectedRelationshipStatus,
        
        // THE INTERVIEW traits stored in looking_for
        'looking_for': _selectedTraits.toList(),
        
        // Logistics
        'hosting_status': _selectedHostingStatus,
        'discretion_level': _selectedDiscretionLevel,
        'travel_radius': _travelRadius,
        'bandwidth': _bandwidth,
        
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);
      
      ref.invalidate(userProfileProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: VesparaColors.success),
                const SizedBox(width: 12),
                Text('Profile updated!'),
              ],
            ),
            backgroundColor: VesparaColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: VesparaColors.error),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to save: $e')),
              ],
            ),
            backgroundColor: VesparaColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    
    return profileAsync.when(
      loading: () => Scaffold(
        backgroundColor: VesparaColors.background,
        body: Center(
          child: CircularProgressIndicator(color: VesparaColors.glow),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: VesparaColors.background,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: VesparaColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load profile', style: TextStyle(color: VesparaColors.secondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (profile) {
        if (!_isLoaded && profile != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateFromProfile(profile);
            setState(() {});
          });
        }
        
        return Scaffold(
          backgroundColor: VesparaColors.background,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildSectionNav(),
              Expanded(child: _buildCurrentSection()),
            ],
          ),
        );
      },
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: VesparaColors.background,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: VesparaColors.primary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        children: [
          Text(
            'BUILD',
            style: TextStyle(
              color: VesparaColors.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          Text(
            'Edit Your Profile',
            style: TextStyle(
              fontSize: 12,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _saveProfile,
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VesparaColors.glow,
                  ),
                )
              : Text(
                  'Save',
                  style: TextStyle(
                    color: VesparaColors.glow,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildSectionNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        border: Border(bottom: BorderSide(color: VesparaColors.glow.withOpacity(0.1))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_sectionNames.length, (index) {
            final isSelected = _currentSection == index;
            return GestureDetector(
              onTap: () => setState(() => _currentSection = index),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? VesparaColors.glow : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? VesparaColors.glow : VesparaColors.glow.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _sectionNames[index],
                  style: TextStyle(
                    color: isSelected ? VesparaColors.background : VesparaColors.primary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
  
  Widget _buildCurrentSection() {
    switch (_currentSection) {
      case 0:
        return _buildBasicsSection();
      case 1:
        return _buildIdentitySection();
      case 2:
        return _buildInterviewSection();
      case 3:
        return _buildLogisticsSection();
      default:
        return _buildBasicsSection();
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1: BASICS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBasicsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Your Basics', Icons.person_outline),
          _buildTextField('Display Name', _displayNameController),
          _buildTextField('Hook', _hookController, hint: '140 char tagline that catches attention...', maxLength: 140),
          _buildTextField('Headline', _headlineController, hint: 'A catchy tagline...'),
          _buildTextField('Bio', _bioController, maxLines: 5, hint: 'Tell people about yourself, what you\'re into, what you\'re looking for...'),
          _buildTextField('Occupation', _occupationController, hint: 'What do you do?'),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Location', Icons.location_on_outlined),
          Row(
            children: [
              Expanded(flex: 2, child: _buildTextField('City', _cityController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('State', _stateController)),
            ],
          ),
          _buildTextField('ZIP Code', _zipCodeController),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2: IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildIdentitySection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Identity', Icons.face_outlined),
          _buildDropdown('Pronouns', _pronounOptions, _selectedPronouns, 
              (val) => setState(() => _selectedPronouns = val)),
          _buildMultiSelectBasic('Gender', _genderOptions, _selectedGender),
          _buildMultiSelectBasic('Orientation', _orientationOptions, _selectedOrientation),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Relationship', Icons.favorite_border),
          _buildMultiSelectBasic('Relationship Status', _relationshipStatusOptions, _selectedRelationshipStatus),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3: THE INTERVIEW (ALL TRAIT CATEGORIES)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInterviewSection() {
    final categories = _allTraits.keys.toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count
          Row(
            children: [
              Icon(Icons.auto_awesome, color: VesparaColors.glow, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Interview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: VesparaColors.glow,
                      ),
                    ),
                    Text(
                      '${_selectedTraits.length} traits selected',
                      style: TextStyle(
                        fontSize: 13,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select everything that applies to you. Be honest—better matches come from authentic profiles.',
            style: TextStyle(
              fontSize: 13,
              color: VesparaColors.secondary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          
          // All trait categories
          ...categories.map((category) => _buildTraitCategory(category)),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildTraitCategory(String category) {
    final traits = _allTraits[category] ?? [];
    final selectedInCategory = traits.where((t) => _selectedTraits.contains(t)).length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              if (selectedInCategory > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: VesparaColors.glow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$selectedInCategory',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.glow,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: traits.map((trait) {
              final isSelected = _selectedTraits.contains(trait);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTraits.remove(trait);
                    } else {
                      _selectedTraits.add(trait);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? VesparaColors.glow : VesparaColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? VesparaColors.glow : VesparaColors.glow.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: VesparaColors.glow.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ] : null,
                  ),
                  child: Text(
                    trait,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? VesparaColors.background : VesparaColors.primary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
  // SECTION 4: LOGISTICS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLogisticsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Logistics & Availability', Icons.schedule_outlined),
          
          _buildDropdown('Hosting Status', _hostingOptions, _selectedHostingStatus,
              (val) => setState(() => _selectedHostingStatus = val)),
          _buildDropdown('Discretion Level', _discretionOptions, _selectedDiscretionLevel,
              (val) => setState(() => _selectedDiscretionLevel = val)),
          
          // Travel Radius slider
          _buildSliderField(
            'Travel Radius',
            '$_travelRadius miles',
            _travelRadius.toDouble(),
            5,
            100,
            (val) => setState(() => _travelRadius = val.round()),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Current Bandwidth', Icons.speed_outlined),
          
          Text(
            'How much energy do you have for new connections right now?',
            style: TextStyle(
              fontSize: 13,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildBandwidthSlider(),
          
          const SizedBox(height: 40),
          
          // Save button at bottom
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.glow,
                foregroundColor: VesparaColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VesparaColors.background,
                      ),
                    )
                  : Text('Save All Changes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildBandwidthSlider() {
    final bandwidthLabels = ['Empty', 'Low', 'Medium', 'High', 'Full'];
    final bandwidthColors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.lightGreen,
      Colors.green,
    ];
    
    final index = (_bandwidth * 4).round().clamp(0, 4);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              bandwidthLabels[index],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: bandwidthColors[index],
              ),
            ),
            Text(
              '${(_bandwidth * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: bandwidthColors[index],
            inactiveTrackColor: VesparaColors.surface,
            thumbColor: bandwidthColors[index],
            overlayColor: bandwidthColors[index].withOpacity(0.2),
            trackHeight: 8,
          ),
          child: Slider(
            value: _bandwidth,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (val) => setState(() => _bandwidth = val),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🔋 Empty', style: TextStyle(fontSize: 11, color: VesparaColors.secondary)),
            Text('⚡ Full', style: TextStyle(fontSize: 11, color: VesparaColors.secondary)),
          ],
        ),
      ],
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: VesparaColors.glow, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: VesparaColors.glow,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? hint, int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            style: TextStyle(color: VesparaColors.primary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
              filled: true,
              fillColor: VesparaColors.surface,
              counterStyle: TextStyle(color: VesparaColors.secondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: VesparaColors.glow, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: options.map((o) => o.toLowerCase()).contains(value?.toLowerCase()) 
                    ? options.firstWhere((o) => o.toLowerCase() == value?.toLowerCase())
                    : null,
                isExpanded: true,
                dropdownColor: VesparaColors.surface,
                hint: Text('Select...', style: TextStyle(color: VesparaColors.secondary.withOpacity(0.5))),
                style: TextStyle(color: VesparaColors.primary),
                icon: Icon(Icons.keyboard_arrow_down, color: VesparaColors.secondary),
                items: options.map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMultiSelectBasic(String label, List<String> options, List<String> selected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                  fontWeight: FontWeight.w500,
                  color: VesparaColors.secondary,
                ),
              ),
              if (selected.isNotEmpty)
                Text(
                  '${selected.length} selected',
                  style: TextStyle(
                    fontSize: 11,
                    color: VesparaColors.glow,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = selected.contains(opt);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selected.remove(opt);
                    } else {
                      selected.add(opt);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? VesparaColors.glow : VesparaColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? VesparaColors.glow : VesparaColors.surface,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? VesparaColors.background : VesparaColors.primary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
  
  Widget _buildSliderField(String label, String displayValue, double value, double min, double max, Function(double) onChanged, {int? divisions}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                  fontWeight: FontWeight.w500,
                  color: VesparaColors.secondary,
                ),
              ),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.glow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: VesparaColors.glow,
              inactiveTrackColor: VesparaColors.surface,
              thumbColor: VesparaColors.glow,
              overlayColor: VesparaColors.glow.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
