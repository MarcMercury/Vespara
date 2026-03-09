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
  final _friendController = TextEditingController();
  String? _generatedSafeWord;
  String? _explanation;
  bool _isRevealing = false;
  bool _isRare = false;
  bool _isFriendMode = false;
  int _playCount = 0;
  int _selectedVibe = 0;

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late AnimationController _pulseController;

  static const Color _accentColor = Color(0xFFE91E63);

  static const List<String> _vibeLabels = [
    'Flirting', 'Chaos', 'Trouble', 'Romance', 'Bad Decisions',
  ];
  static const List<String> _vibeEmojis = [
    '😏', '🔥', '😈', '💕', '🍸',
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // SAFE WORD DATA — Organized by vibe
  // ═══════════════════════════════════════════════════════════════════════

  static const List<List<String>> _wordsByVibe = [
    // 0: Flirting
    [
      'Library Card', 'Avocado Toast', 'Pillow Menu', 'Candle Budget',
      'Soft Launch', 'Lip Gloss', 'Eye Contact', 'Playlist Swap',
      'Slow Dance', 'Whisper Tax', 'Blushing Receipt', 'Wink Protocol',
      'Dimmer Switch', 'Thigh Graze', 'Breath Mint Emergency',
      'Hair Tuck', 'Neck Whisper', 'Cheek Kiss Audit', 'Eyelash Wish',
      'Shoulder Touch', 'Inside Joke', 'Goodnight Text', 'Morning Voice',
    ],
    // 1: Chaos
    [
      'Tax Deduction', 'Parking Meter', 'Terms of Service', 'Jury Duty',
      'HOA Meeting', 'Spreadsheet', 'Budget Review', 'Dental Appointment',
      'Smoke Detector', 'Fire Drill', 'Eviction Notice', 'Audit Season',
      'Flash Mob', 'Wrong Flight', 'Stolen Cart', 'False Alarm',
      'Power Outage', 'Plot Twist', 'Witness Protection', 'Escape Hatch',
      'Broken Lease', 'Late Fee', 'Expired Coupon', 'No Signal',
    ],
    // 2: Trouble
    [
      'Restraining Order', 'Bail Money', 'Getaway Car', 'Alibi Needed',
      'Objection', 'Lawyer Up', 'Crime Scene', 'Forensic Evidence',
      'Security Footage', 'Blackmail Folder', 'Burner Phone', 'Back Exit',
      'Wanted Poster', 'Lie Detector', 'Confession Booth', 'Suspect List',
      'Fingerprints', 'Double Cross', 'Silent Treatment', 'Cover Story',
      'Plausible Deniability', 'Paper Trail', 'Mistrial', 'Caught Red-Handed',
    ],
    // 3: Romance
    [
      'Candlelight', 'Rose Petal', 'Love Letter', 'Slow Motion',
      'Sunset Drive', 'Forehead Kiss', 'Hand Holding', 'Serenade',
      'Stargazing', 'Couples Massage', 'Proposal Rehearsal', 'Anniversary',
      'Honeymoon Phase', 'Love Language', 'Butterflies', 'First Dance',
      'Pillow Fort', 'Breakfast in Bed', 'Rain Kiss', 'Matching Tattoo',
      'Promise Ring', 'Soul Tie', 'Heart Flutter', 'Love Drunk',
    ],
    // 4: Bad Decisions
    [
      'Tequila Sunrise', 'Last Call', 'Hold My Drink', 'YOLO Receipt',
      'Uber to the Ex', 'Reply All', 'Send It', 'No Regrets',
      'Triple Dog Dare', 'One More Round', 'Bar Tab Denial', 'Shots Fired',
      'Drunk Text', 'Walk of Shame', 'Morning After', 'Bad Tattoo',
      'Lost Wallet', 'Wrong Address', 'Group Chat Leak', 'Voicemail Delete',
      'Emergency Pizza', 'Karaoke Solo', 'Stage Dive', 'Crowd Surf',
    ],
  ];

  // Escalation extras — added for repeat plays
  static const List<String> _extras = [
    'at Brunch', 'on a Tuesday', 'with Witnesses', 'during Mercury Retrograde',
    'at the DMV', 'in Crocs', 'with Ranch Dressing', 'at Your In-Laws',
    'in a Bouncy Castle', 'at Bible Study', 'during a Work Call',
    'in a Denny\'s Parking Lot', 'at Costco', 'with a Slow Clap',
    'in Business Casual', 'at a PTA Meeting', 'in the Ball Pit',
    'during Tax Season', 'at the Salad Bar', 'in a Snuggie',
    'with Jazz Hands', 'at Chuck E. Cheese', 'during a Seance',
    'at Grandma\'s', 'in Economy Class', 'with Finger Guns',
    'at a Funeral', 'in the Ikea Showroom', 'during Karaoke',
    'in a Onesie', 'with Eye Contact', 'at a Dog Park',
  ];

  // Rare results (1-2% chance)
  static const List<String> _rareWords = [
    'Pineapple on Pizza During an Exorcism',
    'Certified Emotional Damage',
    'The IRS Called — They Know',
    'Mercury Retrograde\'s Personal Victim',
    'Witness Protection With Benefits',
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
    _friendController.dispose();
    _revealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _generateSafeWord() {
    final name = _isFriendMode
        ? _friendController.text.trim()
        : _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isRevealing = true);
    _playCount++;
    unawaited(MinisAnalyticsService.instance.trackGamePlay('safe_word'));

    final seed = DateTime.now().microsecondsSinceEpoch ^
      name.hashCode ^
      _playCount ^
      (_selectedVibe << 8);
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
      final vibeWords = _wordsByVibe[_selectedVibe];
      safeWord = vibeWords[rng.nextInt(vibeWords.length)];

      // Escalation: after 3+ plays, add extras
      if (_playCount >= 3) {
        safeWord += ' ${_extras[rng.nextInt(_extras.length)]}';
      }
      // After 5+ plays, double up
      if (_playCount >= 5) {
        safeWord += ' (${_extras[rng.nextInt(_extras.length)]})';
      }

      explanation = _isFriendMode
          ? '$name\'s safe word energy is... concerning.'
          : 'Use it wisely. Or don\'t. We\'re not your therapist.';
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _generatedSafeWord = safeWord;
        _explanation = explanation;
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
              'Enter your name, pick a vibe,\nand discover the word you never knew you needed.',
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
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
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
              '$name\'s Safe Word:',
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
            // Vibe badge
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
