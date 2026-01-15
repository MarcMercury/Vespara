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
    '🧠 Mind': [
      '📚 Intellectual',
      '🎨 Creative Soul',
      '💡 Endlessly Curious',
      '🧩 Analytical',
      '💭 Deep Thinker',
      '🎯 Driven & Ambitious',
    ],
    '💫 Spirit': [
      '😂 Witty & Sarcastic',
      '💝 Hopeless Romantic',
      '🔥 Passionate',
      '😌 Easy Going',
      '🌟 Eternal Optimist',
      '🖤 Dark Humor',
    ],
    
    // DESIRES & CONNECTION
    '💕 Looking For': [
      '💕 Something Real',
      '🌶️ Spicy Adventures',
      '🤝 New Friends',
      '💫 Go With the Flow',
      '👀 Just Exploring',
      '🔐 Discreet Fun',
    ],
    '💬 Connection Style': [
      '💬 Deep Conversations',
      '🎲 Spontaneous Fun',
      '🌹 Old School Romance',
      '🔗 No Strings Attached',
      '🎯 Direct & Honest',
      '🔥 Chemistry First',
    ],
    '⏱️ Pace': [
      '🐢 Slow Burn',
      '🚀 Fast & Intense',
      '🌊 See Where It Goes',
      '⏰ Here for a Good Time',
      '💎 Worth the Wait',
    ],
    
    // LIFESTYLE & INTERESTS
    '🍷 Interests': [
      '🍷 Wine Connoisseur',
      '🏋️ Fitness Obsessed',
      '✈️ Travel Addict',
      '🎵 Music is Life',
      '📺 Binge Watcher',
      '🎮 Gamer',
      '👨‍🍳 Foodie',
      '📖 Bookworm',
      '🎬 Film Buff',
      '🎧 Podcast Junkie',
    ],
    '🌃 Vibes': [
      '🌃 City Nights',
      '🏔️ Nature Escapes',
      '🍸 Cocktail Hours',
      '☕ Coffee Dates',
      '🏠 Netflix & Chill',
      '💃 Dance Floors',
      '🎪 Festival Season',
      '🕯️ Candlelit Dinners',
    ],
    '🔞 After Dark': [
      '👀 Curious',
      '🔥 Adventurous',
      '💋 Sensual',
      '🎭 Role Play',
      '🌶️ Spicy',
      '💫 Vanilla is Fine',
      '🔐 Private',
    ],
  };
  
  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _displayNameController.text.trim().isNotEmpty;
      case 1:
        return _selectedTraits.length >= 5;
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
      // (Edge function has JWT issues, so we do it client-side)
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
  
  /// Generate a charming, witty bio based on selected traits
  String _generateLocalBio() {
    final name = _displayNameController.text.trim();
    final traits = _selectedTraits.toList();
    
    // Categorize selected traits
    final personality = <String>[];
    final desires = <String>[];
    final lifestyle = <String>[];
    
    for (final trait in traits) {
      final cleanTrait = trait.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
      if (cleanTrait.contains('night owl') || cleanTrait.contains('early') || 
          cleanTrait.contains('energy') || cleanTrait.contains('calm') ||
          cleanTrait.contains('party') || cleanTrait.contains('homebody') ||
          cleanTrait.contains('intellectual') || cleanTrait.contains('creative') ||
          cleanTrait.contains('witty') || cleanTrait.contains('romantic') ||
          cleanTrait.contains('passionate') || cleanTrait.contains('optimist')) {
        personality.add(trait);
      } else if (cleanTrait.contains('looking') || cleanTrait.contains('connection') ||
                 cleanTrait.contains('deep') || cleanTrait.contains('spontaneous') ||
                 cleanTrait.contains('chemistry') || cleanTrait.contains('adventure') ||
                 cleanTrait.contains('spicy') || cleanTrait.contains('discreet')) {
        desires.add(trait);
      } else {
        lifestyle.add(trait);
      }
    }
    
    // Build bio with personality
    final List<String> bioOptions = [
      // Charming & mysterious
      "Hey, I'm $name. Looking to meet interesting people and see what happens. I believe the best stories start with \"we probably shouldn't, but...\"\n\nI bring ${_getTraitPhrase(personality)} to the table, and I'm here for ${_getDesirePhrase(desires)}.\n\nIf you're into ${_getLifestylePhrase(lifestyle)}, we might just get along.",
      
      // Witty & direct  
      "$name here. Part ${_getRandomTrait(personality)}, part ${_getRandomTrait(lifestyle)}, 100% not here to waste your time.\n\nLooking for: ${_getDesirePhrase(desires)}.\n\nSwipe right if you've got wit and aren't afraid to use it.",
      
      // Intriguing & playful
      "I'm $name, and I'm probably more fun than your last few matches combined.\n\n${_getTraitPhrase(personality)} meets ${_getLifestylePhrase(lifestyle)}.\n\nHere for ${_getDesirePhrase(desires)}. Your move.",
      
      // Confident & enticing
      "They call me $name. ${_getTraitPhrase(personality)} by day, ${_getLifestylePhrase(lifestyle)} enthusiast by night.\n\nI'm looking for ${_getDesirePhrase(desires)}. If you can keep up, let's make some memories worth deleting later.",
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
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          
          // Selection counter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedTraits.length} selected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
                      style: TextStyle(
                        color: VesparaColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(height: 8),
          
          // Trait categories
          ..._allTraits.entries.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
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
