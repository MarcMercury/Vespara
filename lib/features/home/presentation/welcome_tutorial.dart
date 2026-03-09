import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_effects.dart';

/// WelcomeTutorial - First-time user click-through guide
/// Introduces the 6 core sections of Vespara with a luxurious dark aesthetic
class WelcomeTutorial extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeTutorial({super.key, required this.onComplete});

  static const String _prefKey = 'vespara_tutorial_seen';

  /// Check if the user has already seen the tutorial
  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Mark tutorial as seen
  static Future<void> markTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  @override
  State<WelcomeTutorial> createState() => _WelcomeTutorialState();
}

class _WelcomeTutorialState extends State<WelcomeTutorial>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const List<_TutorialPage> _pages = [
    _TutorialPage(
      icon: Icons.auto_awesome_rounded,
      emoji: '🪞',
      title: 'MIRROR',
      subtitle: 'Your Reflection',
      description:
          'Build and manage your profile. Set your vibe, upload photos, '
          'customize your interests, and let AI craft your perfect bio.',
      color: Color(0xFFBFA6D8),
    ),
    _TutorialPage(
      icon: Icons.travel_explore_rounded,
      emoji: '🔮',
      title: 'DISCOVER',
      subtitle: 'The Hunt',
      description:
          'Find other users who match your energy. Browse profiles, '
          'swipe through potential connections, and spark new chemistry.',
      color: Color(0xFFFF6B9D),
    ),
    _TutorialPage(
      icon: Icons.favorite_rounded,
      emoji: '💜',
      title: 'SANCTUM',
      subtitle: 'Your Inner Circle',
      description:
          'Organize and manage your connections. Keep track of matches, '
          'conversations, and the people who matter most.',
      color: Color(0xFF4ECDC4),
    ),
    _TutorialPage(
      icon: Icons.auto_delete_rounded,
      emoji: '🥀',
      title: 'SHREDDER',
      subtitle: 'Clean Slate',
      description:
          'Disconnect with confidence. AI-powered cleanup helps you '
          'end connections gracefully and maintain your boundaries.',
      color: Color(0xFFEF5350),
    ),
    _TutorialPage(
      icon: Icons.local_fire_department_rounded,
      emoji: '🎭',
      title: 'TAG',
      subtitle: 'Trusted Adult Games',
      description:
          'Break the ice and heat things up with curated adult games '
          'designed to deepen connections and spark unforgettable moments.',
      color: Color(0xFFFFD54F),
    ),
    _TutorialPage(
      icon: Icons.auto_awesome_rounded,
      emoji: '🎯',
      title: 'MINIS',
      subtitle: 'Quick Hits',
      description:
          'Kill time with addictive daily mini-games. Compete, '
          'challenge yourself, and have fun between connections.',
      color: Color(0xFFFF6B9D),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeTutorial();
    }
  }

  void _onSkip() {
    _completeTutorial();
  }

  Future<void> _completeTutorial() async {
    await WelcomeTutorial.markTutorialSeen();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: VesparaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VesparaNeonText(
                      text: 'WELCOME',
                      style: GoogleFonts.cinzel(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: VesparaColors.primary,
                      ),
                      glowColor: VesparaColors.glow,
                      glowRadius: 12,
                    ),
                    TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Page dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: index == _currentPage ? 28 : 8,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? _pages[_currentPage].color
                          : VesparaColors.surface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) =>
                      _buildPage(_pages[index]),
                ),
              ),

              // Bottom button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      foregroundColor: VesparaColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'LET\'S GO ✨'
                          : 'NEXT',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_TutorialPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  page.color.withOpacity(0.3),
                  page.color.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: page.color.withOpacity(0.25),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: GoogleFonts.cinzel(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
              color: page.color,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            page.subtitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: VesparaColors.secondary,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 32),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: VesparaColors.primary.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialPage {
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final Color color;

  const _TutorialPage({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
  });
}
