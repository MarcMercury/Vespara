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
/// WHAT'S YOUR SAFE WORD? 🔐
/// Name + vibe → absurdly specific safe word
/// Addictive: vibe selector, friend challenge, rare results, escalation,
/// cross-game suggestions, screenshot cards
/// ════════════════════════════════════════════════════════════════════════════

class SafeWordScreen extends StatefulWidget {
  const SafeWordScreen({super.key});

  @override
  State<SafeWordScreen> createState() => _SafeWordScreenState();
}

class _SafeWordScreenState extends State<SafeWordScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _igController = TextEditingController();
  final _friendController = TextEditingController();
  String? _generatedSafeWord;
  String? _explanation;
  bool _isRevealing = false;
  bool _isRare = false;
  bool _isFriendMode = false;
  int _playCount = 0;
  double _analysisProgress = 0;
  String _analysisLabel = 'Waiting for profile scan...';

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;

  static const Color _accentColor = Color(0xFFE91E63);

  static const List<String> _safeWordPool = [
    'Emergency Glitter Protocol',
    'Consensual Chaos Shutdown',
    'Hydration Break Apocalypse',
    'Velvet Logistics Failure',
    'Cuddle Pile Evacuation',
    'Too Many Volunteers',
    'Soft Limits Meteor Strike',
    'Afterparty Risk Committee',
    'Disco Ball Time-Out',
    'Certified Bad Planning',
    'Moonlight Coordination Error',
    'Respectfully Abort Mission',
    'Overbooked Makeout Calendar',
    'Advanced Group Project',
    'Friendly Panic Button',
    'Cobalt Codeword',
    'Velvet Timeout',
    'Panic Pineapple',
    'Toaster Eclipse',
    'Banana Parliament',
    'Laser Pigeon',
    'Salsa Helmet',
    'Crouton Emergency',
    'Velcro Moon',
    'Yogurt Siren',
    'Pogo Marmalade',
    'Neon Turnip',
    'Giraffe Invoice',
    'Biscuit Tornado',
    'Quantum Pickle',
    'Noodle Sir',
    'Velvet Tractor',
    'Otter Fax Machine',
    'Chrome Waffle',
    'Pocket Volcano',
    'Disco Cactus',
    'Marshmallow Jury',
    'Goblin Receipt',
    'Taco Lighthouse',
    'Parsnip Royale',
    'Jellybean Orbit',
    'Mango Algebra',
    'Raccoon Sonata',
    'Cinnamon Turbine',
    'Pancake Nebula',
    'Banjo Gravity',
    'Dolphin Memo',
    'Pinecone Mirage',
    'Kiwi Firewall',
    'Bubblewrap Verdict',
    'Static Croissant',
    'Moonbeam Stapler',
    'Turbo Lasagna',
    'Pepperoni Comet',
    'Arctic Mustache',
    'Omelet Monsoon',
    'Pluto Side Quest',
    'Nacho Cathedral',
    'Corgi Parliament',
    'Walrus WiFi',
    'Velvet Jalapeno',
    'Caffeine Origami',
    'Haunted Blender',
    'Sassy Quasar',
    'Burrito Roulette',
    'Meteor Pajamas',
  ];

  static const List<String> _actionExplanations = [
    'Deploy it when your "quick experiment" suddenly needs a full planning committee.',
    'Use it the second your curiosity turns into a five-person scheduling conflict.',
    'Shout it before your "for science" idea recruits more volunteers than expected.',
    'Activate it when confidence outruns your stretching routine.',
    'Drop it when the vibe shifts from playful chaos to advanced group project.',
    'Say it before someone turns this into a workshop with no instructor.',
  ];

  // Rare results (1-2% chance)
  static const List<String> _rareWords = [
    'Pineapple Exorcism',
    'Certified Emotional Damage',
    'IRS Panic',
    'Retrograde Victim',
    'Witness Benefits',
    'Midnight Spatula',
    'Diplomatic Ravioli',
    'Goblin Jazz',
    'Velvet Tsunami',
    'Tax Evasion Waltz',
    'Quantum Meatball',
    'Bureaucratic Owl',
    'Cha Cha Chernobyl',
    'Neon Squirrel Tribunal',
    'Biscuit Catastrophe',
    'Astral Meatloaf',
    'Waffle Detonation',
    'Pogo Apocalypse',
    'Feral Crumpet',
    'Mystic Parking Ticket',
    'Pinecone Diplomacy',
    'Ominous Cupcake',
    'Synchronized Mayhem',
    'Unlicensed Moonwalk',
    'Cosmic Nonsense Bureau',
    'Cranky Stardust',
    'Lobster Thunder',
    'Viking Smoothie',
    'Banana Conspiracy',
    'Feral Confetti',
    'Hovercraft Biscuit',
    'Shampoo Prophecy',
    'Dragon Fruit Subpoena',
    'Meowtini Protocol',
    'Algebraic Chaos Nugget',
    'Mildly Haunted Nachos',
    'Rogue Marshmallow Fleet',
    'Diplomatic Scream',
    'Parsnip Vendetta',
    'Lunar Coupon',
  ];

  static const List<String> _rareExplanations = [
    'This safe word has never been assigned before. You are cosmically chosen.',
    'Legends speak of this word. It appears once in 10,000 plays.',
    'The algorithm broke trying to generate this. Congratulations, you\'re an anomaly.',
    'This is the rarest safe word in existence. Screenshot immediately.',
    'You\'ve unlocked a safe word so powerful it needs its own restraining order.',
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
      'Opening @$igHandle profile... ',
      'Reviewing questionable highlights...',
      'Counting chaotic comment sections...',
      'Calibrating nonsense detector...',
      'Finalizing unhinged verdict...',
    ];

    for (var i = 0; i < stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      setState(() {
        _analysisProgress = (i + 1) / stages.length;
        _analysisLabel = stages[i];
      });
    }
  }

  Future<void> _generateSafeWord() async {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    final igHandle = _igController.text.trim().replaceAll('@', '');
    if (name.isEmpty || igHandle.isEmpty) return;

    setState(() {
      _isRevealing = true;
      _analysisProgress = 0;
      _analysisLabel = 'Queued for IG chaos scan...';
    });
    _playCount++;
    unawaited(MinisAnalyticsService.instance.trackGamePlay('safe_word'));

    final seed = DateTime.now().microsecondsSinceEpoch ^
      name.hashCode ^
      _playCount ^
      igHandle.hashCode;
    final rng = Random(seed);

    // 1-2% rare result chance
    final isRare = rng.nextInt(100) < 2;

    String safeWord;
    String explanation;

    if (isRare) {
      final idx = rng.nextInt(_rareWords.length);
      safeWord = _rareWords[idx];
      explanation = _rareExplanations[idx];
    } else {
      safeWord = _safeWordPool[rng.nextInt(_safeWordPool.length)];
      final action =
          _actionExplanations[rng.nextInt(_actionExplanations.length)];
      explanation = _isFriendMode
          ? '$name + @$igHandle radiates elite chaos. $action'
          : 'Algorithm says @$igHandle should keep this in a fireproof envelope. $action';
    }

    await _runFakeIgReview(igHandle);
    if (!mounted) return;

    setState(() {
      _generatedSafeWord = safeWord;
      _explanation = explanation;
      _isRare = isRare;
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
              text: 'SAFE WORD',
              style: GoogleFonts.cinzel(
                fontSize: 20,
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
            // Pulsing icon
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
                    Icons.lock_rounded,
                    color: _accentColor,
                    size: 32,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              "What's Your Safe Word?",
              style: GoogleFonts.cinzel(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VesparaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter name + IG handle and let the app\npretend to profile-stalk your chaos.',
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
              onSubmit: _generateSafeWord,
            ),
            const SizedBox(height: 12),

            _buildInput(
              controller: _igController,
              hint: 'Enter IG handle (required)...',
              onSubmit: _generateSafeWord,
            ),
            const SizedBox(height: 12),

            // ── FRIEND CHALLENGE TOGGLE ──
            _buildFriendToggle(),
            if (_isFriendMode) ...[
              const SizedBox(height: 12),
              _buildInput(
                controller: _friendController,
                hint: 'Enter your friend\'s name...',
                onSubmit: _generateSafeWord,
              ),
            ],
            const SizedBox(height: 20),

            // ── GENERATE BUTTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRevealing ? null : _generateSafeWord,
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
                        _generatedSafeWord == null
                            ? '🔐 Reveal My Safe Word'
                            : '🔄 Generate Another',
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

            // ── RESULT CARD ──
            if (_generatedSafeWord != null) ...[
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
            color: _isRare
                ? const Color(0xFFFFD700).withOpacity(0.6)
                : _accentColor.withOpacity(0.4),
            width: _isRare ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isRare ? const Color(0xFFFFD700) : _accentColor)
                  .withOpacity(0.15),
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
            // Party branding
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
              '$name (@${_igController.text.trim().replaceAll('@', '')})\'s Safe Word:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.secondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"$_generatedSafeWord"',
              style: GoogleFonts.cinzel(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _isRare ? const Color(0xFFFFD700) : _accentColor,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _explanation!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: VesparaColors.secondary.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() => Row(
        children: [
          Expanded(
            child: _actionButton(
              '🔄 Again',
              _generateSafeWord,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              '🎲 Try Red Flag',
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
              const Text('🍸', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Now find your cocktail match',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
                    Text(
                      'Play "What Cocktail Are You?" next →',
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
