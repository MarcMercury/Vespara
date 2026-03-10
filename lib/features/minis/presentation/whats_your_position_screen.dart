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

  double _analysisProgress = 0;
  String _analysisLabel = 'Queued for acrobatic profile scan...';

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;

  static const Color _accentColor = Color(0xFF00ACC1);

  // Curated position pool — each with a one-liner zinger.
  static const List<_PositionProfile> _positionProfiles = [
    _PositionProfile(
      name: 'Missionary',
      descriptor:
          'You\'re basic but reliable — like hotel Wi-Fi that actually works.',
    ),
    _PositionProfile(
      name: 'Doggy Style',
      descriptor:
          'You don\'t need eye contact to know you\'re running the show.',
    ),
    _PositionProfile(
      name: 'Cowgirl',
      descriptor:
          'You\'re a control freak who calls it "taking initiative."',
    ),
    _PositionProfile(
      name: 'Reverse Cowgirl',
      descriptor:
          'You like being in charge but absolutely hate small talk.',
    ),
    _PositionProfile(
      name: 'Spooning',
      descriptor:
          'You\'re suspiciously warm and emotionally available — red flag honestly.',
    ),
    _PositionProfile(
      name: '69',
      descriptor:
          'You\'re a giver who always expects a receipt.',
    ),
    _PositionProfile(
      name: 'Standing',
      descriptor:
          'You have commitment issues — even your positions refuse to sit down.',
    ),
    _PositionProfile(
      name: 'Sideways',
      descriptor:
          'You do everything the unconventional way and call it "vibes."',
    ),
    _PositionProfile(
      name: 'Lazy Dog',
      descriptor:
          'You want all the reward with absolutely none of the effort.',
    ),
    _PositionProfile(
      name: 'The Seated',
      descriptor:
          'You bring the same energy to the bedroom as you do to Zoom meetings.',
    ),
    _PositionProfile(
      name: 'The Lotus',
      descriptor:
          'You went to one yoga class and made it your whole personality.',
    ),
    _PositionProfile(
      name: 'The Splitting Bamboo',
      descriptor:
          'You peaked in gymnastics and never let anyone forget it.',
    ),
    _PositionProfile(
      name: 'The Suspended Congress',
      descriptor:
          'You treat the bedroom like a CrossFit box with worse lighting.',
    ),
    _PositionProfile(
      name: 'The Padlock',
      descriptor:
          'Once you latch on, there\'s no escape — emotionally or physically.',
    ),
    _PositionProfile(
      name: 'The Glowing Triangle',
      descriptor:
          'You\'re way too into geometry for someone who failed math.',
    ),
    _PositionProfile(
      name: 'The Spider',
      descriptor:
          'You\'re creepy, flexible, and somehow always upside down.',
    ),
    _PositionProfile(
      name: 'The Rowing Boat',
      descriptor:
          'You think teamwork makes the dream work — even horizontally.',
    ),
    _PositionProfile(
      name: 'The Yawning',
      descriptor:
          'You make everything look effortless because you\'re half asleep.',
    ),
    _PositionProfile(
      name: 'The Tigress',
      descriptor:
          'You\'re fierce until you pull a hamstring two minutes in.',
    ),
    _PositionProfile(
      name: 'The Churning',
      descriptor:
          'You bring the same intensity to the bedroom as a 6 AM spin class.',
    ),
    _PositionProfile(
      name: 'The Milk and Water',
      descriptor:
          'You\'re smooth, blended, and impossible to explain to your parents.',
    ),
    _PositionProfile(
      name: 'The Erotic V',
      descriptor:
          'You peaked during cheerleading tryouts and this is your final form.',
    ),
    _PositionProfile(
      name: 'The Wheelbarrow',
      descriptor:
          'You treat romance like a trip to Home Depot — functional and sweaty.',
    ),
    _PositionProfile(
      name: 'The Pretzel',
      descriptor:
          'You\'re complex, twisted, and best enjoyed with salt.',
    ),
    _PositionProfile(
      name: 'The Helicopter',
      descriptor:
          'You\'re a showoff who peaked on the playground merry-go-round.',
    ),
    _PositionProfile(
      name: 'The Piledriver',
      descriptor:
          'You have zero chill and your chiropractor has a yacht because of you.',
    ),
    _PositionProfile(
      name: 'The London Bridge',
      descriptor:
          'You\'re architectural, dramatic, and structurally unsound.',
    ),
    _PositionProfile(
      name: 'The Face Off',
      descriptor:
          'You maintain eye contact like a psychopath and call it "intimacy."',
    ),
    _PositionProfile(
      name: 'The Lazy Susan',
      descriptor:
          'You spin through life doing the bare minimum in every direction.',
    ),
    _PositionProfile(
      name: 'The Crab Walk',
      descriptor:
          'You move sideways through problems, relationships, and furniture.',
    ),
    _PositionProfile(
      name: 'The Butter Churner',
      descriptor:
          'You treat romance like an Amish side hustle.',
    ),
    _PositionProfile(
      name: 'The Amazon',
      descriptor:
          'You\'re dominant, fearless, and deliver in two days or less.',
    ),
    _PositionProfile(
      name: 'The Flatiron',
      descriptor:
          'You press hard, run hot, and leave a lasting impression.',
    ),
    _PositionProfile(
      name: 'The Seashell',
      descriptor:
          'You look peaceful on the outside but it\'s absolute chaos in there.',
    ),
    _PositionProfile(
      name: 'The Eiffel Tower',
      descriptor:
          'You\'re cultured, tall, and require two other people minimum.',
    ),
    _PositionProfile(
      name: 'The Spit Roast',
      descriptor:
          'You\'re a people person who literally hates being left out.',
    ),
    _PositionProfile(
      name: 'The Lucky Pierre',
      descriptor:
          'You\'re the ultimate middle child — finally getting attention from both sides.',
    ),
    _PositionProfile(
      name: 'The Daisy Chain',
      descriptor:
          'You take "the more the merrier" as a personal lifestyle mission.',
    ),
    _PositionProfile(
      name: 'The Sandwich',
      descriptor:
          'You\'re layered, filling, and always better with extra hands.',
    ),
    _PositionProfile(
      name: 'The Train',
      descriptor:
          'You\'re punctual, efficient, and everyone lines up for a ride.',
    ),
    _PositionProfile(
      name: 'The Menage Stack',
      descriptor:
          'You treat intimacy like a competitive sport with a deep roster.',
    ),
    _PositionProfile(
      name: 'The Triangle',
      descriptor:
          'You peaked in geometry and never emotionally recovered.',
    ),
    _PositionProfile(
      name: 'The Throne Room',
      descriptor:
          'You sit back and let everyone else do the work — royally.',
    ),
    _PositionProfile(
      name: 'The Human Centipede',
      descriptor:
          'You watched that movie and thought "challenge accepted."',
    ),
    _PositionProfile(
      name: 'The Double Decker',
      descriptor:
          'You\'re extra in every sense and somehow still want the top bunk.',
    ),
    _PositionProfile(
      name: 'The Square Dance',
      descriptor:
          'You\'re wholesome on the surface but absolutely unhinged with a partner.',
    ),
    _PositionProfile(
      name: 'The Four Corners',
      descriptor:
          'You need a GPS and a safety briefing before getting started.',
    ),
    _PositionProfile(
      name: 'The Orgy Circle',
      descriptor:
          'You\'re inclusive, organized, and suspiciously good at event logistics.',
    ),
    _PositionProfile(
      name: 'The Plus Sign',
      descriptor:
          'You\'re mathematical about love and always looking to add more.',
    ),
    _PositionProfile(
      name: 'The Stand and Carry',
      descriptor:
          'You never skip leg day and this is exactly why.',
    ),
    _PositionProfile(
      name: 'The Shoulder Holder',
      descriptor:
          'You\'re supportive in the most physically uncomfortable way possible.',
    ),
    _PositionProfile(
      name: 'The Flying Dutchman',
      descriptor:
          'You\'re legendary, mysterious, and no one\'s quite sure you\'re real.',
    ),
    _PositionProfile(
      name: 'The Dancer',
      descriptor:
          'You have rhythm, grace, and zero regard for nearby furniture.',
    ),
    _PositionProfile(
      name: 'The Suspended Lotus',
      descriptor:
          'You combined yoga with reckless endangerment into one glorious flex.',
    ),
    _PositionProfile(
      name: 'The Headstand',
      descriptor:
          'You see the world differently — mostly because all the blood rushed to your head.',
    ),
    _PositionProfile(
      name: 'The Bridge of Sighs',
      descriptor:
          'You\'re romantic, dramatic, and structurally questionable at best.',
    ),
    _PositionProfile(
      name: 'The Valedictorian',
      descriptor:
          'You studied for this and still somehow need the instruction manual.',
    ),
    _PositionProfile(
      name: 'Yab-Yum',
      descriptor:
          'You googled "tantric" once and never shut up about it.',
    ),
    _PositionProfile(
      name: 'The Embrace',
      descriptor:
          'You hug like you\'re trying to absorb someone\'s entire soul.',
    ),
    _PositionProfile(
      name: 'The Soul Gaze',
      descriptor:
          'You stare into eyes so hard people start filing restraining orders.',
    ),
    _PositionProfile(
      name: 'Synchronized Breathing',
      descriptor:
          'You turned breathing into a couples activity — peak overachiever energy.',
    ),
    _PositionProfile(
      name: 'The Melting Hug',
      descriptor:
          'You\'re so warm and clingy people genuinely check you for a fever.',
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
    unawaited(MinisAnalyticsService.instance.trackGamePlay('whats_your_position'));

    final rng = Random.secure();
    final profile = _positionProfiles[rng.nextInt(_positionProfiles.length)];

    await _runFakeIgReview(igHandle);
    if (!mounted) return;

    setState(() {
      _result = _PositionResult(
        name: profile.name,
        descriptor: profile.descriptor,
      );
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
            color: _accentColor.withOpacity(0.45),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.15),
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
                color: _accentColor,
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
