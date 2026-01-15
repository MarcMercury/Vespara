import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';

/// OnboardingScreen - Simplified version for web
/// Collects basic profile info before showing the main app
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  
  // Form data
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final Set<String> _selectedTags = {};
  
  // Available vibe tags
  final List<String> _vibeTags = [
    '🌙 Night Owl',
    '☀️ Early Bird',
    '🎨 Creative',
    '💼 Ambitious',
    '🏃 Active',
    '📚 Intellectual',
    '🎉 Social',
    '🏠 Homebody',
    '🌍 Adventurer',
    '💝 Romantic',
    '😂 Funny',
    '🧘 Spiritual',
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _firstNameController.text.isNotEmpty;
      case 1:
        return _selectedTags.length >= 3;
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
    } else {
      _completeOnboarding();
    }
  }
  
  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No user found');
      
      // Upsert profile with onboarding data
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'bio': _bioController.text.trim().isEmpty 
            ? 'New to Vespara ✨' 
            : _bioController.text.trim(),
        'vibe_tags': _selectedTags.toList(),
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Force a rebuild of the AuthGate by triggering auth state
      // The AuthGate will re-check onboarding status
      if (mounted) {
        // Navigate by triggering a state change
        // Since AuthGate listens for profile changes, we just need to rebuild
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'THE INTERVIEW',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 4,
                      color: VesparaColors.primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tell us about yourself',
                    style: TextStyle(
                      fontSize: 14,
                      color: VesparaColors.secondary,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        width: index == _currentPage ? 32 : 12,
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
                  _buildIdentityPage(),
                  _buildVibeTagsPage(),
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
                          _currentPage == 2 ? 'ENTER VESPARA' : 'CONTINUE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
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
  
  Widget _buildIdentityPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24),
          
          Text(
            'What should we call you?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          
          SizedBox(height: 32),
          
          // First name
          TextField(
            controller: _firstNameController,
            style: TextStyle(color: VesparaColors.primary, fontSize: 18),
            decoration: InputDecoration(
              labelText: 'First Name *',
              labelStyle: TextStyle(color: VesparaColors.secondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: VesparaColors.surface),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: VesparaColors.primary),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          
          SizedBox(height: 24),
          
          // Last name
          TextField(
            controller: _lastNameController,
            style: TextStyle(color: VesparaColors.primary, fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Last Name (optional)',
              labelStyle: TextStyle(color: VesparaColors.secondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: VesparaColors.surface),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: VesparaColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVibeTagsPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24),
          
          Text(
            'Pick your vibe',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          
          SizedBox(height: 8),
          
          Text(
            'Select at least 3 that describe you',
            style: TextStyle(
              fontSize: 14,
              color: VesparaColors.secondary,
            ),
          ),
          
          SizedBox(height: 24),
          
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _vibeTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? VesparaColors.primary : VesparaColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? VesparaColors.primary 
                            : VesparaColors.surface,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected 
                            ? VesparaColors.background 
                            : VesparaColors.primary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: 16),
          
          Text(
            '${_selectedTags.length} / 3+ selected',
            style: TextStyle(
              fontSize: 12,
              color: _selectedTags.length >= 3 
                  ? VesparaColors.success 
                  : VesparaColors.secondary,
            ),
          ),
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
          SizedBox(height: 24),
          
          Text(
            'Your bio',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: VesparaColors.primary,
            ),
          ),
          
          SizedBox(height: 8),
          
          Text(
            'Write a short intro (optional)',
            style: TextStyle(
              fontSize: 14,
              color: VesparaColors.secondary,
            ),
          ),
          
          SizedBox(height: 24),
          
          Expanded(
            child: TextField(
              controller: _bioController,
              style: TextStyle(color: VesparaColors.primary, fontSize: 16),
              maxLines: null,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Tell people a little about yourself...',
                hintStyle: TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: VesparaColors.surface),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: VesparaColors.surface),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: VesparaColors.primary),
                ),
                filled: true,
                fillColor: VesparaColors.surface,
                counterStyle: TextStyle(color: VesparaColors.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
