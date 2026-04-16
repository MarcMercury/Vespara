import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

/// MFA Email Verify Screen — Shown on each login for users who chose email OTP
class MfaEmailVerifyScreen extends StatefulWidget {
  const MfaEmailVerifyScreen({super.key});

  @override
  State<MfaEmailVerifyScreen> createState() => _MfaEmailVerifyScreenState();
}

class _MfaEmailVerifyScreenState extends State<MfaEmailVerifyScreen> {
  static const _background = Color(0xFF1A1523);
  static const _surface = Color(0xFF2D2640);
  static const _primary = Color(0xFFE0D8EA);
  static const _muted = Color(0xFF9A8EB5);
  static const _glow = Color(0xFFD4A8FF);
  static const _error = Color(0xFFEF5350);

  // Class-level guard: prevent re-sending if the screen is re-mounted within cooldown
  static DateTime? _lastSendTime;
  static const _minSendInterval = Duration(seconds: 60);

  final _codeController = TextEditingController();
  bool _isSending = false;
  bool _isVerifying = false;
  bool _codeSent = false;
  String? _errorMessage;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
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
        setState(() => _codeSent = true);
        _startCooldown();
      } else {
        setState(() {
          _errorMessage = body['error'] ?? 'Failed to send code.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send code. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
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
        _errorMessage = 'Verification failed. Try again.';
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email_rounded, color: _glow, size: 56),
                const SizedBox(height: 24),
                const Text(
                  'Email Verification',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeSent
                      ? 'Enter the code we sent to your email'
                      : 'Sending verification code...',
                  style: const TextStyle(color: _muted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                if (_isSending && !_codeSent) ...[
                  const CircularProgressIndicator(color: _glow),
                  const SizedBox(height: 24),
                ],

                // Error
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
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

                // Resend
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
                            'Verify',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign out option
                TextButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  child: const Text(
                    'Sign in with a different account',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
