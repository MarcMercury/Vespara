import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:vibration/vibration.dart';

import '../../core/services/auth_service.dart';

/// LoginScreen: "The Gate" - First impression of Vespara
/// 
/// Design: Vespara Night background with centered moon/logo animation
/// Three auth options: Apple (primary), Google, Email magic link
/// No passwords, no friction - just a velvet rope
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showEmailInput = false;
  final _emailController = TextEditingController();

  // Vespara Night Color Palette
  static const _background = Color(0xFF1A1523);
  static const _surface = Color(0xFF2D2640);
  static const _primary = Color(0xFFE0D8EA);
  static const _accent = Color(0xFFBFB3D2);
  static const _muted = Color(0xFF9A8EB5);

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signInWithApple() async {
    await _performAuth(() async {
      await ref.read(authServiceProvider).signInWithApple();
    });
  }

  Future<void> _signInWithGoogle() async {
    await _performAuth(() async {
      await ref.read(authServiceProvider).signInWithGoogle();
    });
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }
    
    await _performAuth(() async {
      await ref.read(authServiceProvider).signInWithEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Check your email for the magic link ✨',
              style: TextStyle(color: _primary),
            ),
            backgroundColor: _surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _showEmailInput = false);
      }
    });
  }

  Future<void> _performAuth(Future<void> Function() authAction) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Haptic feedback
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }

    try {
      await authAction();
      
      if (mounted) {
        // Check if onboarding is needed
        final isComplete = await ref.read(authServiceProvider).isOnboardingComplete;
        if (isComplete) {
          context.go('/');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        HapticFeedback.heavyImpact();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // Moon Logo with breathing glow
              _buildMoonLogo(),
              
              const SizedBox(height: 48),
              
              // Vespara wordmark
              Text(
                'VESPARA',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  color: _primary,
                  letterSpacing: 12,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'Social Operating System',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: _muted,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 600.ms),
              
              const Spacer(flex: 3),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn().shake(),
              
              // Email input (if showing)
              if (_showEmailInput) _buildEmailInput(),
              
              // Auth buttons
              if (!_showEmailInput) ...[
                // Apple Sign In - Primary
                _buildAuthButton(
                  onPressed: _signInWithApple,
                  icon: Icons.apple,
                  label: 'Continue with Apple',
                  isPrimary: true,
                ).animate().fadeIn(duration: 600.ms, delay: 800.ms)
                  .slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 12),
                
                // Google Sign In
                _buildAuthButton(
                  onPressed: _signInWithGoogle,
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Continue with Google',
                ).animate().fadeIn(duration: 600.ms, delay: 900.ms)
                  .slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 12),
                
                // Email Sign In
                _buildAuthButton(
                  onPressed: () => setState(() => _showEmailInput = true),
                  icon: Iconsax.sms,
                  label: 'Continue with Email',
                ).animate().fadeIn(duration: 600.ms, delay: 1000.ms)
                  .slideY(begin: 0.3, end: 0),
              ],
              
              const Spacer(),
              
              // Terms
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _muted.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 1200.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoonLogo() {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final glowOpacity = 0.3 + (_breathingController.value * 0.4);
        final scale = 1.0 + (_breathingController.value * 0.05);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primary,
                  _accent,
                  _surface,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(glowOpacity),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
                BoxShadow(
                  color: _accent.withOpacity(glowOpacity * 0.5),
                  blurRadius: 100,
                  spreadRadius: 40,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primary.withOpacity(0.9),
                      _accent.withOpacity(0.7),
                    ],
                  ),
                ),
                // Inner crescent shadow for moon effect
                child: Stack(
                  children: [
                    Positioned(
                      right: 15,
                      top: 15,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _surface.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 1200.ms).scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildAuthButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? _primary : _surface,
          foregroundColor: isPrimary ? _background : _primary,
          disabledBackgroundColor: (isPrimary ? _primary : _surface).withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary 
                ? BorderSide.none 
                : BorderSide(color: _accent.withOpacity(0.3)),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isPrimary ? _background : _primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: _primary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: _muted.withOpacity(0.7)),
              prefixIcon: Icon(Iconsax.sms, color: _muted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 16),
        
        _buildAuthButton(
          onPressed: _signInWithEmail,
          icon: Iconsax.magic_star,
          label: 'Send Magic Link',
          isPrimary: true,
        ).animate().fadeIn(delay: 100.ms),
        
        const SizedBox(height: 12),
        
        TextButton(
          onPressed: () => setState(() {
            _showEmailInput = false;
            _emailController.clear();
          }),
          child: Text(
            'Back to options',
            style: TextStyle(
              fontFamily: 'Inter',
              color: _muted,
              fontSize: 14,
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }
}
