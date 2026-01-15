import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  runApp(const ProviderScope(child: VesparaApp()));
}

class VesparaApp extends StatelessWidget {
  const VesparaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vespara',
      debugShowCheckedModeBanner: false,
      theme: VesparaTheme.dark,
      home: const AuthGate(),
    );
  }
}

/// Listens to auth state and shows appropriate screen
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  Session? _session;
  String? _error;
  bool? _hasCompletedOnboarding;
  
  @override
  void initState() {
    super.initState();
    _initAuth();
  }
  
  Future<void> _initAuth() async {
    try {
      // Listen for auth changes FIRST
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        debugPrint('Vespara Auth: ${data.event} - session: ${data.session != null}');
        if (mounted) {
          setState(() {
            _session = data.session;
            _isLoading = false;
          });
          // Check onboarding status when session changes
          if (data.session != null) {
            _checkOnboardingStatus(data.session!.user.id);
          }
        }
      });
      
      // On web, check if we're returning from OAuth
      if (kIsWeb) {
        final uri = Uri.base;
        debugPrint('Vespara: Current URL = $uri');
        
        // Check for OAuth callback parameters
        if (uri.hasFragment || uri.queryParameters.containsKey('code')) {
          debugPrint('Vespara: Detected OAuth callback, waiting for session...');
          // Wait longer for PKCE code exchange
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      // Get current session
      _session = Supabase.instance.client.auth.currentSession;
      debugPrint('Vespara: Final session check = ${_session != null}');
      
      // Check onboarding status if we have a session
      if (_session != null) {
        await _checkOnboardingStatus(_session!.user.id);
      }
      
    } catch (e) {
      debugPrint('Vespara Auth Error: $e');
      _error = e.toString();
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _checkOnboardingStatus(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('onboarding_completed')
          .eq('id', userId)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = response?['onboarding_completed'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Vespara: Error checking onboarding: $e');
      // If profile doesn't exist or table error, skip onboarding for now
      // and let user into the app
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = true; // Skip onboarding if DB issue
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: VesparaColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: VesparaColors.primary),
              SizedBox(height: 16),
              Text('Loading...', style: TextStyle(color: VesparaColors.secondary)),
            ],
          ),
        ),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        backgroundColor: VesparaColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: VesparaColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Error: $_error', style: const TextStyle(color: VesparaColors.error)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _initAuth();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Not logged in - show login screen
    if (_session == null) {
      return const LoginScreen();
    }
    
    // Logged in but loading onboarding status
    if (_hasCompletedOnboarding == null) {
      return const Scaffold(
        backgroundColor: VesparaColors.background,
        body: Center(
          child: CircularProgressIndicator(color: VesparaColors.primary),
        ),
      );
    }
    
    // Logged in but hasn't completed onboarding
    if (_hasCompletedOnboarding == false) {
      return const OnboardingScreen();
    }
    
    // Logged in and onboarding complete - show the full app!
    return const HomeScreen();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN - Working OAuth implementation
// ═══════════════════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'https://vespara.vercel.app',
      );
    } catch (e) {
      _showError('Apple Sign In failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://vespara.vercel.app',
      );
    } catch (e) {
      _showError('Google Sign In failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: const Text('Enter your email', style: TextStyle(color: VesparaColors.primary)),
        content: TextField(
          controller: emailController,
          style: const TextStyle(color: VesparaColors.primary),
          decoration: InputDecoration(
            hintText: 'your@email.com',
            hintStyle: TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: VesparaColors.secondary)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: VesparaColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signInWithEmail(emailController.text);
            },
            child: const Text('Send Magic Link', style: TextStyle(color: VesparaColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithEmail(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'https://vespara.vercel.app',
      );
      _showSuccess('Magic link sent! Check your email ✨');
    } catch (e) {
      _showError('Failed to send magic link: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: VesparaColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: VesparaColors.background)),
        backgroundColor: VesparaColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) => Opacity(
          opacity: _fadeIn.value,
          child: Transform.translate(
            offset: Offset(0, _slideUp.value),
            child: child,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Moon Logo with glow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [VesparaColors.primary, VesparaColors.primary.withOpacity(0.6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: VesparaColors.glow.withOpacity(0.4),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                Text(
                  'VESPARA',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    letterSpacing: 12,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                const Text(
                  'Your secrets are safe here',
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: VesparaColors.secondary,
                    letterSpacing: 1,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Apple Sign In
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signInWithApple,
                    icon: const Icon(Icons.apple, size: 24),
                    label: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Continue with Apple', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VesparaColors.primary,
                      foregroundColor: VesparaColors.background,
                      disabledBackgroundColor: VesparaColors.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VesparaBorderRadius.button)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Google Sign In
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VesparaColors.primary,
                      disabledForegroundColor: VesparaColors.primary.withOpacity(0.5),
                      side: BorderSide(color: VesparaColors.primary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VesparaBorderRadius.button)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Email Sign In
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _showEmailDialog,
                    icon: const Icon(Icons.email_outlined, size: 24),
                    label: const Text('Continue with Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VesparaColors.primary,
                      disabledForegroundColor: VesparaColors.primary.withOpacity(0.5),
                      side: BorderSide(color: VesparaColors.primary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VesparaBorderRadius.button)),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'What happens in Vespara, stays in Vespara',
                    style: TextStyle(
                      fontSize: 12,
                      color: VesparaColors.secondary.withOpacity(0.7),
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
  }
}
