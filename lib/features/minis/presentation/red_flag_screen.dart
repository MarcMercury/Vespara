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
/// Name + IG handle → random hilarious red flag output
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
  bool _isFriendMode = false;
  double _analysisProgress = 0;
  String _analysisLabel = 'Queued for red-flag inspection...';

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;
  late AnimationController _flagWaveController;

  static const Color _accentColor = Color(0xFFFF1744);

  static const List<String> _randomFlags = [
    'Your name is also the adjective people use to describe you.',
    'You keep a laminated Consent Flowchart in your phone.',
    'You own a small suitcase labeled "Afterparty Logistics."',
    'You\'ve started a cuddle pile that required two safewords and a group moderator.',
    'You\'ve told someone, "Don\'t worry, the rules only exist because of something I did last year."',
    'You walk into a party and immediately start reorganizing the lighting, the music, and the energy like a chaotic cruise director.',
    'You\'ve been asked to stop bringing props without emailing the host first.',
    'You\'ve turned a quiet gathering into a three-hour negotiation about boundaries and snacks.',
    'You keep a mental map of which houses have the good bathroom.',
    'You\'ve referred to a poor relationship choice as "a successful experiment."',
    'You bring a portable disco light because you refuse to let bad lighting ruin good decisions.',
    'You\'ve been told, "Please don\'t turn this into a workshop again."',
    'You\'ve started a game that accidentally required a whiteboard to track.',
    'You\'ve been introduced to someone as "the person who escalates things."',
    'You\'ve organized a "low-key hang" that required three different group chats and a Partiful invite to coordinate.',
    'You\'ve been banned from starting icebreaker games after midnight.',
    'You once turned a casual hangout into an over the top costumed/themed event.',
    'You\'ve walked into a party and someone immediately handed you the responsibility clipboard.',
    'You\'ve referred to yourself as "a facilitator of vibes."',
    'You\'ve been told, "You\'re the reason we had to clarify that rule."',
    'You turn a calm conversation into a full-blown group discussion about feelings.',
    'You look at a completely fine evening and think, "We can make this more interesting."',
    'You say, "Don\'t worry, I\'ve done this before," to things you\'ve never done before.',
    'You\'ve accidentally created a cult.',
    'You\'ve stared at a Taco Bell menu at 2 AM like a medieval scholar decoding prophecy.',
    'You\'ve chased a lost vape like a bloodhound tracking a fugitive.',
    'You\'ve opened the fridge 14 times like it might suddenly generate new food out of fear.',
    'You\'ve looked for your phone while holding your phone like a confused TSA agent.',
    'You have sat in total silence in an Uber at 2am because you know the driver knows you\'re naked under that coat.',
    'You have a dozen sets of black lingerie you are not sure are yours.',
    'You are colloquially known as "everybody\'s boyfriend/girlfriend."',
    'You refuse to get to know someone until you\'ve slept with them.',
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
    unawaited(MinisAnalyticsService.instance.trackGamePlay('red_flag'));

    final rng = Random.secure();
    final flag = _randomFlags[rng.nextInt(_randomFlags.length)];

    await _runFakeIgReview(igHandle);
    if (!mounted) return;

    setState(() {
      _generatedFlag = flag;
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
            color: _accentColor.withOpacity(0.4),
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
                color: _accentColor,
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
