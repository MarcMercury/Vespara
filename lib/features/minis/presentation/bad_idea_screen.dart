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
  final _igController = TextEditingController();
  final _friendController = TextEditingController();
  _BadIdea? _result;
  bool _isRevealing = false;
  bool _isRare = false;
  bool _isFriendMode = false;
  int _playCount = 0;
  double _analysisProgress = 0;
  String _analysisLabel = 'Queued for terrible-idea synthesis...';

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;
  late AnimationController _flickerController;

  static const Color _accentColor = Color(0xFF00BFA5);

  static const List<String> _chaosAddons = [
    'Then go live for no reason and call it manifestation.',
    'Also tag three mutuals and one random DJ.',
    'Finish by posting a cryptic quote about "energy shifts."',
    'Bring a fog machine. Explain nothing. Leave suddenly.',
    'Afterward, deny all responsibility and blame moonlight.',
  ];

  static const List<_BadIdea> _communityIdeas = [
    _BadIdea(idea: 'Text your ex\'s best friend "hey, you up?" and screenshot the reply for your group chat.', regret: 10),
    _BadIdea(idea: 'Hook up with someone at a house party, then accidentally match with their roommate on Tinder the next morning and swipe right anyway.', regret: 10),
    _BadIdea(idea: 'Give your real number to two people at the same bar and let them figure it out when you text back "which one are you again?"', regret: 9),
    _BadIdea(idea: 'Sleep with your roommate and just assume the living situation will sort itself out.', regret: 10),
    _BadIdea(idea: 'Send nudes from the work bathroom during a team meeting you\'re still technically on camera for.', regret: 10),
    _BadIdea(idea: 'Bring a Bluetooth speaker into the bedroom, play your own entrance music, and refuse to explain.', regret: 8),
    _BadIdea(idea: 'Drunkenly tell your partner\'s parents exactly how you two met — including the parts you swore you\'d never repeat.', regret: 10),
    _BadIdea(idea: 'Start a group chat called "candidates" with everyone you\'re currently seeing and accidentally send a message to it.', regret: 10),
    _BadIdea(idea: 'Let your friend set up a hidden camera prank during your next hookup and only tell you about it after.', regret: 10),
    _BadIdea(idea: 'Get your FWB\'s name tattooed on your inner thigh after the third hookup to "see where it goes."', regret: 10),
    _BadIdea(idea: 'Accept a dare to skinny dip at a pool party where your boss is also a guest.', regret: 10),
    _BadIdea(idea: 'Leave your unlocked phone on the table during a first date with your Tinder notifications still on.', regret: 9),
    _BadIdea(idea: 'Reply "I love you" to someone you\'ve been seeing for two weeks just to see how fast they type back.', regret: 9),
    _BadIdea(idea: 'Use your couple\'s therapy session to announce you\'ve been DMing their coworker.', regret: 10),
    _BadIdea(idea: 'Agree to a threesome with two people who don\'t know they\'re both your exes until everyone shows up.', regret: 10),
    _BadIdea(idea: 'Post a thirst trap from your partner\'s apartment with the location tag on and let the chaos unfold.', regret: 9),
    _BadIdea(idea: 'Confess feelings for your best friend at 2am via voice note, then pretend your phone was hacked.', regret: 10),
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
      _BadIdea(idea: 'Schedule a quarterly performance review with your partner complete with KPIs', regret: 8),
      _BadIdea(idea: 'Practice breakup speeches in front of your partner before every date, just to be prepared', regret: 6),
    ],
    // 4: Bad Decisions
    [
      _BadIdea(idea: 'Go on a Tinder date and bring your mom for "quality control"', regret: 10),
      _BadIdea(idea: 'Use your partner\'s toothbrush as a power move to establish dominance', regret: 7),
      _BadIdea(idea: 'Bring a whiteboard to bed and ask for a post-game analysis', regret: 9),
      _BadIdea(idea: 'Tell your date you\'re "emotionally available" while visibly texting 3 other people', regret: 8),
      _BadIdea(idea: 'Order for your date without asking what they want because "I know what\'s best"', regret: 8),
      _BadIdea(idea: 'Bring a chaperone to every date until "trust is established" at the 6 month mark', regret: 9),
      _BadIdea(idea: 'Start rating your partner\'s outfits on a 1-10 scale every morning. Out loud.', regret: 8),
      _BadIdea(idea: 'Respond to every vulnerability your partner shares with "that\'s crazy, anyway..."', regret: 10),
      _BadIdea(idea: 'Set up a customer satisfaction survey after every hookup and tie bonuses to the results', regret: 9),
      _BadIdea(idea: 'Start introducing strangers to each other as "people who should definitely hook up" and then leave the room.', regret: 10),
      _BadIdea(idea: 'Grab a whiteboard and start diagramming everyone\'s relationship structure.', regret: 10),
      _BadIdea(idea: 'Walk into the busiest room and loudly ask "so what are the rules in here?"', regret: 8),
      _BadIdea(idea: 'Pick two people at random and tell them "you two have incredible chemistry."', regret: 8),
      _BadIdea(idea: 'Begin narrating what\'s happening in the room like a sports commentator.', regret: 8),
      _BadIdea(idea: 'Ask everyone nearby what their safe word is and start ranking them.', regret: 10),
      _BadIdea(idea: 'Try to start a chant for absolutely no reason.', regret: 7),
      _BadIdea(idea: 'Wander into a room, clap once loudly, and say "okay hear me out.", then immediately leave the room.', regret: 8),
      _BadIdea(idea: 'Ask a group of strangers if they want to try something "logistically ambitious."', regret: 10),
      _BadIdea(idea: 'Start a timer and tell everyone something interesting needs to happen before it ends.', regret: 8),
      _BadIdea(idea: 'Begin giving unsolicited performance coaching.', regret: 8),
      _BadIdea(idea: 'Decide the party needs a tournament and start assigning brackets.', regret: 9),
      _BadIdea(idea: 'Start a drinking game based on awkward eye contact.', regret: 8),
      _BadIdea(idea: 'Suggest adding more people to a situation that is already complicated.', regret: 10),
      _BadIdea(idea: 'Start assigning people nicknames based on their energy.', regret: 7),
      _BadIdea(idea: 'Start explaining a plan that somehow involves everyone in the room.', regret: 10),
      _BadIdea(idea: 'Offer to referee something nobody realized was competitive.', regret: 8),
      _BadIdea(idea: 'Start recruiting participants for something you\'re calling "Phase Two."', regret: 10),
      _BadIdea(idea: 'Begin explaining a plan that involves moving furniture.', regret: 9),
      _BadIdea(idea: 'Ask if anyone has a coin so you can let fate decide something.', regret: 7),
      _BadIdea(idea: 'Suggest combining two completely unrelated ideas.', regret: 9),
      _BadIdea(idea: 'Explain your entire polycule structure to someone who only asked what you\'re drinking, then invite them to meet everyone immediately.', regret: 10),
      _BadIdea(idea: 'Bring three people who don\'t know each other together, introduce them as "future best friends," and walk away.', regret: 8),
      _BadIdea(idea: 'Walk up to the toy table, grab something you\'ve never used before, and treat it like a puzzle you\'re determined to solve.', regret: 9),
      _BadIdea(idea: 'Turn a quiet moment into a group activity by inviting whoever happens to be nearby.', regret: 8),
      _BadIdea(idea: 'Turn a casual flirtation into a multi-person situation before anyone finishes their drink.', regret: 10),
      _BadIdea(idea: 'Invite someone to join you in exploring whatever is happening in the next room.', regret: 8),
      _BadIdea(idea: 'Take a suggestion someone makes jokingly and treat it like a real plan.', regret: 8),
      _BadIdea(idea: 'Follow someone into another room just to see what happens.', regret: 7),
      _BadIdea(idea: 'Commit fully to an idea that sounded funny thirty seconds ago.', regret: 9),
      _BadIdea(idea: 'Turn curiosity into a multi-person collaboration.', regret: 8),
      _BadIdea(idea: 'Join a situation mid-way through and assume you\'ll catch up quickly.', regret: 8),
    ],
  ];

  // Rare bad ideas (1-2% chance)
  static const List<_BadIdea> _rareIdeas = [
    _BadIdea(
      idea: 'Hire a string quartet to soundtrack your debrief circle and insist this improves emotional processing.',
      regret: 11,
    ),
    _BadIdea(
      idea: 'Publish a laminated play-party flowchart titled "Operational Passion v3" and hand it to strangers at check-in.',
      regret: 11,
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
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _igController.dispose();
    _friendController.dispose();
    _revealController.dispose();
    _pulseController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  Future<void> _runFakeIgReview(String igHandle) async {
    final stages = <String>[
      'Opening @$igHandle profile...',
      'Reviewing impulsive captions...',
      'Checking for strategic oversharing...',
      'Computing regret probability...',
      'Assembling premium bad idea...',
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

  Future<void> _generateBadIdea() async {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    final igHandle = _igController.text.trim().replaceAll('@', '');
    if (name.isEmpty || igHandle.isEmpty) return;

    setState(() {
      _isRevealing = true;
      _analysisProgress = 0;
      _analysisLabel = 'Queued for terrible-idea synthesis...';
    });
    _playCount++;
    unawaited(MinisAnalyticsService.instance.trackGamePlay('bad_idea'));

    final seed = DateTime.now().microsecondsSinceEpoch ^
      name.hashCode ^
      _playCount ^
      igHandle.hashCode;
    final rng = Random(seed);

    final isRare = rng.nextInt(100) < 2;
    _BadIdea idea;

    if (isRare) {
      idea = _rareIdeas[rng.nextInt(_rareIdeas.length)];
    } else {
      final picked = _communityIdeas[rng.nextInt(_communityIdeas.length)];
      idea = _BadIdea(
        idea: '${picked.idea} ${_chaosAddons[rng.nextInt(_chaosAddons.length)]}',
        regret: (picked.regret + rng.nextInt(2)).clamp(1, 11),
      );
    }

    await _runFakeIgReview(igHandle);
    if (!mounted) return;

    setState(() {
      _result = idea;
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
              'Enter name + IG handle and we\'ll fake-calculate the worst possible plan.',
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
              onSubmit: _generateBadIdea,
            ),
            const SizedBox(height: 12),

            _buildInput(
              controller: _igController,
              hint: 'Enter IG handle (required)...',
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
                    ? Text(
                        'Reviewing @${_igController.text.trim().replaceAll('@', '')}...',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
              '$name (@${_igController.text.trim().replaceAll('@', '')})\'s Bad Idea:',
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
            ],
            const SizedBox(height: 12),
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
