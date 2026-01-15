import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/haptics.dart';

/// OnboardingScreen: "The Interview" - 4-Card Progressive Disclosure
/// 
/// Card 1: Identity (Name + Birthday)
/// Card 2: Visuals (3 photos minimum)
/// Card 3: Vibe Tags (pick 3-5 personality markers)
/// Card 4: AI Bio (auto-generated from tags, user can edit)
/// 
/// Design: Swipeable cards with progress indicator
/// Target: Complete in under 60 seconds
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form data
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _birthDate;
  final List<XFile> _photos = [];
  final Map<String, Uint8List> _photoBytes = {}; // Cache for web compatibility
  final Set<String> _selectedTags = {};
  final _bioController = TextEditingController();
  bool _isGeneratingBio = false;

  // Vibe tags from database
  List<Map<String, dynamic>> _vibeTags = [];

  // Vespara Night Color Palette
  static const _background = Color(0xFF1A1523);
  static const _surface = Color(0xFF2D2640);
  static const _primary = Color(0xFFE0D8EA);
  static const _accent = Color(0xFFBFB3D2);
  static const _muted = Color(0xFF9A8EB5);
  static const _success = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadVibeTags();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Gets an ImageProvider for the photo at the given index
  /// Uses cached bytes for web compatibility
  ImageProvider? _getPhotoImage(int index) {
    if (index >= _photos.length) return null;
    final bytes = _photoBytes[_photos[index].path];
    if (bytes != null) {
      return MemoryImage(bytes);
    }
    return null;
  }

  Future<void> _loadVibeTags() async {
    try {
      final response = await Supabase.instance.client
          .from('vibe_tags')
          .select()
          .order('category')
          .order('display_order');
      
      setState(() {
        _vibeTags = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Failed to load vibe tags: $e');
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0: // Identity
        return _firstNameController.text.trim().isNotEmpty && 
               _birthDate != null &&
               _isAdult();
      case 1: // Photos
        return _photos.length >= 3;
      case 2: // Vibe Tags
        return _selectedTags.length >= 3 && _selectedTags.length <= 5;
      case 3: // Bio
        return _bioController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  bool _isAdult() {
    if (_birthDate == null) return false;
    final now = DateTime.now();
    final age = now.year - _birthDate!.year - 
        (now.month > _birthDate!.month || 
         (now.month == _birthDate!.month && now.day >= _birthDate!.day) ? 0 : 1);
    return age >= 18;
  }

  Future<void> _nextPage() async {
    if (!_canProceed()) return;
    
    HapticFeedback.lightImpact();
    
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      
      // Auto-generate bio when reaching the bio page
      if (_currentPage == 2) {
        _generateBio();
      }
    } else {
      // Complete onboarding
      await _completeOnboarding();
    }
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 6) return;
    
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _photos.add(image);
        _photoBytes[image.path] = bytes;
      });
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _takePhoto() async {
    if (_photos.length >= 6) return;
    
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _photos.add(image);
        _photoBytes[image.path] = bytes;
      });
      HapticFeedback.selectionClick();
    }
  }

  void _removePhoto(int index) {
    final path = _photos[index].path;
    setState(() {
      _photos.removeAt(index);
      _photoBytes.remove(path);
    });
    HapticFeedback.lightImpact();
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTags.contains(tagId)) {
        _selectedTags.remove(tagId);
      } else if (_selectedTags.length < 5) {
        _selectedTags.add(tagId);
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _generateBio() async {
    if (_isGeneratingBio) return;
    
    setState(() => _isGeneratingBio = true);
    
    try {
      final firstName = _firstNameController.text.trim();
      final selectedTagNames = _vibeTags
          .where((t) => _selectedTags.contains(t['id']))
          .map((t) => t['name'] as String)
          .toList();
      
      final response = await Supabase.instance.client.functions.invoke(
        'generate-bio',
        body: {
          'firstName': firstName,
          'tags': selectedTagNames,
        },
      );
      
      if (response.data != null && response.data['bio'] != null) {
        setState(() {
          _bioController.text = response.data['bio'];
        });
      }
    } catch (e) {
      debugPrint('Failed to generate bio: $e');
      // Fallback bio
      final firstName = _firstNameController.text.trim();
      setState(() {
        _bioController.text = 
            'Hey, I\'m $firstName. Looking to meet interesting people and create memorable experiences.';
      });
    } finally {
      setState(() => _isGeneratingBio = false);
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final uuid = const Uuid();
      
      // Upload photos
      final photoUrls = <String>[];
      for (int i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        final fileName = '${userId}/${uuid.v4()}.jpg';
        final bytes = await photo.readAsBytes();
        
        await supabase.storage.from('avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        
        final url = supabase.storage.from('avatars').getPublicUrl(fileName);
        photoUrls.add(url);
      }
      
      // Update profile
      await supabase.from('profiles').update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'birth_date': _birthDate!.toIso8601String().split('T')[0],
        'photos': photoUrls,
        'bio': _bioController.text.trim(),
        'vibe_tags': _selectedTags.toList(),
        'onboarding_complete': true,
        'avatar_url': photoUrls.isNotEmpty ? photoUrls.first : null,
      }).eq('id', userId);
      
      // Haptic celebration
      VesparaHaptics.success();
      
      if (mounted) {
        // Navigate to home with warp animation
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete setup: $e'),
            backgroundColor: Colors.red,
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
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildIdentityCard(),
                  _buildPhotosCard(),
                  _buildVibeTagsCard(),
                  _buildBioCard(),
                ],
              ),
            ),
            
            // Continue button
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentPage;
          final isComplete = index < _currentPage;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive ? _primary : _surface,
              ),
              child: isComplete
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _success,
                      ),
                    )
                  : null,
            ).animate(
              target: isActive ? 1 : 0,
            ).shimmer(duration: 1500.ms, color: _accent.withOpacity(0.3)),
          );
        }),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          
          Text(
            'Let\'s get to know you',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: _primary,
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: 8),
          
          Text(
            'This is how you\'ll appear to others',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: _muted,
            ),
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 48),
          
          // First Name
          _buildTextField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Iconsax.user,
            textCapitalization: TextCapitalization.words,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 16),
          
          // Last Name
          _buildTextField(
            controller: _lastNameController,
            label: 'Last Name (optional)',
            icon: Iconsax.user_tag,
            textCapitalization: TextCapitalization.words,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 24),
          
          // Birthday
          GestureDetector(
            onTap: _selectBirthDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.cake, color: _muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birthday',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _birthDate != null
                              ? '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}'
                              : 'Select your birthday',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: _birthDate != null ? _primary : _muted.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Iconsax.arrow_right_3, color: _muted),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          
          if (_birthDate != null && !_isAdult())
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'You must be 18 or older to use Vespara',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.redAccent,
                ),
              ),
            ).animate().fadeIn().shake(),
        ],
      ),
    );
  }

  Widget _buildPhotosCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          
          Text(
            'Show your best self',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: _primary,
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: 8),
          
          Text(
            'Add at least 3 photos • First photo is your avatar',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: _muted,
            ),
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 32),
          
          // Photo grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              if (index < _photos.length) {
                return _buildPhotoTile(index);
              } else if (index == _photos.length) {
                return _buildAddPhotoTile();
              } else {
                return _buildEmptyPhotoTile();
              }
            },
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 24),
          
          // Photo tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.info_circle, size: 18, color: _accent),
                    const SizedBox(width: 8),
                    Text(
                      'Photo Tips',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTip('Clear face shots work best'),
                _buildTip('Show your personality and interests'),
                _buildTip('Good lighting makes all the difference'),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildVibeTagsCard() {
    final groupedTags = <String, List<Map<String, dynamic>>>{};
    for (final tag in _vibeTags) {
      final category = tag['category'] as String;
      groupedTags.putIfAbsent(category, () => []).add(tag);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          
          Text(
            'What\'s your vibe?',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: _primary,
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: 8),
          
          Text(
            'Pick 3-5 tags that describe you • ${_selectedTags.length}/5 selected',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: _selectedTags.length >= 3 ? _success : _muted,
            ),
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 32),
          
          ...groupedTags.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCategory(entry.key),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.map((tag) {
                    final isSelected = _selectedTags.contains(tag['id']);
                    return GestureDetector(
                      onTap: () => _toggleTag(tag['id']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? _primary : _surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? _primary : _accent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tag['emoji'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tag['name'],
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? _background : _primary,
                              ),
                            ),
                          ],
                        ),
                      ).animate(
                        target: isSelected ? 1 : 0,
                      ).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 150.ms,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBioCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          
          Text(
            'Your story',
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: _primary,
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: 8),
          
          Text(
            'AI-crafted from your vibe • Feel free to edit',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: _muted,
            ),
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 32),
          
          if (_isGeneratingBio)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(_primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Crafting your bio...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().shimmer(duration: 1500.ms)
          else
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _bioController,
                maxLines: 5,
                maxLength: 200,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: _primary,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Write something about yourself...',
                  hintStyle: TextStyle(color: _muted.withOpacity(0.7)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  counterStyle: TextStyle(color: _muted),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 16),
          
          // Regenerate button
          if (!_isGeneratingBio)
            TextButton.icon(
              onPressed: _generateBio,
              icon: Icon(Iconsax.magic_star, color: _accent),
              label: Text(
                'Regenerate with AI',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: _accent,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 48),
          
          // Preview card
          Text(
            'Preview',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _muted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_surface, _surface.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar preview
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _background,
                        image: _photos.isNotEmpty && _getPhotoImage(0) != null
                            ? DecorationImage(
                                image: _getPhotoImage(0)!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _photos.isEmpty
                          ? Icon(Iconsax.user, color: _muted)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _firstNameController.text.isNotEmpty
                                ? _firstNameController.text
                                : 'Your Name',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: _selectedTags.take(3).map((tagId) {
                              final tag = _vibeTags.firstWhere(
                                (t) => t['id'] == tagId,
                                orElse: () => {'emoji': '✨'},
                              );
                              return Text(
                                tag['emoji'] ?? '✨',
                                style: const TextStyle(fontSize: 14),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _bioController.text.isNotEmpty
                      ? _bioController.text
                      : 'Your bio will appear here...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: _bioController.text.isNotEmpty ? _primary : _muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final canProceed = _canProceed();
    final isLastPage = _currentPage == 3;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: canProceed && !_isLoading ? _nextPage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: _background,
            disabledBackgroundColor: _surface,
            disabledForegroundColor: _muted,
            elevation: 0,
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
                    valueColor: AlwaysStoppedAnimation(_background),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'Complete Setup' : 'Continue',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastPage ? Iconsax.tick_circle : Iconsax.arrow_right_3,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    ).animate(target: canProceed ? 1 : 0).scale(
      begin: const Offset(0.98, 0.98),
      end: const Offset(1, 1),
      duration: 200.ms,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: textCapitalization,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: _primary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _muted),
          prefixIcon: Icon(icon, color: _muted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _primary,
              surface: _surface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() => _birthDate = date);
      HapticFeedback.selectionClick();
    }
  }

  Widget _buildPhotoTile(int index) {
    final imageProvider = _getPhotoImage(index);
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: imageProvider != null
                ? DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
        if (index == 0)
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Avatar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _background,
                ),
              ),
            ),
          ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _background.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 16, color: _primary),
            ),
          ),
        ),
      ],
    ).animate().fadeIn().scale();
  }

  Widget _buildAddPhotoTile() {
    return GestureDetector(
      onTap: () => _showPhotoOptions(),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.add, size: 32, color: _accent),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildEmptyPhotoTile() {
    return Container(
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.1)),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _muted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Icon(Iconsax.camera, color: _primary),
                  title: Text('Take Photo', style: TextStyle(color: _primary)),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                ListTile(
                  leading: Icon(Iconsax.gallery, color: _primary),
                  title: Text('Choose from Gallery', style: TextStyle(color: _primary)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Iconsax.tick_circle, size: 14, color: _success),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory(String category) {
    return category.replaceAll('_', ' ').toUpperCase();
  }
}
