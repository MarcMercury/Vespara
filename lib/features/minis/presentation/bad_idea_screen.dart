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
/// BAD IDEA GENERATOR 💀
/// Name + vibe → terrible dating/sex/relationship idea + regret meter
/// Addictive: vibe selector, friend challenge, rare results, escalation,
/// cross-game suggestions, screenshot cards
/// ════════════════════════════════════════════════════════════════════════════

class BadIdeaScreen extends StatefulWidget {
  const BadIdeaScreen({super.key});

  @override
  State<BadIdeaScreen> createState() => _BadIdeaScreenState();
}

class _BadIdeaScreenState extends State<BadIdeaScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _friendController = TextEditingController();
  _BadIdea? _result;
  bool _isRevealing = false;
  bool _isRare = false;
  bool _isFriendMode = false;
  int _playCount = 0;
  int _selectedVibe = 0;

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;
  late AnimationController _flickerController;

  static const Color _accentColor = Color(0xFF00BFA5);

  static const List<String> _vibeLabels = [
    'Flirting', 'Chaos', 'Trouble', 'Romance', 'Bad Decisions',
  ];
  static const List<String> _vibeEmojis = [
    '😏', '🔥', '😈', '💕', '🍸',
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // BAD IDEAS — By vibe, with regret levels
  // ═══════════════════════════════════════════════════════════════════════

  static const List<List<_BadIdea>> _ideasByVibe = [
    // 0: Flirting
    [
      _BadIdea(idea: 'Slide into your crush\'s DMs by commenting "🍆" on their family vacation photo', regret: 9),
      _BadIdea(idea: 'Fake an accent for the entire first date and see how long you can sustain it', regret: 6),
      _BadIdea(idea: 'Bring flash cards with pre-written compliments to a date and read them verbatim', regret: 6),
      _BadIdea(idea: 'Send a "we need to talk" text and then just send a meme', regret: 7),
      _BadIdea(idea: 'Create a dating profile where every photo is a different disguise', regret: 5),
      _BadIdea(idea: 'Show up to a date with a clipboard and interview them like it\'s a job application', regret: 7),
      _BadIdea(idea: 'Use a megaphone to ask someone out in a crowded restaurant', regret: 9),
      _BadIdea(idea: 'Tell your date you googled them and then list everything you found, in chronological order', regret: 9),
      _BadIdea(idea: 'Casually bring up your wedding Pinterest board during appetizers on a first date', regret: 9),
      _BadIdea(idea: 'Respond to their "goodnight" text with a full business proposal for the relationship', regret: 8),
    ],
    // 1: Chaos
    [
      _BadIdea(idea: 'Double-book two dates at the same restaurant and try to manage both simultaneously', regret: 10),
      _BadIdea(idea: 'Livestream your dates on TikTok for "content" without telling the other person', regret: 10),
      _BadIdea(idea: 'Replace all the photos in your home with photos of your date before they come over for the first time', regret: 10),
      _BadIdea(idea: 'Wear a body cam on every first date "for legal purposes"', regret: 9),
      _BadIdea(idea: 'Announce your body count at Thanksgiving dinner to "keep things transparent"', regret: 10),
      _BadIdea(idea: 'Play your sex playlist on aux at a family BBQ and pretend you "didn\'t notice"', regret: 9),
      _BadIdea(idea: 'Hire a skywriter to ask someone to be exclusive after 2 dates', regret: 9),
      _BadIdea(idea: 'Install a clap-on light in the bedroom and see what happens', regret: 7),
      _BadIdea(idea: 'Set up a projector to display your ex\'s texts as a "learning experience" during a date', regret: 10),
      _BadIdea(idea: 'Name your sex moves after your favorite wrestlers and announce them in real time', regret: 8),
    ],
    // 2: Trouble
    [
      _BadIdea(idea: 'Text your ex "I miss you" at 2am and then immediately text "sorry wrong person"', regret: 9),
      _BadIdea(idea: 'Test your partner\'s loyalty by creating a fake dating profile and matching with them', regret: 10),
      _BadIdea(idea: 'Tell your partner you need space and then show up at every place they go', regret: 10),
      _BadIdea(idea: 'Leave a Yelp review for your ex and tag them in it', regret: 10),
      _BadIdea(idea: 'CC your entire friend group on the "I think we should see other people" email', regret: 10),
      _BadIdea(idea: 'Ghost someone and then act surprised when you see them: "Oh, I thought you moved!"', regret: 8),
      _BadIdea(idea: 'Create a LinkedIn post about your breakup with actionable takeaways', regret: 10),
      _BadIdea(idea: 'Break up by changing your Netflix password and waiting for them to figure it out', regret: 7),
      _BadIdea(idea: 'Keep a scoreboard of arguments won in the relationship and bring it up during fights', regret: 9),
      _BadIdea(idea: 'Make a PowerPoint about why you\'re better than their ex and present it at dinner', regret: 9),
    ],
    // 3: Romance
    [
      _BadIdea(idea: 'Propose on the first date because "when you know, you know"', regret: 10),
      _BadIdea(idea: 'Get matching tattoos on the second date because "we\'re soulmates"', regret: 10),
      _BadIdea(idea: 'Tell your date you already named your future kids... after your exes', regret: 10),
      _BadIdea(idea: 'Update your relationship status to "It\'s Complicated" the morning after the first date', regret: 8),
      _BadIdea(idea: 'Start a relationship journal and leave it open on the coffee table during a date', regret: 8),
      _BadIdea(idea: 'Bring your own chef to cook at their apartment on a third date to "set the standard"', regret: 6),
      _BadIdea(idea: 'Tell someone their kissing technique "needs work" and offer to grade them on a rubric', regret: 8),
      _BadIdea(idea: 'Use astrology to justify every terrible thing you do: "Sorry I ghosted, Mercury was in retrograde"', regret: 6),
      _BadIdea(idea: 'Schedule a quarterly performance review with your partner complete with KPIs', regret: 8),
      _BadIdea(idea: 'Practice breakup speeches in the mirror before every date, just to be prepared', regret: 6),
    ],
    // 4: Bad Decisions
    [
      _BadIdea(idea: 'Go on a Tinder date and bring your mom for "quality control"', regret: 10),
      _BadIdea(idea: 'Use your partner\'s toothbrush as a power move to establish dominance', regret: 7),
      _BadIdea(idea: 'Venmo request your date for exactly half the bill — including tax, tip, and the bread they didn\'t eat', regret: 7),
      _BadIdea(idea: 'Bring a whiteboard to bed and ask for a post-game analysis', regret: 9),
      _BadIdea(idea: 'Tell your date you\'re "emotionally available" while visibly texting 3 other people', regret: 8),
      _BadIdea(idea: 'Order for your date without asking what they want because "I know what\'s best"', regret: 8),
      _BadIdea(idea: 'Bring a chaperone to every date until "trust is established" at the 6 month mark', regret: 9),
      _BadIdea(idea: 'Start rating your partner\'s outfits on a 1-10 scale every morning. Out loud.', regret: 8),
      _BadIdea(idea: 'Respond to every vulnerability your partner shares with "that\'s crazy, anyway..."', regret: 10),
      _BadIdea(idea: 'Set up a customer satisfaction survey after every hookup and tie bonuses to the results', regret: 9),
    ],
  ];

  // Rare bad ideas (1-2% chance)
  static const List<_BadIdea> _rareIdeas = [
    _BadIdea(
      idea: 'Rent a billboard on your ex\'s commute that just says "I\'m doing better than you" with your Venmo QR code',
      regret: 11,
    ),
    _BadIdea(
      idea: 'Hire a mariachi band to follow your date around for a week to see if they can "handle the pressure"',
      regret: 11,
    ),
    _BadIdea(
      idea: 'File a Freedom of Information Act request on your partner\'s search history and present it framed',
      regret: 11,
    ),
  ];

  // Escalation lines for repeat plays
  static const List<String> _escalation = [
    'Your friends would stage an intervention if they saw this.',
    'You\'ve gone too deep. There\'s no coming back.',
    'This is your fourth bad idea. You ARE the bad idea now.',
    'At this point, you should teach a masterclass.',
    'Somewhere, a reality TV producer just got excited.',
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
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _friendController.dispose();
    _revealController.dispose();
    _pulseController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  void _generateBadIdea() {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isRevealing = true);
    _playCount++;
    unawaited(MinisAnalyticsService.instance.trackGamePlay('bad_idea'));

    final seed = DateTime.now().microsecondsSinceEpoch ^
      name.hashCode ^
      _playCount ^
      (_selectedVibe << 8);
    final rng = Random(seed);

    final isRare = rng.nextInt(100) < 2;
    _BadIdea idea;

    if (isRare) {
      idea = _rareIdeas[rng.nextInt(_rareIdeas.length)];
    } else {
      final vibeIdeas = _ideasByVibe[_selectedVibe];
      idea = vibeIdeas[rng.nextInt(vibeIdeas.length)];
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _result = idea;
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
              text: 'BAD IDEAS',
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
            // Flame icon
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
                    Icons.whatshot_rounded,
                    color: _accentColor,
                    size: 32,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Bad Idea Generator',
              style: GoogleFonts.cinzel(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VesparaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your name and get a dating idea\nso bad it might actually work.',
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
              onSubmit: _generateBadIdea,
            ),
            const SizedBox(height: 12),

            // ── FRIEND CHALLENGE ──
            _buildFriendToggle(),
            if (_isFriendMode) ...[
              const SizedBox(height: 12),
              _buildInput(
                controller: _friendController,
                hint: 'Enter your friend\'s name...',
                onSubmit: _generateBadIdea,
              ),
            ],
            const SizedBox(height: 20),

            // ── GENERATE BUTTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRevealing ? null : _generateBadIdea,
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
                            ? '💀 Generate a Bad Idea'
                            : '💀 Give Me Another',
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
    final idea = _result!;
    final regret = idea.regret.clamp(1, 11);
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
            const SizedBox(height: 12),
            Text(
              '$name\'s Bad Idea:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.secondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              idea.idea,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isRare ? const Color(0xFFFFD700) : VesparaColors.primary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Regret meter
            Column(
              children: [
                Text(
                  'REGRET METER',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: VesparaColors.secondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(10, (i) {
                    final filled = i < regret;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedBuilder(
                        animation: _flickerController,
                        builder: (context, child) {
                          final flicker = filled && i == regret - 1
                              ? _flickerController.value
                              : 1.0;
                          return Opacity(
                            opacity: filled ? 0.5 + flicker * 0.5 : 0.2,
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              size: 18,
                              color: filled
                                  ? _regretColor(regret)
                                  : VesparaColors.secondary,
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${regret > 10 ? "11" : "$regret"}/10 — ${_regretLabel(regret)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _regretColor(regret),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
            child: _actionButton('🔄 Again', _generateBadIdea),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              '🚩 Try Red Flag',
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
              const Text('📍', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where would you act on it?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
                    Text(
                      'Play "Where You\'d Definitely Get Caught" next →',
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

  Color _regretColor(int level) {
    if (level <= 3) return const Color(0xFF4CAF50);
    if (level <= 6) return const Color(0xFFFF9800);
    if (level <= 8) return const Color(0xFFFF5722);
    return const Color(0xFFFF1744);
  }

  String _regretLabel(int level) {
    if (level <= 3) return 'Mildly Questionable';
    if (level <= 5) return 'Probably Shouldn\'t';
    if (level <= 7) return 'Definitely Shouldn\'t';
    if (level <= 8) return 'Absolutely Do Not';
    if (level <= 10) return 'Restraining Order Territory';
    return 'Beyond Human Comprehension';
  }
}

class _BadIdea {
  const _BadIdea({
    required this.idea,
    required this.regret,
  });
  final String idea;
  final int regret;
}
