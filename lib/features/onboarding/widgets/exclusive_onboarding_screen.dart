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
  bool _showIntro = true; // Re-enabled VelvetRopeIntro
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
  double _bandwidth = 0.5; // 0 = Lurking, 1 = Ravenous
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM DATA - The Vibe (Dynamics & Heat)
  // ═══════════════════════════════════════════════════════════════════════════
  
  String? _heatLevel;
  final Set<String> _hardLimits = {};
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM DATA - The Dossier
  // ═══════════════════════════════════════════════════════════════════════════
  
  final _hookController = TextEditingController(); // 140 char hook
  
  // ═══════════════════════════════════════════════════════════════════════════
  // FORM DATA - Traits & Preferences
  // ═══════════════════════════════════════════════════════════════════════════
  
  final Set<String> _selectedTraits = {};
  
  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIONS DATA
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const List<Map<String, dynamic>> _genderOptions = [
    {'id': 'man', 'label': 'Man', 'emoji': '♂️'},
    {'id': 'woman', 'label': 'Woman', 'emoji': '♀️'},
    {'id': 'non_binary', 'label': 'Non-Binary', 'emoji': '⚧️'},
    {'id': 'trans_man', 'label': 'Trans Man', 'emoji': '🏳️‍⚧️'},
    {'id': 'trans_woman', 'label': 'Trans Woman', 'emoji': '🏳️‍⚧️'},
    {'id': 'genderqueer', 'label': 'Genderqueer', 'emoji': '🌈'},
    {'id': 'genderfluid', 'label': 'Genderfluid', 'emoji': '🌊'},
    {'id': 'agender', 'label': 'Agender', 'emoji': '✧'},
    {'id': 'two_spirit', 'label': 'Two-Spirit', 'emoji': '🪶'},
    {'id': 'other', 'label': 'Other', 'emoji': '🔮'},
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
    {'id': 'friends', 'label': 'Friends', 'emoji': '🤝', 'desc': 'New friends & community'},
    {'id': 'dates', 'label': 'Casual Dates', 'emoji': '🥂', 'desc': 'Coffee, drinks, good times'},
    {'id': 'fwb', 'label': 'FWB', 'emoji': '🔥', 'desc': 'Friends with benefits'},
    {'id': 'ongoing', 'label': 'Ongoing Connection', 'emoji': '♾️', 'desc': 'Regular thing, not one-off'},
    {'id': 'relationship', 'label': 'Relationship', 'emoji': '❤️‍🔥', 'desc': 'Something serious'},
    {'id': 'play_partners', 'label': 'Play Partners', 'emoji': '🎭', 'desc': 'For scenes & play'},
    {'id': 'third', 'label': 'Third', 'emoji': '🦄', 'desc': 'Looking to join a couple'},
    {'id': 'couple', 'label': 'Couples', 'emoji': '💑', 'desc': 'Looking for couples'},
    {'id': 'group', 'label': 'Group Experiences', 'emoji': '🫦', 'desc': 'Moresomes, parties'},
    {'id': 'events', 'label': 'Events & Parties', 'emoji': '🪩', 'desc': 'Social gatherings'},
    {'id': 'exploring', 'label': 'Just Exploring', 'emoji': '🔮', 'desc': 'See what happens'},
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
    {'id': 'club_events', 'label': 'Club Events', 'emoji': '🪩'},
    {'id': 'lifestyle_events', 'label': 'Lifestyle Events', 'emoji': '🎭'},
    {'id': 'hotel_takeovers', 'label': 'Hotel Takeovers', 'emoji': '🏨'},
    {'id': 'vacations', 'label': 'Lifestyle Vacations', 'emoji': '🌴'},
    {'id': 'dinner_parties', 'label': 'Dinner Parties', 'emoji': '🥂'},
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
      '👁️ Voyeur',
      '🎪 Exhibitionist',
      '🍦 Vanilla',
      '⛓️ Bondage',
      '🎨 Sensation Play',
      '🧊 Temperature Play',
      '👢 Boot/Foot Worship',
      '🩹 Impact Play',
      '🎀 Service Oriented',
      '👅 Oral Focused',
      '🌊 Edging',
      '🫦 Tantric',
    ],
    '🌶️ Turn Ons': [
      '💋 Kissing',
      '🗣️ Dirty Talk',
      '👙 Lingerie',
      '👁️ Eye Contact',
      '🔊 Being Vocal',
      '💆 Massage',
      '🍑 Toys',
      '📸 Photos/Videos (Private)',
      '🪢 Being Tied',
      '👄 Teasing',
      '💦 Squirting',
      '🌙 Aftercare',
      '🎭 Costumes',
      '📍 Public Risk',
    ],
    '🛏️ Experience': [
      '🌱 Curious Beginner',
      '📚 Still Learning',
      '✅ Experienced',
      '🎓 Very Experienced',
      '👨‍🏫 Happy to Teach',
    ],
  };
  
  // Heat level options (how spicy)
  static const List<Map<String, dynamic>> _heatLevelOptions = [
    {'id': 'mild', 'label': 'Mild', 'emoji': '🌸', 'desc': 'Romance & connection first', 'color': 0xFF4CAF50},
    {'id': 'medium', 'label': 'Medium', 'emoji': '🌶️', 'desc': 'Open to experimentation', 'color': 0xFFFFC107},
    {'id': 'hot', 'label': 'Hot', 'emoji': '🔥', 'desc': 'Kink friendly', 'color': 0xFFFF9800},
    {'id': 'nuclear', 'label': 'Nuclear', 'emoji': '☢️', 'desc': 'Anything goes', 'color': 0xFFF44336},
  ];
  
  // Hard limits
  static const List<Map<String, String>> _hardLimitOptions = [
    {'id': 'no_smokers', 'label': 'No Smokers'},
    {'id': 'no_drugs', 'label': 'No Drug Use'},
    {'id': 'no_pain', 'label': 'No Pain Play'},
    {'id': 'no_blood', 'label': 'No Blood'},
    {'id': 'no_humiliation', 'label': 'No Humiliation'},
    {'id': 'no_anal', 'label': 'No Anal'},
    {'id': 'no_choking', 'label': 'No Breath Play'},
    {'id': 'no_marking', 'label': 'No Marks/Bruises'},
    {'id': 'no_filming', 'label': 'No Photos/Videos'},
    {'id': 'no_couples', 'label': 'No Couples'},
    {'id': 'no_groups', 'label': 'No Groups'},
    {'id': 'no_bareback', 'label': 'No Bareback'},
    {'id': 'no_fluids', 'label': 'No Fluid Exchange'},
    {'id': 'no_public', 'label': 'Nothing Public'},
    {'id': 'no_strangers', 'label': 'Must Know First'},
    {'id': 'sober_only', 'label': 'Sober Only'},
  ];
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP DEFINITIONS - THE INTERVIEW
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const List<Map<String, String>> _steps = [
    {'title': 'CLEARANCE', 'subtitle': 'Age verification'},
    {'title': 'THE BASICS', 'subtitle': 'Name, identity, location'},
    {'title': 'LOGISTICS', 'subtitle': 'Status, availability, hosting'},
    {'title': 'THE SEARCH', 'subtitle': 'What you\'re looking for'},
    {'title': 'THE VIBE', 'subtitle': 'Your dynamic & heat level'},
    {'title': 'THE DOSSIER', 'subtitle': 'Photos & your hook'},
    {'title': 'VESPARA PROFILE', 'subtitle': 'Let Vespara craft your story'},
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _hookController.dispose();
    super.dispose();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  bool _canProceed() {
    switch (_currentStep) {
      case 0: // CLEARANCE - Age verification
        return _birthDate != null && _ageConfirmed && _isOver21();
      case 1: // THE BASICS - Name, identity, location
        return _displayNameController.text.trim().isNotEmpty &&
               _selectedGenders.isNotEmpty &&
               _selectedOrientations.isNotEmpty;
      case 2: // LOGISTICS - Status, availability, hosting
        return _relationshipStatus.isNotEmpty &&
               _availability.isNotEmpty &&
               _hostingStatus != null;
      case 3: // THE SEARCH - What you're looking for
        return _seeking.isNotEmpty;
      case 4: // THE VIBE - Dynamics & heat level
        return _selectedTraits.length >= 3 && _heatLevel != null;
      case 5: // THE DOSSIER - Photos & hook
        return true; // Optional but encouraged
      case 6: // AI PROFILE - Bio generation
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
      
      // Auto-generate bio when entering AI Profile step
      if (_currentStep == 6 && _bioController.text.isEmpty) {
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
      
      if (mounted) {
        setState(() {
          _bioController.text = bio;
        });
      }
    } catch (e) {
      debugPrint('Bio generation error: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingBio = false);
      }
    }
  }
  
  // Random number for bio variation
  int _bioStyleSeed = DateTime.now().millisecondsSinceEpoch;
  
  String _buildBioFromSelections(String name) {
    // Increment seed for variety on each regeneration
    _bioStyleSeed++;
    final random = _bioStyleSeed % 100;
    
    // Gather all the raw data
    final relationshipIds = _relationshipStatus.toList();
    final seekingIds = _seeking.toList();
    final traits = _selectedTraits.toList();
    final isSpontaneous = _availability.contains('spontaneous');
    final isNightOwl = traits.any((t) => t.contains('Night Owl'));
    final isEarlyRiser = traits.any((t) => t.contains('Early Riser'));
    final isHighEnergy = traits.any((t) => t.contains('High Energy'));
    final isCalm = traits.any((t) => t.contains('Calm'));
    final isLifeOfParty = traits.any((t) => t.contains('Life of the Party'));
    final isHomebody = traits.any((t) => t.contains('Homebody'));
    final isWitty = traits.any((t) => t.contains('Witty'));
    final isRomantic = traits.any((t) => t.contains('Romantic'));
    final isMischievous = traits.any((t) => t.contains('Mischievous'));
    final isPassionate = traits.any((t) => t.contains('Passionate'));
    final isDominant = traits.any((t) => t.contains('Dominant'));
    final isSubmissive = traits.any((t) => t.contains('Submissive'));
    final isSwitch = traits.any((t) => t.contains('Switch'));
    final isBeginner = traits.any((t) => t.contains('Beginner') || t.contains('Learning'));
    final isExperienced = traits.any((t) => t.contains('Experienced'));
    final canTeach = traits.any((t) => t.contains('Teach'));
    
    // Location with flair
    final locationPhrase = _city != null && _state != null 
        ? _getLocationPhrase('$_city, $_state', random)
        : '';
    
    // Build personality snippet with shuffling based on random seed
    final allPersonalityBits = <String>[];
    if (isWitty) allPersonalityBits.add('fluent in sarcasm');
    if (isRomantic) allPersonalityBits.add('secretly a romantic');
    if (isMischievous) allPersonalityBits.add('trouble in the best way');
    if (isPassionate) allPersonalityBits.add('intensity is my love language');
    if (isCalm) allPersonalityBits.add('unfairly calm under pressure');
    if (isHighEnergy) allPersonalityBits.add('powered by an internal espresso machine');
    if (isNightOwl) allPersonalityBits.add('a creature of the night');
    if (isEarlyRiser) allPersonalityBits.add('annoyingly awake at sunrise');
    if (isLifeOfParty) allPersonalityBits.add('the one people remember');
    if (isHomebody) allPersonalityBits.add('a cozy soul');
    
    // Shuffle personality bits for variety
    final personalityBits = List<String>.from(allPersonalityBits);
    if (personalityBits.length > 1) {
      // Simple shuffle using seed
      final offset = random % personalityBits.length;
      personalityBits.insert(0, personalityBits.removeAt(offset));
    }
    
    // Build vibe snippet
    final vibeSnippet = personalityBits.isNotEmpty 
        ? personalityBits.take(2).join(', ')
        : 'still figuring out my brand';
    
    // Lifestyle context (pass random for variation)
    final lifestyleHint = _getLifestyleHint(relationshipIds, random);
    
    // What they want (natural language, pass random for variation)
    final wantingPhrase = _getWantingPhrase(seekingIds, random);
    
    // Energy/timing style with more options
    final timingOptions = isSpontaneous 
        ? ['Spontaneity appreciated.', 'Down for last-minute plans.', 'Text me at 11pm, I might say yes.']
        : _schedulingStyle == 'same_day' 
            ? ['Same-day plans? Yes please.', 'I move fast.', 'Today works.']
            : ['I like a little runway.', 'Let\'s plan ahead.', 'Calendar tetris is my sport.'];
    final timingStyle = timingOptions[random % timingOptions.length];
    
    // Discretion (only if relevant) with variety
    final discretionOptions = _discretionLevel == 'very_discreet'
        ? ['Discretion isn\'t a preference—it\'s non-negotiable.', 'Privacy is sacred here.', 'Some things stay between us.']
        : _discretionLevel == 'discreet'
            ? ['Privacy matters here.', 'I value discretion.', 'What happens stays private.']
            : [''];
    final discretionNote = discretionOptions[random % discretionOptions.length];
    
    // Experience level (tasteful)
    final experienceNote = isBeginner
        ? 'New to this scene. Patient guides welcome.'
        : canTeach
            ? 'Happy to show someone the ropes.'
            : '';
    
    // Dynamic power hint
    final powerHint = isDominant
        ? 'I know what I want.'
        : isSubmissive
            ? 'I aim to please.'
            : isSwitch
                ? 'Depends on my mood—and yours.'
                : '';
    
    // Generate multiple bio styles and pick one randomly for variety
    final bios = <String>[
      // Style 1: Confident & Playful
      _buildStyle1(name, vibeSnippet, lifestyleHint, wantingPhrase, 
                   locationPhrase, timingStyle, discretionNote, powerHint),
      
      // Style 2: Mysterious & Intriguing  
      _buildStyle2(name, personalityBits, lifestyleHint, wantingPhrase,
                   locationPhrase, discretionNote, experienceNote),
      
      // Style 3: Warm & Direct
      _buildStyle3(name, traits, lifestyleHint, wantingPhrase,
                   locationPhrase, timingStyle, powerHint),
    ];
    
    // Pick semi-randomly based on personality and seed for variety on regeneration
    int styleIndex = random % 3;
    
    return bios[styleIndex];
  }
  
  String _buildStyle1(String name, String vibeSnippet, String lifestyleHint,
      String wantingPhrase, String locationPhrase, String timingStyle, 
      String discretionNote, String powerHint) {
    final lines = <String>[
      '$name. $vibeSnippet.',
      '',
      lifestyleHint,
      wantingPhrase,
      '',
    ];
    
    if (powerHint.isNotEmpty) lines.add(powerHint);
    if (timingStyle.isNotEmpty) lines.add(timingStyle);
    if (discretionNote.isNotEmpty) lines.add(discretionNote);
    if (locationPhrase.isNotEmpty) lines.add(locationPhrase);
    
    return lines.where((l) => l.isNotEmpty || l == '').join('\n').trim();
  }
  
  String _buildStyle2(String name, List<String> personalityBits, String lifestyleHint,
      String wantingPhrase, String locationPhrase, String discretionNote, 
      String experienceNote) {
    final opener = personalityBits.isNotEmpty
        ? 'They say I\'m ${personalityBits.first}. They\'re not wrong.'
        : 'Some things are better discovered in person.';
    
    final lines = <String>[
      opener,
      '',
      lifestyleHint,
      wantingPhrase,
      '',
    ];
    
    if (experienceNote.isNotEmpty) lines.add(experienceNote);
    if (discretionNote.isNotEmpty) lines.add(discretionNote);
    if (locationPhrase.isNotEmpty) lines.add(locationPhrase);
    lines.add('');
    lines.add('— $name');
    
    return lines.where((l) => l.isNotEmpty || l == '').join('\n').trim();
  }
  
  String _buildStyle3(String name, List<String> traits, String lifestyleHint,
      String wantingPhrase, String locationPhrase, String timingStyle,
      String powerHint) {
    // Extract clean trait words
    final cleanTraits = traits
        .map((t) => t.replaceAll(RegExp(r'^[^\w]*'), '').trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList();
    
    final traitLine = cleanTraits.isNotEmpty 
        ? cleanTraits.join(' · ')
        : '';
    
    final lines = <String>[
      'Hi, I\'m $name.',
      '',
      lifestyleHint,
      wantingPhrase,
      '',
    ];
    
    if (traitLine.isNotEmpty) lines.add(traitLine);
    if (powerHint.isNotEmpty) lines.add(powerHint);
    if (timingStyle.isNotEmpty) lines.add(timingStyle);
    if (locationPhrase.isNotEmpty) lines.add(locationPhrase);
    
    return lines.where((l) => l.isNotEmpty || l == '').join('\n').trim();
  }
  
  String _getLocationPhrase(String location, int random) {
    final phrases = [
      'Based in $location.',
      '$location, for now.',
      'You\'ll find me in $location.',
      'Home base: $location.',
      'Currently in $location.',
      '$location calling.',
    ];
    return phrases[random % phrases.length];
  }
  
  String _getLifestyleHint(List<String> relationshipIds, int random) {
    // Multiple options per status for variety
    if (relationshipIds.contains('single')) {
      final options = [
        'Happily unattached and keeping my options open.',
        'Single and ready for... well, anything interesting.',
        'Flying solo and loving the view.',
      ];
      return options[random % options.length];
    } else if (relationshipIds.contains('partnered_open') || 
               relationshipIds.contains('married_open')) {
      final options = [
        'Partnered and playing with permission—enthusiastic permission.',
        'In a loving open relationship. Yes, they know.',
        'Committed at home, exploring outside.',
      ];
      return options[random % options.length];
    } else if (relationshipIds.contains('poly_solo')) {
      final options = [
        'Solo poly. My heart has room, but no one has the keys.',
        'Polyamorous and independently minded.',
        'Multiple connections, no primary—by design.',
      ];
      return options[random % options.length];
    } else if (relationshipIds.contains('poly_nested') || 
               relationshipIds.contains('poly_network')) {
      final options = [
        'Part of a happy polycule. More love to go around.',
        'Poly with a network of wonderful people.',
        'Already blessed with partners, always open to more.',
      ];
      return options[random % options.length];
    } else if (relationshipIds.contains('relationship_anarchist')) {
      final options = [
        'I don\'t do labels. Connections happen on their own terms.',
        'Relationship anarchist. Rules are boring.',
        'No hierarchy, no expectations, just vibes.',
      ];
      return options[random % options.length];
    } else if (relationshipIds.contains('exploring')) {
      final options = [
        'Figuring out what I want—and enjoying the journey.',
        'Exploring my options and loving it.',
        'Still writing my story.',
      ];
      return options[random % options.length];
    } else if (relationshipIds.contains('situationship')) {
      final options = [
        'It\'s complicated. And I kind of like it that way.',
        'Somewhere between something and nothing.',
        'Currently in undefined territory.',
      ];
      return options[random % options.length];
    } else if (relationshipIds.contains('divorced')) {
      final options = [
        'New chapter, new adventures.',
        'Divorced and rediscovering myself.',
        'Past closed, future wide open.',
      ];
      return options[random % options.length];
    } else if (relationshipIds.contains('dating')) {
      final options = [
        'Dating around, not settling down.',
        'Casually dating, no strings attached.',
        'Playing the field, having fun.',
      ];
      return options[random % options.length];
    } else if (relationshipIds.contains('partnered')) {
      final options = [
        'In a relationship, exploring together.',
        'Partnered and curious.',
        'Together but open-minded.',
      ];
      return options[random % options.length];
    }
    final defaultOptions = [
      'Living life on my own terms.',
      'Making my own rules.',
      'Here for the experience.',
    ];
    return defaultOptions[random % defaultOptions.length];
  }
  
  String _getWantingPhrase(List<String> seekingIds, int random) {
    final phrases = <String>[];
    
    if (seekingIds.contains('friends')) {
      phrases.add('genuine connections');
    }
    if (seekingIds.contains('fwb')) {
      phrases.add('the fun kind of friendship');
    }
    if (seekingIds.contains('ongoing')) {
      phrases.add('something consistent');
    }
    if (seekingIds.contains('relationship')) {
      phrases.add('something real');
    }
    if (seekingIds.contains('play_partners')) {
      phrases.add('playmates who get it');
    }
    if (seekingIds.contains('dates')) {
      phrases.add('good conversation over drinks');
    }
    if (seekingIds.contains('group')) {
      phrases.add('memorable group experiences');
    }
    if (seekingIds.contains('third')) {
      phrases.add('the right couple');
    }
    if (seekingIds.contains('couple')) {
      phrases.add('couples who click');
    }
    if (seekingIds.contains('events')) {
      phrases.add('the right parties');
    }
    if (seekingIds.contains('exploring')) {
      phrases.add('seeing where things go');
    }
    
    // Shuffle phrases for variety
    if (phrases.length > 1) {
      final offset = random % phrases.length;
      phrases.insert(0, phrases.removeAt(offset));
    }
    
    // Vary the phrasing structure
    final starters = ['Here for', 'Looking for', 'Seeking', 'Interested in'];
    final starter = starters[random % starters.length];
    
    if (phrases.isEmpty) {
      final emptyOptions = ['Open to what comes my way.', 'Here for the adventure.', 'Curious about everything.'];
      return emptyOptions[random % emptyOptions.length];
    } else if (phrases.length == 1) {
      return '$starter ${phrases.first}.';
    } else if (phrases.length == 2) {
      return '$starter ${phrases[0]} and ${phrases[1]}.';
    } else {
      return '$starter ${phrases.take(2).join(', ')}, and more.';
    }
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
        'hook': _hookController.text.trim(),
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
        
        // Availability & Logistics
        'availability_general': _availability.toList(),
        'scheduling_style': _schedulingStyle,
        'hosting_status': _hostingStatus,
        'discretion_level': _discretionLevel,
        'travel_radius': _travelRadius,
        'party_availability': _partyAvailability.toList(),
        'bandwidth': _bandwidth,
        
        // Vibe & Heat
        'looking_for': _selectedTraits.toList(),
        'heat_level': _heatLevel,
        'hard_limits': _hardLimits.toList(),
        
        // Onboarding status
        'onboarding_complete': true,
        'onboarding_step': 9,
        'onboarding_completed_at': DateTime.now().toIso8601String(),
        'is_verified': true,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await Supabase.instance.client.from('profiles').upsert(profileData);
      
      print('[Onboarding] Profile saved successfully');
      
      // Refresh session to trigger navigation
      if (mounted) {
        await Supabase.instance.client.auth.refreshSession();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to Vespara! ✨'),
            backgroundColor: VesparaColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('[Onboarding] Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
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
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  
  @override
  Widget build(BuildContext context) {
    // Show velvet rope intro first
    if (_showIntro) {
      // Wrap in a Builder to catch any rendering errors and provide fallback
      return Builder(
        builder: (context) {
          try {
            return VelvetRopeIntro(
              onComplete: () {
                setState(() => _showIntro = false);
              },
            );
          } catch (e) {
            debugPrint('VelvetRopeIntro error: $e');
            // Skip intro if there's an error and go straight to onboarding
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _showIntro = false);
              }
            });
            return Scaffold(
              backgroundColor: VesparaColors.background,
              body: Center(
                child: CircularProgressIndicator(color: VesparaColors.glow),
              ),
            );
          }
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
                  _buildClearanceStep(),      // 0: Age verification
                  _buildBasicsStep(),          // 1: Name, identity, location
                  _buildLogisticsStep(),       // 2: Status, availability, hosting
                  _buildSearchStep(),          // 3: What you're looking for
                  _buildVibeStep(),            // 4: Dynamics & heat level
                  _buildDossierStep(),         // 5: Photos & hook
                  _buildAIProfileStep(),       // 6: AI-generated bio
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
  // STEP 0: CLEARANCE (Age Verification)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildClearanceStep() {
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
  // STEP 1: THE BASICS (Name, Identity, Location)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildBasicsStep() {
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
  // STEP 5: THE DOSSIER (Photos & Hook)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildDossierStep() {
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
          
          const SizedBox(height: 40),
          
          // THE HOOK - 140 character teaser
          Text(
            '✨ The Hook',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '140 characters to make them swipe right. Make it count!',
            style: TextStyle(
              fontSize: 12,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VesparaColors.border),
            ),
            child: TextField(
              controller: _hookController,
              maxLength: 140,
              maxLines: 2,
              style: TextStyle(
                color: VesparaColors.primary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., "Adventurous spirit seeking midnight conversations and morning coffee dates..."',
                hintStyle: TextStyle(
                  color: VesparaColors.secondary.withOpacity(0.6),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
                counterStyle: TextStyle(
                  color: _hookController.text.length > 120 
                      ? VesparaColors.tagsRed 
                      : VesparaColors.secondary,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
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
  // STEP 2: LOGISTICS (Status, Availability, Hosting)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildLogisticsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // RELATIONSHIP STATUS
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
            'Select all that apply',
            style: TextStyle(
              fontSize: 12,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          
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
          
          // PARTNER INVOLVEMENT (if applicable)
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
          
          const SizedBox(height: 32),
          
          // AVAILABILITY
          Text(
            'When are you typically free to connect?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: TextStyle(
              fontSize: 12,
              color: VesparaColors.secondary,
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
          
          // HOSTING
          Text(
            'What is your hosting situation?',
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
          
          // TRAVEL RADIUS
          Text(
            'How far are you willing to go?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$_travelRadius miles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.glow,
                ),
              ),
              const Spacer(),
              Text(
                _travelRadius <= 10 ? 'Local only' : 
                _travelRadius <= 25 ? 'My area' :
                _travelRadius <= 50 ? 'Regional' : 'Will travel',
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
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
          
          // BANDWIDTH SLIDER
          Text(
            'How much energy do you have for this right now?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🐢 Just Lurking', style: TextStyle(fontSize: 11, color: VesparaColors.secondary)),
              Text('🔥 Ravenous', style: TextStyle(fontSize: 11, color: VesparaColors.secondary)),
            ],
          ),
          Slider(
            value: _bandwidth,
            min: 0,
            max: 1,
            activeColor: _bandwidth < 0.3 ? VesparaColors.tagsGreen :
                        _bandwidth < 0.6 ? VesparaColors.tagsYellow :
                        _bandwidth < 0.8 ? Colors.orange : VesparaColors.tagsRed,
            inactiveColor: VesparaColors.surface,
            onChanged: (value) {
              setState(() => _bandwidth = value);
            },
          ),
          Center(
            child: Text(
              _bandwidth < 0.2 ? 'Taking it slow, just browsing' :
              _bandwidth < 0.4 ? 'Open to the right opportunity' :
              _bandwidth < 0.6 ? 'Actively looking' :
              _bandwidth < 0.8 ? 'Ready to meet' : 'Available and eager! 🔥',
              style: TextStyle(
                color: VesparaColors.glow,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 3: THE SEARCH (What You're Looking For)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildSearchStep() {
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
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 4: THE VIBE (Dynamics & Heat Level)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildVibeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // HEAT LEVEL SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '🔥 Your Heat Level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'How spicy are you looking to get?',
              style: TextStyle(
                fontSize: 12,
                color: VesparaColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          ..._heatLevelOptions.map((option) {
            final isSelected = _heatLevel == option['id'];
            final Color cardColor = option['id'] == 'mild' ? Colors.pink.shade100 :
                                   option['id'] == 'medium' ? Colors.orange.shade200 :
                                   option['id'] == 'hot' ? Colors.red.shade300 :
                                   Colors.purple.shade400;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: GestureDetector(
                onTap: () => setState(() => _heatLevel = option['id'] as String),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? cardColor.withOpacity(0.3) : VesparaColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? cardColor : VesparaColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(option['emoji'] as String, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['label'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? cardColor : VesparaColors.primary,
                              ),
                            ),
                            Text(
                              option['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: VesparaColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: cardColor),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 32),
          
          // HARD LIMITS SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '🚫 Hard Limits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Non-negotiables. Select any that apply.',
              style: TextStyle(
                fontSize: 12,
                color: VesparaColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hardLimitOptions.map((option) {
                final isSelected = _hardLimits.contains(option['id']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _hardLimits.remove(option['id']);
                      } else {
                        _hardLimits.add(option['id'] as String);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? VesparaColors.tagsRed.withOpacity(0.2) : VesparaColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? VesparaColors.tagsRed : VesparaColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${option['emoji']} ${option['label']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? VesparaColors.tagsRed : VesparaColors.primary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // TRAITS SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '✨ Your Vibe Traits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
          ),
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
  // STEP 6: AI PROFILE (Bio Generation)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildAIProfileStep() {
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
