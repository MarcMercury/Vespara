import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// Vespara - Social Operating System
/// A luxury relationship management platform with TAGS game engine
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('Vespara: Starting app initialization...');
  
  // Set system UI overlay style for luxury dark aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: VesparaColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Lock to portrait orientation for optimal Bento Grid experience
  // Skip on web as it's not supported
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  // Load environment variables (skip on web if using --dart-define)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: .env file not found, using dart-define values');
    }
  }
  
  // Configure Google Fonts for web - use system fonts as fallback
  GoogleFonts.config.allowRuntimeFetching = true;
  
  debugPrint('Vespara: Supabase URL = ${Env.supabaseUrl}');
  debugPrint('Vespara: Initializing Supabase...');
  
  // Initialize Supabase with configuration
  bool supabaseInitialized = false;
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    supabaseInitialized = true;
    debugPrint('Vespara: Supabase initialized successfully');
  } catch (e) {
    debugPrint('Vespara: Supabase initialization error: $e');
  }
  
  debugPrint('Vespara: Running app...');
  
  // Set up error handling for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Run the application wrapped in ProviderScope
  runApp(
    ProviderScope(
      child: VesparaApp(supabaseReady: supabaseInitialized),
    ),
  );
}

/// The root Vespara application widget
class VesparaApp extends ConsumerWidget {
  final bool supabaseReady;
  
  const VesparaApp({super.key, required this.supabaseReady});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('VesparaApp.build called, supabaseReady: $supabaseReady');
    
    // MINIMAL TEST: Skip everything and just show basic UI
    return MaterialApp(
      title: 'Vespara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1523),
      ),
      home: const _MinimalLoginScreen(),
    );
  }
}

/// Super minimal login screen to test basic rendering
class _MinimalLoginScreen extends StatelessWidget {
  const _MinimalLoginScreen();
  
  @override
  Widget build(BuildContext context) {
    debugPrint('MinimalLoginScreen.build');
    return Scaffold(
      backgroundColor: const Color(0xFF1A1523),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple moon
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE0D8EA),
              ),
            ),
            const SizedBox(height: 40),
            // Text
            const Text(
              'VESPARA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE0D8EA),
                letterSpacing: 10,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF9A8EB5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
