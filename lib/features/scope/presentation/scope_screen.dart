import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/domain/models/roster_match.dart';

/// The Scope Screen - Discovery / Focus Batch
/// Web-safe version using PageView instead of CardSwiper
class ScopeScreen extends ConsumerStatefulWidget {
  const ScopeScreen({super.key});

  @override
  ConsumerState<ScopeScreen> createState() => _ScopeScreenState();
}

class _ScopeScreenState extends ConsumerState<ScopeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentIndex = 0;
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _nextCard() {
    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusBatch = ref.watch(focusBatchProvider);
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Focus Batch cards
            Expanded(
              child: focusBatch.when(
                data: (matches) => _buildFocusBatch(context, matches),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e'),
                ),
              ),
            ),
            
            // Action buttons
            _buildActionButtons(context),
            
            const SizedBox(height: VesparaSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              VesparaHaptics.lightTap();
              context.go('/home');
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VesparaColors.border),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: VesparaColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: VesparaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE SCOPE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Focus Batch • 5 Curated Matches',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.remove_red_eye_outlined,
              color: VesparaColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFocusBatch(BuildContext context, List<RosterMatch> matches) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                color: VesparaColors.secondary,
                size: 48,
              ),
            ),
            const SizedBox(height: VesparaSpacing.lg),
            Text(
              'No matches in your Focus Batch',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: VesparaSpacing.sm),
            Text(
              'Check back later for curated recommendations',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(matches.length, (index) {
              return Container(
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentIndex == index 
                    ? VesparaColors.primary 
                    : VesparaColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        
        // Cards
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: matches.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: _buildProfileCard(context, matches[index]),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfileCard(BuildContext context, RosterMatch match) {
    return Container(
      decoration: VesparaGlass.tagsCard,
      child: Column(
        children: [
          // Profile image placeholder
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: VesparaColors.surfaceElevated,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(VesparaBorderRadius.card),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: VesparaColors.secondary,
                  size: 80,
                ),
              ),
            ),
          ),
          
          // Profile info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(VesparaSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: VesparaSpacing.sm),
                  if (match.bio != null)
                    Text(
                      match.bio!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  // Tags
                  if (match.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: match.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: VesparaColors.glow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tag,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: VesparaColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VesparaSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          _buildActionButton(
            icon: Icons.close,
            color: VesparaColors.tagsRed,
            onTap: () {
              VesparaHaptics.lightTap();
              _nextCard();
            },
          ),
          
          // Super like button
          _buildActionButton(
            icon: Icons.star,
            color: VesparaColors.glow,
            size: 64,
            onTap: () {
              VesparaHaptics.heavyTap();
              _nextCard();
            },
          ),
          
          // Like button
          _buildActionButton(
            icon: Icons.favorite,
            color: VesparaColors.tagsGreen,
            onTap: () {
              VesparaHaptics.success();
              _nextCard();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VesparaColors.surface,
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }
}
