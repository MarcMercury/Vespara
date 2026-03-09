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
/// Name + vibe → where you'd get busted in public
/// Result format: Location + "You thought X. You were wrong."
/// Addictive: vibe selector, friend challenge, rare results, escalation,
/// cross-game suggestions, screenshot cards
/// ════════════════════════════════════════════════════════════════════════════

class CaughtInTheActScreen extends StatefulWidget {
  const CaughtInTheActScreen({super.key});

  @override
  State<CaughtInTheActScreen> createState() => _CaughtInTheActScreenState();
}

class _CaughtInTheActScreenState extends State<CaughtInTheActScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _friendController = TextEditingController();
  _LocationResult? _result;
  bool _isRevealing = false;
  bool _isRare = false;
  bool _isFriendMode = false;
  int _playCount = 0;
  int _selectedVibe = 0;

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;

  static const Color _accentColor = Color(0xFFFF6D00);

  static const List<String> _vibeLabels = [
    'Flirting', 'Chaos', 'Trouble', 'Romance', 'Bad Decisions',
  ];
  static const List<String> _vibeEmojis = [
    '😏', '🔥', '😈', '💕', '🍸',
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // LOCATION RESULTS — By vibe
  // Format: Location + short funny punchline
  // ═══════════════════════════════════════════════════════════════════════

  static const List<List<_LocationResult>> _locationsByVibe = [
    // 0: Flirting
    [
      _LocationResult(location: 'Hotel Elevator', emoji: '🛗', punchline: 'You thought 45 seconds between floors was enough. The bellhop disagrees.'),
      _LocationResult(location: 'Rooftop Bar Bathroom', emoji: '🍸', punchline: 'You thought the "occupied" sign was enough. The line of 12 people wasn\'t.'),
      _LocationResult(location: 'Beach After Midnight', emoji: '🏖️', punchline: 'You thought the moonlight was romantic. The dog walkers thought otherwise.'),
      _LocationResult(location: 'Hot Tub at an Airbnb', emoji: '♨️', punchline: 'You thought it was private. The Ring doorbell thought differently.'),
      _LocationResult(location: 'Yacht Club Dock', emoji: '⛵', punchline: 'You thought rich people sleep early. The dock master has night vision.'),
      _LocationResult(location: 'Cruise Ship Balcony', emoji: '🚢', punchline: 'You thought international waters meant no witnesses. The retired couple from Ohio saw everything.'),
      _LocationResult(location: 'Private Cabana', emoji: '🏝️', punchline: 'You thought the curtains were enough. The pool boy schedules around you now.'),
      _LocationResult(location: 'Wine Cellar', emoji: '🍷', punchline: 'You thought nobody goes down there. The sommelier has a schedule.'),
    ],
    // 1: Chaos
    [
      _LocationResult(location: 'Ikea Showroom Bedroom', emoji: '🛏️', punchline: 'You thought testing the MALM bed was a joke. A family of 4 rounded the corner.'),
      _LocationResult(location: 'Music Festival Porta-Potty', emoji: '🎵', punchline: 'You thought the bass would cover you. The 200 people in line heard everything.'),
      _LocationResult(location: 'Costco Parking Lot', emoji: '🛒', punchline: 'You thought bulk toilet paper provided cover. The receipt checker saw you leave.'),
      _LocationResult(location: 'Ferris Wheel', emoji: '🎡', punchline: 'You thought 4 minutes was enough. The operator knows exactly what that rocking means.'),
      _LocationResult(location: 'Corn Maze', emoji: '🌽', punchline: 'You thought you were lost on purpose. The family on the hayride was not amused.'),
      _LocationResult(location: 'Escape Room', emoji: '🔑', punchline: 'You paid to be locked in with cameras. The game master buzzed in: "Need a hint?"'),
      _LocationResult(location: 'Bounce House', emoji: '🏰', punchline: 'You thought no one was watching. A child\'s birthday party arrived 10 minutes early.'),
      _LocationResult(location: 'Drive-In Movie', emoji: '🎬', punchline: 'You thought the foggy windows were subtle. The car next to you started clapping.'),
    ],
    // 2: Trouble
    [
      _LocationResult(location: 'Your Ex\'s Neighborhood', emoji: '💀', punchline: 'You thought parking on their street was coincidental. They walked their dog past your car.'),
      _LocationResult(location: 'Company Parking Garage', emoji: '🅿️', punchline: 'You thought Level 4 was empty. Steve from Accounting parks there. Monday will be awkward.'),
      _LocationResult(location: 'Rooftop of Your Office', emoji: '🏢', punchline: 'You thought skyline views were worth it. You\'re now starring in the HR training video.'),
      _LocationResult(location: 'Walk-In Freezer at Work', emoji: '🥶', punchline: 'You thought passion would keep you warm. The cook needed the salmon in 90 seconds.'),
      _LocationResult(location: 'Your Therapist\'s Waiting Room', emoji: '🧠', punchline: 'You thought creating new problems where you solve them was efficient. Your 3pm was early.'),
      _LocationResult(location: 'Library Study Room', emoji: '📚', punchline: 'You forgot the study rooms have glass walls. GLASS. WALLS.'),
      _LocationResult(location: 'Airport TSA Line', emoji: '✈️', punchline: 'You called it "mile high club pregame." TSA called it a security incident.'),
      _LocationResult(location: 'Jury Duty Bathroom', emoji: '⚖️', punchline: 'You thought civic duty was boring. The bailiff knocking changed your mind.'),
    ],
    // 3: Romance
    [
      _LocationResult(location: 'Museum After Hours', emoji: '🎨', punchline: 'You thought a Monet backdrop was romantic. The motion sensors near the art thought otherwise.'),
      _LocationResult(location: 'Golf Course at Night', emoji: '⛳', punchline: 'You thought starlit grass was perfect. The automated sprinklers at 11pm had zero mercy.'),
      _LocationResult(location: 'National Park Trail', emoji: '🏕️', punchline: 'You thought nature was calling. A Boy Scout troop answered instead.'),
      _LocationResult(location: 'Train Sleeper Car', emoji: '🚂', punchline: 'You thought the rocking was romantic. The conductor\'s judgment said otherwise.'),
      _LocationResult(location: 'Botanical Garden', emoji: '🌺', punchline: 'You thought the flowers provided cover. The groundskeeper has seen things.'),
      _LocationResult(location: 'Castle Tower', emoji: '🏰', punchline: 'You thought fairy tales were real. The tour group rounding the spiral staircase wasn\'t.'),
      _LocationResult(location: 'Lighthouse', emoji: '🗼', punchline: 'You thought the rotating beam added ambiance. The coast guard was doing inspections.'),
      _LocationResult(location: 'Covered Bridge', emoji: '🌉', punchline: 'You thought it was secluded. The photographer shooting engagement photos didn\'t.'),
    ],
    // 4: Bad Decisions
    [
      _LocationResult(location: 'Dressing Room at Nordstrom', emoji: '👗', punchline: 'You thought "checking the fit" was believable. The sales associate always knows.'),
      _LocationResult(location: 'Movie Theater Back Row', emoji: '🎬', punchline: 'You picked a terrible movie nobody watches. The usher\'s flashlight found you in the one quiet scene.'),
      _LocationResult(location: 'Laundromat at 2am', emoji: '🧺', punchline: 'You thought the vibrating washer was "just for balance." The insomniac doing whites disagreed.'),
      _LocationResult(location: 'Wedding Reception Coat Room', emoji: '🎩', punchline: 'You thought the ceremony was long enough. The mother of the bride needed her shawl.'),
      _LocationResult(location: 'Gym Sauna', emoji: '🧖', punchline: 'You thought the steam provided cover. The personal trainer does sauna sessions at this hour.'),
      _LocationResult(location: 'Trampoline Park After Hours', emoji: '🤸', punchline: 'You thought bouncing was fun. The security camera footage became staff training material.'),
      _LocationResult(location: 'IHOP Bathroom', emoji: '🥞', punchline: 'You thought 3am pancake runs provided anonymity. The staff has seen everything.'),
      _LocationResult(location: 'Storage Unit', emoji: '📦', punchline: 'You rented a 10x10 for this. The guy in Unit 7B can hear through the walls.'),
    ],
  ];

  // Rare results (1-2% chance)
  static const List<_LocationResult> _rareLocations = [
    _LocationResult(
      location: 'The International Space Station',
      emoji: '🚀',
      punchline: 'Zero gravity. Zero privacy. NASA\'s live feed had its highest viewership in history.',
    ),
    _LocationResult(
      location: 'The Oval Office',
      emoji: '🏛️',
      punchline: 'This location is classified. The Secret Service has revoked your clearance.',
    ),
    _LocationResult(
      location: 'A Time Machine',
      emoji: '⏰',
      punchline: 'You got caught in every timeline simultaneously. Paradox achieved.',
    ),
  ];

  // Escalation flavor for repeat plays
  static const List<String> _escalation = [
    'At this point, you should be on a list somewhere.',
    'This is a pattern now. Seek help.',
    'Your location history is a crime spree.',
    'Even Google Maps is judging you.',
    'Authorities have been notified. (Just kidding. Maybe.)',
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
    _friendController.dispose();
    _revealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _generateLocation() {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isRevealing = true);
    _playCount++;
    unawaited(MinisAnalyticsService.instance.trackGamePlay('get_caught'));

    final seed = DateTime.now().microsecondsSinceEpoch ^
      name.hashCode ^
      _playCount ^
      (_selectedVibe << 8);
    final rng = Random(seed);

    final isRare = rng.nextInt(100) < 2;
    _LocationResult location;

    if (isRare) {
      location = _rareLocations[rng.nextInt(_rareLocations.length)];
    } else {
      final vibeLocations = _locationsByVibe[_selectedVibe];
      location = vibeLocations[rng.nextInt(vibeLocations.length)];
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _result = location;
        _isRare = isRare;
        _isRevealing = false;
      });
      _revealController.forward(from: 0);
      HapticFeedback.heavyImpact();
    });
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
              'Enter your name and find out where\nyou\'d absolutely get busted.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: VesparaColors.secondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // ── VIBE SELECTOR ──
            _buildVibeSelector(),
            const SizedBox(height: 20),

            // ── NAME INPUT ──
            _buildInput(
              controller: _nameController,
              hint: 'Enter your name...',
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
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
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

  Widget _buildVibeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'PICK YOUR VIBE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: VesparaColors.secondary,
                letterSpacing: 2,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_vibeLabels.length, (i) {
                final selected = _selectedVibe == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedVibe = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: selected
                            ? _accentColor.withOpacity(0.2)
                            : VesparaColors.surface,
                        border: Border.all(
                          color: selected
                              ? _accentColor
                              : VesparaColors.secondary.withOpacity(0.2),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_vibeEmojis[i], style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            _vibeLabels[i],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected ? _accentColor : VesparaColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      );

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
    final displayColor = _isRare ? const Color(0xFFFFD700) : _accentColor;

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
            color: displayColor.withOpacity(_isRare ? 0.6 : 0.4),
            width: _isRare ? 2.5 : 2,
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
            if (_isRare) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  '✨ ULTRA RARE ✨',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
              '$name would get caught at:',
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
            if (_playCount >= 3) ...[
              const SizedBox(height: 12),
              Text(
                _escalation[_playCount % _escalation.length],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: VesparaColors.secondary.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _accentColor.withOpacity(0.1),
              ),
              child: Text(
                '${_vibeEmojis[_selectedVibe]} ${_vibeLabels[_selectedVibe]} Vibe',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
