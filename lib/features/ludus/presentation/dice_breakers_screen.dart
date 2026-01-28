import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/domain/models/tag_rating.dart';
import '../../../core/theme/vespara_icons.dart';
import '../widgets/tag_rating_display.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// DICE BREAKERS - Naughty Dice Rolling Game
/// "Let fate decide what happens next"
///
/// Two modes:
/// - JUST DICE: Quick anonymous play
/// - NAME PLAYERS: Turn-based with player assignments
///
/// TAG Rating: 70mph / R / Quickie (5-15 min)
/// Vibe: Vegas casino meets bedroom adventure
/// ════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// COLOR PALETTE (Casino Night Vibe)
// ═══════════════════════════════════════════════════════════════════════════

class DiceColors {
  static const background = Color(0xFF1A1523); // Deep Obsidian
  static const primary = Color(0xFFE040FB); // Electric Purple
  static const secondary = Color(0xFFE0D8EA); // Soft Lavender
  static const bodyDie = Color(0xFF00E5FF); // Cyan - Body Parts Die
  static const actionDie = Color(0xFFFFD700); // Gold - Action Die
  static const redDie = Color(0xFFFF1744); // Hot Red - Escalation Die
  static const success = Color(0xFF2ECC71); // Green
  static const cardBg = Color(0xFF2D2438); // Dark Purple
}

// ═══════════════════════════════════════════════════════════════════════════
// DICE DATA
// ═══════════════════════════════════════════════════════════════════════════

// Body Dice Options
const List<String> bodyPartsPG13 = [
  'Mouth',
  'Neck',
  'Back',
  'Thigh',
  'Chest',
  'Ass',
];

const List<String> bodyPartsX = [
  'Mouth',
  'Nipples',
  'Cock',
  'Pussy',
  'Asshole',
  'Neck',
  'Chest',
];

// Action Dice Options
const List<String> actionsPG13 = [
  'Kiss',
  'Rub',
  'Squeeze',
  'Lick',
  'Pinch',
  'Suck',
];

const List<String> actionsX = [
  'Kiss',
  'Lick',
  'Suck',
  'Stroke',
  'Tease',
  'Devour',
];

// Modifier Die Options
const List<String> modifierDieFaces = [
  'X',
  'XXX',
  'Orgy',
  'Threesome',
  'Private Play',
  'Director',
  'Penetrate',
];

// ═══════════════════════════════════════════════════════════════════════════
// GAME ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum DiceGameMode { justDice, namePlayers }

enum DiceGamePhase {
  discovery,
  modeSelect,
  diceSelect,
  playerSetup,
  playing,
  result
}

enum BodyDieType { pg13, x }

enum ActionDieType { pg13, x }

enum DiceCount { two, three }

// ═══════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class DiceBreakersScreen extends StatefulWidget {
  const DiceBreakersScreen({super.key});

  @override
  State<DiceBreakersScreen> createState() => _DiceBreakersScreenState();
}

