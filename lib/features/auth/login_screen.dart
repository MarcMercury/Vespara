import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mfa_email_verify_screen.dart';
import 'mfa_method_screen.dart';
import 'mfa_setup_screen.dart';
import 'mfa_verify_screen.dart';

/// Members-Only Login Screen - Email + Password with required MFA
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _background = Color(0xFF1A1523);
  static const _surface = Color(0xFF2D2640);
  static const _primary = Color(0xFFE0D8EA);
  static const _muted = Color(0xFF9A8EB5);
  static const _error = Color(0xFFEF5350);
  static const _glow = Color(0xFFD4A8FF);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      if (_isSignUp) {
        // Sign up with email + password
        final response = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null && mounted) {
          // After signup, let user choose MFA method
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MfaMethodScreen(),
            ),
          );
        }
      } else {
        // Sign in
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        // Check MFA enrollment - require MFA verification
        final factors = await supabase.auth.mfa.listFactors();
        final totpFactors = factors.totp;

        if (totpFactors.isNotEmpty &&
            totpFactors.any((f) => f.status == FactorStatus.verified)) {
          // User has TOTP MFA enrolled, need to verify
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MfaVerifyScreen(
                factorId: totpFactors
                    .firstWhere((f) => f.status == FactorStatus.verified)
                    .id,
              ),
            ),
          );
        } else {
          // Check if user has email OTP enrolled
          final profile = await supabase
              .from('profiles')
              .select('mfa_method, mfa_enrolled')
              .eq('id', supabase.auth.currentUser!.id)
              .maybeSingle();

          final mfaMethod = profile?['mfa_method'] as String?;
          final mfaEnrolled = profile?['mfa_enrolled'] as bool? ?? false;

          if (mfaMethod == 'email' && mfaEnrolled && mounted) {
            // User uses email OTP - send code and verify
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MfaEmailVerifyScreen(),
              ),
            );
          } else if (mounted) {
            // User doesn't have any MFA yet - let them choose
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MfaMethodScreen(),
              ),
            );
          }
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email address first';
      });
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
            backgroundColor: _surface,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not send reset email. Try again.';
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 10) return 'Minimum 10 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Include a lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include a number';
    if (!RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,\.<>\?]').hasMatch(value)) {
      return 'Include a special character';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Moon Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primary.withOpacity(0.8),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'VESPARA',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      color: _primary,
                      letterSpacing: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _isSignUp ? 'Create Your Account' : 'Members Only',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _muted,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _error.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: _error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: const TextStyle(color: _primary),
                    decoration: _inputDecoration('Email', Icons.email_outlined),
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    validator: _isSignUp ? _validatePassword : null,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: _primary),
                    decoration: _inputDecoration(
                      'Password',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: _muted,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),

                  // Confirm password (sign up only)
                  if (_isSignUp) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      obscureText: _obscureConfirm,
                      style: const TextStyle(color: _primary),
                      decoration: _inputDecoration(
                        'Confirm Password',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: _muted,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Password requirements hint
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '• 10+ characters  • Upper & lowercase\n• Number  • Special character',
                        style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _glow,
                        foregroundColor: _background,
                        disabledBackgroundColor: _glow.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _background,
                              ),
                            )
                          : Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Forgot password (sign in only)
                  if (!_isSignUp)
                    TextButton(
                      onPressed: _handlePasswordReset,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Toggle sign up / sign in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp
                            ? 'Already a member?'
                            : "Don't have an account?",
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _isSignUp = !_isSignUp;
                          _errorMessage = null;
                          _formKey.currentState?.reset();
                        }),
                        child: Text(
                          _isSignUp ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(
                            color: _glow,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // MFA badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, color: _glow, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Protected by 2-Factor Authentication',
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Terms
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                      style: TextStyle(
                        fontSize: 12,
                        color: _muted.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        prefixIcon: Icon(icon, color: _muted, size: 20),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _glow, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _error, fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      );
}
