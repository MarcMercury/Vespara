import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/minis_analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vespara_icons.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/premium_effects.dart';
import 'safe_word_screen.dart';
import 'red_flag_screen.dart';
import 'cocktail_screen.dart';
import 'caught_in_the_act_screen.dart';
import 'bad_idea_screen.dart';
import 'whats_your_position_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// MINI'S — Quick Solo Mini-Games
/// Icon-grid hub matching TAG's layout with full-bleed game icons
/// ════════════════════════════════════════════════════════════════════════════

class MinisScreen extends StatefulWidget {
  const MinisScreen({super.key});

  @override
  State<MinisScreen> createState() => _MinisScreenState();
}

class _MinisScreenState extends State<MinisScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<Animation<double>> _cardAnimations;
  MinisAnalyticsSnapshot? _snapshot;

  static const List<String> _gameTitles = [
    'Safe Word',
    'Red Flag',
    'Cocktail',
    'Get Caught',
    'Bad Idea',
    'Position',
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardAnimations = List.generate(_gameTitles.length, (index) {
      final startTime = index * 0.12;
      final endTime = startTime + 0.4;
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          startTime,
          endTime.clamp(0.0, 1.0),
          curve: Curves.easeOutBack,
        ),
      );
    });

    _staggerController.forward();
    unawaited(_trackHubVisitAndRefresh());
  }

  Future<void> _trackHubVisitAndRefresh() async {
    await MinisAnalyticsService.instance.trackHubVisit();
    await _refreshSnapshot();
  }

  Future<void> _refreshSnapshot() async {
    final snapshot = await MinisAnalyticsService.instance.getSnapshot();
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _openGame(int index) {
    final gameKey = _getGameKey(index);
    if (gameKey == null) return;

    Widget screen;
    switch (index) {
      case 0:
        screen = const SafeWordScreen();
        break;
      case 1:
        screen = const RedFlagScreen();
        break;
      case 2:
        screen = const CocktailScreen();
        break;
      case 3:
        screen = const CaughtInTheActScreen();
        break;
      case 4:
        screen = const BadIdeaScreen();
        break;
      case 5:
        screen = const WhatsYourPositionScreen();
        break;
      default:
        return;
    }

    unawaited(MinisAnalyticsService.instance.trackGameOpen(gameKey));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      unawaited(_refreshSnapshot());
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: VesparaAnimatedBackground(
          enableParticles: true,
          particleCount: 15,
          auroraIntensity: 0.8,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildGamesGrid()),
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
            Column(
              children: [
                VesparaNeonText(
                  text: "MINI'S",
                  style: GoogleFonts.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: const Color(0xFFFF6B9D),
                  ),
                  glowColor: const Color(0xFFFF6B9D),
                  glowRadius: 12,
                ),
                const SizedBox(height: 2),
                Text(
                  'Quick Hits',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                  ),
                ),
                if ((_snapshot?.gamePlays ?? 0) > 0)
                  Text(
                    'Top: ${_labelForGameKey(_snapshot?.topGameKey)}  |  Plays: ${_snapshot?.gamePlays ?? 0}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: VesparaColors.secondary.withOpacity(0.85),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      );

  Widget _buildGamesGrid() => LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final aspectRatio = screenWidth < 360 ? 0.75 : 0.85;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _gameTitles.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _cardAnimations[index],
                builder: (context, child) {
                  final value = _cardAnimations[index].value;
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _buildGameCard(index),
              );
            },
          );
        },
      );

  Widget _buildGameCard(int index) {
    final gameColor = _getGameAccentColor(index);

    return Vespara3DTiltCard(
      maxTiltDegrees: 7,
      borderRadius: 20,
      glowColor: gameColor,
      onTap: () => _openGame(index),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gameColor.withOpacity(0.7), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: gameColor.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    _getGameIconPath(index),
                    fit: BoxFit.contain,
                    cacheWidth: 400,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          _gameTitles[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: VesparaColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGameIconPath(int index) {
    switch (index) {
      case 0:
        return 'assets/images/GAME ICONS/Safe Word.png';
      case 1:
        return 'assets/images/GAME ICONS/Red Flag.png';
      case 2:
        return 'assets/images/GAME ICONS/Cocktail.png';
      case 3:
        return 'assets/images/GAME ICONS/Get Caught.png';
      case 4:
        return 'assets/images/GAME ICONS/Bad Idea.png';
      case 5:
        return 'assets/images/GAME ICONS/Position.png';
      default:
        return 'assets/images/GAME ICONS/Safe Word.png';
    }
  }

  Color _getGameAccentColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFE91E63); // Safe Word — hot pink
      case 1:
        return const Color(0xFFFF1744); // Red Flag — red
      case 2:
        return const Color(0xFF9C27B0); // Cocktail — purple
      case 3:
        return const Color(0xFFFF6D00); // Get Caught — orange
      case 4:
        return const Color(0xFF00BFA5); // Bad Idea — teal
      case 5:
        return const Color(0xFF00ACC1); // Position — cyan
      default:
        return const Color(0xFFFF6B9D);
    }
  }

  String? _getGameKey(int index) {
    switch (index) {
      case 0:
        return 'safe_word';
      case 1:
        return 'red_flag';
      case 2:
        return 'cocktail';
      case 3:
        return 'get_caught';
      case 4:
        return 'bad_idea';
      case 5:
        return 'whats_your_position';
      default:
        return null;
    }
  }

  String _labelForGameKey(String? key) {
    switch (key) {
      case 'safe_word':
        return 'Safe Word';
      case 'red_flag':
        return 'Red Flag';
      case 'cocktail':
        return 'Cocktail';
      case 'get_caught':
        return 'Get Caught';
      case 'bad_idea':
        return 'Bad Idea';
      case 'whats_your_position':
        return 'Position';
      default:
        return 'None';
    }
  }
}
