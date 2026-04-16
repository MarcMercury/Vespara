import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

/// MFA Email OTP Setup Screen — Send a verification code to the user's email
class MfaEmailSetupScreen extends StatefulWidget {
  const MfaEmailSetupScreen({super.key});

  @override
  State<MfaEmailSetupScreen> createState() => _MfaEmailSetupScreenState();
}

class _MfaEmailSetupScreenState extends State<MfaEmailSetupScreen> {
  static const _background = Color(0xFF1A1523);
  static const _surface = Color(0xFF2D2640);
  static const _primary = Color(0xFFE0D8EA);
  static const _muted = Color(0xFF9A8EB5);
  static const _glow = Color(0xFFD4A8FF);
  static const _error = Color(0xFFEF5350);
  static const _success = Color(0xFF4ECDC4);

  // Class-level guard: prevent re-sending if the screen is re-mounted within cooldown
  static DateTime? _lastSendTime;
  static const _minSendInterval = Duration(seconds: 60);

  final _codeController = TextEditingController();
  bool _isSending = false;
  bool _isVerifying = false;
  bool _codeSent = false;
  String? _errorMessage;
  String? _userEmail;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _userEmail = Supabase.instance.client.auth.currentUser?.email;
    // Only auto-send if we haven't sent recently (prevents re-mount spam)
    if (_lastSendTime == null ||
        DateTime.now().difference(_lastSendTime!) > _minSendInterval) {
      _sendCode();
    } else {
      // Already sent recently - show the code input immediately
      _codeSent = true;
      final remaining = _minSendInterval.inSeconds -
          DateTime.now().difference(_lastSendTime!).inSeconds;
      if (remaining > 0) {
        _resendCooldown = remaining;
        _startCooldown();
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) timer.cancel();
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendCode() async {
    if (_isSending || _resendCooldown > 0) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${Env.supabaseUrl}/functions/v1/mfa-email-otp'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
          'apikey': Env.supabaseAnonKey,
        },
        body: jsonEncode({'action': 'send'}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _lastSendTime = DateTime.now();
        setState(() {
          _codeSent = true;
        });
        _startCooldown();
      } else if (response.statusCode == 429) {
        setState(() {
          _errorMessage = body['error'] ?? 'Too many requests. Please wait.';
        });
      } else {
        setState(() {
          _errorMessage = body['error'] ?? 'Failed to send code.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send verification code. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Enter the 6-digit code from your email';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${Env.supabaseUrl}/functions/v1/mfa-email-otp'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
          'apikey': Env.supabaseAnonKey,
        },
        body: jsonEncode({'action': 'verify', 'code': code}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['verified'] == true) {
        // Email OTP verified — navigate back to AuthGate
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        setState(() {
          _errorMessage = body['error'] ?? 'Invalid code. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].length < 2) return email;
    final name = parts[0];
    final masked =
        '${name[0]}${'•' * (name.length - 2)}${name[name.length - 1]}';
    return '$masked@${parts[1]}';
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.email_rounded, color: _glow, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Email Verification',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We\'ll send a verification code to your email\neach time you sign in.',
                  style: TextStyle(color: _muted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Step 1: Email sent
                _buildStep(
                  '1',
                  'Check your email',
                  _codeSent && _userEmail != null
                      ? 'Code sent to ${_maskEmail(_userEmail!)}'
                      : 'Sending code to your email...',
                ),

                const SizedBox(height: 16),

                // Email sent indicator
                if (_codeSent)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _success.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: _success, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Code sent! Check your inbox.',
                          style: TextStyle(color: _success, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                if (_isSending && !_codeSent) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: _glow),
                ],

                const SizedBox(height: 24),

                // Step 2: Enter code
                _buildStep(
                  '2',
                  'Enter the 6-digit code',
                  'From the email we just sent:',
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
                    autofocus: true,
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
                    onFieldSubmitted: (_) => _verifyCode(),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend link
                TextButton(
                  onPressed:
                      _resendCooldown > 0 || _isSending ? null : _sendCode,
                  child: Text(
                    _resendCooldown > 0
                        ? 'Resend code in ${_resendCooldown}s'
                        : 'Didn\'t get the code? Resend',
                    style: TextStyle(
                      color:
                          _resendCooldown > 0 ? _muted.withOpacity(0.5) : _glow,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Hint about spam folder
                const Text(
                  'Check your spam folder if you don\'t see it.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),

                const SizedBox(height: 24),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isVerifying || !_codeSent ? null : _verifyCode,
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
