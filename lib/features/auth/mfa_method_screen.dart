import 'package:flutter/material.dart';

import 'mfa_email_setup_screen.dart';
import 'mfa_setup_screen.dart';

/// MFA Method Selection Screen — Choose between authenticator app or email code
class MfaMethodScreen extends StatelessWidget {
  const MfaMethodScreen({super.key});

  static const _background = Color(0xFF1A1523);
  static const _surface = Color(0xFF2D2640);
  static const _primary = Color(0xFFE0D8EA);
  static const _muted = Color(0xFF9A8EB5);
  static const _glow = Color(0xFFD4A8FF);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          foregroundColor: _primary,
          title: const Text('Set Up 2-Factor Auth'),
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.shield_rounded, color: _glow, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Secure Your Account',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vespara requires two-factor authentication\nto protect your privacy.',
                  style: TextStyle(color: _muted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose your preferred verification method:',
                  style: TextStyle(color: _muted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Option 1: Email Code
                _MethodCard(
                  icon: Icons.email_outlined,
                  title: 'Email Verification Code',
                  subtitle:
                      'We\'ll send a 6-digit code to your email each time you log in.',
                  recommended: true,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const MfaEmailSetupScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Option 2: Authenticator App
                _MethodCard(
                  icon: Icons.phone_android_rounded,
                  title: 'Authenticator App',
                  subtitle:
                      'Use Google Authenticator, Authy, or 1Password to generate codes.',
                  recommended: false,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const MfaSetupScreen(),
                    ),
                  ),
                ),

                const Spacer(),

                // Security note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: _muted, size: 18),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Both methods provide strong security. You can change your method later in Settings.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool recommended;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.recommended,
    required this.onTap,
  });

  static const _surface = Color(0xFF2D2640);
  static const _primary = Color(0xFFE0D8EA);
  static const _muted = Color(0xFF9A8EB5);
  static const _glow = Color(0xFFD4A8FF);
  static const _background = Color(0xFF1A1523);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: recommended ? _glow.withOpacity(0.5) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _glow.withOpacity(0.15),
                ),
                child: Icon(icon, color: _glow, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _glow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Easiest',
                              style: TextStyle(
                                color: _glow,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _muted, size: 20),
            ],
          ),
        ),
      );
}
