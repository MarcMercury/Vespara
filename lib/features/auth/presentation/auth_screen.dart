import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';

/// Auth Screen - Login / Sign Up
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _error;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    VesparaHaptics.lightTap();
    
    try {
      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      
      VesparaHaptics.success();
      if (mounted) {
        context.go('/home');
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
      VesparaHaptics.error();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VesparaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              
              // Header
              Text(
                _isSignUp ? 'CREATE ACCOUNT' : 'WELCOME BACK',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: VesparaSpacing.sm),
              Text(
                _isSignUp 
                    ? 'Join the Vespara experience'
                    : 'Enter your credentials to continue',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: VesparaSpacing.xl),
              
              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              
              const SizedBox(height: VesparaSpacing.md),
              
              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              
              // Error message
              if (_error != null) ...[
                const SizedBox(height: VesparaSpacing.md),
                Container(
                  padding: const EdgeInsets.all(VesparaSpacing.sm),
                  decoration: BoxDecoration(
                    color: VesparaColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: VesparaColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: VesparaColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: VesparaSpacing.lg),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: VesparaColors.background,
                          ),
                        )
                      : Text(_isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN'),
                ),
              ),
              
              const SizedBox(height: VesparaSpacing.md),
              
              // Toggle sign up / sign in
              Center(
                child: TextButton(
                  onPressed: () {
                    VesparaHaptics.lightTap();
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _error = null;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : 'Don\'t have an account? Sign up',
                  ),
                ),
              ),
              
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
