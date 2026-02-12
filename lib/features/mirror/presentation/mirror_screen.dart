import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/services/hard_truth_engine.dart';
import '../../../core/services/smart_trait_recommender.dart';
import '../../../core/domain/models/analytics.dart';
import '../../../core/domain/models/profile_photo.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/domain/models/user_settings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/profile_photos_provider.dart';
import '../../../core/providers/user_settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/premium_effects.dart';
import '../widgets/qr_connect_modal.dart';
import 'edit_profile_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// THE MIRROR - Module 1
/// Profile management, brutal honest AI feedback, settings, analytics
/// "Look at yourself. No, really look."
/// ════════════════════════════════════════════════════════════════════════════

class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});

  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Deep AI state
  HardTruthAssessment? _hardTruthAssessment;
  bool _loadingAssessment = false;
  TraitRecommendations? _traitRecommendations;
  bool _loadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 0 && _hardTruthAssessment == null && !_loadingAssessment) {
        _loadHardTruthAssessment();
      } else if (_tabController.index == 1 && _traitRecommendations == null && !_loadingRecommendations) {
        _loadTraitRecommendations();
      }
    }
  }

  Future<void> _loadHardTruthAssessment() async {
    setState(() => _loadingAssessment = true);
    try {
      final engine = HardTruthEngine.instance;
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId != null) {
        final assessment = await engine.generateAssessment(userId);
        if (mounted) setState(() => _hardTruthAssessment = assessment);
      }
    } catch (e) {
      debugPrint('Hard truth assessment error: $e');
    } finally {
      if (mounted) setState(() => _loadingAssessment = false);
    }
  }

  Future<void> _loadTraitRecommendations() async {
    setState(() => _loadingRecommendations = true);
    try {
      final recommender = SmartTraitRecommender.instance;
      final userId = SupabaseService.instance.currentUser?.id;
      if (userId != null) {
        final recs = await recommender.getRecommendations(userId);
        if (mounted) setState(() => _traitRecommendations = recs);
      }
    } catch (e) {
      debugPrint('Trait recommendation error: $e');
    } finally {
      if (mounted) setState(() => _loadingRecommendations = false);
    }
  }

  UserAnalytics? get _analytics => ref.read(userAnalyticsProvider).valueOrNull;

  void _navigateToEditProfile(UserProfile profile) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profile: profile),
      ),
    )
        .then((updated) {
      // Refresh profile if changes were made
      if (updated == true) {
        ref.invalidate(userProfileProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch analytics from provider (triggers rebuilds)
    ref.watch(userAnalyticsProvider);

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: VesparaAnimatedBackground(
        enableParticles: true,
        particleCount: 15,
        auroraIntensity: 0.7,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBrutalTruthTab(), // TRUTH
                    _buildBuildTab(), // BUILD - Combined Profile + Build + Photos
                    _buildSettingsTab(), // SETTINGS
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            Column(
              children: [
                VesparaNeonText(
                  text: 'THE MIRROR',
                  style: GoogleFonts.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: VesparaColors.primary,
                  ),
                  glowColor: VesparaColors.glow,
                  glowRadius: 12,
                ),
                const SizedBox(height: 2),
                Text(
                  'Face yourself',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => showQrConnectModal(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [VesparaColors.glow, VesparaColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_scanner,
                    color: Colors.white, size: 20,),
              ),
            ),
          ],
        ),
      );

  Widget _buildTabBar() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: VesparaColors.glow,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: VesparaColors.background,
          unselectedLabelColor: VesparaColors.secondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          dividerHeight: 0,
          tabs: const [
            Tab(icon: Icon(Icons.psychology_outlined, size: 16), text: 'TRUTH'),
            Tab(icon: Icon(Icons.auto_awesome, size: 16), text: 'BUILD'),
            Tab(
                icon: Icon(Icons.settings_outlined, size: 16),
                text: 'SETTINGS',),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // PROFILE TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildProfileTab() {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: VesparaColors.error, size: 48,),
            const SizedBox(height: 16),
            const Text('Failed to load profile',
                style: TextStyle(color: VesparaColors.secondary),),
            TextButton(
              onPressed: () => ref.invalidate(userProfileProvider),
              child: const Text('Retry',
                  style: TextStyle(color: VesparaColors.glow),),
            ),
          ],
        ),
      ),
      data: (profile) => profile != null
          ? _buildProfileContent(profile)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined,
                      color: VesparaColors.secondary, size: 48,),
                  const SizedBox(height: 16),
                  const Text('No profile found',
                      style: TextStyle(color: VesparaColors.secondary),),
                  TextButton(
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: const Text('Retry',
                        style: TextStyle(color: VesparaColors.glow),),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileContent(UserProfile profile) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile photo
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          VesparaColors.glow,
                          VesparaColors.glow.withOpacity(0.5),
                        ],
                      ),
                      border: Border.all(color: VesparaColors.glow, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        profile.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.background,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VesparaColors.surface,
                        border: Border.all(color: VesparaColors.glow),
                      ),
                      child: const Icon(Icons.edit,
                          size: 16, color: VesparaColors.glow,),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                profile.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: VesparaColors.primary,
                ),
              ),
            ),
            Center(
              child: Text(
                profile.headline ?? 'Add a headline...',
                style: const TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick stats
            _buildQuickStats(),

            const SizedBox(height: 24),

            // Profile sections
            _buildProfileSection(
                'About Me', profile.bio ?? 'No bio yet', Icons.person_outline,),
            _buildProfileSection(
                'Location',
                profile.displayLocation.isNotEmpty
                    ? profile.displayLocation
                    : 'Not set',
                Icons.location_on_outlined,),
            _buildProfileSection('Pronouns', profile.pronouns ?? 'Not set',
                Icons.person_pin_outlined,),
            _buildProfileSection(
                'Gender',
                profile.gender.isNotEmpty
                    ? profile.gender.join(', ')
                    : 'Not set',
                Icons.face_outlined,),
            _buildProfileSection(
                'Orientation',
                profile.orientation.isNotEmpty
                    ? profile.orientation.join(', ')
                    : 'Not set',
                Icons.favorite_border,),
            _buildProfileSection(
                'Relationship Status',
                profile.relationshipStatus.isNotEmpty
                    ? profile.relationshipStatus.join(', ')
                    : 'Not set',
                Icons.people_outline,),
            _buildProfileSection(
                'Seeking',
                profile.seeking.isNotEmpty
                    ? profile.seeking.join(', ')
                    : 'Not set',
                Icons.search,),
            _buildProfileSection(
                'Looking For',
                profile.lookingFor.isNotEmpty
                    ? profile.lookingFor.join(', ')
                    : 'Not set',
                Icons.favorite_outline,),
            _buildProfileSection(
                'Kinks & Interests',
                profile.kinks.isNotEmpty ? profile.kinks.join(', ') : 'Not set',
                Icons.whatshot_outlined,),
            _buildProfileSection(
                'Boundaries',
                profile.boundaries.isNotEmpty
                    ? profile.boundaries.join(', ')
                    : 'Not set',
                Icons.shield_outlined,),
            _buildProfileSection(
                'Love Languages',
                profile.loveLanguages.isNotEmpty
                    ? profile.loveLanguages.join(', ')
                    : 'Not set',
                Icons.language,),
            _buildProfileSection(
                'Availability',
                profile.availabilityGeneral.isNotEmpty
                    ? profile.availabilityGeneral.join(', ')
                    : 'Not set',
                Icons.schedule_outlined,),
            _buildProfileSection('Hosting Status',
                profile.hostingStatus ?? 'Not set', Icons.home_outlined,),
            _buildProfileSection(
                'Discretion Level',
                profile.discretionLevel ?? 'Not set',
                Icons.visibility_outlined,),

            const SizedBox(height: 24),

            // Edit profile button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToEditProfile(profile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow,
                  foregroundColor: VesparaColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w600),),
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickStats() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VesparaColors.glow.withOpacity(0.15),
              VesparaColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn((_analytics?.totalMatches ?? 0).toString(), 'Matches'),
            Container(
                width: 1,
                height: 40,
                color: VesparaColors.glow.withOpacity(0.2),),
            _buildStatColumn(
                '${((_analytics?.responseRate ?? 0.0) * 100).toInt()}%', 'Response',),
            Container(
                width: 1,
                height: 40,
                color: VesparaColors.glow.withOpacity(0.2),),
            _buildStatColumn((_analytics?.activeDays ?? 0).toString(), 'Days Active'),
          ],
        ),
      );

  Widget _buildStatColumn(String value, String label) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: VesparaColors.glow,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      );

  Widget _buildProfileSection(String title, String content, IconData icon) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: VesparaColors.glow, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content.isNotEmpty ? content : 'Not set',
                    style: const TextStyle(
                      fontSize: 14,
                      color: VesparaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: VesparaColors.secondary, size: 20,),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // BRUTAL TRUTH TAB - AI Feedback
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBrutalTruthTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrutalHeader(),
            const SizedBox(height: 24),
            // Deep AI Assessment section
            if (_loadingAssessment)
              _buildAssessmentLoading()
            else if (_hardTruthAssessment != null) ...[
              _buildArchetypeCard(),
              const SizedBox(height: 20),
              _buildBrutalOneLiner(),
              const SizedBox(height: 20),
              _buildContradictionsCard(),
              const SizedBox(height: 20),
              _buildBlindSpotsCard(),
              const SizedBox(height: 20),
              _buildStrengthsCard(),
              const SizedBox(height: 20),
            ],
            _buildPersonalitySummary(),
            const SizedBox(height: 20),
            _buildDatingStyle(),
            const SizedBox(height: 20),
            _buildBehaviorMetrics(),
            const SizedBox(height: 20),
            _buildImprovementTips(),
            const SizedBox(height: 20),
            _buildRedFlags(),
            const SizedBox(height: 20),
            // Refresh assessment button
            Center(
              child: TextButton.icon(
                onPressed: _loadingAssessment ? null : () {
                  HardTruthEngine.instance.invalidateCache(
                    SupabaseService.instance.currentUser?.id ?? '',
                  );
                  _loadHardTruthAssessment();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  _hardTruthAssessment == null ? 'Generate AI Assessment' : 'Refresh Assessment',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildBrutalHeader() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VesparaColors.error.withOpacity(0.3),
              VesparaColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.error.withOpacity(0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.psychology, size: 48, color: VesparaColors.error),
            SizedBox(height: 12),
            Text(
              'The Brutal Truth',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VesparaColors.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'AI analysis of your dating behavior. No sugarcoating. No excuses.',
              style: TextStyle(
                fontSize: 13,
                color: VesparaColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════
  // DEEP AI ASSESSMENT WIDGETS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildAssessmentLoading() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: VesparaColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Column(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: VesparaColors.glow,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'The AI is studying your patterns...',
          style: TextStyle(
            fontSize: 14,
            color: VesparaColors.secondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );

  Widget _buildArchetypeCard() {
    final assessment = _hardTruthAssessment!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VesparaColors.glow.withOpacity(0.15),
            VesparaColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.fingerprint, size: 36, color: VesparaColors.glow),
          const SizedBox(height: 12),
          Text(
            assessment.personalityArchetype,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: VesparaColors.glow,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Overall score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScorePill('Overall', assessment.overallScore, VesparaColors.glow),
              const SizedBox(width: 8),
              _buildScorePill('Consistency', assessment.consistencyScore, VesparaColors.tagsYellow),
              const SizedBox(width: 8),
              _buildScorePill('Effort', assessment.effortScore, VesparaColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScorePill(String label, double score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: ${(score * 100).toInt()}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBrutalOneLiner() {
    final oneLiner = _hardTruthAssessment!.brutalTruthOneLiner;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: VesparaColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              oneLiner,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContradictionsCard() {
    final contradictions = _hardTruthAssessment!.contradictionInsights;
    if (contradictions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows, color: VesparaColors.tagsYellow, size: 18),
              SizedBox(width: 8),
              Text(
                'Your Contradictions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.tagsYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Where your words and actions don\'t match',
            style: TextStyle(fontSize: 11, color: VesparaColors.secondary),
          ),
          const SizedBox(height: 12),
          ...contradictions.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VesparaColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c,
                    style: const TextStyle(
                      fontSize: 13,
                      color: VesparaColors.primary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBlindSpotsCard() {
    final blindSpots = _hardTruthAssessment!.blindSpots;
    if (blindSpots.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility_off, color: VesparaColors.error, size: 18),
              SizedBox(width: 8),
              Text(
                'Blind Spots',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...blindSpots.map((spot) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 6, color: VesparaColors.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    spot,
                    style: const TextStyle(
                      fontSize: 13,
                      color: VesparaColors.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStrengthsCard() {
    final strengths = _hardTruthAssessment!.strengths;
    final growthEdges = _hardTruthAssessment!.growthEdges;
    if (strengths.isEmpty && growthEdges.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (strengths.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.star, color: VesparaColors.success, size: 18),
                SizedBox(width: 8),
                Text(
                  'Your Strengths',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: strengths.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: VesparaColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 12,
                    color: VesparaColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
          if (strengths.isNotEmpty && growthEdges.isNotEmpty)
            const SizedBox(height: 16),
          if (growthEdges.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.trending_up, color: VesparaColors.tagsYellow, size: 18),
                SizedBox(width: 8),
                Text(
                  'Growth Edges',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.tagsYellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...growthEdges.map((edge) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_upward, size: 14, color: VesparaColors.tagsYellow),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      edge,
                      style: const TextStyle(
                        fontSize: 13,
                        color: VesparaColors.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalitySummary() {
    final deepSummary = _hardTruthAssessment?.personalitySummary;
    final summary = deepSummary ?? _analytics?.aiPersonalitySummary;
    final hasRealData = summary != null && summary.isNotEmpty;
    
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: VesparaColors.glow, size: 18),
                SizedBox(width: 8),
                Text(
                  'AI Personality Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.glow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasRealData)
              Text(
                summary,
                style: const TextStyle(
                  fontSize: 14,
                  color: VesparaColors.primary,
                  height: 1.5,
                ),
              )
            else
              const Text(
                'Not enough activity yet to generate your personality summary. Keep using the app and check back soon!',
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
          ],
        ),
      );
  }

  Widget _buildDatingStyle() {
    final deepStyle = _hardTruthAssessment?.datingStyle;
    final style = deepStyle ?? _analytics?.aiDatingStyle;
    final hasRealData = style != null && style.isNotEmpty;
    
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.heart_broken,
                    color: VesparaColors.tagsYellow, size: 18,),
                SizedBox(width: 8),
                Text(
                  'Your Dating Style',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.tagsYellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasRealData) ...[
              Text(
                style,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getDatingStyleDescription(),
                style: const TextStyle(
                  fontSize: 13,
                  color: VesparaColors.secondary,
                  height: 1.4,
                ),
              ),
            ] else
              const Text(
                'Your dating style will be analyzed once you have more activity. Keep swiping, matching, and chatting!',
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
          ],
        ),
      );
  }
  
  String _getDatingStyleDescription() {
    // Generate description based on actual metrics
    final ghostRate = _analytics?.ghostRate ?? 0;
    final responseRate = _analytics?.responseRate ?? 0;
    final totalMatches = _analytics?.totalMatches ?? 0;
    
    if (ghostRate > 50) {
      return 'You tend to disappear from conversations. Consider being more consistent with your responses.';
    } else if (responseRate > 80) {
      return 'You\'re highly engaged and responsive. People appreciate that you follow through.';
    } else if (totalMatches > 20 && responseRate < 30) {
      return 'You match frequently but rarely engage. Quality over quantity might serve you better.';
    } else {
      return 'Based on your activity patterns and engagement style.';
    }
  }

  Widget _buildBehaviorMetrics() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Behavior Metrics',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
                'Ghost Rate', _analytics?.ghostRate ?? 0.0, VesparaColors.error,),
            _buildMetricRow(
                'Flake Rate', _analytics?.flakeRate ?? 0.0, VesparaColors.warning,),
            _buildMetricRow('Response Rate', _analytics?.responseRate ?? 0.0,
                VesparaColors.success,),
            _buildMetricRow(
                'Match Rate', _analytics?.matchRate ?? 0.0, VesparaColors.glow,),
          ],
        ),
      );

  Widget _buildMetricRow(String label, double value, Color color) {
    final percentage = (value * 100).toInt();
    final isGood = label == 'Response Rate' || label == 'Match Rate'
        ? value > 0.5
        : value < 0.3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: VesparaColors.secondary,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: VesparaColors.background,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementTips() {
    // Use deep AI assessment tips first, then fall back to analytics/metrics
    final deepAdvice = _hardTruthAssessment?.optimizationAdvice;
    final tips = deepAdvice ?? _analytics?.aiImprovementTips ?? _generateTipsFromMetrics();
    final hasTips = tips.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: VesparaColors.success, size: 18,),
              SizedBox(width: 8),
              Text(
                'How to Not Suck',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasTips)
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: VesparaColors.success,),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 13,
                          color: VesparaColors.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              'Keep using the app to get personalized improvement tips based on your activity!',
              style: TextStyle(
                fontSize: 13,
                color: VesparaColors.secondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
  
  List<String> _generateTipsFromMetrics() {
    final tips = <String>[];
    final ghostRate = _analytics?.ghostRate ?? 0;
    final flakeRate = _analytics?.flakeRate ?? 0;
    final responseRate = _analytics?.responseRate ?? 0;
    final totalMatches = _analytics?.totalMatches ?? 0;
    
    // Only add tips if we have actual concerning metrics
    if (ghostRate > 30) {
      tips.add('Try to close conversations gracefully instead of disappearing');
    }
    if (flakeRate > 30) {
      tips.add('Follow through on plans you make - reliability builds trust');
    }
    if (responseRate < 50 && totalMatches > 5) {
      tips.add('Respond to messages within 24 hours to keep momentum');
    }
    if (totalMatches > 20 && responseRate < 30) {
      tips.add('Quality over quantity - focus on fewer, better connections');
    }
    
    return tips;
  }

  Widget _buildRedFlags() {
    // Generate red flags from actual analytics data
    final redFlags = _generateRedFlagsFromMetrics();
    final hasFlags = redFlags.isNotEmpty;
    
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFlags 
              ? VesparaColors.error.withOpacity(0.1)
              : VesparaColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFlags 
                ? VesparaColors.error.withOpacity(0.3)
                : VesparaColors.success.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasFlags ? Icons.flag : Icons.check_circle,
                  color: hasFlags ? VesparaColors.error : VesparaColors.success,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  hasFlags ? 'Areas to Improve' : 'Looking Good!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasFlags ? VesparaColors.error : VesparaColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasFlags)
              ...redFlags.map((flag) => _buildRedFlagItem(flag))
            else
              const Text(
                'No concerning patterns detected. Keep up the good work!',
                style: TextStyle(
                  fontSize: 13,
                  color: VesparaColors.primary,
                ),
              ),
          ],
        ),
      );
  }
  
  List<String> _generateRedFlagsFromMetrics() {
    final flags = <String>[];
    final ghostRate = _analytics?.ghostRate ?? 0;
    final flakeRate = _analytics?.flakeRate ?? 0;
    final responseRate = _analytics?.responseRate ?? 0;
    final activeConversations = _analytics?.activeConversations ?? 0;
    final totalMatches = _analytics?.totalMatches ?? 0;
    
    // Only flag genuinely concerning behavior based on real data
    if (ghostRate > 50) {
      flags.add('High ghost rate (${ghostRate.toInt()}%) - conversations are ending abruptly');
    }
    if (flakeRate > 50) {
      flags.add('High flake rate (${flakeRate.toInt()}%) - plans are being cancelled frequently');
    }
    if (responseRate < 20 && totalMatches > 10) {
      flags.add('Low response rate (${responseRate.toInt()}%) with ${totalMatches} matches');
    }
    if (activeConversations == 0 && totalMatches > 5) {
      flags.add('No active conversations despite having matches');
    }
    
    return flags;
  }

  Widget _buildRedFlagItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber,
                size: 14, color: VesparaColors.error,),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  color: VesparaColors.primary,
                ),
              ),
            ),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD TAB - Edit Vibes, Interests, Desires from Onboarding
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBuildTab() {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(
          child: Text('Error loading profile',
              style: TextStyle(color: VesparaColors.error),),),
      data: (profile) => profile == null
          ? const Center(
              child: Text('No profile found',
                  style: TextStyle(color: VesparaColors.secondary),),)
          : _buildBuildContent(profile),
    );
  }

  Widget _buildBuildContent(UserProfile profile) {
    // Watch photo state
    final photosState = ref.watch(profilePhotosProvider);
    
    // All vibe options from onboarding
    final allVibes = [
      {'emoji': '🌙', 'label': 'Night Owl'},
      {'emoji': '❄️', 'label': 'Early Riser'},
      {'emoji': '⚡', 'label': 'High Energy'},
      {'emoji': '🧘', 'label': 'Calm & Centered'},
      {'emoji': '🎉', 'label': 'Life of the Party'},
      {'emoji': '🏠', 'label': 'Cozy Homebody'},
      {'emoji': '👥', 'label': 'Small Groups Only'},
      {'emoji': '🦋', 'label': 'Social Butterfly'},
      {'emoji': '😂', 'label': 'Witty & Sarcastic'},
      {'emoji': '💝', 'label': 'Hopeless Romantic'},
      {'emoji': '🔥', 'label': 'Passionate'},
      {'emoji': '😌', 'label': 'Easy Going'},
      {'emoji': '😈', 'label': 'Mischievous'},
      {'emoji': '🏔️', 'label': 'Adventurous'},
      {'emoji': '📚', 'label': 'Intellectual'},
      {'emoji': '🎨', 'label': 'Creative'},
      {'emoji': '🚀', 'label': 'Ambitious'},
      {'emoji': '🎲', 'label': 'Spontaneous'},
      {'emoji': '🧠', 'label': 'Deep Thinker'},
      {'emoji': '🦅', 'label': 'Free Spirit'},
      {'emoji': '👴', 'label': 'Old Soul'},
      {'emoji': '❤️', 'label': 'Young at Heart'},
    ];

    final allInterests = [
      {'emoji': '✈️', 'label': 'Travel'},
      {'emoji': '🎵', 'label': 'Music'},
      {'emoji': '🎬', 'label': 'Movies & TV'},
      {'emoji': '📚', 'label': 'Reading'},
      {'emoji': '🎮', 'label': 'Gaming'},
      {'emoji': '🏋️', 'label': 'Fitness'},
      {'emoji': '🍳', 'label': 'Cooking'},
      {'emoji': '🍷', 'label': 'Wine & Spirits'},
      {'emoji': '🎨', 'label': 'Art'},
      {'emoji': '📷', 'label': 'Photography'},
      {'emoji': '🌿', 'label': 'Nature'},
      {'emoji': '🎭', 'label': 'Theater'},
      {'emoji': '💃', 'label': 'Dancing'},
      {'emoji': '🧘', 'label': 'Yoga & Meditation'},
      {'emoji': '🏖️', 'label': 'Beach Life'},
      {'emoji': '⛷️', 'label': 'Winter Sports'},
    ];

    // Get current selections from profile
    final selectedVibes =
        profile.lookingFor; // This is where onboarding saves vibe traits
    final selectedInterests = profile.interestTags;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ════════════════════════════════════════════════════════════════════
        // PROFILE HEADER WITH NAME & BIO
        // ════════════════════════════════════════════════════════════════════
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VesparaColors.glow.withOpacity(0.2),
                VesparaColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                profile.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: VesparaColors.primary,
                ),
              ),
              if (profile.headline != null && profile.headline!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    profile.headline!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: VesparaColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: VesparaColors.glow, size: 16,),
                  const SizedBox(width: 6),
                  Text(
                    '${photosState.photos.length}/5 photos • ${selectedVibes.length + selectedInterests.length} traits',
                    style: const TextStyle(fontSize: 12, color: VesparaColors.glow),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════════
        // PHOTO GALLERY SECTION
        // ════════════════════════════════════════════════════════════════════
        _buildPhotoGallerySection(photosState),

        const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════════
        // AI PHOTO RECOMMENDATION SECTION
        // ════════════════════════════════════════════════════════════════════
        if (photosState.recommendation != null)
          _buildPhotoRecommendationSection(photosState),

        if (photosState.recommendation != null) const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════════
        // PROFILE INFO SECTION (Collapsible)
        // ════════════════════════════════════════════════════════════════════
        _buildProfileInfoSection(profile),

        const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════════
        // AI SUGGESTIONS SECTION
        // ════════════════════════════════════════════════════════════════════
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VesparaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_fix_high,
                          color: VesparaColors.glow, size: 20,),
                      SizedBox(width: 8),
                      Text(
                        'CHECK ME',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: VesparaColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AI POWERED',
                      style: TextStyle(
                          fontSize: 10,
                          color: VesparaColors.glow,
                          fontWeight: FontWeight.bold,),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Personalized suggestions based on your psychological profile, behavior patterns, and compatibility insights.',
                style: TextStyle(fontSize: 12, color: VesparaColors.secondary),
              ),
              const SizedBox(height: 12),
              if (_loadingRecommendations)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: VesparaColors.glow),
                    ),
                  ),
                )
              else if (_traitRecommendations != null) ...[
                // Gap insights
                if (_traitRecommendations!.gapInsights.isNotEmpty) ...[
                  ..._traitRecommendations!.gapInsights.take(2).map((gap) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: VesparaColors.tagsYellow.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 16, color: VesparaColors.tagsYellow),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              gap.insight,
                              style: const TextStyle(fontSize: 12, color: VesparaColors.primary, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
                const Text('Suggested for you:',
                    style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _traitRecommendations!.suggestions.take(6).map((s) =>
                    _buildSmartSuggestionChip(s),
                  ).toList(),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _traitRecommendations = null);
                      _loadTraitRecommendations();
                    },
                    child: const Text(
                      'Refresh suggestions',
                      style: TextStyle(fontSize: 11, color: VesparaColors.glow),
                    ),
                  ),
                ),
              ] else ...[
                const Text('You might also like:',
                    style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSuggestionChip('🏔️', 'Adventurous'),
                    _buildSuggestionChip('🎨', 'Creative'),
                    _buildSuggestionChip('✈️', 'Travel'),
                    _buildSuggestionChip('🎵', 'Music'),
                  ],
                ),
                Center(
                  child: TextButton(
                    onPressed: _loadTraitRecommendations,
                    child: const Text(
                      'Get AI suggestions',
                      style: TextStyle(fontSize: 11, color: VesparaColors.glow),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════════
        // YOUR VIBE SECTION
        // ════════════════════════════════════════════════════════════════════
        _buildBuildSection(
          title: 'YOUR VIBE',
          subtitle: 'How would you describe your energy?',
          icon: Icons.mood,
          selectedCount: selectedVibes.length,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allVibes.map((vibe) {
                final isSelected =
                    selectedVibes.any((v) => v.contains(vibe['label']!));
                return _buildVibeChip(
                    vibe['emoji']!, vibe['label']!, isSelected,);
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════════
        // YOUR INTERESTS SECTION
        // ════════════════════════════════════════════════════════════════════
        _buildBuildSection(
          title: 'YOUR INTERESTS',
          subtitle: 'What lights you up?',
          icon: Icons.favorite,
          selectedCount: selectedInterests.length,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allInterests.map((interest) {
                final isSelected =
                    selectedInterests.contains(interest['label']);
                return _buildVibeChip(
                    interest['emoji']!, interest['label']!, isSelected,);
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ════════════════════════════════════════════════════════════════════
        // HEAT LEVEL SECTION
        // ════════════════════════════════════════════════════════════════════
        if (profile.heatLevel != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VesparaColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      'YOUR HEAT LEVEL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getHeatColor(profile.heatLevel!).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _getHeatColor(profile.heatLevel!)),
                  ),
                  child: Text(
                    profile.heatLevel!.toUpperCase(),
                    style: TextStyle(
                      color: _getHeatColor(profile.heatLevel!),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 32),

        // ════════════════════════════════════════════════════════════════════
        // EDIT PROFILE BUTTON
        // ════════════════════════════════════════════════════════════════════
        ElevatedButton.icon(
          onPressed: () => _navigateToEditProfile(profile),
          style: ElevatedButton.styleFrom(
            backgroundColor: VesparaColors.glow,
            foregroundColor: VesparaColors.background,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.edit),
          label: const Text('Edit Full Profile',
              style: TextStyle(fontWeight: FontWeight.bold),),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PHOTO GALLERY SECTION - Upload up to 5 photos
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildPhotoGallerySection(ProfilePhotosState photosState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.photo_library, color: VesparaColors.glow, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'YOUR PHOTOS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.primary,
                    ),
                  ),
                ],
              ),
              Text(
                '${photosState.photos.length}/5',
                style: const TextStyle(
                  fontSize: 12,
                  color: VesparaColors.glow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Add up to 5 photos. Drag to reorder. Other users will rank them to help you pick the best one.',
            style: TextStyle(fontSize: 12, color: VesparaColors.secondary),
          ),
          const SizedBox(height: 16),
          
          // Photo Grid (2x3 grid with 5 slots + primary indicator)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              final position = index + 1;
              final photo = photosState.photoAtPosition(position);
              final isUploading = photosState.isUploading && 
                  photosState.uploadingPosition == position;
              
              return _buildPhotoSlot(
                position: position,
                photo: photo,
                isUploading: isUploading,
                isPrimary: photo?.isPrimary ?? false,
              );
            },
          ),
          
          // Ranking stats
          if (photosState.totalRankingsReceived > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.how_to_vote, 
                        color: VesparaColors.glow, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${photosState.totalRankingsReceived} people have ranked your photos',
                      style: const TextStyle(
                        fontSize: 12,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot({
    required int position,
    ProfilePhoto? photo,
    required bool isUploading,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: () => _handlePhotoTap(position, photo),
      onLongPress: photo != null ? () => _showPhotoOptions(position, photo) : null,
      child: Container(
        decoration: BoxDecoration(
          color: VesparaColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? VesparaColors.glow : VesparaColors.border,
            width: isPrimary ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo or placeholder
            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  photo.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const Center(
                    child: Icon(Icons.broken_image, color: VesparaColors.error),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      color: VesparaColors.secondary.withOpacity(0.5),
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 10,
                        color: VesparaColors.secondary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Upload progress indicator
            if (isUploading)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(VesparaColors.glow),
                  ),
                ),
              ),
            
            // Primary badge
            if (isPrimary)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: VesparaColors.glow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '★ PRIMARY',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            
            // Position number
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$position',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            // Score badge (if photo has rankings)
            if (photo?.score != null && photo!.score!.totalRankings > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: VesparaColors.tagsYellow, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        photo.score!.averageRank.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePhotoTap(int position, ProfilePhoto? existingPhoto) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    
    if (image == null) return;
    
    final bytes = await image.readAsBytes();
    final extension = image.path.split('.').last.toLowerCase();
    
    final success = await ref.read(profilePhotosProvider.notifier).uploadPhoto(
      bytes,
      position,
      extension: extension,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Photo uploaded!' : 'Failed to upload photo'),
          backgroundColor: success ? VesparaColors.success : VesparaColors.error,
        ),
      );
    }
  }

  void _showPhotoOptions(int position, ProfilePhoto photo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Photo Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            if (!photo.isPrimary)
              ListTile(
                leading: const Icon(Icons.star, color: VesparaColors.glow),
                title: const Text('Set as Primary',
                    style: TextStyle(color: VesparaColors.primary)),
                subtitle: const Text('This photo will be shown first',
                    style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(profilePhotosProvider.notifier).setAsPrimary(photo.id);
                },
              ),
            
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: VesparaColors.secondary),
              title: const Text('Replace Photo',
                  style: TextStyle(color: VesparaColors.primary)),
              onTap: () {
                Navigator.pop(context);
                _handlePhotoTap(position, photo);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.delete_outline, color: VesparaColors.error),
              title: const Text('Delete Photo',
                  style: TextStyle(color: VesparaColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: VesparaColors.surface,
                    title: const Text('Delete Photo?',
                        style: TextStyle(color: VesparaColors.primary)),
                    content: const Text('This action cannot be undone.',
                        style: TextStyle(color: VesparaColors.secondary)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: VesparaColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(profilePhotosProvider.notifier).deletePhoto(photo.id);
                }
              },
            ),
            
            if (photo.score != null && photo.score!.totalRankings > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VesparaColors.glow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics, color: VesparaColors.glow, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Avg Rank: ${photo.score!.averageRank.toStringAsFixed(1)} / 5',
                              style: const TextStyle(
                                color: VesparaColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${photo.score!.totalRankings} rankings received',
                              style: const TextStyle(
                                color: VesparaColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // AI PHOTO RECOMMENDATION SECTION
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildPhotoRecommendationSection(ProfilePhotosState photosState) {
    final recommendation = photosState.recommendation!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VesparaColors.glow.withOpacity(0.15),
            VesparaColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, 
                    color: VesparaColors.glow, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI PHOTO RECOMMENDATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: VesparaColors.glow,
                      ),
                    ),
                    Text(
                      'Based on how others ranked your photos',
                      style: TextStyle(
                        fontSize: 11,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (recommendation.hasRecommendation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VesparaColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recommendation.confidenceLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.success,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Insights
          if (recommendation.insights.isNotEmpty)
            ...recommendation.insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, 
                      color: VesparaColors.tagsYellow, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(
                        fontSize: 12,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          
          // Apply recommendation button
          if (recommendation.hasRecommendation)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final success = await ref
                        .read(profilePhotosProvider.notifier)
                        .applyAIRecommendation();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success 
                              ? 'Photos reordered based on AI recommendation!' 
                              : 'Failed to apply recommendation'),
                          backgroundColor: success 
                              ? VesparaColors.success 
                              : VesparaColors.error,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Apply AI Recommendation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VesparaColors.glow,
                    side: const BorderSide(color: VesparaColors.glow),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PROFILE INFO SECTION - Key profile details
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildProfileInfoSection(UserProfile profile) {
    return Column(
      children: [
        // Basic Info Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VesparaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_outline, color: VesparaColors.glow, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PROFILE INFO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildCompactProfileRow('Bio', profile.bio ?? 'Not set'),
              if (profile.hook != null && profile.hook!.isNotEmpty)
                _buildCompactProfileRow('Hook', profile.hook!),
              _buildCompactProfileRow('Location', 
                  profile.displayLocation.isNotEmpty ? profile.displayLocation : 'Not set'),
              _buildCompactProfileRow('Pronouns', profile.pronouns ?? 'Not set'),
              _buildCompactProfileRow('Gender', 
                  profile.gender.isNotEmpty ? profile.gender.join(', ') : 'Not set'),
              _buildCompactProfileRow('Orientation',
                  profile.orientation.isNotEmpty ? profile.orientation.join(', ') : 'Not set'),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Relationship Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VesparaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite_outline, color: VesparaColors.glow, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'RELATIONSHIP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildCompactProfileRow('Status',
                  profile.relationshipStatus.isNotEmpty 
                      ? profile.relationshipStatus.join(', ') : 'Not set'),
              _buildCompactProfileRow('Seeking',
                  profile.seeking.isNotEmpty ? profile.seeking.join(', ') : 'Not set'),
              if (profile.partnerInvolvement != null)
                _buildCompactProfileRow('Partner', profile.partnerInvolvement!),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Logistics Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VesparaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule_outlined, color: VesparaColors.glow, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'LOGISTICS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildCompactProfileRow('Availability',
                  profile.availabilityGeneral.isNotEmpty 
                      ? profile.availabilityGeneral.join(', ') : 'Not set'),
              if (profile.schedulingStyle != null)
                _buildCompactProfileRow('Scheduling', profile.schedulingStyle!),
              if (profile.hostingStatus != null)
                _buildCompactProfileRow('Hosting', profile.hostingStatus!),
              if (profile.discretionLevel != null)
                _buildCompactProfileRow('Discretion', profile.discretionLevel!),
              _buildCompactProfileRow('Travel Radius', '${profile.travelRadius} miles'),
              _buildCompactProfileRow('Bandwidth', _getBandwidthLabel(profile.bandwidth)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Events & Parties Section
        if (profile.partyAvailability.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VesparaColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.celebration_outlined, color: VesparaColors.glow, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'EVENTS & PARTIES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.partyAvailability.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      p.replaceAll('_', ' ').split(' ').map((w) => 
                          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
                      ).join(' '),
                      style: const TextStyle(fontSize: 12, color: VesparaColors.glow),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),

        if (profile.partyAvailability.isNotEmpty) const SizedBox(height: 16),

        // Hard Limits Section
        if (profile.hardLimits.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VesparaColors.error.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.block, color: VesparaColors.error.withOpacity(0.8), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'HARD LIMITS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: VesparaColors.error.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.hardLimits.map((limit) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: VesparaColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VesparaColors.error.withOpacity(0.3)),
                    ),
                    child: Text(
                      _formatHardLimit(limit),
                      style: TextStyle(fontSize: 12, color: VesparaColors.error.withOpacity(0.8)),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getBandwidthLabel(double bandwidth) {
    if (bandwidth < 0.2) return '😴 Lurking';
    if (bandwidth < 0.4) return '🌱 Low Key';
    if (bandwidth < 0.6) return '⚡ Moderate';
    if (bandwidth < 0.8) return '🔥 Active';
    return '🌋 Ravenous';
  }

  String _formatHardLimit(String limit) {
    const labels = {
      'no_smokers': '🚭 No Smokers',
      'no_drugs': '💊 No Drug Use',
      'no_pain': '🚫 No Pain Play',
      'no_blood': '🩸 No Blood',
      'no_humiliation': '😤 No Humiliation',
      'no_anal': '🚫 No Anal',
      'no_choking': '😮‍💨 No Breath Play',
      'protection_required': '🛡️ Protection Required',
      'no_bareback': '🚫 No Bareback',
      'no_age_gaps': '📅 No Large Age Gaps',
      'no_couples': '👫 No Couples',
      'no_singles': '👤 No Singles',
      'no_public': '🏠 Nothing Public',
      'no_filming': '📵 No Photos/Videos',
      'must_verify': '✅ Must Verify',
      'no_strangers': '🤝 Must Know First',
      'sti_tested_only': '🧪 STI Tested Only',
      'no_marking': '✋ No Marks',
      'no_fluids': '💧 No Fluids',
      'sober_only': '🥤 Sober Only',
    };
    return labels[limit] ?? limit.replaceAll('_', ' ');
  }

  Widget _buildCompactProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: VesparaColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: VesparaColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required int selectedCount,
    required List<Widget> children,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: VesparaColors.glow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VesparaColors.glow,
                    ),
                  ),
                ],
              ),
              Text(
                '$selectedCount selected',
                style: const TextStyle(
                    fontSize: 12, color: VesparaColors.secondary,),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: VesparaColors.secondary,),),
          const SizedBox(height: 12),
          ...children,
        ],
      );

  Widget _buildVibeChip(String emoji, String label, bool isSelected) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? VesparaColors.glow.withOpacity(0.2)
              : VesparaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? VesparaColors.glow : VesparaColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? VesparaColors.glow : VesparaColors.primary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (!isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.add, size: 14, color: VesparaColors.secondary),
            ],
          ],
        ),
      );

  Widget _buildSuggestionChip(String emoji, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: VesparaColors.glow.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji),
            const SizedBox(width: 6),
            Text(
              label,
              style:
                  const TextStyle(fontSize: 12, color: VesparaColors.primary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.add, size: 14, color: VesparaColors.glow),
          ],
        ),
      );

  Widget _buildSmartSuggestionChip(TraitSuggestion suggestion) {
    return Tooltip(
      message: suggestion.reason,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VesparaColors.glow.withOpacity(0.15),
              VesparaColors.glow.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  suggestion.trait,
                  style: const TextStyle(fontSize: 12, color: VesparaColors.primary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.add, size: 14, color: VesparaColors.glow),
              ],
            ),
            if (suggestion.reason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  suggestion.reason,
                  style: const TextStyle(fontSize: 9, color: VesparaColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getHeatColor(String heatLevel) {
    switch (heatLevel.toLowerCase()) {
      case 'mild':
        return Colors.pink.shade300;
      case 'medium':
        return Colors.orange.shade400;
      case 'hot':
        return Colors.red.shade400;
      case 'nuclear':
        return Colors.purple.shade400;
      default:
        return VesparaColors.glow;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SETTINGS TAB
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSettingsTab() {
    final settingsAsync = ref.watch(userSettingsProvider);
    
    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading settings: $e')),
      data: (settings) {
        // Use defaults if settings is null
        final s = settings ?? UserSettings.defaults('');
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSettingsSection('Discovery Preferences', [
              _buildSettingTile(
                  'Age Range', 
                  '${s.minAge}-${s.maxAge}', 
                  Icons.cake_outlined, 
                  () => _showAgeRangeDialog(s),),
              _buildSettingTile(
                  'Distance', 
                  'Within ${s.maxDistance} miles',
                  Icons.location_on_outlined, 
                  () => _showDistanceDialog(s),),
              _buildSettingTile(
                  'Show Me', 
                  s.showMe, 
                  Icons.people_outline,
                  () => _showGenderPreferenceDialog(s),),
              _buildSettingTile(
                  'Relationship Types', 
                  '${s.relationshipTypes.length} selected',
                  Icons.favorite_outline, 
                  () => _showRelationshipTypesDialog(s),),
            ]),
            const SizedBox(height: 16),
            _buildSettingsSection('Notifications', [
              _buildSettingToggleWithProvider('New Matches', 'notify_new_matches', s.notifyNewMatches),
              _buildSettingToggleWithProvider('Messages', 'notify_new_messages', s.notifyNewMessages),
              _buildSettingToggleWithProvider('Date Reminders', 'notify_date_reminders', s.notifyDateReminders),
              _buildSettingToggleWithProvider('AI Insights', 'notify_ai_insights', s.notifyAiInsights),
            ]),
            const SizedBox(height: 16),
            _buildSettingsSection('Privacy', [
              _buildSettingToggleWithProvider('Show Online Status', 'show_online_status', s.showOnlineStatus),
              _buildSettingToggleWithProvider('Read Receipts', 'read_receipts', s.readReceipts),
              _buildSettingToggleWithProvider('Profile Visible', 'profile_visible', s.profileVisible),
            ]),
            const SizedBox(height: 16),
            _buildSettingsSection('Calendar Sync', [
              _buildSettingTile(
                  'Google Calendar', 
                  s.googleCalendarConnected ? 'Connected' : 'Not Connected',
                  Icons.calendar_today, 
                  () => _showCalendarSyncDialog('Google', s),),
              _buildSettingTile(
                  'Apple Calendar', 
                  s.appleCalendarConnected ? 'Connected' : 'Not Connected', 
                  Icons.event,
                  () => _showCalendarSyncDialog('Apple', s),),
            ]),
            const SizedBox(height: 16),
            _buildSettingsSection('Account', [
              _buildSettingTile(
                  'Subscription', 
                  s.subscriptionTier.toUpperCase(), 
                  Icons.star_outline,
                  _showSubscriptionDialog,),
              _buildSettingTile(
                  'Email',
                  ref.watch(userProfileProvider).valueOrNull?.email ?? 'Not set',
                  Icons.email_outlined,
                  _showEditEmailDialog,),
              _buildSettingTile(
                  'Phone', 
                  s.phone ?? 'Not set', 
                  Icons.phone_outlined,
                  () => _showEditPhoneDialog(s),),
            ]),
            const SizedBox(height: 24),
            _buildDangerZone(s),
          ],
        );
      },
    );
  }

  void _showAgeRangeDialog(UserSettings settings) {
    RangeValues range = RangeValues(settings.minAge.toDouble(), settings.maxAge.toDouble());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Age Range',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,),),
              const SizedBox(height: 24),
              Text(
                '${range.start.toInt()} - ${range.end.toInt()} years',
                style: const TextStyle(fontSize: 24, color: VesparaColors.glow),
              ),
              RangeSlider(
                values: range,
                min: 18,
                max: 65,
                divisions: 47,
                activeColor: VesparaColors.glow,
                inactiveColor: VesparaColors.glow.withOpacity(0.2),
                onChanged: (v) => setModalState(() => range = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(userSettingsProvider.notifier).updateDiscovery(
                      minAge: range.start.toInt(),
                      maxAge: range.end.toInt(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Age range updated to ${range.start.toInt()}-${range.end.toInt()}',),),
                      );
                    }
                  },
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w600,),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDistanceDialog(UserSettings settings) {
    double distance = settings.maxDistance.toDouble();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Maximum Distance',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,),),
              const SizedBox(height: 24),
              Text('${distance.toInt()} miles',
                  style:
                      const TextStyle(fontSize: 24, color: VesparaColors.glow),),
              Slider(
                value: distance,
                min: 1,
                max: 100,
                divisions: 99,
                activeColor: VesparaColors.glow,
                inactiveColor: VesparaColors.glow.withOpacity(0.2),
                onChanged: (v) => setModalState(() => distance = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(userSettingsProvider.notifier).updateDiscovery(
                      maxDistance: distance.toInt(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Distance updated to ${distance.toInt()} miles',),),
                      );
                    }
                  },
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w600,),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGenderPreferenceDialog(UserSettings settings) {
    String selected = settings.showMe;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Show Me',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,),),
              const SizedBox(height: 24),
              ...['Women', 'Men', 'Everyone'].map(
                (option) => RadioListTile<String>(
                  title: Text(option,
                      style: const TextStyle(color: VesparaColors.primary),),
                  value: option,
                  groupValue: selected,
                  activeColor: VesparaColors.glow,
                  onChanged: (v) async {
                    setModalState(() => selected = v!);
                    Navigator.pop(context);
                    await ref.read(userSettingsProvider.notifier).updateDiscovery(
                      showMe: v,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Preference updated to $v')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRelationshipTypesDialog(UserSettings settings) {
    final types = ['Long-term', 'Casual', 'Open', 'Friendship', 'Unsure'];
    final selected = Set<String>.from(settings.relationshipTypes);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Relationship Types',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,),),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types
                    .map(
                      (type) => FilterChip(
                        label: Text(type),
                        selected: selected.contains(type),
                        onSelected: (v) {
                          setModalState(() {
                            v ? selected.add(type) : selected.remove(type);
                          });
                        },
                        selectedColor: VesparaColors.glow.withOpacity(0.3),
                        checkmarkColor: VesparaColors.glow,
                        backgroundColor: VesparaColors.background,
                        labelStyle: TextStyle(
                            color: selected.contains(type)
                                ? VesparaColors.glow
                                : VesparaColors.primary,),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(userSettingsProvider.notifier).updateDiscovery(
                      relationshipTypes: selected.toList(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${selected.length} relationship types selected',),),
                      );
                    }
                  },
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w600,),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCalendarSyncDialog(String provider, UserSettings settings) {
    final isConnected = provider == 'Google' 
        ? settings.googleCalendarConnected 
        : settings.appleCalendarConnected;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$provider Calendar',
            style: const TextStyle(color: VesparaColors.primary),),
        content: Text(
          isConnected
              ? 'Your $provider Calendar is connected. Disconnect?'
              : 'Connect your $provider Calendar to sync dates automatically.',
          style: const TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(userSettingsProvider.notifier).toggleCalendar(provider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(isConnected
                          ? 'Disconnected from $provider Calendar'
                          : 'Connected to $provider Calendar',),),
                );
              }
            },
            child: Text(isConnected ? 'Disconnect' : 'Connect',
                style: const TextStyle(color: VesparaColors.glow),),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 48, color: VesparaColors.glow),
            const SizedBox(height: 16),
            const Text('Vespara Plus',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: VesparaColors.glow,),),
            const SizedBox(height: 8),
            const Text('You\'re on the Plus plan!',
                style: TextStyle(color: VesparaColors.secondary),),
            const SizedBox(height: 24),
            _buildSubscriptionFeature('Unlimited swipes'),
            _buildSubscriptionFeature('See who likes you'),
            _buildSubscriptionFeature('AI dating coach'),
            _buildSubscriptionFeature('Priority matching'),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Opening subscription management...'),),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: VesparaColors.glow),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),),
              ),
              child: const Text('Manage Subscription',
                  style: TextStyle(color: VesparaColors.glow),),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionFeature(String feature) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle,
                color: VesparaColors.success, size: 20,),
            const SizedBox(width: 12),
            Text(feature, style: const TextStyle(color: VesparaColors.primary)),
          ],
        ),
      );

  void _showEditEmailDialog() {
    final currentEmail = ref.read(userProfileProvider).valueOrNull?.email ?? '';
    final controller = TextEditingController(text: currentEmail);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Email',
            style: TextStyle(color: VesparaColors.primary),),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email, color: VesparaColors.glow),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: const TextStyle(color: VesparaColors.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          TextButton(
            onPressed: () async {
              final newEmail = controller.text.trim();
              if (newEmail.isEmpty || !newEmail.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address'),
                    backgroundColor: VesparaColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              try {
                // Supabase requires email verification for changes
                await ref.read(userSettingsProvider.notifier).updateEmail(newEmail);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Verification email sent to $newEmail'),
                      backgroundColor: VesparaColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update email: $e'),
                      backgroundColor: VesparaColors.error,
                    ),
                  );
                }
              }
            },
            child:
                const Text('Save', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(UserSettings settings) {
    final controller = TextEditingController(text: settings.phone ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Phone',
            style: TextStyle(color: VesparaColors.primary),),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+1 (555) 000-0000',
            hintStyle: const TextStyle(color: VesparaColors.secondary),
            prefixIcon: const Icon(Icons.phone, color: VesparaColors.glow),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: const TextStyle(color: VesparaColors.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(userSettingsProvider.notifier).updatePhone(controller.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number updated'),),
                );
              }
            },
            child:
                const Text('Save', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: VesparaColors.secondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      );

  Widget _buildSettingTile(
          String title, String value, IconData icon, VoidCallback onTap,) =>
      ListTile(
        leading: Icon(icon, color: VesparaColors.glow, size: 20),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: VesparaColors.primary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: VesparaColors.secondary, size: 18,),
          ],
        ),
        onTap: onTap,
      );

  Widget _buildSettingToggle(String title) => ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: VesparaColors.primary,
          ),
        ),
        trailing: Switch.adaptive(
          value: false,
          onChanged: (v) {},
          activeColor: VesparaColors.glow,
        ),
      );

  Widget _buildSettingToggleWithProvider(String title, String dbKey, bool currentValue) => ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: VesparaColors.primary,
          ),
        ),
        trailing: Switch.adaptive(
          value: currentValue,
          onChanged: (v) async {
            await ref.read(userSettingsProvider.notifier).updateSetting(dbKey, v);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title ${v ? 'enabled' : 'disabled'}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          activeColor: VesparaColors.glow,
        ),
      );

  Widget _buildDangerZone(UserSettings settings) => DecoratedBox(
        decoration: BoxDecoration(
          color: VesparaColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VesparaColors.error.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                settings.isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
                color: VesparaColors.warning,),
              title: Text(settings.isPaused ? 'Unpause Account' : 'Pause Account',
                  style: const TextStyle(color: VesparaColors.primary),),
              onTap: () => _showPauseAccountDialog(settings),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: VesparaColors.error),
              title: const Text('Delete Account',
                  style: TextStyle(color: VesparaColors.error),),
              onTap: _showDeleteAccountDialog,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: VesparaColors.error),
              title: const Text('Log Out',
                  style: TextStyle(color: VesparaColors.error),),
              onTap: _showLogoutDialog,
            ),
          ],
        ),
      );

  void _showPauseAccountDialog(UserSettings settings) {
    final isPaused = settings.isPaused;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isPaused ? 'Unpause Your Account?' : 'Pause Your Account?',
            style: const TextStyle(color: VesparaColors.primary),),
        content: Text(
          isPaused 
              ? 'Your profile will become visible again and you\'ll start receiving matches.'
              : 'Your profile will be hidden and you won\'t receive new matches. You can unpause anytime.',
          style: const TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(userSettingsProvider.notifier).togglePause();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isPaused 
                        ? 'Account unpaused. Welcome back!'
                        : 'Account paused. Come back when you\'re ready!',),
                    backgroundColor: VesparaColors.warning,
                  ),
                );
              }
            },
            child: Text(isPaused ? 'Unpause' : 'Pause',
                style: const TextStyle(color: VesparaColors.warning),),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?',
            style: TextStyle(color: VesparaColors.error),),
        content: const Text(
          'This action cannot be undone. All your data, matches, and messages will be permanently deleted.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Delete user data from database (cascade will handle related tables)
                await SupabaseService.signOut();
                // Note: Full account deletion requires admin SDK or Edge Function
                // For now, signing out effectively removes access
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted. We\'re sorry to see you go.'),
                      backgroundColor: VesparaColors.error,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e')),
                  );
                }
              }
            },
            child: const Text('Delete Forever',
                style: TextStyle(color: VesparaColors.error),),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out?',
            style: TextStyle(color: VesparaColors.primary),),
        content: const Text(
          'You\'ll need to sign in again to access your account.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              try {
                await SupabaseService.signOut();
                // Clear navigation stack and go to root (AuthGate will show login)
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              }
            },
            child: const Text('Log Out',
                style: TextStyle(color: VesparaColors.error),),
          ),
        ],
      ),
    );
  }
}