class _DiceBreakersScreenState extends State<DiceBreakersScreen>
    with TickerProviderStateMixin {
  // Game state
  DiceGamePhase _phase = DiceGamePhase.discovery;
  DiceGameMode? _gameMode;
  DiceCount _diceCount = DiceCount.two;
  BodyDieType _bodyDieType = BodyDieType.pg13;
  ActionDieType _actionDieType = ActionDieType.pg13;
  bool _useModifierDie = false;
  final List<String> _players = [];
  int _currentPlayerIndex = 0;
  final TextEditingController _playerNameController = TextEditingController();

  // Dice results
  String? _bodyResult;
  String? _actionResult;
  String? _redResult;
  String? _targetPlayer;
  List<String>? _targetPlayers; // For ORGY mode

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _diceRollController;
  late AnimationController _bounceController;

  // Rolling state
  bool _isRolling = false;
  Timer? _rollTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _diceRollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _diceRollController.dispose();
    _bounceController.dispose();
    _rollTimer?.cancel();
    _playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DiceColors.background,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _buildPhase(),
          ),
        ),
      );

  Widget _buildPhase() {
    switch (_phase) {
      case DiceGamePhase.discovery:
        return _buildDiscoveryPhase();
      case DiceGamePhase.modeSelect:
        return _buildModeSelectPhase();
      case DiceGamePhase.diceSelect:
        return _buildDiceSelectPhase();
      case DiceGamePhase.playerSetup:
        return _buildPlayerSetupPhase();
      case DiceGamePhase.playing:
        return _buildPlayingPhase();
      case DiceGamePhase.result:
        return _buildResultPhase();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 1: DISCOVERY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDiscoveryPhase() => Container(
        key: const ValueKey('discovery'),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Dice emoji with glow
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) => Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: DiceColors.primary.withOpacity(
                                  0.3 + (_glowController.value * 0.3)),
                              blurRadius: 50 + (_glowController.value * 30),
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: const Text('🎲', style: TextStyle(fontSize: 80)),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [DiceColors.primary, DiceColors.actionDie],
                      ).createShader(bounds),
                      child: const Text(
                        'DICE BREAKERS',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      '"Let fate decide what happens next"',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.white60,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // TAG Rating
                    const TagRatingDisplay(rating: TagRating.diceBreakers),

                    const SizedBox(height: 24),

                    // How it works
                    _buildHowItWorks(),

                    const SizedBox(height: 32),

                    // Play button
                    _buildPlayButton(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                if (_phase == DiceGamePhase.discovery) {
                  Navigator.pop(context);
                } else {
                  _goBack();
                }
              },
              icon: const Icon(VesparaIcons.back, color: Colors.white70),
            ),
            const Spacer(),
          ],
        ),
      );

  Widget _buildHowItWorks() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DiceColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DiceColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Text(
              '🎯 HOW IT WORKS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DiceColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            _buildDiceInfo(
              '🔵',
              'Body Die',
              'PG-13 or X-rated body parts',
              DiceColors.bodyDie,
            ),
            const SizedBox(height: 12),
            _buildDiceInfo(
              '🟡',
              'Action Die',
              'PG-13 or X-rated actions',
              DiceColors.actionDie,
            ),
            const SizedBox(height: 12),
            _buildDiceInfo(
              '🔴',
              'Modifier Die (Optional)',
              'X • XXX • Orgy • Threesome • and more!',
              DiceColors.redDie,
            ),
          ],
        ),
      );

  Widget _buildDiceInfo(
          String emoji, String title, String items, Color color) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  items,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildPlayButton() => GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          setState(() => _phase = DiceGamePhase.modeSelect);
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DiceColors.primary,
                  DiceColors.primary
                      .withOpacity(0.7 + (_pulseController.value * 0.3)),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: DiceColors.primary.withOpacity(0.4),
                  blurRadius: 20 + (_pulseController.value * 10),
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'ROLL THE DICE 🎲',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 2: MODE SELECT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildModeSelectPhase() => Container(
        key: const ValueKey('modeSelect'),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎲',
                      style: TextStyle(fontSize: 60),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SELECT MODE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Just Dice Mode
                    _buildModeCard(
                      icon: '🎯',
                      title: 'JUST DICE',
                      subtitle: 'Quick & anonymous',
                      description:
                          'Roll the dice and see what fate decides.\nNo names, just action.',
                      color: DiceColors.bodyDie,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _gameMode = DiceGameMode.justDice;
                          _phase = DiceGamePhase.diceSelect;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Name Players Mode
                    _buildModeCard(
                      icon: '👥',
                      title: 'NAME PLAYERS',
                      subtitle: 'Turn-based with assignments',
                      description:
                          'Add player names and take turns.\nDice assigns who does what to whom!',
                      color: DiceColors.primary,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _gameMode = DiceGameMode.namePlayers;
                          _phase = DiceGamePhase.diceSelect;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildModeCard({
    required String icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DiceColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 32),
            ],
          ),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 3: DICE SELECT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDiceSelectPhase() => Container(
        key: const ValueKey('diceSelect'),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        '🎲🎲',
                        style: TextStyle(fontSize: 60),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'SELECT DICE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // BODY DICE SECTION
                    _buildSectionHeader(
                      '🔵 BODY DICE',
                      'Must select 1',
                      DiceColors.bodyDie,
                    ),
                    const SizedBox(height: 12),
                    _buildDiceOptionCard(
                      title: 'Die 1 - Body (PG-13)',
                      items: bodyPartsPG13.join(' • '),
                      color: DiceColors.bodyDie,
                      isSelected: _bodyDieType == BodyDieType.pg13,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _bodyDieType = BodyDieType.pg13);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDiceOptionCard(
                      title: 'Die 2 - Body (X)',
                      items: bodyPartsX.join(' • '),
                      color: DiceColors.bodyDie,
                      isSelected: _bodyDieType == BodyDieType.x,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _bodyDieType = BodyDieType.x);
                      },
                    ),

                    const SizedBox(height: 32),

                    // ACTION DICE SECTION
                    _buildSectionHeader(
                      '🟡 ACTION DICE',
                      'Must select 1',
                      DiceColors.actionDie,
                    ),
                    const SizedBox(height: 12),
                    _buildDiceOptionCard(
                      title: 'Die 1 - Action (PG-13)',
                      items: actionsPG13.join(' • '),
                      color: DiceColors.actionDie,
                      isSelected: _actionDieType == ActionDieType.pg13,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _actionDieType = ActionDieType.pg13);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDiceOptionCard(
                      title: 'Die 2 - Action (X)',
                      items: actionsX.join(' • '),
                      color: DiceColors.actionDie,
                      isSelected: _actionDieType == ActionDieType.x,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _actionDieType = ActionDieType.x);
                      },
                    ),

                    const SizedBox(height: 32),

                    // MODIFIER DICE SECTION (Optional)
                    _buildSectionHeader(
                      '🔴 MODIFIER DICE',
                      'Optional 3rd Dice',
                      DiceColors.redDie,
                    ),
                    const SizedBox(height: 12),
                    _buildModifierToggleCard(
                      title: 'Add Modifier Die',
                      items: modifierDieFaces.join(' • '),
                      color: DiceColors.redDie,
                      isEnabled: _useModifierDie,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _useModifierDie = !_useModifierDie;
                          _diceCount = _useModifierDie ? DiceCount.three : DiceCount.two;
                        });
                      },
                    ),

                    const SizedBox(height: 40),

                    // Continue button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        if (_gameMode == DiceGameMode.namePlayers) {
                          setState(() => _phase = DiceGamePhase.playerSetup);
                        } else {
                          setState(() => _phase = DiceGamePhase.playing);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [DiceColors.primary, DiceColors.actionDie],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: DiceColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _gameMode == DiceGameMode.namePlayers
                                ? 'ADD PLAYERS →'
                                : 'START ROLLING 🎲',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSectionHeader(String title, String subtitle, Color color) =>
      Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      );

  Widget _buildDiceOptionCard({
    required String title,
    required String items,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : DiceColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : Colors.white38,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? color.withOpacity(0.8) : Colors.white54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildModifierToggleCard({
    required String title,
    required String items,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEnabled ? color.withOpacity(0.2) : DiceColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled ? color : Colors.white.withOpacity(0.2),
              width: isEnabled ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isEnabled ? color : Colors.white24,
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isEnabled ? color : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items,
                      style: TextStyle(
                        fontSize: 12,
                        color: isEnabled ? color.withOpacity(0.8) : Colors.white54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 4: PLAYER SETUP (Name Players mode only)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlayerSetupPhase() => Container(
        key: const ValueKey('playerSetup'),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      '👥 ADD PLAYERS',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    Text(
                      '${_players.length}/10 players',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Player name input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _playerNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter player name...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: DiceColors.cardBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            onSubmitted: (_) => _addPlayer(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _addPlayer,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: DiceColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Player list
                    Expanded(
                      child: _players.isEmpty
                          ? const Center(
                              child: Text(
                                'Add at least 2 players to continue',
                                style: TextStyle(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _players.length,
                              itemBuilder: (context, index) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: DiceColors.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _getPlayerColor(index),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _players[index],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removePlayer(index),
                                      icon: const Icon(Icons.close,
                                          color: Colors.white38),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    // Start button
                    if (_players.length >= 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            setState(() => _phase = DiceGamePhase.playing);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  DiceColors.primary,
                                  DiceColors.actionDie
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: DiceColors.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'START GAME 🎲',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  void _addPlayer() {
    final name = _playerNameController.text.trim();
    if (name.isNotEmpty && _players.length < 10) {
      HapticFeedback.lightImpact();
      setState(() {
        _players.add(name);
        _playerNameController.clear();
      });
    }
  }

  void _removePlayer(int index) {
    HapticFeedback.lightImpact();
    setState(() => _players.removeAt(index));
  }

  Color _getPlayerColor(int index) {
    final colors = [
      DiceColors.primary,
      DiceColors.bodyDie,
      DiceColors.actionDie,
      DiceColors.redDie,
      DiceColors.success,
      const Color(0xFFFF6B9D),
      const Color(0xFF9B59B6),
      const Color(0xFF3498DB),
      const Color(0xFFE67E22),
      const Color(0xFF1ABC9C),
    ];
    return colors[index % colors.length];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 5: PLAYING
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlayingPhase() => Container(
        key: const ValueKey('playing'),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Current player indicator (Name Players mode)
                    if (_gameMode == DiceGameMode.namePlayers &&
                        _players.isNotEmpty) ...[
                      Text(
                        "${_players[_currentPlayerIndex]}'s Turn",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _getPlayerColor(_currentPlayerIndex),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Dice display area
                    _buildDiceArea(),

                    const SizedBox(height: 48),

                    // Roll button
                    GestureDetector(
                      onTap: _isRolling ? null : _rollDice,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          gradient: _isRolling
                              ? LinearGradient(
                                  colors: [
                                    Colors.grey.shade700,
                                    Colors.grey.shade800,
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    DiceColors.primary,
                                    DiceColors.actionDie
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _isRolling
                                  ? Colors.transparent
                                  : DiceColors.primary.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isRolling ? 'ROLLING...' : 'ROLL THE DICE 🎲',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _isRolling ? Colors.white38 : Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildDiceArea() {
    // Get the correct body and action lists based on selection
    final bodyList = _bodyDieType == BodyDieType.pg13 ? bodyPartsPG13 : bodyPartsX;
    final actionList = _actionDieType == ActionDieType.pg13 ? actionsPG13 : actionsX;

    final diceWidgets = <Widget>[
      _buildDie(
        color: DiceColors.bodyDie,
        label: 'BODY',
        value: _isRolling ? bodyList[_random.nextInt(bodyList.length)] : '?',
        isRolling: _isRolling,
      ),
      const SizedBox(width: 16),
      _buildDie(
        color: DiceColors.actionDie,
        label: 'ACTION',
        value: _isRolling ? actionList[_random.nextInt(actionList.length)] : '?',
        isRolling: _isRolling,
      ),
    ];

    if (_diceCount == DiceCount.three) {
      diceWidgets.addAll([
        const SizedBox(width: 16),
        _buildDie(
          color: DiceColors.redDie,
          label: 'MODIFIER',
          value: _isRolling
              ? modifierDieFaces[_random.nextInt(modifierDieFaces.length)]
              : '?',
          isRolling: _isRolling,
          isDiamond: true,
        ),
      ]);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: diceWidgets,
    );
  }

  Widget _buildDie({
    required Color color,
    required String label,
    required String value,
    required bool isRolling,
    bool isDiamond = false,
  }) {
    final size = isDiamond ? 85.0 : 95.0;
    final borderRadius = isDiamond ? 14.0 : 18.0;
    
    return AnimatedBuilder(
      animation: _diceRollController,
      builder: (context, child) {
        final shake =
            isRolling ? sin(_diceRollController.value * pi * 8) * 5 : 0.0;
        final pulse = isRolling ? 1.0 + sin(_diceRollController.value * pi * 4) * 0.05 : 1.0;
        
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: pulse,
            child: Transform.rotate(
              angle: isDiamond ? pi / 4 : 0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  // Outer glow
                  boxShadow: [
                    // Primary glow
                    BoxShadow(
                      color: color.withOpacity(isRolling ? 0.8 : 0.5),
                      blurRadius: isRolling ? 30 : 20,
                      spreadRadius: isRolling ? 4 : 2,
                    ),
                    // Bottom shadow for depth
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    // 3D gradient - top-left highlight to bottom-right shadow
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.4),
                        color.withOpacity(0.2),
                        color.withOpacity(0.05),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    border: Border.all(
                      width: 2,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius - 4),
                      // Inner bevel effect
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                      // Inner shadow simulation
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        left: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        bottom: BorderSide(
                          color: Colors.black.withOpacity(0.3),
                          width: 1.5,
                        ),
                        right: BorderSide(
                          color: Colors.black.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius - 6),
                        // Glossy center
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.3),
                          radius: 1.2,
                          colors: [
                            color.withOpacity(0.3),
                            color.withOpacity(0.15),
                            DiceColors.background.withOpacity(0.8),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                      child: Transform.rotate(
                        angle: isDiamond ? -pi / 4 : 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Label with glow
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: color,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: color.withOpacity(0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Value with embossed effect
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color.withOpacity(0.4),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: value.length > 6 ? 10 : (value.length > 4 ? 12 : 15),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: color,
                                      blurRadius: 10,
                                    ),
                                    const Shadow(
                                      color: Colors.black,
                                      blurRadius: 2,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _rollDice() {
    HapticFeedback.heavyImpact();
    setState(() => _isRolling = true);

    _diceRollController.repeat();

    // Roll animation duration
    int rollCount = 0;
    _rollTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      HapticFeedback.lightImpact();
      setState(() {}); // Force rebuild for random values
      rollCount++;
      if (rollCount >= 20) {
        timer.cancel();
        _finishRoll();
      }
    });
  }

  void _finishRoll() {
    _diceRollController.stop();
    HapticFeedback.heavyImpact();

    // Get the correct lists based on selection
    final bodyList = _bodyDieType == BodyDieType.pg13 ? bodyPartsPG13 : bodyPartsX;
    final actionList = _actionDieType == ActionDieType.pg13 ? actionsPG13 : actionsX;

    // Final results
    _bodyResult = bodyList[_random.nextInt(bodyList.length)];
    _actionResult = actionList[_random.nextInt(actionList.length)];
    if (_diceCount == DiceCount.three) {
      _redResult = modifierDieFaces[_random.nextInt(modifierDieFaces.length)];
    }

    // Assign target player(s) for Name Players mode
    if (_gameMode == DiceGameMode.namePlayers && _players.length > 1) {
      final otherPlayers = List<String>.from(_players)
        ..removeAt(_currentPlayerIndex);

      if (_diceCount == DiceCount.three && _redResult == 'Orgy') {
        _targetPlayers = otherPlayers; // Everyone plays!
      } else if (_diceCount == DiceCount.three && _redResult == 'Threesome') {
        // Pick 2 random players (including potential duplicates from other players)
        if (otherPlayers.length >= 2) {
          otherPlayers.shuffle();
          _targetPlayers = otherPlayers.take(2).toList();
        } else {
          _targetPlayer = otherPlayers.first;
        }
      } else {
        _targetPlayer = otherPlayers[_random.nextInt(otherPlayers.length)];
      }
    }

    setState(() {
      _isRolling = false;
      _phase = DiceGamePhase.result;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 6: RESULT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildResultPhase() => Container(
        key: const ValueKey('result'),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Player turn indicator
                    if (_gameMode == DiceGameMode.namePlayers) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _getPlayerColor(_currentPlayerIndex)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: _getPlayerColor(_currentPlayerIndex)),
                        ),
                        child: Text(
                          _players[_currentPlayerIndex].toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _getPlayerColor(_currentPlayerIndex),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'must...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action result
                    _buildResultCard(
                      icon: '🎯',
                      label: 'ACTION',
                      value: _actionResult ?? '?',
                      color: DiceColors.actionDie,
                    ),

                    const SizedBox(height: 16),

                    // Body result
                    _buildResultCard(
                      icon: '💋',
                      label: 'THE',
                      value: _bodyResult ?? '?',
                      color: DiceColors.bodyDie,
                    ),

                    // Target player(s)
                    if (_gameMode == DiceGameMode.namePlayers) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'of',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTargetDisplay(),
                    ],

                    // Red die result
                    if (_diceCount == DiceCount.three &&
                        _redResult != null) ...[
                      const SizedBox(height: 24),
                      _buildRedDieResult(),
                    ],

                    const SizedBox(height: 48),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _nextTurn,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    DiceColors.primary,
                                    DiceColors.actionDie
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  _gameMode == DiceGameMode.namePlayers
                                      ? 'NEXT PLAYER →'
                                      : 'ROLL AGAIN 🎲',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _endGame,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: DiceColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child:
                                const Icon(Icons.stop, color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildResultCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              '$label ',
              style: TextStyle(
                fontSize: 18,
                color: color,
                letterSpacing: 1,
              ),
            ),
            Text(
              value.toUpperCase(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );

  Widget _buildTargetDisplay() {
    if (_targetPlayers != null && _targetPlayers!.isNotEmpty) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: _targetPlayers!.map((player) {
          final index = _players.indexOf(player);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _getPlayerColor(index).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getPlayerColor(index)),
            ),
            child: Text(
              player.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _getPlayerColor(index),
                letterSpacing: 1,
              ),
            ),
          );
        }).toList(),
      );
    } else if (_targetPlayer != null) {
      final index = _players.indexOf(_targetPlayer!);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: _getPlayerColor(index).withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _getPlayerColor(index), width: 2),
        ),
        child: Text(
          _targetPlayer!.toUpperCase(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _getPlayerColor(index),
            letterSpacing: 2,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildRedDieResult() {
    String description;
    String emoji;

    switch (_redResult) {
      case 'X':
        description = 'Standard intensity';
        emoji = '🔥';
      case 'XXX':
        description = 'Maximum intensity!';
        emoji = '🔥🔥🔥';
      case 'Threesome':
        description = 'Bring in a third!';
        emoji = '👥';
      case 'Orgy':
        description = 'Everyone plays!';
        emoji = '🎉';
      case 'Private Play':
        description = 'Complete in private!';
        emoji = '🚪';
      case 'Director':
        description = 'Roller directs 2 players!';
        emoji = '🎬';
      case 'Penetrate':
        description = 'Take it all the way!';
        emoji = '💥';
      default:
        description = '';
        emoji = '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DiceColors.redDie.withOpacity(0.3),
            DiceColors.redDie.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DiceColors.redDie, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔴', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                _redResult ?? '',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: DiceColors.redDie,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(width: 8),
              Text(emoji, style: const TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _nextTurn() {
    HapticFeedback.mediumImpact();
    setState(() {
      // Clear results
      _bodyResult = null;
      _actionResult = null;
      _redResult = null;
      _targetPlayer = null;
      _targetPlayers = null;

      // Next player
      if (_gameMode == DiceGameMode.namePlayers && _players.isNotEmpty) {
        _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
      }

      _phase = DiceGamePhase.playing;
    });
  }

  void _endGame() {
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = DiceGamePhase.discovery;
      _gameMode = null;
      _diceCount = DiceCount.two;
      _bodyDieType = BodyDieType.pg13;
      _actionDieType = ActionDieType.pg13;
      _useModifierDie = false;
      _players.clear();
      _currentPlayerIndex = 0;
      _bodyResult = null;
      _actionResult = null;
      _redResult = null;
      _targetPlayer = null;
      _targetPlayers = null;
    });
  }

  void _goBack() {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_phase) {
        case DiceGamePhase.discovery:
          Navigator.pop(context);
        case DiceGamePhase.modeSelect:
          _phase = DiceGamePhase.discovery;
        case DiceGamePhase.diceSelect:
          _phase = DiceGamePhase.modeSelect;
        case DiceGamePhase.playerSetup:
          _phase = DiceGamePhase.diceSelect;
        case DiceGamePhase.playing:
          if (_gameMode == DiceGameMode.namePlayers) {
            _phase = DiceGamePhase.playerSetup;
          } else {
            _phase = DiceGamePhase.diceSelect;
          }
        case DiceGamePhase.result:
          _phase = DiceGamePhase.playing;
      }
    });
  }
}
