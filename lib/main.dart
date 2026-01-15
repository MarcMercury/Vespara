import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// Vespara - Social Operating System
/// A luxury relationship management platform with TAGS game engine
Future<void> main() async {
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
  
  // Lock to portrait orientation (skip on web)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  // Load environment variables (skip on web)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: .env file not found, using dart-define values');
    }
  }
  
  // Configure Google Fonts
  GoogleFonts.config.allowRuntimeFetching = true;
  
  debugPrint('Vespara: Supabase URL = ${Env.supabaseUrl}');
  debugPrint('Vespara: Initializing Supabase...');
  
  // Initialize Supabase
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
  
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
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
    final router = ref.watch(routerProvider);
    debugPrint('Router created successfully');
    
    // Use simple theme to avoid Google Fonts issues
    final theme = _buildTheme();
    debugPrint('Theme created successfully');
    
    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
  
  /// Build theme without Google Fonts to avoid web issues
  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: VesparaColors.primary,
        onPrimary: VesparaColors.background,
        secondary: VesparaColors.secondary,
        onSecondary: VesparaColors.background,
        surface: VesparaColors.surface,
        onSurface: VesparaColors.primary,
        error: VesparaColors.error,
        onError: VesparaColors.background,
      ),
      scaffoldBackgroundColor: VesparaColors.background,
      canvasColor: VesparaColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: VesparaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: VesparaColors.primary,
          letterSpacing: 2,
        ),
        iconTheme: IconThemeData(color: VesparaColors.primary),
      ),
      cardTheme: CardThemeData(
        color: VesparaColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: VesparaColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VesparaColors.primary,
          foregroundColor: VesparaColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
