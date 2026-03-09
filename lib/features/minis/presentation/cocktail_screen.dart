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
/// WHAT COCKTAIL ARE YOU? 🍸
/// Name + vibe → cocktail personality match
/// Addictive: vibe selector, friend challenge, rare results, escalation,
/// cross-game suggestions, screenshot cards
/// ════════════════════════════════════════════════════════════════════════════

class CocktailScreen extends StatefulWidget {
  const CocktailScreen({super.key});

  @override
  State<CocktailScreen> createState() => _CocktailScreenState();
}

class _CocktailScreenState extends State<CocktailScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _friendController = TextEditingController();
  _CocktailResult? _result;
  bool _isRevealing = false;
  bool _isRare = false;
  bool _isFriendMode = false;
  int _playCount = 0;
  int _selectedVibe = 0;

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;

  static const Color _accentColor = Color(0xFF9C27B0);

  static const List<String> _vibeLabels = [
    'Flirting', 'Chaos', 'Trouble', 'Romance', 'Bad Decisions',
  ];
  static const List<String> _vibeEmojis = [
    '😏', '🔥', '😈', '💕', '🍸',
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // COCKTAIL RESULTS — By vibe
  // ═══════════════════════════════════════════════════════════════════════

  static const List<List<_CocktailResult>> _cocktailsByVibe = [
    // 0: Flirting
    [
      _CocktailResult(name: 'Dirty Martini', emoji: '🍸', color: Color(0xFF8BC34A), personality: 'You walk in like you own the room, even when you definitely don\'t.'),
      _CocktailResult(name: 'Cosmopolitan', emoji: '🍸', color: Color(0xFFEC407A), personality: 'Your entire personality is a Sex and the City episode and you\'re fine with that.'),
      _CocktailResult(name: 'Aperol Spritz', emoji: '🍊', color: Color(0xFFFF7043), personality: 'You ordered this for the color. Your entire personality is "European Summer."'),
      _CocktailResult(name: 'French 75', emoji: '🎩', color: Color(0xFFE0E0E0), personality: 'You seduce people with vocabulary and wine knowledge. You own linen pants.'),
      _CocktailResult(name: 'Daiquiri', emoji: '🍓', color: Color(0xFFE91E63), personality: 'You look sweet and innocent but you\'ve done things that would make a sailor blush.'),
      _CocktailResult(name: 'Mojito', emoji: '🌿', color: Color(0xFF4CAF50), personality: 'Fresh, fun, and absolutely will not be pinned down. "We\'re vibing" is your catchphrase.'),
      _CocktailResult(name: 'Champagne Cocktail', emoji: '🥂', color: Color(0xFFFFD54F), personality: 'Bougie on a budget. Your "luxury lifestyle" is a face mask from CVS.'),
      _CocktailResult(name: 'Vesper', emoji: '🕴️', color: Color(0xFF546E7A), personality: 'Licensed to kill hearts. You disappear into the night before they realize you\'re trouble.'),
      _CocktailResult(name: 'Paloma', emoji: '🌸', color: Color(0xFFF48FB1), personality: 'Lowkey dangerous. You suggest body shots at 11pm on a Tuesday.'),
      _CocktailResult(name: 'Pisco Sour', emoji: '🏔️', color: Color(0xFFF0F4C3), personality: 'Nobody sees you coming and that\'s your superpower. A wolf in introvert\'s clothing.'),
    ],
    // 1: Chaos
    [
      _CocktailResult(name: 'Long Island Iced Tea', emoji: '🥃', color: Color(0xFFAB47BC), personality: 'Seems chill at first. By round three you\'re the reason someone texted their ex.'),
      _CocktailResult(name: 'Jägerbomb', emoji: '💣', color: Color(0xFF1B5E20), personality: 'Walking bad decision. Your friends have a bail money fund named after you.'),
      _CocktailResult(name: 'Hurricane', emoji: '🌀', color: Color(0xFFE65100), personality: 'Category 5 dating disaster. Your dating history reads like a FEMA report.'),
      _CocktailResult(name: 'Tequila Shot', emoji: '🥃', color: Color(0xFFFFD740), personality: 'No thoughts just vibes. You skip foreplay in every area of life.'),
      _CocktailResult(name: 'Absinthe', emoji: '🧚', color: Color(0xFF69F0AE), personality: 'Artistic and unhinged. You journal about hookups in third person.'),
      _CocktailResult(name: 'Kamikaze', emoji: '✈️', color: Color(0xFF2979FF), personality: 'Self-destructive legend. You say "I love you" on the third date and mean it.'),
      _CocktailResult(name: 'Frozen Margarita', emoji: '🧊', color: Color(0xFF00E676), personality: 'Brain freeze energy. You once swiped right on your boss and didn\'t realize until the date.'),
      _CocktailResult(name: 'Rum Punch', emoji: '🥊', color: Color(0xFFEF5350), personality: 'Physically incapable of a quiet evening. You started a conga line at a funeral once.'),
      _CocktailResult(name: 'Harvey Wallbanger', emoji: '🧱', color: Color(0xFFFFAB00), personality: 'Relentlessly persistent. You showed up to a date you weren\'t invited to.'),
      _CocktailResult(name: 'Jungle Bird', emoji: '🦜', color: Color(0xFFFF3D00), personality: 'Loud and unfiltered. People either love you or block you. No in-between.'),
    ],
    // 2: Trouble
    [
      _CocktailResult(name: 'Negroni', emoji: '🍷', color: Color(0xFFE53935), personality: 'Pretentious but hot. Your dating profile says "sapiosexual" unironically.'),
      _CocktailResult(name: 'Dark & Stormy', emoji: '⛈️', color: Color(0xFF455A64), personality: 'Brooding heartbreaker. You don\'t ghost — you "drift," which is somehow worse.'),
      _CocktailResult(name: 'Porn Star Martini', emoji: '⭐', color: Color(0xFFFF6F00), personality: 'Zero shame, full send. You\'ve been described as "a lot" and took it as a compliment.'),
      _CocktailResult(name: 'Gimlet', emoji: '💚', color: Color(0xFF76FF03), personality: 'Sarcastic and untouchable. Your Bumble bio is just "no."'),
      _CocktailResult(name: 'Screwdriver', emoji: '🔧', color: Color(0xFFFF6F00), personality: 'Straightforward menace. You text "come over" with no context and everyone says yes.'),
      _CocktailResult(name: 'Boulevardier', emoji: '🎻', color: Color(0xFFB71C1C), personality: 'Emotionally intelligent but morally ambiguous. You weaponize therapy speak.'),
      _CocktailResult(name: 'Last Word', emoji: '🎤', color: Color(0xFF558B2F), personality: 'Has to win every argument. Your relationships end in closing statements, not breakups.'),
      _CocktailResult(name: 'Sidecar', emoji: '🏎️', color: Color(0xFFFF8F00), personality: 'Vintage heartbreaker. Your love letters could start wars and your DMs could end marriages.'),
      _CocktailResult(name: 'Grasshopper', emoji: '🦗', color: Color(0xFF4CAF50), personality: 'Suspiciously sweet. You weaponize cuteness. Emotional warfare in pastel colors.'),
      _CocktailResult(name: 'Sazerac', emoji: '🎷', color: Color(0xFF6D4C41), personality: 'Old soul, young chaos. Music taste of a jazz musician, hookup history of a sophomore.'),
    ],
    // 3: Romance
    [
      _CocktailResult(name: 'Sex on the Beach', emoji: '🏖️', color: Color(0xFFFF7043), personality: 'Shameless flirt. You\'ve never met a stranger — just future mistakes.'),
      _CocktailResult(name: 'Piña Colada', emoji: '🍍', color: Color(0xFFFFF176), personality: 'Delusional optimist. You think every toxic situationship ends differently "this time."'),
      _CocktailResult(name: 'Old Fashioned', emoji: '🥃', color: Color(0xFF8D6E63), personality: 'Emotionally unavailable hot person. People obsess over "cracking your code" but there is no code.'),
      _CocktailResult(name: 'Whiskey Sour', emoji: '🥃', color: Color(0xFFFFCA28), personality: 'Cynical romantic. You roast happy couples then cry to Adele alone in your car.'),
      _CocktailResult(name: 'Amaretto Sour', emoji: '🍑', color: Color(0xFFFFAB40), personality: 'Hopeless romantic disaster. You fall in love with everyone who makes eye contact for 3 seconds.'),
      _CocktailResult(name: 'Manhattan', emoji: '🌃', color: Color(0xFFC62828), personality: 'Intimidatingly attractive. Your resting face alone has rejected at least 30 people this year.'),
      _CocktailResult(name: 'Lemon Drop', emoji: '🍋', color: Color(0xFFFFEB3B), personality: 'Sweet now, sour later. You love-bomb then ghost. Emotionally inconsistent.'),
      _CocktailResult(name: 'Caipirinha', emoji: '🍋', color: Color(0xFFCDDC39), personality: 'International heartbreaker. You have an ex on every continent.'),
      _CocktailResult(name: 'Singapore Sling', emoji: '🌴', color: Color(0xFFFF80AB), personality: 'Dramatic internationalist. Every story starts with "so I was in [country]."'),
      _CocktailResult(name: 'Corpse Reviver', emoji: '💀', color: Color(0xFFB0BEC5), personality: 'Back from the dead. You\'ve been ghosted, bred-crumbed, and zombied — and survived.'),
    ],
    // 4: Bad Decisions
    [
      _CocktailResult(name: 'Espresso Martini', emoji: '☕', color: Color(0xFF5D4037), personality: 'Chaotic overachiever. You close the bar at 2am and send a work email at 2:47am.'),
      _CocktailResult(name: 'Tequila Sunrise', emoji: '🌅', color: Color(0xFFFF9800), personality: 'Main character energy. "I don\'t have exes, I have origin stories."'),
      _CocktailResult(name: 'Margarita', emoji: '🍹', color: Color(0xFF66BB6A), personality: 'Life of the party. First on the dance floor, last to leave. Salsa danced with a mannequin once.'),
      _CocktailResult(name: 'Moscow Mule', emoji: '🫏', color: Color(0xFFFFB74D), personality: 'Trendy contrarian. You broke up with someone over the wrong font in a text.'),
      _CocktailResult(name: 'Bloody Mary', emoji: '🍅', color: Color(0xFFD32F2F), personality: 'Chaos before noon. You treat hangovers as a personality trait.'),
      _CocktailResult(name: 'Gin & Tonic', emoji: '🫧', color: Color(0xFF81D4FA), personality: 'Type-A party animal. Your Google Calendar has color codes for "shenanigans."'),
      _CocktailResult(name: 'Blue Lagoon', emoji: '💎', color: Color(0xFF00B0FF), personality: 'Genetically blessed and emotionally cursed. Never single for more than 3 weeks.'),
      _CocktailResult(name: 'White Russian', emoji: '🥛', color: Color(0xFFBCAAA4), personality: 'Unbothered legend. Showed up in sweatpants to a formal event and still got hit on.'),
      _CocktailResult(name: 'Irish Coffee', emoji: '☘️', color: Color(0xFF33691E), personality: 'Functioning wreck. Held together by caffeine and spite.'),
      _CocktailResult(name: 'Mai Tai', emoji: '🌺', color: Color(0xFFFF5722), personality: 'Tropical unhinged. Your love language is "spontaneous bad decisions."'),
    ],
  ];

  // Rare cocktails (1-2% chance)
  static const List<_CocktailResult> _rareCocktails = [
    _CocktailResult(
      name: 'The Forbidden Elixir',
      emoji: '🔮',
      color: Color(0xFFFFD700),
      personality: 'This cocktail doesn\'t exist on any menu. It materialized from pure chaotic energy. You are the drink. The drink is you. Bartenders weep.',
    ),
    _CocktailResult(
      name: 'Liquid Audacity',
      emoji: '⚡',
      color: Color(0xFFFFD700),
      personality: 'One sip and you become unstoppable. Two sips and you become a wanted person in three states. This is the rarest cocktail assignment in existence.',
    ),
    _CocktailResult(
      name: 'The Main Character',
      emoji: '👑',
      color: Color(0xFFFFD700),
      personality: 'You didn\'t get a cocktail. You ARE the cocktail. Every bar was built in your honor. The algorithm broke trying to contain your energy.',
    ),
  ];

  // Escalation flavor texts for repeat plays
  static const List<String> _escalation = [
    'The bartender is concerned about you.',
    'Your liver filed a formal complaint.',
    'This is your villain origin story.',
    'Somewhere, a therapist just got a new client.',
    'Your friends made a group chat about this.',
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

  void _generateCocktail() {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isRevealing = true);
    _playCount++;
    unawaited(MinisAnalyticsService.instance.trackGamePlay('cocktail'));

    final seed = DateTime.now().microsecondsSinceEpoch ^
      name.hashCode ^
      _playCount ^
      (_selectedVibe << 8);
    final rng = Random(seed);

    final isRare = rng.nextInt(100) < 2;
    _CocktailResult cocktail;

    if (isRare) {
      cocktail = _rareCocktails[rng.nextInt(_rareCocktails.length)];
    } else {
      final vibeCocktails = _cocktailsByVibe[_selectedVibe];
      cocktail = vibeCocktails[rng.nextInt(vibeCocktails.length)];
    }

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _result = cocktail;
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
              text: 'COCKTAIL',
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
            // Cocktail icon
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
                    Icons.local_bar_rounded,
                    color: _accentColor,
                    size: 32,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'What Cocktail Are You?',
              style: GoogleFonts.cinzel(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VesparaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your name and find out which drink\nmatches your chaotic energy.',
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
              onSubmit: _generateCocktail,
            ),
            const SizedBox(height: 12),

            // ── FRIEND CHALLENGE ──
            _buildFriendToggle(),
            if (_isFriendMode) ...[
              const SizedBox(height: 12),
              _buildInput(
                controller: _friendController,
                hint: 'Enter your friend\'s name...',
                onSubmit: _generateCocktail,
              ),
            ],
            const SizedBox(height: 20),

            // ── GENERATE BUTTON ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRevealing ? null : _generateCocktail,
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
                            ? '🍸 Mix My Cocktail'
                            : '🍸 Shake Again',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // ── RESULT CARD ──
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
    final cocktail = _result!;
    final displayColor = _isRare ? const Color(0xFFFFD700) : cocktail.color;

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
            color: displayColor.withOpacity(_isRare ? 0.6 : 0.5),
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
              cocktail.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              '$name is a...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: VesparaColors.secondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cocktail.name,
              style: GoogleFonts.cinzel(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: displayColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              cocktail.personality,
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
            child: _actionButton('🔄 Again', _generateCocktail),
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
                      'Where would you get caught?',
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
}

class _CocktailResult {
  const _CocktailResult({
    required this.name,
    required this.emoji,
    required this.color,
    required this.personality,
  });
  final String name;
  final String emoji;
  final Color color;
  final String personality;
}
