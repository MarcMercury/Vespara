import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// MFA Setup Screen - Required for all members
/// Enrolls TOTP authenticator app factor
class MfaSetupScreen extends StatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  State<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends State<MfaSetupScreen> {
  static const _background = Color(0xFF1A1523);
  static const _surface = Color(0xFF2D2640);
  static const _primary = Color(0xFFE0D8EA);
  static const _muted = Color(0xFF9A8EB5);
  static const _glow = Color(0xFFD4A8FF);
  static const _error = Color(0xFFEF5350);

  final _codeController = TextEditingController();
  bool _isLoading = true;
  bool _isVerifying = false;
  String? _errorMessage;

  // MFA enrollment data
  String? _factorId;
  String? _totpUri;
  String? _secret;
  String? _qrImageUrl;

  @override
  void initState() {
    super.initState();
    _enrollMfa();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _enrollMfa() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.mfa.enroll(
        factorType: FactorType.totp,
        friendlyName: 'Vespara Authenticator',
      );

      setState(() {
        _factorId = response.id;
        _totpUri = response.totp?.uri;
        _secret = response.totp?.secret;
        // Build QR code URL from the TOTP URI
        _qrImageUrl = response.totp?.qrCode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to set up 2FA. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyMfa() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Enter the 6-digit code from your authenticator app';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final challenge =
          await supabase.auth.mfa.challenge(factorId: _factorId!);

      await supabase.auth.mfa.verify(
        factorId: _factorId!,
        challengeId: challenge.id,
        code: code,
      );

      // Mark TOTP as the chosen MFA method in profile
      await supabase
          .from('profiles')
          .update({'mfa_method': 'totp', 'mfa_enrolled': true})
          .eq('id', supabase.auth.currentUser!.id);

      // MFA is now enrolled and verified. AuthGate will handle navigation.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed. Check your code and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _glow),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: _glow,
                        size: 48,
                      ),
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
                      const SizedBox(height: 32),

                      // Step 1: Install authenticator
                      _buildStep(
                        '1',
                        'Install an authenticator app',
                        'Google Authenticator, Authy, or 1Password',
                      ),

                      const SizedBox(height: 16),

                      // Step 2: QR code
                      _buildStep(
                        '2',
                        'Scan this QR code',
                        'Open your authenticator and scan:',
                      ),

                      const SizedBox(height: 16),

                      // QR code display
                      if (_qrImageUrl != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.memory(
                            base64Decode(_qrImageUrl!.split(',').last),
                            width: 200,
                            height: 200,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Manual entry secret
                      if (_secret != null)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _secret!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Secret copied to clipboard'),
                                backgroundColor: _surface,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _secret!,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.copy,
                                  color: _muted,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Step 3: Enter code
                      _buildStep(
                        '3',
                        'Enter the 6-digit code',
                        'From your authenticator app:',
                      ),

                      const SizedBox(height: 16),

                      // Error
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: _error, fontSize: 13),
                          ),
                        ),

                      // Code input
                      SizedBox(
                        width: 240,
                        child: TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 28,
                            letterSpacing: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: _surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: _glow, width: 1.5),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyMfa,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _glow,
                            foregroundColor: _background,
                            disabledBackgroundColor: _glow.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _background,
                                  ),
                                )
                              : const Text(
                                  'Verify & Complete Setup',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );

  Widget _buildStep(String number, String title, String subtitle) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _glow.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: _glow,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
}
