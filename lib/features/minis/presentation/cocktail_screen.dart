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
/// Name + IG handle → random real cocktail personality match
/// ════════════════════════════════════════════════════════════════════════════

class CocktailScreen extends StatefulWidget {
  const CocktailScreen({super.key});

  @override
  State<CocktailScreen> createState() => _CocktailScreenState();
}

class _CocktailScreenState extends State<CocktailScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _igController = TextEditingController();
  final _friendController = TextEditingController();
  _CocktailResult? _result;
  bool _isRevealing = false;
  bool _isFriendMode = false;
  double _analysisProgress = 0;
  String _analysisLabel = 'Queued for cocktail profiling...';

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;

  static const Color _accentColor = Color(0xFF9C27B0);

  static const List<_CocktailResult> _chaosCocktailPool = [
    _CocktailResult(name: 'Margarita', emoji: '🍹', color: Color(0xFF66BB6A), personality: 'You treat minor inconveniences like they\'re betrayal arcs in a long-running drama.'),
    _CocktailResult(name: 'Negroni', emoji: '🍷', color: Color(0xFFE53935), personality: 'You make eye contact with animals like you\'re negotiating something.'),
    _CocktailResult(name: 'Old Fashioned', emoji: '🥃', color: Color(0xFF8D6E63), personality: 'You maintain a suspicious level of confidence about things you clearly just made up.'),
    _CocktailResult(name: 'Espresso Martini', emoji: '☕', color: Color(0xFF5D4037), personality: 'You operate like every situation secretly requires a dramatic speech.'),
    _CocktailResult(name: 'Martini', emoji: '🍸', color: Color(0xFFB0BEC5), personality: 'You behave like you are constantly seconds away from revealing a master plan.'),
    _CocktailResult(name: 'Cosmopolitan', emoji: '🍸', color: Color(0xFFEC407A), personality: 'You talk about normal life events like they\'re legendary stories from a war.'),
    _CocktailResult(name: 'Mojito', emoji: '🌿', color: Color(0xFF4CAF50), personality: 'You radiate the energy of someone who would absolutely escalate things "for the plot."'),
    _CocktailResult(name: 'Manhattan', emoji: '🌃', color: Color(0xFFC62828), personality: 'You carry yourself like a person who has beef with at least one bird species.'),
    _CocktailResult(name: 'Whiskey Sour', emoji: '🥃', color: Color(0xFFFFCA28), personality: 'You pause mid-conversation like you\'re remembering a prophecy.'),
    _CocktailResult(name: 'Dark \u0027n\u0027 Stormy', emoji: '⛈️', color: Color(0xFF455A64), personality: 'You look at everyday problems like they\'re puzzles you plan to defeat personally.'),
    _CocktailResult(name: 'Paloma', emoji: '🌸', color: Color(0xFFF48FB1), personality: 'You treat coincidence like it\'s proof of a larger conspiracy.'),
    _CocktailResult(name: 'Mai Tai', emoji: '🌺', color: Color(0xFFFF5722), personality: 'You maintain the energy of someone who absolutely has a fake backstory prepared.'),
    _CocktailResult(name: 'French 75', emoji: '🎩', color: Color(0xFFE0E0E0), personality: 'You behave like background music should start playing when you enter a room.'),
    _CocktailResult(name: 'Daiquiri', emoji: '🍓', color: Color(0xFFE91E63), personality: 'You give advice with the confidence of someone who learned it five minutes ago.'),
    _CocktailResult(name: 'Bloody Mary', emoji: '🍅', color: Color(0xFFD32F2F), personality: 'You treat brunch like a strategic summit.'),
    _CocktailResult(name: 'Sidecar', emoji: '🏎️', color: Color(0xFFFF8F00), personality: 'You react to small victories like you\'ve conquered a kingdom.'),
    _CocktailResult(name: 'Aperol Spritz', emoji: '🍊', color: Color(0xFFFF7043), personality: 'You describe simple tasks like they\'re complex operations.'),
    _CocktailResult(name: 'Sazerac', emoji: '🎷', color: Color(0xFF6D4C41), personality: 'You give off the energy of someone who has quietly declared a rivalry with a household appliance.'),
    _CocktailResult(name: 'Pisco Sour', emoji: '🏔️', color: Color(0xFFF0F4C3), personality: 'You treat mild inconveniences like they\'re evidence of a larger plot against you.'),
    _CocktailResult(name: 'Long Island Iced Tea', emoji: '🥃', color: Color(0xFFAB47BC), personality: 'Subtlety is something you\'ve heard about but never attempted.'),
    _CocktailResult(name: 'Mint Julep', emoji: '🌿', color: Color(0xFF8BC34A), personality: 'You behave like politeness is a competitive sport.'),
    _CocktailResult(name: 'Boulevardier', emoji: '🎻', color: Color(0xFFB71C1C), personality: 'You look at maps like you\'re planning something questionable.'),
    _CocktailResult(name: 'Tom Collins', emoji: '🍋', color: Color(0xFFFFEB3B), personality: 'You maintain the confidence of someone who absolutely will try something again after it fails.'),
    _CocktailResult(name: 'Caipirinha', emoji: '🍋', color: Color(0xFFCDDC39), personality: 'You behave like every moment might become a story later.'),
    _CocktailResult(name: 'Vesper Martini', emoji: '🕴️', color: Color(0xFF546E7A), personality: 'You act like you\'re undercover in normal life.'),
    _CocktailResult(name: 'White Russian', emoji: '🥛', color: Color(0xFFBCAAA4), personality: 'You bring the calm presence of someone who is clearly about to do something ridiculous.'),
    _CocktailResult(name: 'Black Russian', emoji: '🖤', color: Color(0xFF424242), personality: 'You have the quiet intensity of someone who absolutely judges furniture.'),
    _CocktailResult(name: 'Hurricane', emoji: '🌀', color: Color(0xFFE65100), personality: 'You escalate situations with the enthusiasm of a reality TV producer.'),
    _CocktailResult(name: 'Singapore Sling', emoji: '🌴', color: Color(0xFFFF80AB), personality: 'You behave like you\'re part of a secret society that never actually meets.'),
    _CocktailResult(name: 'Paper Plane', emoji: '✈️', color: Color(0xFF2979FF), personality: 'You treat random ideas like startup pitches.'),
    _CocktailResult(name: 'Clover Club', emoji: '🍀', color: Color(0xFF7E57C2), personality: 'You give off the energy of someone who would absolutely start a cult by accident.'),
    _CocktailResult(name: 'Corpse Reviver #2', emoji: '💀', color: Color(0xFFB0BEC5), personality: 'You maintain the vibe of someone who wakes up already skeptical of the day.'),
    _CocktailResult(name: 'Penicillin', emoji: '🧪', color: Color(0xFFFFB300), personality: 'You describe basic self-care like it\'s advanced survival strategy.'),
    _CocktailResult(name: 'Zombie', emoji: '🧟', color: Color(0xFF8BC34A), personality: 'You move through life like you\'re waiting for something extremely weird to happen.'),
    _CocktailResult(name: 'Painkiller', emoji: '💊', color: Color(0xFFFF8A65), personality: 'You treat mild discomfort like it\'s character development.'),
    _CocktailResult(name: 'Bee\'s Knees', emoji: '🐝', color: Color(0xFFFFD54F), personality: 'You behave like you personally approve or disapprove of the weather.'),
    _CocktailResult(name: 'Grasshopper', emoji: '🦗', color: Color(0xFF4CAF50), personality: 'You get suspiciously excited about desserts.'),
    _CocktailResult(name: 'Brandy Alexander', emoji: '🥛', color: Color(0xFFA1887F), personality: 'You act like every gathering could turn into a tradition.'),
    _CocktailResult(name: 'Irish Coffee', emoji: '☘️', color: Color(0xFF33691E), personality: 'You operate with the quiet determination of someone trying to fix everything at once.'),
    _CocktailResult(name: 'Rusty Nail', emoji: '🔩', color: Color(0xFF795548), personality: 'You hold grudges against inanimate objects.'),
    _CocktailResult(name: 'Last Word', emoji: '🎤', color: Color(0xFF558B2F), personality: 'You carry the energy of someone who will absolutely continue an argument in the shower later.'),
    _CocktailResult(name: 'Aviation', emoji: '🛩️', color: Color(0xFF90CAF9), personality: 'You behave like obscure trivia is a form of currency.'),
    _CocktailResult(name: 'Gimlet', emoji: '💚', color: Color(0xFF76FF03), personality: 'You react to nonsense with intense analytical focus.'),
    _CocktailResult(name: 'Tequila Sunrise', emoji: '🌅', color: Color(0xFFFF9800), personality: 'You treat aesthetics like they\'re legally binding.'),
    _CocktailResult(name: 'Blue Hawaiian', emoji: '💎', color: Color(0xFF00B0FF), personality: 'You commit to ideas with reckless enthusiasm.'),
    _CocktailResult(name: 'Sex on the Beach', emoji: '🏖️', color: Color(0xFFFF7043), personality: 'You laugh at things five seconds after everyone else stops laughing.'),
    _CocktailResult(name: 'Lemon Drop', emoji: '🍋', color: Color(0xFFFFEB3B), personality: 'You celebrate small wins like they\'re national holidays.'),
    _CocktailResult(name: 'French Martini', emoji: '🍸', color: Color(0xFFF06292), personality: 'You give the impression you know exactly what\'s going on even when you absolutely do not.'),
    _CocktailResult(name: 'Amaretto Sour', emoji: '🍑', color: Color(0xFFFFAB40), personality: 'You look innocent but clearly have questionable instincts.'),
    _CocktailResult(name: 'Kamikaze', emoji: '✈️', color: Color(0xFF2979FF), personality: 'You approach new situations with the confidence of someone who hasn\'t considered consequences.'),
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
      'Reviewing stories for reckless confidence...',
      'Counting mirror selfies under neon lighting...',
      'Mixing ingredients from your comment section...',
      'Serving final identity cocktail...',
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

  Future<void> _generateCocktail() async {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    final igHandle = _igController.text.trim().replaceAll('@', '');
    if (name.isEmpty || igHandle.isEmpty) return;

    setState(() {
      _isRevealing = true;
      _analysisProgress = 0;
      _analysisLabel = 'Queued for cocktail profiling...';
    });
    unawaited(MinisAnalyticsService.instance.trackGamePlay('cocktail'));

    final rng = Random.secure();
    final cocktail =
        _chaosCocktailPool[rng.nextInt(_chaosCocktailPool.length)];

    await _runFakeIgReview(igHandle);
    if (!mounted) return;

    setState(() {
      _result = cocktail;
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
              'Drop name + IG handle and let us fake\na deeply scientific social-media analysis.',
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
              onSubmit: _generateCocktail,
            ),
            const SizedBox(height: 12),

            _buildInput(
              controller: _igController,
              hint: 'Enter IG handle (required)...',
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
                    ? Text(
                        'Reviewing @${_igController.text.trim().replaceAll('@', '')}...',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
    final cocktail = _result!;
    final displayColor = cocktail.color;

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
            color: displayColor.withOpacity(0.5),
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
              cocktail.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              '$name (@${_igController.text.trim().replaceAll('@', '')}) is a...',
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
            const SizedBox(height: 12),
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
