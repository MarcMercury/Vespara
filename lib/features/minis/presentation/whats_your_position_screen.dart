import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/minis_analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/premium_effects.dart';

/// Standalone mini game using a curated list of real sexual position names.
class WhatsYourPositionScreen extends StatefulWidget {
  const WhatsYourPositionScreen({super.key});

  @override
  State<WhatsYourPositionScreen> createState() => _WhatsYourPositionScreenState();
}

class _WhatsYourPositionScreenState extends State<WhatsYourPositionScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _igController = TextEditingController();
  final _friendController = TextEditingController();

  _PositionResult? _result;
  bool _isRevealing = false;
  bool _isFriendMode = false;
  bool _isRare = false;
  int _playCount = 0;
  double _analysisProgress = 0;
  String _analysisLabel = 'Queued for acrobatic profile scan...';

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;

  static const Color _accentColor = Color(0xFF00ACC1);

  // Real sexual position names used by this standalone mini game.
  static const List<_PositionProfile> _positionProfiles = [
    _PositionProfile(
      name: 'Missionary',
      descriptor:
          'You value trust, eye contact, and emotional closeness before anything else.',
    ),
    _PositionProfile(
      name: 'Doggy',
      descriptor:
          'You are bold, direct, and confident about what you want without overexplaining.',
    ),
    _PositionProfile(
      name: 'Reverse Cowgirl',
      descriptor:
          'You are independent, self-driven, and happiest when you set the pace.',
    ),
    _PositionProfile(
      name: 'Sixty-Nine',
      descriptor:
          'You are all about reciprocity and making sure everyone feels seen and satisfied.',
    ),
    _PositionProfile(
      name: 'Pretzel',
      descriptor:
          'You are creative, flexible, and low-key competitive when things get playful.',
    ),
    _PositionProfile(
      name: 'Helicopter',
      descriptor:
          'You are spontaneous chaos in the best way and keep energy high wherever you go.',
    ),
    _PositionProfile(
      name: 'Table Delight',
      descriptor:
          'You are practical and strategic, turning any environment into an opportunity.',
    ),
    _PositionProfile(
      name: 'Wall Hug',
      descriptor:
          'You thrive on intensity, urgency, and that thrilling in-the-moment vibe.',
    ),
    _PositionProfile(
      name: 'Tree Hugger',
      descriptor:
          'You are affectionate and grounded, balancing passion with warmth.',
    ),
    _PositionProfile(
      name: 'Hammock',
      descriptor:
          'You are calm, reassuring, and naturally good at helping people relax.',
    ),
    _PositionProfile(
      name: 'Superman',
      descriptor:
          'You are adventurous, fearless, and always down to try something memorable.',
    ),
    _PositionProfile(
      name: 'Ballerina',
      descriptor:
          'You bring elegance and control, with a flair for dramatic timing.',
    ),
    _PositionProfile(
      name: 'Acrobat',
      descriptor:
          'You are disciplined, ambitious, and weirdly good under pressure.',
    ),
    _PositionProfile(
      name: 'Pump and Grind',
      descriptor:
          'You are persistent and rhythm-driven, and you do not quit halfway.',
    ),
    _PositionProfile(
      name: 'Power Pump',
      descriptor:
          'You are high-energy, assertive, and naturally take charge of the moment.',
    ),
    _PositionProfile(
      name: 'Head Over Heels',
      descriptor:
          'You are romantic, all-in, and unafraid to fully commit to your feelings.',
    ),
    _PositionProfile(
      name: 'Body Surfing',
      descriptor:
          'You are playful, social, and thrive when the chemistry is mutual and fun.',
    ),
    _PositionProfile(
      name: 'Front Row Seat',
      descriptor:
          'You are observant and detail-oriented, and you notice what others miss.',
    ),
    _PositionProfile(
      name: 'Treasure Hunt',
      descriptor:
          'You are curious and attentive, and you enjoy the build-up as much as the payoff.',
    ),
    _PositionProfile(
      name: 'Celebration',
      descriptor:
          'You bring positive energy and make people feel like every moment is an occasion.',
    ),
    _PositionProfile(
      name: 'Web of Desire',
      descriptor:
          'You are magnetic and intuitive, reading the room before anyone says a word.',
    ),
    _PositionProfile(
      name: 'Best Seat in the House',
      descriptor:
          'You are confident and charismatic, and people naturally follow your lead.',
    ),
    _PositionProfile(
      name: 'Octopus',
      descriptor:
          'You are adaptable and multitask like a pro when things get complicated.',
    ),
    _PositionProfile(
      name: 'Threesome',
      descriptor:
          'You are collaborative, open-minded, and excellent at managing group dynamics.',
    ),
    _PositionProfile(
      name: 'Deep Throat',
      descriptor:
          'You are intense, committed, and not afraid of a challenge most people avoid.',
    ),
    _PositionProfile(
      name: 'Zombie',
      descriptor:
          'You are relentless, resilient, and somehow still standing after a wild night.',
    ),
  ];

  static const List<_PositionProfile> _rareProfiles = [
    _PositionProfile(
      name: 'Helicopter',
      descriptor:
          'You are rare-tier unpredictable: dramatic entrance, loud confidence, unforgettable exit.',
    ),
    _PositionProfile(
      name: 'Web of Desire',
      descriptor:
          'You are rare-tier magnetic: one look and people are fully locked into your orbit.',
    ),
    _PositionProfile(
      name: 'Octopus',
      descriptor:
          'You are rare-tier versatile: no matter the scenario, you make it work beautifully.',
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
      'Opening @$igHandle profile...',
      'Reviewing thirst-trap body angles...',
      'Measuring flexibility in mirror selfies...',
      'Cross-referencing position matrix...',
      'Finalizing certified position identity...',
    ];

    for (var i = 0; i < stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() {
        _analysisProgress = (i + 1) / stages.length;
        _analysisLabel = stages[i];
      });
    }
  }

  Future<void> _generatePosition() async {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    final igHandle = _igController.text.trim().replaceAll('@', '');
    if (name.isEmpty || igHandle.isEmpty) return;

    setState(() {
      _isRevealing = true;
      _analysisProgress = 0;
      _analysisLabel = 'Queued for acrobatic profile scan...';
    });
    _playCount++;
    unawaited(MinisAnalyticsService.instance.trackGamePlay('whats_your_position'));

    final seed = DateTime.now().microsecondsSinceEpoch ^
        name.hashCode ^
        igHandle.hashCode ^
        _playCount;
    final rng = Random(seed);

    final isRare = rng.nextInt(100) < 3;
    final profile = isRare
        ? _rareProfiles[rng.nextInt(_rareProfiles.length)]
        : _positionProfiles[rng.nextInt(_positionProfiles.length)];

    await _runFakeIgReview(igHandle);
    if (!mounted) return;

    setState(() {
      _result = _PositionResult(
        name: profile.name,
        descriptor: profile.descriptor,
      );
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
              text: 'POSITION',
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
                    Icons.accessibility_new_rounded,
                    color: _accentColor,
                    size: 32,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'What\'s Your Position?',
              style: GoogleFonts.cinzel(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VesparaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Name + IG handle required.\nWe pretend to analyze your feed and assign your position personality.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: VesparaColors.secondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            _buildInput(
              controller: _nameController,
              hint: 'Enter your name...',
              onSubmit: _generatePosition,
            ),
            const SizedBox(height: 12),
            _buildInput(
              controller: _igController,
              hint: 'Enter IG handle (required)...',
              onSubmit: _generatePosition,
            ),
            const SizedBox(height: 12),

            _buildFriendToggle(),
            if (_isFriendMode) ...[
              const SizedBox(height: 12),
              _buildInput(
                controller: _friendController,
                hint: 'Enter your friend\'s name...',
                onSubmit: _generatePosition,
              ),
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRevealing ? null : _generatePosition,
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
                            ? '🧭 Reveal My Position'
                            : '🧭 Recalculate Position',
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

            if (_result != null) ...[
              _buildResultCard(),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 40),
          ],
        ),
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
    final result = _result!;

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
            color: (_isRare ? const Color(0xFFFFD700) : _accentColor)
                .withOpacity(0.45),
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
            Text(
              'PARTY MINI\'S',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: VesparaColors.secondary.withOpacity(0.4),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$name (@${_igController.text.trim().replaceAll('@', '')}) is...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.secondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              result.name,
              style: GoogleFonts.cinzel(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _isRare ? const Color(0xFFFFD700) : _accentColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              result.descriptor,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: VesparaColors.primary.withOpacity(0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionResult {
  const _PositionResult({
    required this.name,
    required this.descriptor,
  });

  final String name;
  final String descriptor;
}

class _PositionProfile {
  const _PositionProfile({
    required this.name,
    required this.descriptor,
  });

  final String name;
  final String descriptor;
}
