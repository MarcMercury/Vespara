import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models/tag_rating.dart';
import '../../../core/providers/path_of_pleasure_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/utils/haptics.dart';
import '../widgets/tag_rating_display.dart';

/// Path of Pleasure - 1v1 Kinkiness Sorting Game (Family Feud Style)
/// Teams compete to sort 8 cards from Vanilla to Hardcore
/// First to 20 points wins!
class PathOfPleasureScreen extends ConsumerStatefulWidget {
  const PathOfPleasureScreen({super.key});

  @override
  ConsumerState<PathOfPleasureScreen> createState() =>
      _PathOfPleasureScreenState();
}

class _PathOfPleasureScreenState extends ConsumerState<PathOfPleasureScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pathOfPleasureProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: _buildPhaseContent(state),
      ),
    );
  }

  Widget _buildPhaseContent(PathOfPleasureState state) {
    // Handle handoff screen overlay for Pass & Play
    if (state.showHandoffScreen) {
      return _buildHandoffScreen(state);
    }

    switch (state.phase) {
      case GamePhase.idle:
        return _buildEntryScreen();
      case GamePhase.modeSelect:
        return _buildModeSelectScreen();
      case GamePhase.lobby:
        return _buildLobbyScreen(state);
      case GamePhase.sorting:
      case GamePhase.stealing:
        return _buildSortingScreen(state);
      case GamePhase.scored:
        return _buildScoredScreen(state);
      case GamePhase.decision:
        return _buildDecisionScreen(state);
      case GamePhase.roundResult:
        return _buildRoundResultScreen(state);
      case GamePhase.gameOver:
        return _buildGameOverScreen(state);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ENTRY SCREEN
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildEntryScreen() => Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // Game icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      VesparaIcons.fire,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Path of Pleasure',
                    style: AppTheme.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '1v1 Kinkiness Sorting Battle',
                    style: AppTheme.bodyLarge.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sort 8 cards from Vanilla to Hardcore\nFirst to 20 points wins!',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),
                  const TagRatingDisplay(rating: TagRating.pathOfPleasure),
                  const SizedBox(height: 32),

                  _buildPrimaryButton(
                    label: 'Play Now',
                    icon: VesparaIcons.play,
                    onTap: () {
                      Haptics.light();
                      ref
                          .read(pathOfPleasureProvider.notifier)
                          .showModeSelect();
                    },
                  ),
                  const SizedBox(height: 16),

                  // How It Works button
                  GestureDetector(
                    onTap: () => _showHowToPlay(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Center(
                        child: Text(
                          'How It Works',
                          style: AppTheme.labelLarge
                              .copyWith(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TAG Rating info
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => const TagRatingInfoSheet(),
                      );
                    },
                    child: const Text(
                      'About TAG Ratings \u2192',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white38,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      );

  // ════════════════════════════════════════════════════════════════════════
  // MODE SELECT SCREEN
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildModeSelectScreen() => Column(
        children: [
          _buildHeader(
            showBack: true,
            onBack: () {
              ref.read(pathOfPleasureProvider.notifier).reset();
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Choose Game Mode',
                    style: AppTheme.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Pass & Play
                  _buildModeCard(
                    title: 'Pass & Play',
                    subtitle: 'Share one device between teams',
                    icon: VesparaIcons.users,
                    color: const Color(0xFFFF6B6B),
                    onTap: () {
                      Haptics.medium();
                      ref
                          .read(pathOfPleasureProvider.notifier)
                          .selectMode(ConnectionMode.passAndPlay);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Multi-Screen
                  _buildModeCard(
                    title: 'Multi-Screen',
                    subtitle: 'Each team uses their own device',
                    icon: VesparaIcons.wifi,
                    color: const Color(0xFF4ECDC4),
                    onTap: () {
                      Haptics.medium();
                      ref
                          .read(pathOfPleasureProvider.notifier)
                          .hostMultiScreenGame();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style:
                          AppTheme.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(VesparaIcons.forward, color: color),
            ],
          ),
        ),
      );

  // ════════════════════════════════════════════════════════════════════════
  // LOBBY SCREEN
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildLobbyScreen(PathOfPleasureState state) => Column(
        children: [
          _buildHeader(
            showBack: true,
            onBack: () {
              ref.read(pathOfPleasureProvider.notifier).reset();
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Room code (if multi-screen)
                  if (state.connectionMode == ConnectionMode.multiScreen) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag_rounded, color: Colors.white70),
                          const SizedBox(width: 12),
                          Text(
                            state.roomCode ?? '',
                            style: AppTheme.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(VesparaIcons.copy,
                                color: Colors.white70),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: state.roomCode ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Team setup
                  Text(
                    'Team Setup',
                    style: AppTheme.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Team A
                  _buildTeamSetupCard(
                    team: state.teamA,
                    teamTurn: TeamTurn.teamA,
                    isEditable: true,
                  ),
                  const SizedBox(height: 16),

                  // VS
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'VS',
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Team B
                  _buildTeamSetupCard(
                    team: state.teamB,
                    teamTurn: TeamTurn.teamB,
                    isEditable: true,
                  ),

                  const SizedBox(height: 40),

                  // Game settings
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildSettingRow('Cards per round', '8'),
                        const Divider(color: Colors.white12),
                        _buildSettingRow(
                            'Points to win', '${state.winningScore}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Start Game
                  _buildPrimaryButton(
                    label: 'Start Game',
                    icon: VesparaIcons.play,
                    onTap: () {
                      Haptics.medium();
                      ref.read(pathOfPleasureProvider.notifier).startGame();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildTeamSetupCard({
    required Team team,
    required TeamTurn teamTurn,
    required bool isEditable,
  }) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              team.color.withOpacity(0.3),
              team.color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: team.color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: team.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  team.name[0],
                  style: AppTheme.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: isEditable
                  ? TextField(
                      controller: TextEditingController(text: team.name),
                      style: AppTheme.titleLarge.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Team name',
                        hintStyle:
                            AppTheme.titleLarge.copyWith(color: Colors.white30),
                      ),
                      onChanged: (value) {
                        ref
                            .read(pathOfPleasureProvider.notifier)
                            .setTeamName(teamTurn, value);
                      },
                    )
                  : Text(
                      team.name,
                      style: AppTheme.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      );

  Widget _buildSettingRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTheme.bodyMedium.copyWith(color: Colors.white70)),
            Text(value,
                style: AppTheme.bodyLarge.copyWith(color: Colors.white)),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════
  // HANDOFF SCREEN (Pass & Play)
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildHandoffScreen(PathOfPleasureState state) {
    final activeTeam = state.activeTeam;
    final isStealing = state.phase == GamePhase.stealing;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            activeTeam.color.withOpacity(0.3),
            AppTheme.backgroundDark,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: activeTeam.color,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: activeTeam.color.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    activeTeam.name[0],
                    style: AppTheme.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isStealing ? 'STEAL ATTEMPT!' : 'Your Turn!',
            style: AppTheme.headlineSmall.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            activeTeam.name,
            style: AppTheme.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isStealing
                ? 'Beat their score to steal the points!'
                : 'Sort cards from Vanilla to Hardcore',
            style: AppTheme.bodyLarge.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildPrimaryButton(
            label: 'Ready',
            icon: VesparaIcons.check,
            color: activeTeam.color,
            onTap: () {
              Haptics.medium();
              ref.read(pathOfPleasureProvider.notifier).dismissHandoff();
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SORTING SCREEN
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildSortingScreen(PathOfPleasureState state) {
    final activeTeam = state.activeTeam;
    final isStealing = state.phase == GamePhase.stealing;
    final isSecondAttempt = state.currentRound?.teamAChosePlay == true;

    return Column(
      children: [
        // Game header with scores
        _buildGameHeader(state),

        // Round info
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: activeTeam.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: activeTeam.color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                isStealing
                    ? VesparaIcons.alert
                    : (isSecondAttempt
                        ? VesparaIcons.refresh
                        : VesparaIcons.trending),
                color: activeTeam.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isStealing
                      ? '${activeTeam.name}: Beat their score to steal!'
                      : (isSecondAttempt
                          ? '${activeTeam.name}: Improve your score!'
                          : '${activeTeam.name}: Sort Vanilla → Hardcore'),
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        // Position labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPositionLabel('🍦 Vanilla', Colors.pink.shade200),
              _buildPositionLabel('🔥 Hardcore', Colors.red.shade400),
            ],
          ),
        ),

        // Sortable cards
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.playerSorting.length,
            onReorder: (oldIndex, newIndex) {
              Haptics.light();
              ref
                  .read(pathOfPleasureProvider.notifier)
                  .reorderCard(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) => AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final animValue = Curves.easeInOut.transform(animation.value);
                final scale = 1.0 + (animValue * 0.05);
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: child,
            ),
            itemBuilder: (context, index) {
              final card = state.playerSorting[index];
              return _buildSortableCard(
                key: ValueKey(card.id),
                card: card,
                index: index,
                total: state.playerSorting.length,
              );
            },
          ),
        ),

        // Submit button
        Padding(
          padding: const EdgeInsets.all(24),
          child: _buildPrimaryButton(
            label: 'Lock In',
            icon: VesparaIcons.check,
            color: activeTeam.color,
            onTap: () {
              Haptics.heavy();
              ref.read(pathOfPleasureProvider.notifier).submitSort();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPositionLabel(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: AppTheme.labelMedium.copyWith(color: color),
        ),
      );

  Widget _buildSortableCard({
    required Key key,
    required KinkCard card,
    required int index,
    required int total,
  }) {
    final position = index + 1;
    final gradientStart = position / total;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(Colors.pink.shade200, Colors.red.shade400,
                        gradientStart)!
                    .withOpacity(0.2),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              // Position number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: AppTheme.labelLarge.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Card text
              Expanded(
                child: Text(
                  card.text,
                  style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                ),
              ),

              // Drag handle
              const Icon(VesparaIcons.menu, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SCORED SCREEN (After first submission)
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildScoredScreen(PathOfPleasureState state) {
    final round = state.currentRound;
    final result = round?.teamAFirstAttempt;
    if (round == null || result == null) return const SizedBox();

    return Column(
      children: [
        _buildGameHeader(state),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Score display
                Text(
                  '${result.correctCount}/8',
                  style: AppTheme.headlineLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 72,
                  ),
                ),
                Text(
                  'Correct Positions',
                  style: AppTheme.bodyLarge.copyWith(color: Colors.white70),
                ),

                const SizedBox(height: 40),

                // Decision prompt
                Text(
                  'What will you do?',
                  style: AppTheme.headlineSmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),

                // PASS or PLAY buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildDecisionButton(
                        label: 'PASS',
                        subtitle: 'Let them try to steal',
                        color: Colors.orange,
                        icon: VesparaIcons.forward,
                        onTap: () {
                          Haptics.medium();
                          ref
                              .read(pathOfPleasureProvider.notifier)
                              .choosePass();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDecisionButton(
                        label: 'PLAY',
                        subtitle: 'Try to improve',
                        color: Colors.green,
                        icon: VesparaIcons.refresh,
                        onTap: () {
                          Haptics.medium();
                          ref
                              .read(pathOfPleasureProvider.notifier)
                              .choosePlay();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionButton({
    required String label,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(
                label,
                style: AppTheme.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  // ════════════════════════════════════════════════════════════════════════
  // DECISION SCREEN (Legacy - now using scored screen)
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildDecisionScreen(PathOfPleasureState state) =>
      _buildScoredScreen(state);

  // ════════════════════════════════════════════════════════════════════════
  // ROUND RESULT SCREEN
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildRoundResultScreen(PathOfPleasureState state) {
    final round = state.currentRound;
    if (round == null) return const SizedBox();

    final pointsTeam =
        round.pointsAwardedTo == TeamTurn.teamA ? state.teamA : state.teamB;

    String outcomeText;
    IconData outcomeIcon;
    Color outcomeColor;

    switch (round.outcome) {
      case RoundOutcome.perfectScore:
        outcomeText = 'PERFECT SCORE!';
        outcomeIcon = VesparaIcons.star;
        outcomeColor = Colors.amber;
        break;
      case RoundOutcome.playSuccess:
        outcomeText = 'PLAY SUCCESSFUL!';
        outcomeIcon = VesparaIcons.check;
        outcomeColor = Colors.green;
        break;
      case RoundOutcome.playFail:
        outcomeText = 'PLAY FAILED!';
        outcomeIcon = VesparaIcons.close;
        outcomeColor = Colors.red;
        break;
      case RoundOutcome.stealSuccess:
        outcomeText = 'STOLEN!';
        outcomeIcon = VesparaIcons.alert;
        outcomeColor = Colors.purple;
        break;
      case RoundOutcome.stealFail:
        outcomeText = 'STEAL BLOCKED!';
        outcomeIcon = VesparaIcons.shield;
        outcomeColor = Colors.blue;
        break;
      default:
        outcomeText = 'ROUND COMPLETE';
        outcomeIcon = VesparaIcons.check;
        outcomeColor = Colors.white;
    }

    return Column(
      children: [
        _buildGameHeader(state),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(outcomeIcon, color: outcomeColor, size: 80),
                const SizedBox(height: 16),

                Text(
                  outcomeText,
                  style: AppTheme.headlineMedium.copyWith(
                    color: outcomeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                if (round.pointsAwarded > 0) ...[
                  Text(
                    '+${round.pointsAwarded}',
                    style: AppTheme.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 64,
                    ),
                  ),
                  Text(
                    'points to ${pointsTeam.name}',
                    style: AppTheme.bodyLarge.copyWith(color: Colors.white70),
                  ),
                ] else
                  Text(
                    'No points awarded',
                    style: AppTheme.bodyLarge.copyWith(color: Colors.white54),
                  ),

                const SizedBox(height: 48),

                // Show correct order
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Correct Order:',
                        style:
                            AppTheme.labelLarge.copyWith(color: Colors.white54),
                      ),
                      const SizedBox(height: 8),
                      ...round.correctOrder.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '${entry.key + 1}. ${entry.value.text}',
                                style: AppTheme.bodyMedium
                                    .copyWith(color: Colors.white70),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                _buildPrimaryButton(
                  label: 'Continue',
                  icon: VesparaIcons.forward,
                  onTap: () {
                    Haptics.medium();
                    ref
                        .read(pathOfPleasureProvider.notifier)
                        .continueToNextRound();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // GAME OVER SCREEN
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildGameOverScreen(PathOfPleasureState state) {
    final winner = state.winner;
    if (winner == null) return const SizedBox();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            winner.color.withOpacity(0.4),
            AppTheme.backgroundDark,
          ],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(VesparaIcons.trophy,
                      color: Colors.amber, size: 80),
                  const SizedBox(height: 24),

                  Text(
                    'WINNER!',
                    style: AppTheme.headlineSmall.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    winner.name,
                    style: AppTheme.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Final scores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFinalScoreCard(state.teamA),
                      _buildFinalScoreCard(state.teamB),
                    ],
                  ),

                  const SizedBox(height: 48),

                  _buildPrimaryButton(
                    label: 'Play Again',
                    icon: VesparaIcons.refresh,
                    onTap: () {
                      Haptics.medium();
                      ref.read(pathOfPleasureProvider.notifier).backToLobby();
                    },
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      ref.read(pathOfPleasureProvider.notifier).reset();
                      context.pop();
                    },
                    child: Text(
                      'Exit',
                      style:
                          AppTheme.labelLarge.copyWith(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalScoreCard(Team team) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: team.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: team.color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(
              team.name,
              style: AppTheme.labelLarge.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              '${team.score}',
              style: AppTheme.headlineLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════
  // COMMON WIDGETS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildHeader({bool showBack = false, VoidCallback? onBack}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(VesparaIcons.back, color: Colors.white70),
              onPressed: onBack ??
                  () {
                    ref.read(pathOfPleasureProvider.notifier).reset();
                    context.pop();
                  },
            ),
            const Spacer(),
            Text(
              'PATH OF PLEASURE',
              style: AppTheme.labelLarge.copyWith(
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      );

  Widget _buildGameHeader(PathOfPleasureState state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            // Team A score
            _buildTeamScore(state.teamA, state.currentTurn == TeamTurn.teamA),

            const Spacer(),

            // Round info
            Column(
              children: [
                Text(
                  'Round ${state.roundNumber}',
                  style: AppTheme.labelMedium.copyWith(color: Colors.white54),
                ),
                Text(
                  'First to ${state.winningScore}',
                  style: AppTheme.labelSmall.copyWith(color: Colors.white38),
                ),
              ],
            ),

            const Spacer(),

            // Team B score
            _buildTeamScore(state.teamB, state.currentTurn == TeamTurn.teamB),
          ],
        ),
      );

  Widget _buildTeamScore(Team team, bool isActive) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? team.color.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? team.color : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              team.name,
              style: AppTheme.labelSmall.copyWith(
                color: isActive ? Colors.white : Colors.white54,
              ),
            ),
            Text(
              '${team.score}',
              style: AppTheme.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: color != null
                  ? [color, color.withOpacity(0.7)]
                  : [const Color(0xFFFF6B6B), const Color(0xFF4ECDC4)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (color ?? const Color(0xFFFF6B6B)).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to Play',
              style: AppTheme.headlineSmall.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildHowToItem('1.', 'Teams take turns sorting 8 cards'),
            _buildHowToItem('2.', 'Order them from Vanilla to Hardcore'),
            _buildHowToItem('3.', 'After sorting, choose PASS or PLAY'),
            _buildHowToItem('4.', 'PASS: Other team tries to beat your score'),
            _buildHowToItem('5.', 'PLAY: Try to improve your own score'),
            _buildHowToItem('6.', 'First team to 20 points wins!'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToItem(String number, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: AppTheme.bodyLarge.copyWith(
                color: const Color(0xFFFF6B6B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
}
