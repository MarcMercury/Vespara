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
  
  // Allow Google Fonts to use HTTP on web (handles CORS gracefully)
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
    
    // If Supabase didn't initialize, show error
    if (!supabaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: VesparaColors.background,
        ),
        home: const Scaffold(
          backgroundColor: VesparaColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'VESPARA',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    color: VesparaColors.primary,
                    letterSpacing: 12,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Unable to connect to server',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Get router
    GoRouter router;
    try {
      router = ref.watch(routerProvider);
      debugPrint('Router created successfully');
    } catch (e, stack) {
      debugPrint('Router error: $e');
      debugPrint('Stack: $stack');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: VesparaColors.background,
        ),
        home: Scaffold(
          backgroundColor: VesparaColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'VESPARA',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    color: VesparaColors.primary,
                    letterSpacing: 12,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Router Error: $e',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Get theme with fallback
    ThemeData theme;
    try {
      theme = VesparaTheme.dark;
      debugPrint('Theme created successfully');
    } catch (e, stack) {
      debugPrint('Theme error: $e');
      debugPrint('Stack: $stack');
      theme = ThemeData.dark().copyWith(
        scaffoldBackgroundColor: VesparaColors.background,
        colorScheme: const ColorScheme.dark(
          primary: VesparaColors.primary,
          surface: VesparaColors.surface,
        ),
      );
    }
    
    debugPrint('Returning MaterialApp.router');
    
    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
