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
/// WHAT'S YOUR RED FLAG? 🚩
/// Name + vibe → hilarious, brutally honest red flag
/// Addictive: vibe selector, friend challenge, rare results, escalation,
/// cross-game suggestions, screenshot cards
/// ════════════════════════════════════════════════════════════════════════════

class RedFlagScreen extends StatefulWidget {
  const RedFlagScreen({super.key});

  @override
  State<RedFlagScreen> createState() => _RedFlagScreenState();
}

class _RedFlagScreenState extends State<RedFlagScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _igController = TextEditingController();
  final _friendController = TextEditingController();
  String? _generatedFlag;
  bool _isRevealing = false;
  bool _isRare = false;
  bool _isFriendMode = false;
  int _playCount = 0;
  double _analysisProgress = 0;
  String _analysisLabel = 'Queued for red-flag inspection...';

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;
  late AnimationController _flagWaveController;

  static const Color _accentColor = Color(0xFFFF1744);

  // ═══════════════════════════════════════════════════════════════════════
  // RED FLAG DATA — Organized by vibe
  // ═══════════════════════════════════════════════════════════════════════

  static const List<List<String>> _flagsByVibe = [
    [
      'You say you\'re "just going to watch tonight" and are fully naked within eight minutes.',
      'You treat the play space like a buffet and immediately start sampling the menu.',
      'You once turned harmless flirting into a situation requiring a group meeting.',
      'You wander through rooms like a very friendly tornado.',
      'You think "let\'s just see what happens" is a fully formed life plan.',
      'You once described a hookup afterward as excellent cardio.',
      'You treat flirtation like extreme sports with better lighting.',
      'You have confidently said "this will make a great story later" during a terrible decision.',
      'You bring a backpack to the party and unpack it like a traveling kink salesman.',
      'You say "I\'m pacing myself tonight" and then immediately forget that plan.',
      'You treat awkward silence like a challenge.',
      'You have accidentally created two separate love triangles in the same room.',
      'You once said "this will definitely not get weird" and it immediately got weird.',
      'You think tequila reveals your true self, which is unfortunate.',
      'You say "trust me" immediately before something that absolutely should not be trusted.',
      'You treat eye contact across the room like an invitation from fate.',
      'You believe stamina is mostly a confidence issue.',
      'You wander into cuddle piles like it\'s an open seat on public transit.',
      'You once said "don\'t worry, I\'ve done this before" right before attempting something extremely ambitious.',
      'You have used the phrase "okay but in my defense... chaos."',
      'You treat parties like a choose-your-own-adventure book.',
      'You once explained your dating situation and someone responded "I\'m going to need a diagram."',
      'You believe consequences are a future version of you problem.',
      'You say "I\'ll be right back" and return two hours later with a completely new friend group.',
      'You once paused mid-chaos to ask "has anyone tried this configuration before?"',
      'You think warm-up stretches are a perfectly reasonable thing to do before the party starts.',
      'You once tried to fix a bad decision by making another worse decision.',
      'You approach the night like a scientific field experiment.',
      'You have walked into a room, assessed the chaos, and decided to contribute.',
      'You believe chaos isn\'t something that happens around you - you are the chaos.',
      'You treat the toy table like a hardware store where you forgot your shopping list.',
      'You once said "I\'m just here for the vibe" and then became the vibe.',
      'You believe the phrase "this should work in theory" applies to bedroom logistics.',
      'You say "hold on, I have an idea" and everyone nearby immediately gets nervous.',
      'You once turned a casual moment into an extremely ambitious group activity.',
      'You treat curiosity like a competitive advantage.',
      'You once said "this might require teamwork."',
      'You think every party secretly needs a volunteer coordinator.',
      'You once paused and said "this is getting logistically impressive."',
      'You believe the phrase "just go with it" is a solid operating principle.',
      'You once said "I should probably stretch first."',
      'You approach the night like an Olympic qualifier.',
      'You have the confidence of someone who read half the instructions.',
      'You once said "this is either a great idea or a terrible one."',
      'You think the phrase "let\'s see what happens if..." is irresistible.',
      'You once declared "okay now it\'s a science experiment."',
      'You believe chaos improves with enthusiasm and hydration.',
      'You once said "I regret nothing... yet."',
      'You believe the best stories always start with "so there were more people than expected."',
    ],
  ];

  // Escalation add-ons for repeat plays
  static const List<String> _escalation = [
    '...and immediately recruits two more volunteers',
    '...and somehow turns it into a community project',
    '...and insists this is "actually very organized"',
    '...and proposes a sequel before hydration break',
    '...and calls this phase one with alarming confidence',
    '...and asks who wants to workshop it live',
  ];

  // Rare results (1-2% chance)
  static const List<String> _rareFlags = [
    'They ARE the red flag. Like, the whole flag. The entire flag store. Red Flags R Us. They own the franchise.',
    'Their red flag is so powerful it has its own gravitational pull. Entire dating apps have been destroyed trying to contain it.',
    'Scientists named a new shade of red after this person\'s red flag. It\'s called "Run."',
    'This red flag is visible from space. NASA confirmed.',
    'Their red flag has a red flag. It\'s red flags all the way down.',
  ];

  static const List<String> _chaosAddons = [
    'The room gave this idea side-eye and then participated anyway.',
    'Three strangers heard this plan and asked for a signup sheet.',
    'The algorithm tried to warn us, then joined the afterparty.',
    'Your archived stories now require waivers and hydration reminders.',
    'Someone reported this behavior to astrology and astrology said "fair."',
  ];

  static const List<String> _extremeFlags = [
    'You start every event saying "I\'m just observing" and then recruit a task force 12 minutes later.',
    'You hear "optional group activity" and treat it like your Olympic qualifying round.',
    'You turn one innocent flirt into a logistics map with arrows, initials, and hydration breaks.',
    'You walk into a room, clap once, and accidentally become the unofficial chaos facilitator.',
    'You treat consent check-ins like halftime strategy talks and everyone somehow says yes.',
    'You whisper "what if we escalated responsibly" and suddenly there\'s a sign-up list.',
    'You keep saying "this is a terrible idea" while actively assigning roles.',
    'You call it aftercare, but it\'s mostly a debrief for your latest questionable masterpiece.',
    'You start with "I have a tiny idea" and end with furniture being moved by committee.',
    'You collect people with eye contact and launch projects nobody requested but everyone remembers.',
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
    _flagWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _igController.dispose();
    _friendController.dispose();
    _revealController.dispose();
    _pulseController.dispose();
    _flagWaveController.dispose();
    super.dispose();
  }

  Future<void> _runFakeIgReview(String igHandle) async {
    final stages = <String>[
      'Opening @$igHandle profile...',
      'Reviewing captions under emotional duress...',
      'Parsing suspicious gym selfies...',
      'Cross-checking chaos in comments...',
      'Compiling deeply unnecessary verdict...',
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

  Future<void> _generateRedFlag() async {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    final igHandle = _igController.text.trim().replaceAll('@', '');
    if (name.isEmpty || igHandle.isEmpty) return;

    setState(() {
      _isRevealing = true;
      _analysisProgress = 0;
      _analysisLabel = 'Queued for red-flag inspection...';
    });
    _playCount++;
    unawaited(MinisAnalyticsService.instance.trackGamePlay('red_flag'));

    final seed = DateTime.now().microsecondsSinceEpoch ^
      name.hashCode ^
      _playCount ^
      igHandle.hashCode;
    final rng = Random(seed);

    final isRare = rng.nextInt(100) < 2;

    String flag;
    if (isRare) {
      flag = _rareFlags[rng.nextInt(_rareFlags.length)];
    } else {
      flag = _extremeFlags[rng.nextInt(_extremeFlags.length)];

      // Escalation after 3+ plays
      if (_playCount >= 3) {
        flag += '\n\n${_escalation[rng.nextInt(_escalation.length)]}';
      }
    }

    flag += '\n\n${_chaosAddons[rng.nextInt(_chaosAddons.length)]}';

    await _runFakeIgReview(igHandle);
    if (!mounted) return;

    setState(() {
      _generatedFlag = flag;
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
              text: 'RED FLAG',
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
            // Animated flag icon
            AnimatedBuilder(
              animation: _flagWaveController,
              builder: (context, child) {
                final wave = _flagWaveController.value;
                return Transform.rotate(
                  angle: (wave - 0.5) * 0.15,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _accentColor.withOpacity(0.3 + wave * 0.1),
                          _accentColor.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withOpacity(0.2 + wave * 0.1),
                          blurRadius: 20 + wave * 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      color: _accentColor,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              "What's Your Red Flag?",
              style: GoogleFonts.cinzel(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VesparaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Name + IG handle required.\nWe will now pretend this is forensic science.',
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
              onSubmit: _generateRedFlag,
            ),
            const SizedBox(height: 12),

            _buildInput(
              controller: _igController,
              hint: 'Enter IG handle (required)...',
              onSubmit: _generateRedFlag,
            ),
            const SizedBox(height: 12),

            // ── FRIEND CHALLENGE ──
            _buildFriendToggle(),
            if (_isFriendMode) ...[
              const SizedBox(height: 12),
              _buildInput(
                controller: _friendController,
                hint: 'Enter your friend\'s name...',
                onSubmit: _generateRedFlag,
              ),
            ],
            const SizedBox(height: 20),

            // ── GENERATE BUTTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRevealing ? null : _generateRedFlag,
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
                        _generatedFlag == null
                            ? '🚩 Expose My Red Flag'
                            : '🚩 Show Me Another',
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
            if (_generatedFlag != null) ...[
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
              '🚩 $name (@${_igController.text.trim().replaceAll('@', '')})\'s Red Flag:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.secondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _generatedFlag!,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isRare ? const Color(0xFFFFD700) : _accentColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 12),
            Text(
              'But honestly? You\'re still gonna swipe right.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: VesparaColors.secondary.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() => Row(
        children: [
          Expanded(
            child: _actionButton('🔄 Again', _generateRedFlag),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              '🔐 Try Safe Word',
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
              const Text('💀', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Think you can handle worse?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
                    Text(
                      'Play "Bad Idea Generator" next →',
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
