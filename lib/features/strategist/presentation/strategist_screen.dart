import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/motion.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/data/strategist_repository.dart';
import '../../../core/services/openai_service.dart';

/// The Strategist Screen - AI Planning & Tonight Mode
/// 
/// PHASE 2: Connected to StrategistRepository with real location services
class StrategistScreen extends ConsumerStatefulWidget {
  const StrategistScreen({super.key});

  @override
  ConsumerState<StrategistScreen> createState() => _StrategistScreenState();
}

class _StrategistScreenState extends ConsumerState<StrategistScreen> {
  String? _strategicAdvice;
  bool _isLoadingAdvice = false;
  bool _isTogglingMode = false;
  
  Future<void> _loadStrategicAdvice() async {
    setState(() {
      _isLoadingAdvice = true;
    });
    
    try {
      final analytics = await ref.read(userAnalyticsProvider.future);
      if (analytics != null) {
        final advice = await OpenAIService.generateStrategicAdvice(
          optimizationScore: analytics.optimizationScore,
          activeMatches: analytics.activeConversations,
          staleMatches: analytics.staleMatches,
          responseRate: analytics.responseRate,
        );
        setState(() {
          _strategicAdvice = advice;
        });
      }
    } catch (e) {
      setState(() {
        _strategicAdvice = 'Unable to generate advice. Check your connection.';
      });
    } finally {
      setState(() {
        _isLoadingAdvice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // PHASE 2: Use real-time Tonight Mode state from repository
    final isTonightMode = ref.watch(tonightModeStateProvider);
    final optimizationScore = ref.watch(optimizationScoreProvider);
    final nearbyMatches = ref.watch(nearbyUsersProvider);
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(VesparaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Optimization Score Card
                    _buildOptimizationCard(context, optimizationScore),
                    
                    const SizedBox(height: VesparaSpacing.lg),
                    
                    // Tonight Mode Card
                    _buildTonightModeCard(context, isTonightMode),
                    
                    // Nearby matches (when Tonight Mode is ON)
                    if (isTonightMode) ...[
                      const SizedBox(height: VesparaSpacing.lg),
                      _buildNearbyMatchesSection(context, nearbyMatches),
                    ],
                    
                    const SizedBox(height: VesparaSpacing.lg),
                    
                    // Strategic Advice Card
                    _buildAdviceCard(context),
                  ],
                ),
              ),
            ),
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
                  'THE STRATEGIST',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'AI-Powered Planning',
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
              Icons.auto_awesome,
              color: VesparaColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptimizationCard(
    BuildContext context,
    AsyncValue<double> score,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: VesparaGlass.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPTIMIZATION SCORE',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              letterSpacing: 2,
              color: VesparaColors.secondary,
            ),
          ),
          const SizedBox(height: VesparaSpacing.md),
          score.when(
            data: (value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '%',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VesparaSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 8,
                    backgroundColor: VesparaColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(value),
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('--'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTonightModeCard(BuildContext context, bool isEnabled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: VesparaGlass.tile.copyWith(
        gradient: isEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VesparaColors.glow.withOpacity(0.15),
                  VesparaColors.surface,
                ],
              )
            : null,
        border: isEnabled
            ? Border.all(color: VesparaColors.glow.withOpacity(0.5))
            : Border.all(color: VesparaColors.border),
      ),
      child: Row(
        children: [
          // PHASE 5: Breathing animation for Tonight Mode beacon
          BreathingWidget(
            duration: const Duration(seconds: 3),
            minOpacity: isEnabled ? 0.8 : 1.0,
            maxScale: isEnabled ? 1.05 : 1.0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? VesparaColors.glow.withOpacity(0.2)
                    : VesparaColors.background.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.nightlight_round,
                color: isEnabled ? VesparaColors.primary : VesparaColors.inactive,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: VesparaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TONIGHT MODE',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    letterSpacing: 2,
                    color: isEnabled
                        ? VesparaColors.primary
                        : VesparaColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? 'Scanning for nearby matches...'
                      : 'Enable to discover who\'s out tonight',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: _isTogglingMode ? null : (value) async {
              // PHASE 5: Heavy haptic for Tonight Mode toggle
              VesparaHaptics.tonightModeToggle();
              setState(() => _isTogglingMode = true);
              
              // PHASE 2: Use repository to toggle with real location
              final success = await ref.read(tonightModeStateProvider.notifier).toggle();
              
              if (mounted) {
                setState(() => _isTogglingMode = false);
                
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to enable Tonight Mode. Check location permissions.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildNearbyMatchesSection(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> matches,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: VesparaGlass.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: VesparaColors.glow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'NEARBY TONIGHT',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  letterSpacing: 2,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.md),
          matches.when(
            data: (list) => list.isEmpty
                ? Text(
                    'No matches nearby right now',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: list.take(5).map((user) {
                      final avatarUrl = user['avatar_url'] as String?;
                      final name = user['display_name'] as String? ?? 'Unknown';
                      final distance = user['distance_km'] as num? ?? 0;
                      
                      return Tooltip(
                        message: '$name - ${distance.toStringAsFixed(1)}km away',
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: VesparaColors.surface,
                            border: Border.all(
                              color: VesparaColors.glow.withOpacity(0.5),
                            ),
                            image: avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(avatarUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: avatarUrl == null
                              ? const Icon(
                                  Icons.person,
                                  color: VesparaColors.secondary,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => Text(
              'Unable to fetch nearby matches',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdviceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: VesparaGlass.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STRATEGIC ADVICE',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  letterSpacing: 2,
                  color: VesparaColors.secondary,
                ),
              ),
              GestureDetector(
                onTap: _isLoadingAdvice ? null : _loadStrategicAdvice,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VesparaColors.glow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoadingAdvice
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.refresh,
                          color: VesparaColors.primary,
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.md),
          Text(
            _strategicAdvice ?? 'Tap refresh to get personalized advice from your AI strategist.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    if (score >= 80) return VesparaColors.tagsGreen;
    if (score >= 50) return VesparaColors.tagsYellow;
    return VesparaColors.tagsRed;
  }
}
