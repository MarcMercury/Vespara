import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/models/user_profile.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// EDIT PROFILE SCREEN
/// Allows users to update their profile information
/// ════════════════════════════════════════════════════════════════════════════

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _headlineController;
  late TextEditingController _occupationController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _hookController;

  String? _selectedPronouns;
  List<String> _selectedGender = [];
  List<String> _selectedOrientation = [];
  List<String> _selectedRelationshipStatus = [];
  List<String> _selectedSeeking = [];
  List<String> _selectedLookingFor = [];
  List<String> _selectedAvailability = [];
  String? _selectedHostingStatus;
  String? _selectedDiscretionLevel;
  String? _selectedSchedulingStyle;
  String? _selectedPartnerInvolvement;
  String? _selectedHeatLevel;
  List<String> _selectedHardLimits = [];
  double _bandwidth = 0.5;
  int _travelRadius = 25;
  List<String> _selectedPartyAvailability = [];

  bool _isSaving = false;

  // Options - Using IDs that match onboarding for database consistency
  static const List<String> _pronounOptions = [
    'he/him',
    'she/her',
    'they/them',
    'he/they',
    'she/they',
    'any',
    'ask',
  ];

  static const Map<String, String> _pronounLabels = {
    'he/him': 'He/Him',
    'she/her': 'She/Her',
    'they/them': 'They/Them',
    'he/they': 'He/They',
    'she/they': 'She/They',
    'any': 'Any Pronouns',
    'ask': 'Ask Me',
  };

  static const List<String> _genderOptions = [
    'man',
    'woman',
    'non_binary',
    'trans_man',
    'trans_woman',
    'genderqueer',
    'genderfluid',
    'agender',
    'two_spirit',
    'other',
  ];

  static const Map<String, String> _genderLabels = {
    'man': 'Man',
    'woman': 'Woman',
    'non_binary': 'Non-Binary',
    'trans_man': 'Trans Man',
    'trans_woman': 'Trans Woman',
    'genderqueer': 'Genderqueer',
    'genderfluid': 'Genderfluid',
    'agender': 'Agender',
    'two_spirit': 'Two-Spirit',
    'other': 'Other',
  };

  static const List<String> _orientationOptions = [
    'straight',
    'gay',
    'lesbian',
    'bisexual',
    'pansexual',
    'queer',
    'asexual',
    'demisexual',
    'heteroflexible',
    'homoflexible',
    'questioning',
  ];

  static const Map<String, String> _orientationLabels = {
    'straight': 'Straight',
    'gay': 'Gay',
    'lesbian': 'Lesbian',
    'bisexual': 'Bisexual',
    'pansexual': 'Pansexual',
    'queer': 'Queer',
    'asexual': 'Asexual',
    'demisexual': 'Demisexual',
    'heteroflexible': 'Heteroflexible',
    'homoflexible': 'Homoflexible',
    'questioning': 'Questioning',
  };

  static const List<String> _relationshipStatusOptions = [
    'single',
    'dating',
    'partnered',
    'partnered_open',
    'married',
    'married_open',
    'divorced',
    'poly_solo',
    'poly_nested',
    'poly_network',
    'situationship',
    'exploring',
    'relationship_anarchist',
  ];

  static const Map<String, String> _relationshipStatusLabels = {
    'single': 'Single',
    'dating': 'Dating',
    'partnered': 'Partnered',
    'partnered_open': 'Open Relationship',
    'married': 'Married',
    'married_open': 'Married (Open)',
    'divorced': 'Divorced',
    'poly_solo': 'Solo Poly',
    'poly_nested': 'Nested Poly',
    'poly_network': 'Polycule',
    'situationship': 'Situationship',
    'exploring': 'Exploring',
    'relationship_anarchist': 'Relationship Anarchist',
  };

  static const List<String> _seekingOptions = [
    'friends',
    'dates',
    'fwb',
    'ongoing',
    'relationship',
    'play_partners',
    'third',
    'couple',
    'group',
    'events',
    'exploring',
  ];

  static const Map<String, String> _seekingLabels = {
    'friends': 'Friends',
    'dates': 'Casual Dates',
    'fwb': 'FWB',
    'ongoing': 'Ongoing Connection',
    'relationship': 'Relationship',
    'play_partners': 'Play Partners',
    'third': 'Third',
    'couple': 'Couples',
    'group': 'Group Experiences',
    'events': 'Events & Parties',
    'exploring': 'Just Exploring',
  };

  static const List<String> _lookingForOptions = [
    'Adventurous',
    'Caring',
    'Communicative',
    'Confident',
    'Creative',
    'Dominant',
    'Submissive',
    'Switch',
    'Experienced',
    'Open-minded',
    'Playful',
    'Romantic',
    'Spontaneous',
  ];

  static const List<String> _availabilityOptions = [
    'weekday_days',
    'weekday_evenings',
    'weekday_nights',
    'weekend_days',
    'weekend_evenings',
    'weekend_nights',
    'spontaneous',
    'planned_only',
  ];

  static const Map<String, String> _availabilityLabels = {
    'weekday_days': 'Weekday Days',
    'weekday_evenings': 'Weekday Evenings',
    'weekday_nights': 'Weekday Late Nights',
    'weekend_days': 'Weekend Days',
    'weekend_evenings': 'Weekend Evenings',
    'weekend_nights': 'Weekend Late Nights',
    'spontaneous': 'Spontaneous',
    'planned_only': 'Planned Only',
  };

  static const List<String> _hostingOptions = [
    'can_host',
    'sometimes_host',
    'cannot_host',
    'prefer_not',
    'hotel',
    'adventurous',
  ];

  static const Map<String, String> _hostingLabels = {
    'can_host': 'Can Host',
    'sometimes_host': 'Sometimes',
    'cannot_host': 'Cannot Host',
    'prefer_not': 'Prefer Not',
    'hotel': 'Hotel Only',
    'adventurous': 'Adventurous',
  };

  static const List<String> _discretionOptions = [
    'very_discreet',
    'discreet',
    'casual',
    'open',
  ];

  static const Map<String, String> _discretionLabels = {
    'very_discreet': 'Very Discreet',
    'discreet': 'Discreet',
    'casual': 'Casual',
    'open': 'Open',
  };

  static const List<String> _schedulingOptions = [
    'same_day',
    'day_ahead',
    'week_ahead',
    'flexible',
  ];

  static const Map<String, String> _schedulingLabels = {
    'same_day': 'Same Day OK',
    'day_ahead': 'Day Ahead',
    'week_ahead': 'Week Ahead',
    'flexible': 'Flexible',
  };

  static const List<String> _partnerInvolvementOptions = [
    'na',
    'solo_only',
    'sometimes',
    'always_together',
    'parallel',
    'soft_swap',
    'full_swap',
    'watch',
  ];

  static const Map<String, String> _partnerInvolvementLabels = {
    'na': 'N/A - I\'m Solo',
    'solo_only': 'Solo Only',
    'sometimes': 'Sometimes Together',
    'always_together': 'Always Together',
    'parallel': 'Parallel Play',
    'soft_swap': 'Soft Swap',
    'full_swap': 'Full Swap',
    'watch': 'Partner Watches',
  };

  static const List<String> _heatLevelOptions = [
    'mild',
    'medium',
    'hot',
    'nuclear',
  ];

  static const Map<String, String> _heatLevelLabels = {
    'mild': '🌸 Mild - Romance first',
    'medium': '🔥 Medium - Balanced heat',
    'hot': '🌶️ Hot - Bring the spice',
    'nuclear': '☢️ Nuclear - Anything goes',
  };

  static const List<String> _hardLimitOptions = [
    'no_smokers',
    'no_drugs',
    'no_pain',
    'no_blood',
    'no_humiliation',
    'no_anal',
    'no_choking',
    'protection_required',
    'no_bareback',
    'no_age_gaps',
    'no_couples',
    'no_singles',
    'no_public',
    'no_filming',
    'must_verify',
    'no_strangers',
    'sti_tested_only',
  ];

  static const List<String> _partyAvailabilityOptions = [
    'house_parties',
    'club_events',
    'private_events',
    'lifestyle_events',
    'not_interested',
  ];

  static const Map<String, String> _partyAvailabilityLabels = {
    'house_parties': 'House Parties',
    'club_events': 'Club Events',
    'private_events': 'Private Events',
    'lifestyle_events': 'Lifestyle Events',
    'not_interested': 'Not Interested in Events',
  };

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.profile.displayName);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _headlineController =
        TextEditingController(text: widget.profile.headline ?? '');
    _occupationController =
        TextEditingController(text: widget.profile.occupation ?? '');
    _cityController = TextEditingController(text: widget.profile.city ?? '');
    _stateController = TextEditingController(text: widget.profile.state ?? '');
    _zipCodeController =
        TextEditingController(text: widget.profile.zipCode ?? '');
    _hookController = TextEditingController(text: widget.profile.hook ?? '');

    _selectedPronouns = widget.profile.pronouns;
    _selectedGender = List.from(widget.profile.gender);
    _selectedOrientation = List.from(widget.profile.orientation);
    _selectedRelationshipStatus = List.from(widget.profile.relationshipStatus);
    _selectedSeeking = List.from(widget.profile.seeking);
    _selectedLookingFor = List.from(widget.profile.lookingFor);
    _selectedAvailability = List.from(widget.profile.availabilityGeneral);
    _selectedHostingStatus = widget.profile.hostingStatus;
    _selectedDiscretionLevel = widget.profile.discretionLevel;
    _selectedSchedulingStyle = widget.profile.schedulingStyle;
    _selectedPartnerInvolvement = widget.profile.partnerInvolvement;
    _selectedHeatLevel = widget.profile.heatLevel;
    _selectedHardLimits = List.from(widget.profile.hardLimits);
    _bandwidth = widget.profile.bandwidth;
    _travelRadius = widget.profile.travelRadius;
    _selectedPartyAvailability = List.from(widget.profile.partyAvailability);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _headlineController.dispose();
    _occupationController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _hookController.dispose();
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
        'display_name': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'headline': _headlineController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zip_code': _zipCodeController.text.trim(),
        'hook': _hookController.text.trim(),
        'pronouns': _selectedPronouns,
        'gender': _selectedGender,
        'orientation': _selectedOrientation,
        'relationship_status': _selectedRelationshipStatus,
        'seeking': _selectedSeeking,
        'looking_for': _selectedLookingFor,
        'availability_general': _selectedAvailability,
        'hosting_status': _selectedHostingStatus,
        'discretion_level': _selectedDiscretionLevel,
        'scheduling_style': _selectedSchedulingStyle,
        'partner_involvement': _selectedPartnerInvolvement,
        'heat_level': _selectedHeatLevel,
        'hard_limits': _selectedHardLimits,
        'bandwidth': _bandwidth,
        'travel_radius': _travelRadius,
        'party_availability': _selectedPartyAvailability,
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
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: VesparaColors.success),
                SizedBox(width: 12),
                Text('Profile updated!'),
              ],
            ),
            backgroundColor: VesparaColors.surface,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                const Icon(Icons.error_outline, color: VesparaColors.error),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to save: $e')),
              ],
            ),
            backgroundColor: VesparaColors.surface,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        appBar: AppBar(
          backgroundColor: VesparaColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: VesparaColors.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: VesparaColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VesparaColors.glow,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: VesparaColors.glow,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Section
              _buildSectionHeader('Basic Info'),
              _buildTextField('Display Name', _displayNameController),
              _buildTextField('Headline', _headlineController,
                  hint: 'A catchy tagline...',),
              _buildTextField('Bio', _bioController,
                  maxLines: 4, hint: 'Tell people about yourself...',),
              _buildTextField('Occupation', _occupationController),

              const SizedBox(height: 24),

              // Location Section
              _buildSectionHeader('Location'),
              Row(
                children: [
                  Expanded(
                      flex: 2, child: _buildTextField('City', _cityController),),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('State', _stateController)),
                ],
              ),
              _buildTextField('ZIP Code', _zipCodeController),

              const SizedBox(height: 24),

              // Identity Section
              _buildSectionHeader('Identity'),
              _buildDropdown(
                'Pronouns',
                _pronounOptions,
                _selectedPronouns,
                (val) => setState(() => _selectedPronouns = val),
                labels: _pronounLabels,
              ),
              _buildMultiSelect('Gender', _genderOptions, _selectedGender,
                  labels: _genderLabels,),
              _buildMultiSelect(
                  'Orientation', _orientationOptions, _selectedOrientation,
                  labels: _orientationLabels,),

              const SizedBox(height: 24),

              // Relationship Section
              _buildSectionHeader('Relationship'),
              _buildMultiSelect('Relationship Status',
                  _relationshipStatusOptions, _selectedRelationshipStatus,
                  labels: _relationshipStatusLabels,),
              _buildMultiSelect('Seeking', _seekingOptions, _selectedSeeking,
                  labels: _seekingLabels,),
              _buildMultiSelect('Looking For (Traits)', _lookingForOptions,
                  _selectedLookingFor,),
              _buildDropdown(
                'Partner Involvement',
                _partnerInvolvementOptions,
                _selectedPartnerInvolvement,
                (val) => setState(() => _selectedPartnerInvolvement = val),
                labels: _partnerInvolvementLabels,
              ),

              const SizedBox(height: 24),

              // Logistics Section
              _buildSectionHeader('Logistics'),
              _buildMultiSelect(
                  'Availability', _availabilityOptions, _selectedAvailability,
                  labels: _availabilityLabels,),
              _buildDropdown(
                'Scheduling Style',
                _schedulingOptions,
                _selectedSchedulingStyle,
                (val) => setState(() => _selectedSchedulingStyle = val),
                labels: _schedulingLabels,
              ),
              _buildDropdown(
                'Hosting Status',
                _hostingOptions,
                _selectedHostingStatus,
                (val) => setState(() => _selectedHostingStatus = val),
                labels: _hostingLabels,
              ),
              _buildDropdown(
                'Discretion Level',
                _discretionOptions,
                _selectedDiscretionLevel,
                (val) => setState(() => _selectedDiscretionLevel = val),
                labels: _discretionLabels,
              ),

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
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: VesparaColors.background,
                          ),
                        )
                      : const Text('Save Changes',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16,),),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      );

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: VesparaColors.glow,
          ),
        ),
      );

  Widget _buildTextField(String label, TextEditingController controller,
          {int maxLines = 1, String? hint,}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(color: VesparaColors.primary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
                filled: true,
                fillColor: VesparaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: VesparaColors.glow, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
      );

  Widget _buildDropdown(
    String label,
    List<String> options,
    String? value,
    Function(String?) onChanged, {
    Map<String, String>? labels,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
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
                  value: options.contains(value) ? value : null,
                  isExpanded: true,
                  dropdownColor: VesparaColors.surface,
                  hint: Text('Select...',
                      style: TextStyle(
                          color: VesparaColors.secondary.withOpacity(0.5),),),
                  style: const TextStyle(color: VesparaColors.primary),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: VesparaColors.secondary,),
                  items: options
                      .map(
                        (opt) => DropdownMenuItem(
                          value: opt,
                          child: Text(labels?[opt] ?? opt),
                        ),
                      )
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildMultiSelect(
    String label,
    List<String> options,
    List<String> selected, {
    Map<String, String>? labels,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: VesparaColors.secondary,
              ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VesparaColors.glow
                          : VesparaColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? VesparaColors.glow
                            : VesparaColors.surface,
                      ),
                    ),
                    child: Text(
                      labels?[opt] ?? opt,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? VesparaColors.background
                            : VesparaColors.primary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
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
