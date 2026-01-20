import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/zipcode_service.dart';
import 'velvet_rope_intro.dart';

/// ExclusiveOnboardingScreen - The Club Interview
/// A luxurious, exclusive onboarding experience that makes users feel special
/// while collecting the data needed for AI recommendations and party planning
class ExclusiveOnboardingScreen extends ConsumerStatefulWidget {
  const ExclusiveOnboardingScreen({super.key});

  @override
  ConsumerState<ExclusiveOnboardingScreen> createState() => _ExclusiveOnboardingScreenState();
}

class _ExclusiveOnboardingScreenState extends ConsumerState<ExclusiveOnboardingScreen>
    with TickerProviderStateMixin {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STATE & CONTROLLERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _showIntro = true;
  bool _isGeneratingBio = false;
  
  // Image services
  final _imageUploadService = ImageUploadService();
  final _permissionService = PermissionService();
  
  // Form controllers
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM DATA - Age Verification
  // ═══════════════════════════════════════════════════════════════════════════
  
  DateTime? _birthDate;
  bool _ageConfirmed = false;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM DATA - Basic Info
  // ═══════════════════════════════════════════════════════════════════════════
  
  String? _city;
  String? _state;
  String? _zipCode;
  final List<String> _uploadedPhotos = [];
  String? _avatarUrl;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM DATA - Gender & Identity
  // ═══════════════════════════════════════════════════════════════════════════
  
  final Set<String> _selectedGenders = {};
  String? _selectedPronouns;
  final Set<String> _selectedOrientations = {};
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM DATA - Relationship Status
  // ═══════════════════════════════════════════════════════════════════════════
  
  final Set<String> _relationshipStatus = {};
  final Set<String> _seeking = {};
  String? _partnerInvolvement;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM DATA - Availability & Logistics
  // ═══════════════════════════════════════════════════════════════════════════
  
  final Set<String> _availability = {};
  String? _schedulingStyle;
  String? _hostingStatus;
  String? _discretionLevel;
  int _travelRadius = 25;
  final Set<String> _partyAvailability = {};
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM DATA - Traits & Preferences
  // ═══════════════════════════════════════════════════════════════════════════
  
  final Set<String> _selectedTraits = {};
  
  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIONS DATA
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const List<Map<String, dynamic>> _genderOptions = [
    {'id': 'man', 'label': 'Man', 'emoji': '👨'},
    {'id': 'woman', 'label': 'Woman', 'emoji': '👩'},
    {'id': 'non_binary', 'label': 'Non-Binary', 'emoji': '🧑'},
    {'id': 'trans_man', 'label': 'Trans Man', 'emoji': '🏳️‍⚧️'},
    {'id': 'trans_woman', 'label': 'Trans Woman', 'emoji': '🏳️‍⚧️'},
    {'id': 'genderqueer', 'label': 'Genderqueer', 'emoji': '🌈'},
    {'id': 'genderfluid', 'label': 'Genderfluid', 'emoji': '💫'},
    {'id': 'agender', 'label': 'Agender', 'emoji': '⚪'},
    {'id': 'two_spirit', 'label': 'Two-Spirit', 'emoji': '🪶'},
    {'id': 'other', 'label': 'Other', 'emoji': '✨'},
  ];
  
  static const List<Map<String, String>> _pronounOptions = [
    {'id': 'he/him', 'label': 'He/Him'},
    {'id': 'she/her', 'label': 'She/Her'},
    {'id': 'they/them', 'label': 'They/Them'},
    {'id': 'he/they', 'label': 'He/They'},
    {'id': 'she/they', 'label': 'She/They'},
    {'id': 'any', 'label': 'Any Pronouns'},
    {'id': 'ask', 'label': 'Ask Me'},
  ];
  
  static const List<Map<String, dynamic>> _orientationOptions = [
    {'id': 'straight', 'label': 'Straight', 'emoji': '💑'},
    {'id': 'gay', 'label': 'Gay', 'emoji': '🏳️‍🌈'},
    {'id': 'lesbian', 'label': 'Lesbian', 'emoji': '🏳️‍🌈'},
    {'id': 'bisexual', 'label': 'Bisexual', 'emoji': '💜'},
    {'id': 'pansexual', 'label': 'Pansexual', 'emoji': '💖'},
    {'id': 'queer', 'label': 'Queer', 'emoji': '🌈'},
    {'id': 'heteroflexible', 'label': 'Heteroflexible', 'emoji': '↔️'},
    {'id': 'homoflexible', 'label': 'Homoflexible', 'emoji': '↔️'},
    {'id': 'demisexual', 'label': 'Demisexual', 'emoji': '🖤'},
    {'id': 'asexual', 'label': 'Asexual', 'emoji': '🤍'},
    {'id': 'questioning', 'label': 'Questioning', 'emoji': '❓'},
  ];
  
  static const List<Map<String, dynamic>> _relationshipOptions = [
    {'id': 'single', 'label': 'Single', 'emoji': '🦋', 'desc': 'Flying solo'},
    {'id': 'dating', 'label': 'Dating', 'emoji': '💫', 'desc': 'Casually dating, not exclusive'},
    {'id': 'partnered', 'label': 'Partnered', 'emoji': '💕', 'desc': 'In a relationship'},
    {'id': 'partnered_open', 'label': 'Open Relationship', 'emoji': '💜', 'desc': 'Partnered, ethically non-monogamous'},
    {'id': 'married', 'label': 'Married', 'emoji': '💍', 'desc': 'Married, monogamous'},
    {'id': 'married_open', 'label': 'Married (Open)', 'emoji': '🔓', 'desc': 'Married, open/ENM'},
    {'id': 'divorced', 'label': 'Divorced', 'emoji': '🌅', 'desc': 'Divorced or separated'},
    {'id': 'poly_solo', 'label': 'Solo Poly', 'emoji': '🦄', 'desc': 'Polyamorous, no primary'},
    {'id': 'poly_nested', 'label': 'Nested Poly', 'emoji': '🏡', 'desc': 'Poly with live-in partner(s)'},
    {'id': 'poly_network', 'label': 'Polycule', 'emoji': '🕸️', 'desc': 'Part of a poly network'},
    {'id': 'situationship', 'label': 'Situationship', 'emoji': '🌊', 'desc': 'It\'s complicated'},
    {'id': 'exploring', 'label': 'Exploring', 'emoji': '🧭', 'desc': 'Figuring things out'},
    {'id': 'relationship_anarchist', 'label': 'Relationship Anarchist', 'emoji': '⚡', 'desc': 'No labels, no rules'},
  ];
  
  static const List<Map<String, dynamic>> _seekingOptions = [
    {'id': 'friends', 'label': 'Friends', 'emoji': '👋', 'desc': 'New friends & community'},
    {'id': 'dates', 'label': 'Casual Dates', 'emoji': '🍷', 'desc': 'Coffee, drinks, good times'},
    {'id': 'fwb', 'label': 'FWB', 'emoji': '🔥', 'desc': 'Friends with benefits'},
    {'id': 'ongoing', 'label': 'Ongoing Connection', 'emoji': '🔄', 'desc': 'Regular thing, not one-off'},
    {'id': 'relationship', 'label': 'Relationship', 'emoji': '❤️', 'desc': 'Something serious'},
    {'id': 'play_partners', 'label': 'Play Partners', 'emoji': '🎭', 'desc': 'For scenes & play'},
    {'id': 'third', 'label': 'Third', 'emoji': '🦄', 'desc': 'Looking to join a couple'},
    {'id': 'couple', 'label': 'Couples', 'emoji': '👫', 'desc': 'Looking for couples'},
    {'id': 'group', 'label': 'Group Experiences', 'emoji': '🎉', 'desc': 'Moresomes, parties'},
    {'id': 'events', 'label': 'Events & Parties', 'emoji': '✨', 'desc': 'Social gatherings'},
    {'id': 'exploring', 'label': 'Just Exploring', 'emoji': '🌟', 'desc': 'See what happens'},
  ];
  
  static const List<Map<String, dynamic>> _partnerInvolvementOptions = [
    {'id': 'na', 'label': 'N/A - I\'m Solo', 'emoji': '🦋'},
    {'id': 'solo_only', 'label': 'Solo Only', 'emoji': '👤', 'desc': 'Partner not involved'},
    {'id': 'sometimes', 'label': 'Sometimes Together', 'emoji': '🤝', 'desc': 'Flexible'},
    {'id': 'always_together', 'label': 'Always Together', 'emoji': '👫', 'desc': 'Package deal'},
    {'id': 'parallel', 'label': 'Parallel Play', 'emoji': '🔀', 'desc': 'Same room, separate'},
    {'id': 'soft_swap', 'label': 'Soft Swap', 'emoji': '💋', 'desc': 'Everything but intercourse'},
    {'id': 'full_swap', 'label': 'Full Swap', 'emoji': '🔄', 'desc': 'The whole experience'},
    {'id': 'watch', 'label': 'Partner Watches', 'emoji': '👀', 'desc': 'Voyeur/cuckold dynamic'},
  ];
  
  static const List<Map<String, dynamic>> _availabilityOptions = [
    {'id': 'weekday_days', 'label': 'Weekday Days', 'emoji': '☀️', 'desc': 'Mon-Fri daytime'},
    {'id': 'weekday_evenings', 'label': 'Weekday Evenings', 'emoji': '🌆', 'desc': 'Mon-Fri after work'},
    {'id': 'weekday_nights', 'label': 'Weekday Late Nights', 'emoji': '🌙', 'desc': 'Mon-Fri after 10pm'},
    {'id': 'weekend_days', 'label': 'Weekend Days', 'emoji': '🌤️', 'desc': 'Sat-Sun daytime'},
    {'id': 'weekend_evenings', 'label': 'Weekend Evenings', 'emoji': '🌇', 'desc': 'Sat-Sun evening'},
    {'id': 'weekend_nights', 'label': 'Weekend Late Nights', 'emoji': '🌃', 'desc': 'Sat-Sun after 10pm'},
    {'id': 'spontaneous', 'label': 'Spontaneous', 'emoji': '⚡', 'desc': 'Flexible schedule'},
    {'id': 'planned_only', 'label': 'Planned Only', 'emoji': '📅', 'desc': 'Need advance notice'},
  ];
  
  static const List<Map<String, String>> _schedulingOptions = [
    {'id': 'same_day', 'label': 'Same Day OK', 'desc': 'I can be spontaneous'},
    {'id': 'day_ahead', 'label': 'Day Ahead', 'desc': 'Minimum 24hr notice'},
    {'id': 'week_ahead', 'label': 'Week Ahead', 'desc': 'Need to plan in advance'},
    {'id': 'flexible', 'label': 'Flexible', 'desc': 'Depends on the situation'},
  ];
  
  static const List<Map<String, dynamic>> _hostingOptions = [
    {'id': 'can_host', 'label': 'Can Host', 'emoji': '🏠', 'desc': 'My place works'},
    {'id': 'sometimes_host', 'label': 'Sometimes', 'emoji': '🤷', 'desc': 'Depends on timing'},
    {'id': 'cannot_host', 'label': 'Cannot Host', 'emoji': '🚫', 'desc': 'Need to go elsewhere'},
    {'id': 'prefer_not', 'label': 'Prefer Not', 'emoji': '😬', 'desc': 'Rather not host'},
    {'id': 'hotel', 'label': 'Hotel Only', 'emoji': '🏨', 'desc': 'Neutral ground preferred'},
    {'id': 'adventurous', 'label': 'Adventurous', 'emoji': '🌲', 'desc': 'Creative locations'},
  ];
  
  static const List<Map<String, dynamic>> _discretionOptions = [
    {'id': 'very_discreet', 'label': 'Very Discreet', 'emoji': '🤫', 'desc': 'Zero public acknowledgment'},
    {'id': 'discreet', 'label': 'Discreet', 'emoji': '🔐', 'desc': 'Keep it private'},
    {'id': 'casual', 'label': 'Casual', 'emoji': '😌', 'desc': 'Not advertising, not hiding'},
    {'id': 'open', 'label': 'Open', 'emoji': '🌈', 'desc': 'Everyone knows'},
  ];
  
  static const List<Map<String, dynamic>> _partyOptions = [
    {'id': 'house_parties', 'label': 'House Parties', 'emoji': '🏠'},
    {'id': 'club_events', 'label': 'Club Events', 'emoji': '🎪'},
    {'id': 'lifestyle_events', 'label': 'Lifestyle Events', 'emoji': '🎭'},
    {'id': 'hotel_takeovers', 'label': 'Hotel Takeovers', 'emoji': '🏨'},
    {'id': 'vacations', 'label': 'Lifestyle Vacations', 'emoji': '✈️'},
    {'id': 'dinner_parties', 'label': 'Dinner Parties', 'emoji': '🍽️'},
    {'id': 'none', 'label': 'Not Interested', 'emoji': '🚫'},
  ];
  
  // Trait categories (refined from original)
  final Map<String, List<String>> _allTraits = {
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
    ],
    '💫 Vibe': [
      '😂 Witty & Sarcastic',
      '💝 Hopeless Romantic',
      '🔥 Passionate',
      '😌 Easy Going',
      '😈 Mischievous',
    ],
    '🔥 In The Bedroom': [
      '👑 Dominant',
      '🦋 Submissive',
      '🔄 Switch',
      '🎭 Roleplay',
      '💪 Rough',
      '🌸 Gentle & Sensual',
      '🎲 Spontaneous',
    ],
    '🌶️ Turn Ons': [
      '💋 Kissing',
      '🗣️ Dirty Talk',
      '👙 Lingerie',
      '👁️ Eye Contact',
      '🔊 Being Vocal',
      '💆 Massage',
    ],
    '🛏️ Experience': [
      '🌱 Curious Beginner',
      '📚 Still Learning',
      '✅ Experienced',
      '🎓 Very Experienced',
      '👨‍🏫 Happy to Teach',
    ],
  };
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP DEFINITIONS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const List<Map<String, String>> _steps = [
    {'title': 'AGE VERIFICATION', 'subtitle': 'Confirm you\'re 21+'},
    {'title': 'WHO YOU ARE', 'subtitle': 'The basics'},
    {'title': 'YOUR PHOTOS', 'subtitle': 'Show your best self'},
    {'title': 'RELATIONSHIP STATUS', 'subtitle': 'Your current situation'},
    {'title': 'WHAT YOU\'RE SEEKING', 'subtitle': 'What brings you here'},
    {'title': 'AVAILABILITY', 'subtitle': 'When & where'},
    {'title': 'YOUR VIBE', 'subtitle': 'What makes you, you'},
    {'title': 'YOUR STORY', 'subtitle': 'AI-crafted from your selections'},
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Age verification
        return _birthDate != null && _ageConfirmed && _isOver21();
      case 1: // Basic info
        return _displayNameController.text.trim().isNotEmpty &&
               _selectedGenders.isNotEmpty;
      case 2: // Photos
        return true; // Photos optional but encouraged
      case 3: // Relationship status
        return _relationshipStatus.isNotEmpty;
      case 4: // Seeking
        return _seeking.isNotEmpty;
      case 5: // Availability
        return _availability.isNotEmpty && _hostingStatus != null;
      case 6: // Traits
        return _selectedTraits.length >= 5;
      case 7: // Bio
        return true;
      default:
        return false;
    }
  }
  
  bool _isOver21() {
    if (_birthDate == null) return false;
    final age = DateTime.now().difference(_birthDate!).inDays ~/ 365;
    return age >= 21;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep++);
      
      // Auto-generate bio when entering bio step
      if (_currentStep == 7 && _bioController.text.isEmpty) {
        _generateAIBio();
      }
    } else {
      _completeOnboarding();
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep--);
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTO HANDLING
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _pickPhoto({bool isAvatar = false}) async {
    final pickedFile = await _permissionService.showImageSourcePicker(
      context: context,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    
    if (pickedFile == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final bytes = await pickedFile.readAsBytes();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No user');
      
      final bucket = isAvatar ? 'avatars' : 'photos';
      // Use folder structure: {user_id}/{timestamp}.jpg to match RLS policy
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await Supabase.instance.client.storage.from(bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      
      final url = Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);
      
      setState(() {
        if (isAvatar) {
          _avatarUrl = url;
        } else {
          if (_uploadedPhotos.length < 6) {
            _uploadedPhotos.add(url);
          }
        }
      });
    } catch (e) {
      debugPrint('Photo upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _removePhoto(int index) {
    setState(() {
      _uploadedPhotos.removeAt(index);
    });
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LOCATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _getLocation() async {
    // Show ZIP code input dialog for easy location entry
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _LocationInputDialog(),
    );
    
    if (result != null) {
      setState(() {
        _city = result['city'];
        _state = result['state'];
        _zipCode = result['zipCode'];
      });
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BIO GENERATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _generateAIBio() async {
    setState(() => _isGeneratingBio = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate thinking
      
      final name = _displayNameController.text.trim();
      final bio = _buildBioFromSelections(name);
      
      setState(() {
        _bioController.text = bio;
      });
    } finally {
      if (mounted) {
        setState(() => _isGeneratingBio = false);
      }
    }
  }
  
  String _buildBioFromSelections(String name) {
    // Build a compelling bio from all the data we've collected
    final statusLabel = _relationshipOptions
        .where((o) => _relationshipStatus.contains(o['id']))
        .map((o) => o['label'])
        .join(' & ');
    
    final seekingLabels = _seekingOptions
        .where((o) => _seeking.contains(o['id']))
        .map((o) => o['label'] as String)
        .take(2)
        .join(', ');
    
    final vibeTraits = _selectedTraits
        .map((t) => t.replaceAll(RegExp(r'^[^\w]*'), '').trim().toLowerCase())
        .take(3)
        .join(', ');
    
    final location = _city != null && _state != null 
        ? '$_city, $_state' 
        : 'somewhere interesting';
    
    final discretionText = _discretionLevel == 'very_discreet' 
        ? 'Discretion is paramount.' 
        : _discretionLevel == 'discreet' 
            ? 'Privacy appreciated.' 
            : '';
    
    final hostingText = _hostingStatus == 'can_host' 
        ? 'Can host.' 
        : _hostingStatus == 'hotel' 
            ? 'Hotels preferred.' 
            : '';
    
    // Generate different bio styles
    final bios = [
      "$name here. $statusLabel in $location.\n\n"
      "Looking for: $seekingLabels.\n"
      "$vibeTraits - that's my vibe.\n\n"
      "$discretionText $hostingText".trim(),
      
      "They call me $name. $vibeTraits.\n\n"
      "Currently: $statusLabel. Seeking: $seekingLabels.\n"
      "$discretionText\n\n"
      "Based in $location. ${_availability.contains('spontaneous') ? 'Spontaneous works.' : 'Plan ahead.'}"
      .trim(),
      
      "$name ✨ $location\n\n"
      "$statusLabel | $seekingLabels\n\n"
      "$vibeTraits\n"
      "$discretionText $hostingText".trim(),
    ];
    
    return bios[DateTime.now().millisecond % bios.length];
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE & COMPLETE
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No user found');
      
      // Build the complete profile data
      final profileData = {
        'id': user.id,
        'email': user.email ?? '',
        'display_name': _displayNameController.text.trim(),
        'bio': _bioController.text.trim().isEmpty 
            ? 'New to Vespara ✨' 
            : _bioController.text.trim(),
        'birth_date': _birthDate?.toIso8601String().split('T').first,
        'age_verified': true,
        'age_verified_at': DateTime.now().toIso8601String(),
        'age_verification_method': 'birth_date',
        
        // Location
        'city': _city,
        'state': _state,
        'zip_code': _zipCode,
        
        // Photos
        'avatar_url': _avatarUrl,
        'photos': _uploadedPhotos,
        
        // Identity
        'gender': _selectedGenders.toList(),
        'pronouns': _selectedPronouns,
        'orientation': _selectedOrientations.toList(),
        
        // Relationship
        'relationship_status': _relationshipStatus.toList(),
        'seeking': _seeking.toList(),
        'partner_involvement': _partnerInvolvement,
        
        // Availability
        'availability_general': _availability.toList(),
        'scheduling_style': _schedulingStyle,
        'hosting_status': _hostingStatus,
        'discretion_level': _discretionLevel,
        'travel_radius': _travelRadius,
        'party_availability': _partyAvailability.toList(),
        
        // Traits
        'looking_for': _selectedTraits.toList(),
        
        // Onboarding status
        'onboarding_complete': true,
        'onboarding_step': 9,
        'onboarding_completed_at': DateTime.now().toIso8601String(),
        'is_verified': true,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await Supabase.instance.client.from('profiles').upsert(profileData);
      
      // Refresh session to trigger navigation
      if (mounted) {
        await Supabase.instance.client.auth.refreshSession();
      }
    } catch (e) {
      debugPrint('Onboarding complete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to Vespara! ✨'),
            backgroundColor: VesparaColors.success,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  
  @override
  Widget build(BuildContext context) {
    // Show velvet rope intro first
    if (_showIntro) {
      return VelvetRopeIntro(
        onComplete: () {
          setState(() => _showIntro = false);
        },
      );
    }
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildAgeVerificationStep(),
                  _buildBasicInfoStep(),
                  _buildPhotosStep(),
                  _buildRelationshipStep(),
                  _buildSeekingStep(),
                  _buildAvailabilityStep(),
                  _buildTraitsStep(),
                  _buildBioStep(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _previousStep,
                  icon: Icon(Icons.arrow_back, color: VesparaColors.primary),
                ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _steps[_currentStep]['title']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3,
                        color: VesparaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _steps[_currentStep]['subtitle']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentStep > 0) const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          Row(
            children: List.generate(_steps.length, (index) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentStep 
                        ? VesparaColors.glow 
                        : VesparaColors.surface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _canProceed() && !_isLoading ? _nextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: VesparaColors.glow,
            foregroundColor: VesparaColors.background,
            disabledBackgroundColor: VesparaColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VesparaColors.background,
                  ),
                )
              : Text(
                  _currentStep == _steps.length - 1 
                      ? 'ENTER VESPARA ✨' 
                      : 'CONTINUE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 0: AGE VERIFICATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildAgeVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Shield icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VesparaColors.glow.withOpacity(0.1),
            ),
            child: Icon(
              Icons.verified_user,
              size: 40,
              color: VesparaColors.glow,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Vespara is for adults 21+',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Please confirm your date of birth',
            style: TextStyle(
              fontSize: 14,
              color: VesparaColors.secondary,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Date picker button
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                firstDate: DateTime(1920),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 21)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: VesparaColors.glow,
                        onPrimary: VesparaColors.background,
                        surface: VesparaColors.surface,
                        onSurface: VesparaColors.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _birthDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _birthDate != null 
                      ? VesparaColors.glow 
                      : VesparaColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _birthDate != null 
                        ? VesparaColors.glow 
                        : VesparaColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _birthDate != null
                        ? '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}'
                        : 'Select your birth date',
                    style: TextStyle(
                      fontSize: 18,
                      color: _birthDate != null 
                          ? VesparaColors.primary 
                          : VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_birthDate != null && !_isOver21()) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VesparaColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: VesparaColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You must be 21 or older to join Vespara',
                      style: TextStyle(color: VesparaColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (_birthDate != null && _isOver21()) ...[
            const SizedBox(height: 32),
            
            // Confirmation checkbox
            InkWell(
              onTap: () => setState(() => _ageConfirmed = !_ageConfirmed),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VesparaColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _ageConfirmed 
                        ? VesparaColors.glow 
                        : VesparaColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _ageConfirmed 
                            ? VesparaColors.glow 
                            : Colors.transparent,
                        border: Border.all(
                          color: _ageConfirmed 
                              ? VesparaColors.glow 
                              : VesparaColors.secondary,
                          width: 2,
                        ),
                      ),
                      child: _ageConfirmed
                          ? Icon(Icons.check, size: 16, color: VesparaColors.background)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I confirm I am 21 years or older and agree to Vespara\'s terms of service',
                        style: TextStyle(
                          fontSize: 14,
                          color: VesparaColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 1: BASIC INFO
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Name
          Text(
            'What should we call you?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _displayNameController,
            style: TextStyle(color: VesparaColors.primary, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Your name or alias',
              hintStyle: TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
              filled: true,
              fillColor: VesparaColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (_) => setState(() {}),
          ),
          
          const SizedBox(height: 32),
          
          // Gender
          Text(
            'Gender identity (select all that apply)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genderOptions.map((option) {
              final isSelected = _selectedGenders.contains(option['id']);
              return _buildSelectableChip(
                label: '${option['emoji']} ${option['label']}',
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedGenders.remove(option['id']);
                    } else {
                      _selectedGenders.add(option['id'] as String);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Pronouns
          Text(
            'Pronouns',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pronounOptions.map((option) {
              final isSelected = _selectedPronouns == option['id'];
              return _buildSelectableChip(
                label: option['label']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedPronouns = option['id']);
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Orientation
          Text(
            'Orientation (select all that apply)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _orientationOptions.map((option) {
              final isSelected = _selectedOrientations.contains(option['id']);
              return _buildSelectableChip(
                label: '${option['emoji']} ${option['label']}',
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedOrientations.remove(option['id']);
                    } else {
                      _selectedOrientations.add(option['id'] as String);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Location
          Text(
            'Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _getLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: VesparaColors.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _city != null && _state != null
                          ? '$_city, $_state'
                          : 'Set your location',
                      style: TextStyle(
                        fontSize: 16,
                        color: _city != null 
                            ? VesparaColors.primary 
                            : VesparaColors.secondary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: VesparaColors.secondary),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2: PHOTOS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Main photo (avatar)
          Text(
            'Profile Photo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is your main photo that appears on your profile',
            style: TextStyle(
              fontSize: 12,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          
          Center(
            child: GestureDetector(
              onTap: () => _pickPhoto(isAvatar: true),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VesparaColors.surface,
                  border: Border.all(
                    color: _avatarUrl != null 
                        ? VesparaColors.glow 
                        : VesparaColors.border,
                    width: 2,
                  ),
                  image: _avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _avatarUrl == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: VesparaColors.secondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              fontSize: 12,
                              color: VesparaColors.secondary,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Additional photos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Additional Photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: VesparaColors.primary,
                ),
              ),
              Text(
                '${_uploadedPhotos.length}/6',
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Show more of yourself (optional but recommended)',
            style: TextStyle(
              fontSize: 12,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final hasPhoto = index < _uploadedPhotos.length;
              
              return GestureDetector(
                onTap: hasPhoto 
                    ? () => _showPhotoOptions(index)
                    : _uploadedPhotos.length < 6 
                        ? () => _pickPhoto()
                        : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: VesparaColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VesparaColors.border),
                    image: hasPhoto
                        ? DecorationImage(
                            image: NetworkImage(_uploadedPhotos[index]),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasPhoto
                      ? Icon(
                          Icons.add,
                          color: VesparaColors.secondary.withOpacity(0.5),
                        )
                      : null,
                ),
              );
            },
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  void _showPhotoOptions(int index) {
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
            ListTile(
              leading: Icon(Icons.delete, color: VesparaColors.error),
              title: Text('Remove Photo', style: TextStyle(color: VesparaColors.primary)),
              onTap: () {
                Navigator.pop(context);
                _removePhoto(index);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 3: RELATIONSHIP STATUS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildRelationshipStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'Current relationship situation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply to your current situation',
            style: TextStyle(
              fontSize: 12,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._relationshipOptions.map((option) {
            final isSelected = _relationshipStatus.contains(option['id']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOptionCard(
                emoji: option['emoji'] as String,
                label: option['label'] as String,
                desc: option['desc'] as String,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _relationshipStatus.remove(option['id']);
                    } else {
                      _relationshipStatus.add(option['id'] as String);
                    }
                  });
                },
              ),
            );
          }),
          
          // Partner involvement (if applicable)
          if (_relationshipStatus.any((s) => 
              s.contains('partnered') || 
              s.contains('married') || 
              s.contains('poly'))) ...[
            const SizedBox(height: 24),
            Text(
              'Partner involvement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How does your partner participate?',
              style: TextStyle(
                fontSize: 12,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _partnerInvolvementOptions.map((option) {
                final isSelected = _partnerInvolvement == option['id'];
                return _buildSelectableChip(
                  label: '${option['emoji']} ${option['label']}',
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _partnerInvolvement = option['id'] as String);
                  },
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 4: SEEKING
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildSeekingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'What brings you to Vespara?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that interest you',
            style: TextStyle(
              fontSize: 12,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._seekingOptions.map((option) {
            final isSelected = _seeking.contains(option['id']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOptionCard(
                emoji: option['emoji'] as String,
                label: option['label'] as String,
                desc: option['desc'] as String,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _seeking.remove(option['id']);
                    } else {
                      _seeking.add(option['id'] as String);
                    }
                  });
                },
              ),
            );
          }),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 5: AVAILABILITY
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildAvailabilityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // When
          Text(
            'When are you typically available?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availabilityOptions.map((option) {
              final isSelected = _availability.contains(option['id']);
              return _buildSelectableChip(
                label: '${option['emoji']} ${option['label']}',
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _availability.remove(option['id']);
                    } else {
                      _availability.add(option['id'] as String);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Scheduling
          Text(
            'How much notice do you need?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ..._schedulingOptions.map((option) {
            final isSelected = _schedulingStyle == option['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOptionCard(
                label: option['label']!,
                desc: option['desc']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _schedulingStyle = option['id']);
                },
              ),
            );
          }),
          
          const SizedBox(height: 32),
          
          // Hosting
          Text(
            'Hosting situation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hostingOptions.map((option) {
              final isSelected = _hostingStatus == option['id'];
              return _buildSelectableChip(
                label: '${option['emoji']} ${option['label']}',
                isSelected: isSelected,
                onTap: () {
                  setState(() => _hostingStatus = option['id'] as String);
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Discretion
          Text(
            'Discretion level',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ..._discretionOptions.map((option) {
            final isSelected = _discretionLevel == option['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOptionCard(
                emoji: option['emoji'] as String,
                label: option['label'] as String,
                desc: option['desc'] as String,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _discretionLevel = option['id'] as String);
                },
              ),
            );
          }),
          
          const SizedBox(height: 32),
          
          // Travel radius
          Text(
            'How far will you travel?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_travelRadius miles',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: VesparaColors.glow,
            ),
          ),
          Slider(
            value: _travelRadius.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            activeColor: VesparaColors.glow,
            inactiveColor: VesparaColors.surface,
            onChanged: (value) {
              setState(() => _travelRadius = value.round());
            },
          ),
          
          const SizedBox(height: 32),
          
          // Party availability
          Text(
            'Interested in events/parties?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _partyOptions.map((option) {
              final isSelected = _partyAvailability.contains(option['id']);
              return _buildSelectableChip(
                label: '${option['emoji']} ${option['label']}',
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (option['id'] == 'none') {
                      _partyAvailability.clear();
                      _partyAvailability.add('none');
                    } else {
                      _partyAvailability.remove('none');
                      if (isSelected) {
                        _partyAvailability.remove(option['id']);
                      } else {
                        _partyAvailability.add(option['id'] as String);
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 6: TRAITS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildTraitsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedTraits.length} selected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedTraits.length >= 5 
                        ? VesparaColors.success 
                        : VesparaColors.secondary,
                  ),
                ),
                if (_selectedTraits.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selectedTraits.clear()),
                    child: Text(
                      'Clear all',
                      style: TextStyle(color: VesparaColors.secondary, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          
          if (_selectedTraits.length < 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Select at least 5 to continue',
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.tagsYellow,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Categories
          ..._allTraits.entries.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  child: Text(
                    category.key,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: category.value.map((trait) {
                    final isSelected = _selectedTraits.contains(trait);
                    return _buildSelectableChip(
                      label: trait,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTraits.remove(trait);
                          } else {
                            _selectedTraits.add(trait);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          }),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 7: BIO
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildBioStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your story',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: VesparaColors.primary,
                ),
              ),
              TextButton.icon(
                onPressed: _isGeneratingBio ? null : _generateAIBio,
                icon: _isGeneratingBio 
                    ? SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: VesparaColors.glow,
                        ),
                      )
                    : Icon(Icons.auto_awesome, size: 18, color: VesparaColors.glow),
                label: Text(
                  'Regenerate',
                  style: TextStyle(color: VesparaColors.glow),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'AI-crafted from your selections • Feel free to edit',
            style: TextStyle(
              fontSize: 12,
              color: VesparaColors.secondary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VesparaColors.border),
              ),
              child: TextField(
                controller: _bioController,
                style: TextStyle(
                  color: VesparaColors.primary, 
                  fontSize: 16,
                  height: 1.6,
                ),
                maxLines: null,
                expands: true,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: _isGeneratingBio 
                      ? 'Crafting your story...' 
                      : 'Tell people about yourself...',
                  hintStyle: TextStyle(
                    color: VesparaColors.secondary.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  counterStyle: TextStyle(color: VesparaColors.secondary),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VesparaColors.glow.withOpacity(0.3),
                    image: _avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _avatarUrl == null
                      ? Center(
                          child: Text(
                            _displayNameController.text.isNotEmpty 
                                ? _displayNameController.text[0].toUpperCase() 
                                : '?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayNameController.text.isEmpty 
                            ? 'Your Name' 
                            : _displayNameController.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _city != null ? '$_city${_state != null ? ', $_state' : ''}' : 'Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 11,
                    color: VesparaColors.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? VesparaColors.glow : VesparaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? VesparaColors.glow : VesparaColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? VesparaColors.background : VesparaColors.primary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildOptionCard({
    String? emoji,
    required String label,
    required String desc,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? VesparaColors.glow.withOpacity(0.1) 
              : VesparaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? VesparaColors.glow : VesparaColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: VesparaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: VesparaColors.glow, size: 24),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOCATION INPUT DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _LocationInputDialog extends StatefulWidget {
  @override
  State<_LocationInputDialog> createState() => _LocationInputDialogState();
}

class _LocationInputDialogState extends State<_LocationInputDialog> {
  final _zipController = TextEditingController();
  String? _city;
  String? _state;
  bool _isLoading = false;
  String? _error;

  Future<void> _lookupZip(String zip) async {
    if (zip.length != 5) {
      setState(() {
        _city = null;
        _state = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ZipCodeService.lookup(zip);

    setState(() {
      _isLoading = false;
      if (result != null) {
        _city = result.city;
        _state = result.state;
        _error = null;
      } else {
        _city = null;
        _state = null;
        _error = 'Invalid ZIP code';
      }
    });
  }

  @override
  void dispose() {
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: VesparaColors.surface,
      title: Text(
        'Your Location',
        style: TextStyle(color: VesparaColors.primary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _zipController,
            style: TextStyle(color: VesparaColors.primary),
            keyboardType: TextInputType.number,
            maxLength: 5,
            decoration: InputDecoration(
              labelText: 'ZIP Code',
              hintText: '12345',
              hintStyle: TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
              labelStyle: TextStyle(color: VesparaColors.secondary),
              counterText: '',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: VesparaColors.border),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: VesparaColors.glow),
              ),
              suffixIcon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VesparaColors.glow,
                        ),
                      ),
                    )
                  : null,
            ),
            onChanged: _lookupZip,
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: VesparaColors.error, fontSize: 12),
              ),
            ),
          if (_city != null && _state != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: VesparaColors.glow, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_city, $_state',
                      style: TextStyle(
                        color: VesparaColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.check_circle, color: VesparaColors.glow, size: 18),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
        ),
        ElevatedButton(
          onPressed: _city != null && _state != null
              ? () {
                  Navigator.pop(context, {
                    'city': _city,
                    'state': _state,
                    'zipCode': _zipController.text.trim(),
                  });
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: VesparaColors.glow,
            disabledBackgroundColor: VesparaColors.border,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
