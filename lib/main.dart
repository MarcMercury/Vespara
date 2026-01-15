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
import 'features/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('Vespara: Starting app initialization...');
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: VesparaColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: .env file not found');
    }
  }
  
  GoogleFonts.config.allowRuntimeFetching = true;
  
  debugPrint('Vespara: Supabase URL = ${Env.supabaseUrl}');
  
  // Try to initialize Supabase but don't block the app if it fails
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    debugPrint('Vespara: Supabase initialized successfully');
  } catch (e) {
    debugPrint('Vespara: Supabase error: $e');
  }
  
  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exception}');
  };
  
  runApp(const ProviderScope(child: VesparaApp()));
}

class VesparaApp extends ConsumerWidget {
  const VesparaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('VesparaApp.build');
    
    // Always use the router - it will handle auth state
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      darkTheme: _buildTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
  
  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: VesparaColors.primary,
        onPrimary: VesparaColors.background,
        secondary: VesparaColors.secondary,
        surface: VesparaColors.surface,
        onSurface: VesparaColors.primary,
        error: VesparaColors.error,
      ),
      scaffoldBackgroundColor: VesparaColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: VesparaColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: VesparaColors.primary,
          letterSpacing: 2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VesparaColors.primary,
          foregroundColor: VesparaColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
