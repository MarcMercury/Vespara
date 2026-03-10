import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/minis_analytics_service.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/premium_effects.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// WHERE YOU'D DEFINITELY GET CAUGHT 📍
/// Name + IG handle → random place where you'd get busted in public
/// ════════════════════════════════════════════════════════════════════════════

class CaughtInTheActScreen extends StatefulWidget {
  const CaughtInTheActScreen({super.key});

  @override
  State<CaughtInTheActScreen> createState() => _CaughtInTheActScreenState();
}

class _CaughtInTheActScreenState extends State<CaughtInTheActScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _igController = TextEditingController();
  final _friendController = TextEditingController();
  _LocationResult? _result;
  bool _isRevealing = false;
  bool _isFriendMode = false;
  double _analysisProgress = 0;
  String _analysisLabel = 'Queued for location scandal scan...';

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;

  static const Color _accentColor = Color(0xFFFF6D00);

  static const List<_LocationResult> _communityLocations = [
    _LocationResult(
      location: 'Inside the walk-in freezer of a Dave & Buster\'s',
      emoji: '🧊',
      punchline: 'You finally found a way to make the skee-ball tickets feel meaningful.',
    ),
    _LocationResult(
      location: 'Behind the animatronic band at a Chuck E. Cheese',
      emoji: '🐭',
      punchline: 'Nothing humbles a person like robotic rats judging their life choices.',
    ),
    _LocationResult(
      location: 'The staff breakroom at an Olive Garden during unlimited breadsticks',
      emoji: '🥖',
      punchline: 'You briefly forgot the phrase "when you\'re here, you\'re family" has limits.',
    ),
    _LocationResult(
      location: 'A yoga studio during a very serious sound bath',
      emoji: '🧘',
      punchline: 'You misunderstood what they meant by "finding your center."',
    ),
    _LocationResult(
      location: 'The broom closet at a Planet Fitness',
      emoji: '🧹',
      punchline: 'You\'ve clearly misunderstood the whole "Judgement Free Zone" concept.',
    ),
    _LocationResult(
      location: 'The sample aisle at Costco while someone rings the tiny bell',
      emoji: '🛒',
      punchline: 'You thought the bell meant all bets were off.',
    ),
    _LocationResult(
      location: 'A church basement during a very intense bingo night',
      emoji: '⛪',
      punchline: 'Nothing gets the grandmas gossiping like this.',
    ),
    _LocationResult(
      location: 'The employee training room at a Best Buy',
      emoji: '💻',
      punchline: 'You\'ve taken "Geek Squad support" way too literally.',
    ),
    _LocationResult(
      location: 'A pottery class where everyone else is quietly making bowls',
      emoji: '🏺',
      punchline: 'Your interpretation of "hands-on learning" went in a different direction.',
    ),
    _LocationResult(
      location: 'The shark tunnel at a mid-tier aquarium',
      emoji: '🦈',
      punchline: 'The sharks are the only ones not judging you.',
    ),
    _LocationResult(
      location: 'A community theater dressing room during Fiddler on the Roof intermission',
      emoji: '🎭',
      punchline: 'Somewhere a stage manager is quietly losing their mind.',
    ),
    _LocationResult(
      location: 'The lost-and-found office at a ski resort',
      emoji: '🎿',
      punchline: 'Somehow you still managed to lose your dignity.',
    ),
    _LocationResult(
      location: 'A public library genealogy section surrounded by retirees',
      emoji: '📚',
      punchline: 'Congratulations, you\'re now part of someone\'s family history.',
    ),
    _LocationResult(
      location: 'The backstage hallway of a small-town magician show',
      emoji: '🎩',
      punchline: 'Even the magician didn\'t see this trick coming.',
    ),
    _LocationResult(
      location: 'A trampoline park foam pit',
      emoji: '🤸',
      punchline: 'Turns out the real bounce was your reputation.',
    ),
    _LocationResult(
      location: 'A Home Depot shed display labeled "DIY Backyard Oasis"',
      emoji: '🪚',
      punchline: 'The employee helping customers pick mulch did not need to see that.',
    ),
    _LocationResult(
      location: 'The bird enclosure at a petting zoo',
      emoji: '🦜',
      punchline: 'The parrots are absolutely repeating what they saw.',
    ),
    _LocationResult(
      location: 'A mall Santa photo set in July',
      emoji: '🎅',
      punchline: 'Santa has seen some things, but this is new.',
    ),
    _LocationResult(
      location: 'The mechanical room behind a hotel ice machine',
      emoji: '🧊',
      punchline: 'The ice machine will never emotionally recover from this.',
    ),
    _LocationResult(
      location: 'A university lecture hall during an extremely boring economics class',
      emoji: '🎓',
      punchline: 'Finally, someone made supply and demand interesting.',
    ),
    _LocationResult(
      location: 'The rotating sushi bar conveyor belt area',
      emoji: '🍣',
      punchline: 'That was not on the menu.',
    ),
    _LocationResult(
      location: 'A meditation retreat kitchen where everyone has taken a vow of silence',
      emoji: '🧘',
      punchline: 'The silence just made the scandal louder.',
    ),
    _LocationResult(
      location: 'The dairy aisle of a 24-hour grocery store at 3 AM',
      emoji: '🥛',
      punchline: 'The milk wasn\'t the only thing going bad.',
    ),
    _LocationResult(
      location: 'The janitor\'s closet of a luxury spa',
      emoji: '🧽',
      punchline: 'Not exactly the wellness treatment they were advertising.',
    ),
    _LocationResult(
      location: 'A suburban HOA meeting in someone\'s living room',
      emoji: '🏘️',
      punchline: 'The minutes from this meeting are going to be incredible.',
    ),
    _LocationResult(
      location: 'A museum exhibit titled "Early Farming Equipment"',
      emoji: '🏛️',
      punchline: 'Historians will have questions.',
    ),
    _LocationResult(
      location: 'A bowling alley birthday party for a 9-year-old',
      emoji: '🎳',
      punchline: 'The parents are absolutely cancelling cake.',
    ),
    _LocationResult(
      location: 'The projection booth of an old movie theater',
      emoji: '🎬',
      punchline: 'This was not the director\'s cut.',
    ),
    _LocationResult(
      location: 'A haunted house attraction emergency exit',
      emoji: '👻',
      punchline: 'You\'ve somehow made it the scariest part of the tour.',
    ),
    _LocationResult(
      location: 'The dressing room hallway at a Nordstrom Rack',
      emoji: '👗',
      punchline: 'Even the clearance rack is embarrassed.',
    ),
    _LocationResult(
      location: 'A tiny independent tax preparation office in April',
      emoji: '🧾',
      punchline: 'You just created a deduction nobody can explain.',
    ),
    _LocationResult(
      location: 'A dog obedience class while the instructor is explaining "sit"',
      emoji: '🐕',
      punchline: 'Even the dogs know this isn\'t right.',
    ),
    _LocationResult(
      location: 'The balcony of a cruise ship during mandatory safety drills',
      emoji: '🛳️',
      punchline: 'This was not the lifeboat plan.',
    ),
    _LocationResult(
      location: 'A pumpkin patch gift shop in October',
      emoji: '🎃',
      punchline: 'The scarecrows are now traumatized.',
    ),
    _LocationResult(
      location: 'The inflatable bounce house at a county fair',
      emoji: '🎪',
      punchline: 'The structural integrity report will mention you.',
    ),
    _LocationResult(
      location: 'The employee locker room of a laser tag arena',
      emoji: '🔫',
      punchline: 'The scoreboard will never recover.',
    ),
    _LocationResult(
      location: 'A city council meeting livestream room',
      emoji: '🏛️',
      punchline: 'The public comments section is going to explode.',
    ),
    _LocationResult(
      location: 'The produce refrigerator at a Whole Foods',
      emoji: '🥒',
      punchline: 'Those organic cucumbers didn\'t sign up for this.',
    ),
    _LocationResult(
      location: 'A public transit lost luggage warehouse',
      emoji: '🧳',
      punchline: 'You\'ve officially become part of the inventory.',
    ),
    _LocationResult(
      location: 'A craft brewery tour halfway through the fermentation explanation',
      emoji: '🍺',
      punchline: 'The guide just skipped to the end of the tour.',
    ),
    _LocationResult(
      location: 'The roof of a small-town planetarium',
      emoji: '🔭',
      punchline: 'Somewhere an astronomer is rethinking the universe.',
    ),
    _LocationResult(
      location: 'A wedding venue coat check room during speeches',
      emoji: '💒',
      punchline: 'The coats know everything now.',
    ),
    _LocationResult(
      location: 'The ticket booth of a closed roller coaster',
      emoji: '🎢',
      punchline: 'Turns out the ride wasn\'t actually closed.',
    ),
    _LocationResult(
      location: 'A kids\' science museum electricity demonstration area',
      emoji: '⚡',
      punchline: 'This experiment escalated quickly.',
    ),
    _LocationResult(
      location: 'The backstage prop storage at a Renaissance fair',
      emoji: '🛡️',
      punchline: 'The knights will be talking about this for years.',
    ),
    _LocationResult(
      location: 'A hospital gift shop after visiting hours',
      emoji: '🧸',
      punchline: 'Even the teddy bears are concerned.',
    ),
    _LocationResult(
      location: 'A tiny Airbnb themed "Rustic Lighthouse Escape"',
      emoji: '🏠',
      punchline: 'The host is definitely leaving a review.',
    ),
    _LocationResult(
      location: 'A campground ranger station office',
      emoji: '🏕️',
      punchline: 'Smokey the Bear would like a word.',
    ),
    _LocationResult(
      location: 'A suburban cul-de-sac during a neighborhood watch meeting',
      emoji: '🚨',
      punchline: 'The Nextdoor app is about to explode.',
    ),
    _LocationResult(
      location: 'The waiting room of a DMV five minutes before your number is called',
      emoji: '📋',
      punchline: 'You somehow made the DMV even more uncomfortable.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _igController.dispose();
    _friendController.dispose();
    _revealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runFakeIgReview(String igHandle) async {
    final stages = <String>[
      'Opening @$igHandle geotags...',
      'Reviewing suspicious check-ins...',
      'Mapping maximum embarrassment radius...',
      'Simulating public witnesses...',
      'Finalizing chaotic location forecast...',
    ];
    for (var i = 0; i < stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 240));
      if (!mounted) return;
      setState(() {
        _analysisProgress = (i + 1) / stages.length;
        _analysisLabel = stages[i];
      });
    }
  }

  Future<void> _generateLocation() async {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    final igHandle = _igController.text.trim().replaceAll('@', '');
    if (name.isEmpty || igHandle.isEmpty) return;

    setState(() {
      _isRevealing = true;
      _analysisProgress = 0;
      _analysisLabel = 'Queued for location scandal scan...';
    });
    unawaited(MinisAnalyticsService.instance.trackGamePlay('get_caught'));

    final rng = Random.secure();
    final location =
        _communityLocations[rng.nextInt(_communityLocations.length)];

    await _runFakeIgReview(igHandle);
    if (!mounted) return;

    setState(() {
      _result = location;
      _isRevealing = false;
    });
    _revealController.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: VesparaAnimatedBackground(
          enableParticles: true,
          particleCount: 12,
          auroraIntensity: 0.6,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(VesparaIcons.back, color: VesparaColors.primary),
            ),
            const Spacer(),
            VesparaNeonText(
              text: 'GET CAUGHT',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: _accentColor,
              ),
              glowColor: _accentColor,
              glowRadius: 12,
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      );

  Widget _buildContent() => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Location pin icon
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = _pulseController.value;
                return Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _accentColor.withOpacity(0.3 + pulse * 0.1),
                        _accentColor.withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withOpacity(0.2 + pulse * 0.1),
                        blurRadius: 20 + pulse * 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: _accentColor,
                    size: 32,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              "Where You'd Definitely\nGet Caught",
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: VesparaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter name + IG handle for a place people\nwould never do it, plus why you did and how you got caught.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: VesparaColors.secondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // ── NAME INPUT ──
            _buildInput(
              controller: _nameController,
              hint: 'Enter your name...',
              onSubmit: _generateLocation,
            ),
            const SizedBox(height: 12),

            _buildInput(
              controller: _igController,
              hint: 'Enter IG handle (required)...',
              onSubmit: _generateLocation,
            ),
            const SizedBox(height: 12),

            // ── FRIEND CHALLENGE ──
            _buildFriendToggle(),
            if (_isFriendMode) ...[
              const SizedBox(height: 12),
              _buildInput(
                controller: _friendController,
                hint: 'Enter your friend\'s name...',
                onSubmit: _generateLocation,
              ),
            ],
            const SizedBox(height: 20),

            // ── GENERATE BUTTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRevealing ? null : _generateLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isRevealing
                    ? Text(
                        'Reviewing @${_igController.text.trim().replaceAll('@', '')}...',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Text(
                        _result == null
                            ? '📍 Reveal My Spot'
                            : '📍 Try Another Location',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
                  if (_isRevealing) ...[
                    const SizedBox(height: 10),
                    Text(
                      _analysisLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: VesparaColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _analysisProgress,
                        minHeight: 8,
                        backgroundColor: VesparaColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(_accentColor),
                      ),
                    ),
                  ],
            const SizedBox(height: 32),

            // ── RESULT ──
            if (_result != null) ...[
              _buildResultCard(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildCrossGameSuggestion(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onSubmit,
  }) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentColor.withOpacity(0.3)),
          color: VesparaColors.surface,
        ),
        child: TextField(
          controller: controller,
          style: GoogleFonts.inter(color: VesparaColors.primary, fontSize: 16),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: VesparaColors.secondary.withOpacity(0.5),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
      );

  Widget _buildFriendToggle() => GestureDetector(
        onTap: () => setState(() => _isFriendMode = !_isFriendMode),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isFriendMode ? Icons.person_remove : Icons.person_add,
              color: _accentColor.withOpacity(0.7),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _isFriendMode ? 'Back to mine' : 'Challenge a friend',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _accentColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildResultCard() {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    final loc = _result!;
    const displayColor = _accentColor;

    return AnimatedBuilder(
      animation: _revealAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _revealAnimation.value,
          child: Opacity(
            opacity: _revealAnimation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1A1A2E),
          border: Border.all(
            color: displayColor.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'PARTY MINI\'S',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: VesparaColors.secondary.withOpacity(0.4),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              '$name (@${_igController.text.trim().replaceAll('@', '')}) would get caught at:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.secondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.location,
              style: GoogleFonts.cinzel(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: displayColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              loc.punchline,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: VesparaColors.primary.withOpacity(0.85),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() => Row(
        children: [
          Expanded(
            child: _actionButton('🔄 Again', _generateLocation),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              '🍸 Try Cocktail',
              () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              '👥 Challenge',
              () => setState(() => _isFriendMode = true),
            ),
          ),
        ],
      );

  Widget _actionButton(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: VesparaColors.surface,
            border: Border.all(
              color: _accentColor.withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _buildCrossGameSuggestion() => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: VesparaColors.surface.withOpacity(0.5),
            border: Border.all(
              color: VesparaColors.secondary.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              const Text('🔐', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s your escape plan?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
                    Text(
                      'Play "What\'s Your Safe Word?" next →',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                VesparaIcons.forward,
                color: VesparaColors.secondary,
                size: 16,
              ),
            ],
          ),
        ),
      );
}

class _LocationResult {
  const _LocationResult({
    required this.location,
    required this.emoji,
    required this.punchline,
  });
  final String location;
  final String emoji;
  final String punchline;
}
