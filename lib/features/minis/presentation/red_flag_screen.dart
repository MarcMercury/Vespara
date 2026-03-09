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
  final _friendController = TextEditingController();
  String? _generatedFlag;
  bool _isRevealing = false;
  bool _isRare = false;
  bool _isFriendMode = false;
  int _playCount = 0;
  int _selectedVibe = 0;

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;
  late AnimationController _flagWaveController;

  static const Color _accentColor = Color(0xFFFF1744);

  static const List<String> _vibeLabels = [
    'Flirting', 'Chaos', 'Trouble', 'Romance', 'Bad Decisions',
  ];
  static const List<String> _vibeEmojis = [
    '😏', '🔥', '😈', '💕', '🍸',
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // RED FLAG DATA — Organized by vibe
  // ═══════════════════════════════════════════════════════════════════════

  static const List<List<String>> _flagsByVibe = [
    // 0: Flirting
    [
      'Still has their ex\'s Netflix password AND their nudes saved in a folder called "Tax Documents"',
      'Sends unsolicited voice memos at 3am that are just heavy breathing and "you up?"',
      'Thinks foreplay is just aggressively winking from across the room',
      'Considers watching someone\'s Instagram story as "the first move"',
      'Types "haha" but has never actually laughed in person',
      'Their go-to flirting technique is showing you their credit score',
      'Describes themselves as "sexually advanced" on the first date like it\'s a LinkedIn skill',
      'Screenshots every flirty DM and sends it to the group chat for peer review',
      'Uses finger guns after every orgasm and winks at themselves in the mirror',
      'Still uses pickup lines from 2008 and gets genuinely offended when they don\'t work',
      'Has customized their phone\'s autocorrect to change "sorry" to "your loss"',
      'Sends "u up?" texts to 6 people simultaneously and picks the first responder',
    ],
    // 1: Chaos
    [
      'Has a body count spreadsheet with a rating system and Yelp-style reviews',
      'Has been banned from 3 different dating apps and considers it a flex',
      'Refers to their genitals by a name and introduces them separately',
      'Has an alarm set for "weekly sext quota" and treats it like a KPI',
      'Rates every kiss on a 1-10 scale out loud, in real time',
      'Has a Google Calendar invite for breakups scheduled 6 weeks out',
      'Keeps a drawer of "trophies" from past hookups like a serial killer',
      'Has a Costco-sized bottle of lube on the nightstand and calls it "the essentials"',
      'Calls orgasms "arrivals" and announces them like a flight attendant',
      'Sets a timer during sex and gets competitive about beating their personal record',
      'Brings a whiteboard to the bedroom for "strategic planning"',
      'Has a finsta dedicated entirely to rating their Hinge matches',
    ],
    // 2: Trouble
    [
      'Makes you sign an NDA before the second date',
      'Has a vision board that\'s just pictures of their ex with X\'s through them',
      'Still sleeps with a body pillow that has their ex\'s face printed on it',
      'Their safe word is their ex\'s name and they "forget" every time',
      'Takes a selfie mid-hookup for their "private collection"',
      'Keeps score of who initiates sex and brings up the stats during arguments',
      'Brings measuring tape to the bedroom and won\'t explain why',
      'Has a loyalty card for the STD clinic and is two stamps away from a free test',
      'Moans their own name during sex and sees nothing wrong with it',
      'Tests your loyalty by creating a fake dating profile and matching with you',
      'Wears sunglasses indoors during sex for "the aesthetic"',
      'Records voice notes to themselves after dates titled "performance review"',
    ],
    // 3: Romance
    [
      'Asks "what are we" on the first date while the appetizers are still coming',
      'Has a playlist for every stage of a situationship including "the ghost"',
      'Has matching underwear for every zodiac sign and wears them accordingly',
      'Brings a PowerPoint presentation to the first date titled "Why I\'m Worth It"',
      'Replies to "I love you" with "I know" and genuinely thinks they\'re Han Solo',
      'Cries during sex but insists it\'s "happy tears" every single time',
      'Their idea of dirty talk is reading their horoscope in a seductive voice',
      'Uses the phrase "I\'m kind of a big deal on Tinder" unironically',
      'Brings their emotional support animal to every hookup',
      'Says "that\'s what she said" DURING intimate moments without a hint of irony',
      'Has a highlight reel of their best thirst traps saved as their phone wallpaper',
      'Their pillow talk is literally just them reading tweets out loud',
    ],
    // 4: Bad Decisions
    [
      'Calls their mom DURING sex to ask what temperature to set the oven to',
      'Has a "signature move" they named after themselves and demonstrates at parties',
      'Brings a clipboard to bed and asks you to fill out a feedback form after',
      'Orders for you at restaurants AND in the bedroom',
      'Takes protein shakes to bed and calls it "pre-workout"',
      'Considers "ghosting" a legitimate conflict resolution strategy',
      'Has named every piece of lingerie in their drawer and introduces them like pets',
      'Texts "we need to talk" and then sends a link to their SoundCloud',
      'Still has Tinder notifications on during your anniversary dinner',
      'Has a dating profile that says "fluent in sarcasm" and "not looking for drama"',
      'Has a spreadsheet tracking the ROI of every date they\'ve ever been on',
      'Thinks "Netflix and chill" literally means watching Netflix and being cold',
    ],
  ];

  // Escalation add-ons for repeat plays
  static const List<String> _escalation = [
    '...and genuinely thinks it\'s a green flag',
    '...and has done this at EVERY relationship milestone',
    '...and made a TikTok about it that went viral',
    '...and their therapist already knows about this one',
    '...and they WILL do it again',
    '...and posted about it on LinkedIn',
  ];

  // Rare results (1-2% chance)
  static const List<String> _rareFlags = [
    'They ARE the red flag. Like, the whole flag. The entire flag store. Red Flags R Us. They own the franchise.',
    'Their red flag is so powerful it has its own gravitational pull. Entire dating apps have been destroyed trying to contain it.',
    'Scientists named a new shade of red after this person\'s red flag. It\'s called "Run."',
    'This red flag is visible from space. NASA confirmed.',
    'Their red flag has a red flag. It\'s red flags all the way down.',
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
    _friendController.dispose();
    _revealController.dispose();
    _pulseController.dispose();
    _flagWaveController.dispose();
    super.dispose();
  }

  void _generateRedFlag() {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isRevealing = true);
    _playCount++;
    unawaited(MinisAnalyticsService.instance.trackGamePlay('red_flag'));

    final seed = DateTime.now().microsecondsSinceEpoch ^
      name.hashCode ^
      _playCount ^
      (_selectedVibe << 8);
    final rng = Random(seed);

    final isRare = rng.nextInt(100) < 2;

    String flag;
    if (isRare) {
      flag = _rareFlags[rng.nextInt(_rareFlags.length)];
    } else {
      final vibeFlags = _flagsByVibe[_selectedVibe];
      flag = vibeFlags[rng.nextInt(vibeFlags.length)];

      // Escalation after 3+ plays
      if (_playCount >= 3) {
        flag += '\n\n${_escalation[rng.nextInt(_escalation.length)]}';
      }
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _generatedFlag = flag;
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
              'We all have one. Yours is just funnier\nthan you think.',
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
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
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
              '🚩 $name\'s Red Flag:',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
