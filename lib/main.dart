import 'package:flutter/material.dart';

void main() {
  runApp(const VesparaApp());
}

class VesparaApp extends StatelessWidget {
  const VesparaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vespara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  
  static const _background = Color(0xFF1A1523);
  static const _primary = Color(0xFFE0D8EA);
  static const _muted = Color(0xFF9A8EB5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary,
                ),
              ),
              
              const SizedBox(height: 48),
              
              const Text(
                'VESPARA',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w500,
                  color: _primary,
                  letterSpacing: 12,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Social Operating System',
                style: TextStyle(
                  fontSize: 14,
                  color: _muted,
                  letterSpacing: 2,
                ),
              ),
              
              const Spacer(flex: 2),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: _background,
                  ),
                  child: const Text('Continue with Apple'),
                ),
              ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                  ),
                  child: const Text('Continue with Google'),
                ),
              ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                  ),
                  child: const Text('Continue with Email'),
                ),
              ),
              
              const Spacer(),
              
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  'By continuing, you agree to our Terms',
                  style: TextStyle(fontSize: 12, color: _muted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
