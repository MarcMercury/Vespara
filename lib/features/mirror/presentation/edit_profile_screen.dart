import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/providers/app_providers.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// EDIT PROFILE SCREEN (BUILD)
/// Complete profile editor matching all onboarding categories
/// Shows current saved values and allows updating
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
  
  // Identity
  String? _selectedPronouns;
  List<String> _selectedGender = [];
  List<String> _selectedOrientation = [];
  
  // Relationship
  List<String> _selectedRelationshipStatus = [];
  List<String> _selectedSeeking = [];
  List<String> _selectedLookingFor = [];
  String? _selectedPartnerInvolvement;
  
  // Availability & Logistics
  List<String> _selectedAvailability = [];
  String? _selectedHostingStatus;
  String? _selectedDiscretionLevel;
  String? _selectedSchedulingStyle;
  int _travelRadius = 25;
  List<String> _selectedPartyAvailability = [];
  
  // THE INTERVIEW fields
  String? _selectedHeatLevel;
  List<String> _selectedHardLimits = [];
  double _bandwidth = 0.5;
  
  // Vibe & Interests
  List<String> _selectedVibeTags = [];
  List<String> _selectedInterestTags = [];
  List<String> _selectedDesireTags = [];
  
  bool _isSaving = false;
  bool _isLoaded = false;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
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
  
  static const List<String> _seekingOptions = [
    'Friends', 'Dates', 'Casual', 'Relationship', 'Play partners',
    'Networking', 'Open to anything'
  ];
  
  static const List<String> _lookingForOptions = [
    'Adventurous', 'Caring', 'Communicative', 'Confident', 'Creative',
    'Dominant', 'Submissive', 'Switch', 'Experienced', 'Open-minded',
    'Playful', 'Romantic', 'Spontaneous'
  ];
  
  static const List<String> _availabilityOptions = [
    'Weekday mornings', 'Weekday afternoons', 'Weekday evenings',
    'Weekend mornings', 'Weekend afternoons', 'Weekend evenings', 'Late nights'
  ];
  
  static const List<String> _hostingOptions = [
    'Can host', 'Can\'t host', 'Can travel', 'Can host sometimes', 'Prefer to travel'
  ];
  
  static const List<String> _discretionOptions = [
    'Very discreet', 'Somewhat discreet', 'Open', 'Doesn\'t matter'
  ];
  
  static const List<String> _schedulingOptions = [
    'Spontaneous', 'Planner', 'Flexible', 'Last minute only'
  ];
  
  static const List<String> _partnerInvolvementOptions = [
    'Solo only', 'Partner sometimes joins', 'Partner always joins',
    'Looking for couples', 'Depends on the situation'
  ];
  
  static const List<String> _partyAvailabilityOptions = [
    'House parties', 'Club events', 'Private gatherings', 'Lifestyle events',
    'Meetups', 'Travel events', 'Not interested in parties'
  ];
  
  static const List<String> _heatLevelOptions = [
    'Mild', 'Medium', 'Hot', 'Nuclear'
  ];
  
  static const List<String> _hardLimitOptions = [
    'No photos', 'No public play', 'No group activities', 'No same room',
    'No drugs/alcohol', 'No overnight', 'No unprotected', 'Other (specify in bio)'
  ];
  
  static const List<String> _vibeTagOptions = [
    'Chill', 'Intense', 'Romantic', 'Playful', 'Adventurous', 'Intellectual',
    'Sensual', 'Kinky', 'Vanilla', 'Curious', 'Experienced', 'New to this'
  ];
  
  static const List<String> _interestTagOptions = [
    'Travel', 'Music', 'Art', 'Food & Wine', 'Fitness', 'Dancing',
    'Photography', 'Outdoors', 'Gaming', 'Reading', 'Movies', 'Concerts'
  ];
  
  static const List<String> _desireTagOptions = [
    'Connection', 'Intimacy', 'Exploration', 'Fantasy fulfillment', 'New experiences',
    'Regular partners', 'One-time encounters', 'Long-term dynamics'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty values - will be populated when profile loads
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _hookController = TextEditingController();
    _headlineController = TextEditingController();
    _occupationController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipCodeController = TextEditingController();
    
    // If a profile was passed in, use it initially
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
    _selectedSeeking = List.from(profile.seeking);
    _selectedLookingFor = List.from(profile.lookingFor);
    _selectedAvailability = List.from(profile.availabilityGeneral);
    _selectedHostingStatus = profile.hostingStatus;
    _selectedDiscretionLevel = profile.discretionLevel;
    _selectedSchedulingStyle = profile.schedulingStyle;
    _selectedPartnerInvolvement = profile.partnerInvolvement;
    _travelRadius = profile.travelRadius;
    _selectedPartyAvailability = List.from(profile.partyAvailability);
    _selectedHeatLevel = profile.heatLevel;
    _selectedHardLimits = List.from(profile.hardLimits);
    _bandwidth = profile.bandwidth;
    _selectedVibeTags = List.from(profile.vibeTags);
    _selectedInterestTags = List.from(profile.interestTags);
    _selectedDesireTags = List.from(profile.desireTags);
    
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
        'seeking': _selectedSeeking,
        'looking_for': _selectedLookingFor,
        'partner_involvement': _selectedPartnerInvolvement,
        
        // Availability & Logistics
        'availability_general': _selectedAvailability,
        'hosting_status': _selectedHostingStatus,
        'discretion_level': _selectedDiscretionLevel,
        'scheduling_style': _selectedSchedulingStyle,
        'travel_radius': _travelRadius,
        'party_availability': _selectedPartyAvailability,
        
        // THE INTERVIEW fields
        'heat_level': _selectedHeatLevel?.toLowerCase(),
        'hard_limits': _selectedHardLimits,
        'bandwidth': _bandwidth,
        
        // Vibe & Interests
        'vibe_tags': _selectedVibeTags,
        'interest_tags': _selectedInterestTags,
        'desire_tags': _selectedDesireTags,
        
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);
      
      // Invalidate the profile provider to refetch
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
        Navigator.of(context).pop(true); // Return true to indicate success
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
    // Watch the profile provider for fresh data
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
        // Populate form with fresh data if not already loaded
        if (!_isLoaded && profile != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateFromProfile(profile);
            setState(() {});
          });
        }
        
        return Scaffold(
          backgroundColor: VesparaColors.background,
          appBar: _buildAppBar(),
          body: _buildBody(),
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
            'Edit your profile',
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
  
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // BASIC INFO
          // ═══════════════════════════════════════════════════════════════════
          _buildSectionHeader('Basic Info', Icons.person_outline),
          _buildTextField('Display Name', _displayNameController),
          _buildTextField('Hook', _hookController, hint: '140 char tagline...', maxLength: 140),
          _buildTextField('Headline', _headlineController, hint: 'A catchy tagline...'),
          _buildTextField('Bio', _bioController, maxLines: 4, hint: 'Tell people about yourself...'),
          _buildTextField('Occupation', _occupationController),
          
          const SizedBox(height: 32),
          
          // ═══════════════════════════════════════════════════════════════════
          // LOCATION
          // ═══════════════════════════════════════════════════════════════════
          _buildSectionHeader('Location', Icons.location_on_outlined),
          Row(
            children: [
              Expanded(flex: 2, child: _buildTextField('City', _cityController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('State', _stateController)),
            ],
          ),
          _buildTextField('ZIP Code', _zipCodeController),
          
          const SizedBox(height: 32),
          
          // ═══════════════════════════════════════════════════════════════════
          // IDENTITY
          // ═══════════════════════════════════════════════════════════════════
          _buildSectionHeader('Identity', Icons.face_outlined),
          _buildDropdown('Pronouns', _pronounOptions, _selectedPronouns, 
              (val) => setState(() => _selectedPronouns = val)),
          _buildMultiSelect('Gender', _genderOptions, _selectedGender),
          _buildMultiSelect('Orientation', _orientationOptions, _selectedOrientation),
          
          const SizedBox(height: 32),
          
          // ═══════════════════════════════════════════════════════════════════
          // RELATIONSHIP
          // ═══════════════════════════════════════════════════════════════════
          _buildSectionHeader('Relationship', Icons.favorite_border),
          _buildMultiSelect('Relationship Status', _relationshipStatusOptions, _selectedRelationshipStatus),
          _buildMultiSelect('Seeking', _seekingOptions, _selectedSeeking),
          _buildMultiSelect('Looking For (Traits)', _lookingForOptions, _selectedLookingFor),
          _buildDropdown('Partner Involvement', _partnerInvolvementOptions, _selectedPartnerInvolvement,
              (val) => setState(() => _selectedPartnerInvolvement = val)),
          
          const SizedBox(height: 32),
          
          // ═══════════════════════════════════════════════════════════════════
          // AVAILABILITY & LOGISTICS
          // ═══════════════════════════════════════════════════════════════════
          _buildSectionHeader('Availability & Logistics', Icons.schedule_outlined),
          _buildMultiSelect('General Availability', _availabilityOptions, _selectedAvailability),
          _buildDropdown('Scheduling Style', _schedulingOptions, _selectedSchedulingStyle,
              (val) => setState(() => _selectedSchedulingStyle = val)),
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
          
          _buildMultiSelect('Party/Event Availability', _partyAvailabilityOptions, _selectedPartyAvailability),
          
          const SizedBox(height: 32),
          
          // ═══════════════════════════════════════════════════════════════════
          // THE INTERVIEW (Heat, Limits, Bandwidth)
          // ═══════════════════════════════════════════════════════════════════
          _buildSectionHeader('Intensity & Boundaries', Icons.whatshot_outlined),
          _buildDropdown('Heat Level', _heatLevelOptions, _selectedHeatLevel,
              (val) => setState(() => _selectedHeatLevel = val)),
          _buildMultiSelect('Hard Limits', _hardLimitOptions, _selectedHardLimits),
          
          // Bandwidth slider
          _buildSliderField(
            'Current Bandwidth',
            '${(_bandwidth * 100).toInt()}% available',
            _bandwidth,
            0,
            1,
            (val) => setState(() => _bandwidth = val),
            divisions: 10,
          ),
          
          const SizedBox(height: 32),
          
          // ═══════════════════════════════════════════════════════════════════
          // VIBE & INTERESTS
          // ═══════════════════════════════════════════════════════════════════
          _buildSectionHeader('Vibe & Interests', Icons.auto_awesome),
          _buildMultiSelect('Your Vibe', _vibeTagOptions, _selectedVibeTags),
          _buildMultiSelect('Interests', _interestTagOptions, _selectedInterestTags),
          _buildMultiSelect('Desires', _desireTagOptions, _selectedDesireTags),
          
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
                  : Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
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
  
  Widget _buildMultiSelect(String label, List<String> options, List<String> selected) {
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
