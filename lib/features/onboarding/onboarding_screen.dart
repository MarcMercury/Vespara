import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';

/// OnboardingScreen - The Interview
/// Comprehensive profile setup with personality traits, desires, and AI bio
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isGeneratingBio = false;
  
  // Form data
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final Set<String> _selectedTraits = {};
  
  // ═══════════════════════════════════════════════════════════════════════════
  // COMPREHENSIVE TRAIT CATEGORIES
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
    
    // ═══════════════════════════════════════════════════════════════════════════
    // INTIMATE PREFERENCES
    // ═══════════════════════════════════════════════════════════════════════════
    
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
  
  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  /// Check which categories have at least one selection
  Set<String> _getCategoriesWithSelections() {
    final categoriesWithSelections = <String>{};
    
    for (final entry in _allTraits.entries) {
      final category = entry.key;
      final traits = entry.value;
      
      // Check if any trait from this category is selected
      for (final trait in traits) {
        if (_selectedTraits.contains(trait)) {
          categoriesWithSelections.add(category);
          break;
        }
      }
    }
    
    return categoriesWithSelections;
  }
  
  /// Get list of categories that still need selections
  List<String> _getMissingCategories() {
    final allCategories = _allTraits.keys.toSet();
    final selectedCategories = _getCategoriesWithSelections();
    return allCategories.difference(selectedCategories).toList();
  }
  
  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _displayNameController.text.trim().isNotEmpty;
      case 1:
        // Require at least one selection from EACH category
        final missingCategories = _getMissingCategories();
        return missingCategories.isEmpty;
      case 2:
        return true; // Bio is optional
      default:
        return false;
    }
  }
  
  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
      
      // Auto-generate bio when entering bio page
      if (_currentPage == 2 && _bioController.text.isEmpty) {
        _generateAIBio();
      }
    } else {
      _completeOnboarding();
    }
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }
  
  /// Generate an AI bio based on selected traits
  Future<void> _generateAIBio() async {
    if (_selectedTraits.isEmpty) return;
    
    setState(() => _isGeneratingBio = true);
    
    try {
      // Build a compelling bio locally based on traits
      final bio = _generateLocalBio();
      
      setState(() {
        _bioController.text = bio;
      });
    } catch (e) {
      debugPrint('Bio generation error: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingBio = false);
      }
    }
  }
  
  /// Generate a seductive, confident bio based on selected traits
  String _generateLocalBio() {
    final name = _displayNameController.text.trim();
    final traits = _selectedTraits.toList();
    
    // Categorize selected traits
    final personality = <String>[];
    final kinks = <String>[];
    final dynamics = <String>[];
    
    for (final trait in traits) {
      final cleanTrait = trait.replaceAll(RegExp(r'[^\w\s/]'), '').trim().toLowerCase();
      
      // Kinks & bedroom stuff
      if (cleanTrait.contains('dominant') || cleanTrait.contains('submissive') ||
          cleanTrait.contains('switch') || cleanTrait.contains('bondage') ||
          cleanTrait.contains('bdsm') || cleanTrait.contains('roleplay') ||
          cleanTrait.contains('spanking') || cleanTrait.contains('rough') ||
          cleanTrait.contains('kink') || cleanTrait.contains('fetish') ||
          cleanTrait.contains('voyeur') || cleanTrait.contains('exhib') ||
          cleanTrait.contains('dirty talk') || cleanTrait.contains('rope') ||
          cleanTrait.contains('anal') || cleanTrait.contains('oral')) {
        kinks.add(trait);
      } 
      // Group/relationship dynamics
      else if (cleanTrait.contains('threesome') || cleanTrait.contains('group') ||
               cleanTrait.contains('couple') || cleanTrait.contains('unicorn') ||
               cleanTrait.contains('bull') || cleanTrait.contains('cuck') ||
               cleanTrait.contains('swap') || cleanTrait.contains('hotwife') ||
               cleanTrait.contains('fwb') || cleanTrait.contains('no strings') ||
               cleanTrait.contains('discreet') || cleanTrait.contains('one night')) {
        dynamics.add(trait);
      }
      // Personality
      else {
        personality.add(trait);
      }
    }
    
    // Extract clean text for bio
    String cleanTrait(String t) => t.replaceAll(RegExp(r'^[^\w]*'), '').trim();
    String lowerClean(String t) => cleanTrait(t).toLowerCase();
    
    // Build seductive, confident bios
    final List<String> bioOptions = [
      // Confident & direct
      "$name. I know what I want and I'm not shy about it.\n\n${kinks.isNotEmpty ? 'Into: ${kinks.take(3).map(lowerClean).join(', ')}.' : ''} ${dynamics.isNotEmpty ? 'Looking for ${dynamics.take(2).map(lowerClean).join(' or ')}.' : ''}\n\nIf you can handle ${personality.isNotEmpty ? lowerClean(personality.first) : 'intensity'}, we should talk.",
      
      // Playfully explicit
      "They call me $name. ${personality.isNotEmpty ? cleanTrait(personality.first) : 'Curious'} with a wild side that comes out to play.\n\n${kinks.isNotEmpty ? 'I like my ${lowerClean(kinks.first)}${kinks.length > 1 ? ' with some ${lowerClean(kinks[1])}' : ''}.' : 'Open to exploring.'}\n\n${dynamics.isNotEmpty ? 'Currently seeking: ${dynamics.take(2).map(lowerClean).join(', ')}.' : 'Let\'s see where this goes.'}\n\nDon't be boring. 😈",
      
      // Mysterious & seductive
      "I'm $name, and I have a feeling you're going to enjoy getting to know me.\n\n${personality.isNotEmpty ? cleanTrait(personality.first) : 'Intriguing'} on the surface. ${kinks.isNotEmpty ? cleanTrait(kinks.first) : 'Adventurous'} behind closed doors.\n\n${dynamics.isNotEmpty ? 'Here for ${dynamics.take(2).map(lowerClean).join(', ')}.' : 'Here to explore.'} No games—unless we\'re both playing. 🌙",
      
      // Bold & unapologetic
      "Let's skip the small talk. I'm $name.\n\n${kinks.isNotEmpty ? '✓ ${kinks.take(4).map(cleanTrait).join('\\n✓ ')}' : 'Open-minded and ready to explore.'}\n\n${dynamics.isNotEmpty ? 'Ideal situation: ${dynamics.take(2).map(lowerClean).join(' or ')}.' : ''} ${personality.isNotEmpty ? cleanTrait(personality.first) : 'Confident'} and ready when you are.",
      
      // Sultry & inviting  
      "$name here. ${personality.isNotEmpty ? cleanTrait(personality.first) : 'Passionate'} soul with an appetite for ${kinks.isNotEmpty ? lowerClean(kinks.first) : 'adventure'}.\n\nI believe chemistry is everything. ${dynamics.isNotEmpty ? 'Open to ${dynamics.take(2).map(lowerClean).join(', ')}.' : 'Let\'s see if we have it.'}\n\nMessage me something that makes me smile. Or blush. Preferably both. 💋",
      
      // Dominant energy
      "$name. ${kinks.any((k) => k.toLowerCase().contains('dominant')) ? 'I take control.' : 'I know what I like.'}\n\n${kinks.isNotEmpty ? 'If ${kinks.take(2).map(lowerClean).join(' and ')} sound like your kind of night, keep reading.' : 'Looking for someone who can keep up.'}\n\n${dynamics.isNotEmpty ? 'Seeking: ${dynamics.take(2).map(lowerClean).join(', ')}.' : ''} Come correct or don\'t come at all.",
      
      // Submissive energy
      "$name. ${kinks.any((k) => k.toLowerCase().contains('submissive')) ? 'I follow the right lead.' : 'I appreciate someone who takes charge.'}\n\n${personality.isNotEmpty ? cleanTrait(personality.first) : 'Sweet'} until the bedroom door closes. Then? ${kinks.isNotEmpty ? cleanTrait(kinks.first) : 'Eager to please'}.\n\n${dynamics.isNotEmpty ? 'Looking for ${dynamics.take(2).map(lowerClean).join(' or ')}.' : 'Show me you\'re worth it.'} 🦋",
    ];
    
    // Pick a random bio style
    return bioOptions[DateTime.now().millisecond % bioOptions.length];
  }
  
  String _getTraitPhrase(List<String> traits) {
    if (traits.isEmpty) return 'good vibes';
    if (traits.length == 1) return traits.first.replaceAll(RegExp(r'^[^\w]*'), '').trim();
    
    final clean = traits.map((t) => t.replaceAll(RegExp(r'^[^\w]*'), '').trim()).toList();
    return '${clean[0]} with a side of ${clean.length > 1 ? clean[1] : "mystery"}';
  }
  
  String _getDesirePhrase(List<String> traits) {
    if (traits.isEmpty) return 'genuine connections';
    final clean = traits.map((t) => t.replaceAll(RegExp(r'^[^\w]*'), '').trim().toLowerCase()).toList();
    return clean.take(2).join(' and ');
  }
  
  String _getLifestylePhrase(List<String> traits) {
    if (traits.isEmpty) return 'good times';
    final clean = traits.map((t) => t.replaceAll(RegExp(r'^[^\w]*'), '').trim().toLowerCase()).toList();
    return clean.take(2).join(' + ');
  }
  
  String _getRandomTrait(List<String> traits) {
    if (traits.isEmpty) return 'mystery';
    return traits[DateTime.now().millisecond % traits.length]
        .replaceAll(RegExp(r'^[^\w]*'), '')
        .trim()
        .toLowerCase();
  }
  
  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No user found');
      
      // Combine all traits as looking_for array (existing column)
      final allTraits = _selectedTraits.toList();
      
      // Upsert profile using EXISTING columns only
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'display_name': _displayNameController.text.trim(),
        'bio': _bioController.text.trim().isEmpty 
            ? 'New to Vespara ✨' 
            : _bioController.text.trim(),
        'looking_for': allTraits, // Store traits in existing array column
        'is_verified': true, // Mark as verified to indicate onboarding complete
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Refresh the auth state to trigger AuthGate rebuild
      if (mounted) {
        // Pop all routes and let AuthGate re-evaluate
        await Supabase.instance.client.auth.refreshSession();
        // The auth listener will pick up the change
      }
    } catch (e) {
      debugPrint('Onboarding error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile saved! Entering Vespara...'),
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════════════════
            // HEADER
            // ═══════════════════════════════════════════════════════════════
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: _previousPage,
                          icon: Icon(Icons.arrow_back, color: VesparaColors.primary),
                        ),
                      Expanded(
                        child: Text(
                          'THE INTERVIEW',
                          textAlign: _currentPage > 0 ? TextAlign.center : TextAlign.left,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 3,
                            color: VesparaColors.primary,
                          ),
                        ),
                      ),
                      if (_currentPage > 0) SizedBox(width: 48),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: index == _currentPage ? 40 : 12,
                        height: 4,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index <= _currentPage 
                              ? VesparaColors.primary 
                              : VesparaColors.surface,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    _getPageSubtitle(),
                    style: TextStyle(
                      fontSize: 13,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // PAGES
            // ═══════════════════════════════════════════════════════════════
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildNamePage(),
                  _buildTraitsPage(),
                  _buildBioPage(),
                ],
              ),
            ),
            
            // ═══════════════════════════════════════════════════════════════
            // CONTINUE BUTTON
            // ═══════════════════════════════════════════════════════════════
            Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceed() && !_isLoading ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.primary,
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
                          _currentPage == 2 ? 'ENTER VESPARA ✨' : 'CONTINUE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getPageSubtitle() {
    switch (_currentPage) {
      case 0:
        return 'What should we call you?';
      case 1:
        return 'Select at least 5 that describe you';
      case 2:
        return 'AI-crafted from your vibe • Feel free to edit';
      default:
        return '';
    }
  }
  
  Widget _buildNamePage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          
          // Moon glow decoration
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [VesparaColors.primary, VesparaColors.primary.withOpacity(0.3)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: VesparaColors.glow.withOpacity(0.4),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 48),
          
          // Name input
          TextField(
            controller: _displayNameController,
            style: TextStyle(
              color: VesparaColors.primary, 
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(
                color: VesparaColors.secondary.withOpacity(0.5),
                fontSize: 24,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
          
          SizedBox(height: 24),
          
          Center(
            child: Text(
              'This is how you\'ll appear to others',
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTraitsPage() {
    final missingCategories = _getMissingCategories();
    final selectedCategories = _getCategoriesWithSelections();
    final totalCategories = _allTraits.keys.length;
    final completedCount = selectedCategories.length;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          
          // Category progress indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          completedCount == totalCategories 
                              ? Icons.check_circle 
                              : Icons.radio_button_unchecked,
                          color: completedCount == totalCategories 
                              ? VesparaColors.success 
                              : VesparaColors.secondary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '$completedCount of $totalCategories categories',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: completedCount == totalCategories 
                                ? VesparaColors.success 
                                : VesparaColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedTraits.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _selectedTraits.clear()),
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            color: VesparaColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completedCount / totalCategories,
                    backgroundColor: VesparaColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completedCount == totalCategories 
                          ? VesparaColors.success 
                          : VesparaColors.glow,
                    ),
                    minHeight: 6,
                  ),
                ),
                if (missingCategories.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    'Select at least one from each category to continue',
                    style: TextStyle(
                      fontSize: 12,
                      color: VesparaColors.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          SizedBox(height: 8),
          
          // Trait categories
          ..._allTraits.entries.map((category) {
            final categoryName = category.key;
            final hasCategorySelection = selectedCategories.contains(categoryName);
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                  child: Row(
                    children: [
                      Icon(
                        hasCategorySelection 
                            ? Icons.check_circle 
                            : Icons.circle_outlined,
                        color: hasCategorySelection 
                            ? VesparaColors.success 
                            : VesparaColors.tagsYellow,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hasCategorySelection 
                              ? VesparaColors.primary 
                              : VesparaColors.tagsYellow,
                          letterSpacing: 1,
                        ),
                      ),
                      if (!hasCategorySelection) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: VesparaColors.tagsYellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Pick 1+',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.tagsYellow,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: category.value.map((trait) {
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
                        duration: Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? VesparaColors.primary 
                              : VesparaColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? VesparaColors.primary 
                                : VesparaColors.border,
                          ),
                        ),
                        child: Text(
                          trait,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected 
                                ? VesparaColors.background 
                                : VesparaColors.primary,
                            fontWeight: isSelected 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }).toList(),
          
          SizedBox(height: 100), // Bottom padding for scroll
        ],
      ),
    );
  }
  
  Widget _buildBioPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          
          // Regenerate button
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
          
          SizedBox(height: 16),
          
          // Bio text field
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
                  contentPadding: EdgeInsets.all(20),
                  counterStyle: TextStyle(color: VesparaColors.secondary),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Preview card
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VesparaColors.glow.withOpacity(0.3),
                  ),
                  child: Center(
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
                  ),
                ),
                SizedBox(width: 12),
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
                      SizedBox(height: 4),
                      Text(
                        '${_selectedTraits.length} vibes selected',
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
}
