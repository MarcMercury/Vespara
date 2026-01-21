import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Vespara Night Design System
/// A Celestial Luxury aesthetic - mysterious, expensive, high-contrast with soft glassmorphism
class VesparaColors {
  VesparaColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // THE VESPARA NIGHT PALETTE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Background - "The Void" - Deep Grape/Slate
  static const Color background = Color(0xFF1A1523);
  
  /// Surface - "The Tile" - Lighter Plum for cards
  static const Color surface = Color(0xFF2D2638);
  
  /// Elevated Surface - For modals and overlays
  static const Color surfaceElevated = Color(0xFF362F42);
  
  /// Primary Accent - "Starlight" - Pale Lavender/Silver
  static const Color primary = Color(0xFFE0D8EA);
  
  /// Secondary Accent - "Moonlight" - Muted Purple
  static const Color secondary = Color(0xFF9D85B1);
  
  /// Functional Glow - Glassmorphism effects
  static const Color glow = Color(0xFFBFA6D8);
  static const Color glowWithOpacity = Color(0x33BFA6D8); // 20% opacity
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TAGS CONSENT METER COLORS - Game Ratings
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// 🟢 GREEN - Social & Flirtatious
  static const Color tagsGreen = Color(0xFF4CAF50);
  
  /// 🟡 YELLOW - Sensual & Suggestive  
  static const Color tagsYellow = Color(0xFFFFC107);
  
  /// 🔴 RED - Erotic & Explicit
  static const Color tagsRed = Color(0xFFD32F2F);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Border color - White at 10% opacity
  static const Color border = Color(0x1AFFFFFF);
  
  /// Inactive state
  static const Color inactive = Color(0xFF6B5F7A);
  
  /// Error state
  static const Color error = Color(0xFFCF6679);
  
  /// Success state
  static const Color success = Color(0xFF4CAF50);
  
  /// Warning state
  static const Color warning = Color(0xFFFFC107);
  
  /// Shimmer base
  static const Color shimmerBase = Color(0xFF2D2638);
  
  /// Shimmer highlight
  static const Color shimmerHighlight = Color(0xFF3D3548);
}

/// Vespara Border Radius Constants
class VesparaBorderRadius {
  VesparaBorderRadius._();
  
  /// Bento Tiles - Soft, organic
  static const double tile = 24.0;
  
  /// Cards
  static const double card = 20.0;
  
  /// Buttons
  static const double button = 16.0;
  
  /// Small elements
  static const double small = 12.0;
  
  /// Chips and tags
  static const double chip = 8.0;
  
  /// Full circular
  static const double circular = 100.0;
}

/// Vespara Spacing Constants
class VesparaSpacing {
  VesparaSpacing._();
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Vespara Elevation & Shadows
class VesparaElevation {
  VesparaElevation._();
  
  /// Glow shadow for interactive elements
  static List<BoxShadow> get glow => [
    BoxShadow(
      color: VesparaColors.glow.withOpacity(0.2),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];
  
  /// Subtle elevation shadow
  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Card shadow
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
}

/// Glassmorphism Decoration Factory
class VesparaGlass {
  VesparaGlass._();
  
  /// Standard glassmorphism decoration
  static BoxDecoration get standard => BoxDecoration(
    color: VesparaColors.surface.withOpacity(0.7),
    borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
    border: Border.all(
      color: VesparaColors.border,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: VesparaColors.glow.withOpacity(0.1),
        blurRadius: 20,
        spreadRadius: 0,
      ),
    ],
  );
  
  /// Elevated glassmorphism for modals
  static BoxDecoration get elevated => BoxDecoration(
    color: VesparaColors.surfaceElevated.withOpacity(0.9),
    borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
    border: Border.all(
      color: VesparaColors.border,
      width: 1,
    ),
    boxShadow: VesparaElevation.glow,
  );
  
  /// Tile decoration for Bento Grid
  static BoxDecoration get tile => BoxDecoration(
    color: VesparaColors.surface,
    borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
    border: Border.all(
      color: VesparaColors.border,
      width: 1,
    ),
  );
  
  /// TAGS Game Card decoration - obsidian tablet look
  static BoxDecoration get tagsCard => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        VesparaColors.surface,
        VesparaColors.background,
      ],
    ),
    borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
    border: Border.all(
      color: VesparaColors.glow.withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: VesparaColors.glow.withOpacity(0.15),
        blurRadius: 25,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

/// The Vespara Theme
class VesparaTheme {
  VesparaTheme._();
  
  /// Light theme (not used - Vespara is always dark)
  static ThemeData get light => dark;
  
  /// The Celestial Luxury Dark Theme
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // ═══════════════════════════════════════════════════════════════════════
      // COLOR SCHEME
      // ═══════════════════════════════════════════════════════════════════════
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
      
      // ═══════════════════════════════════════════════════════════════════════
      // SCAFFOLD & BACKGROUND
      // ═══════════════════════════════════════════════════════════════════════
      scaffoldBackgroundColor: VesparaColors.background,
      canvasColor: VesparaColors.background,
      
      // ═══════════════════════════════════════════════════════════════════════
      // TYPOGRAPHY - Cinzel for Headers, Inter for Body
      // ═══════════════════════════════════════════════════════════════════════
      textTheme: _buildTextTheme(),
      
      // ═══════════════════════════════════════════════════════════════════════
      // APP BAR
      // ═══════════════════════════════════════════════════════════════════════
      appBarTheme: AppBarTheme(
        backgroundColor: VesparaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: VesparaColors.primary,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(
          color: VesparaColors.primary,
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // CARD THEME
      // ═══════════════════════════════════════════════════════════════════════
      cardTheme: CardThemeData(
        color: VesparaColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
          side: const BorderSide(
            color: VesparaColors.border,
            width: 1,
          ),
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // ELEVATED BUTTON
      // ═══════════════════════════════════════════════════════════════════════
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VesparaColors.primary,
          foregroundColor: VesparaColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: VesparaSpacing.lg,
            vertical: VesparaSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VesparaBorderRadius.button),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // OUTLINED BUTTON
      // ═══════════════════════════════════════════════════════════════════════
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VesparaColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: VesparaSpacing.lg,
            vertical: VesparaSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VesparaBorderRadius.button),
          ),
          side: const BorderSide(
            color: VesparaColors.primary,
            width: 1,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // TEXT BUTTON
      // ═══════════════════════════════════════════════════════════════════════
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VesparaColors.secondary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // INPUT DECORATION
      // ═══════════════════════════════════════════════════════════════════════
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VesparaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VesparaSpacing.md,
          vertical: VesparaSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VesparaBorderRadius.button),
          borderSide: const BorderSide(
            color: VesparaColors.border,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VesparaBorderRadius.button),
          borderSide: const BorderSide(
            color: VesparaColors.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VesparaBorderRadius.button),
          borderSide: const BorderSide(
            color: VesparaColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VesparaBorderRadius.button),
          borderSide: const BorderSide(
            color: VesparaColors.error,
            width: 1,
          ),
        ),
        hintStyle: GoogleFonts.inter(
          color: VesparaColors.inactive,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: VesparaColors.secondary,
          fontSize: 14,
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // BOTTOM NAVIGATION BAR
      // ═══════════════════════════════════════════════════════════════════════
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: VesparaColors.surface,
        selectedItemColor: VesparaColors.primary,
        unselectedItemColor: VesparaColors.inactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // FLOATING ACTION BUTTON
      // ═══════════════════════════════════════════════════════════════════════
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: VesparaColors.primary,
        foregroundColor: VesparaColors.background,
        elevation: 8,
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // SLIDER (for Consent Meter)
      // ═══════════════════════════════════════════════════════════════════════
      sliderTheme: SliderThemeData(
        activeTrackColor: VesparaColors.primary,
        inactiveTrackColor: VesparaColors.inactive,
        thumbColor: VesparaColors.primary,
        overlayColor: VesparaColors.glow.withOpacity(0.2),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 12,
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // SWITCH
      // ═══════════════════════════════════════════════════════════════════════
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return VesparaColors.primary;
          }
          return VesparaColors.inactive;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return VesparaColors.glow.withOpacity(0.5);
          }
          return VesparaColors.surface;
        }),
        trackOutlineColor: WidgetStateProperty.all(VesparaColors.border),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // DIALOG
      // ═══════════════════════════════════════════════════════════════════════
      dialogTheme: DialogThemeData(
        backgroundColor: VesparaColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
        ),
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: VesparaColors.primary,
          letterSpacing: 1.5,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: VesparaColors.secondary,
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // BOTTOM SHEET
      // ═══════════════════════════════════════════════════════════════════════
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(VesparaBorderRadius.tile),
          ),
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // SNACKBAR
      // ═══════════════════════════════════════════════════════════════════════
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VesparaColors.surfaceElevated,
        contentTextStyle: GoogleFonts.inter(
          color: VesparaColors.primary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VesparaBorderRadius.small),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // CHIP
      // ═══════════════════════════════════════════════════════════════════════
      chipTheme: ChipThemeData(
        backgroundColor: VesparaColors.surface,
        selectedColor: VesparaColors.primary,
        disabledColor: VesparaColors.inactive,
        labelStyle: GoogleFonts.inter(
          color: VesparaColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(
          color: VesparaColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VesparaBorderRadius.chip),
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // DIVIDER
      // ═══════════════════════════════════════════════════════════════════════
      dividerTheme: const DividerThemeData(
        color: VesparaColors.border,
        thickness: 1,
        space: VesparaSpacing.md,
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // ICON
      // ═══════════════════════════════════════════════════════════════════════
      iconTheme: const IconThemeData(
        color: VesparaColors.primary,
        size: 24,
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // PROGRESS INDICATOR
      // ═══════════════════════════════════════════════════════════════════════
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: VesparaColors.primary,
        linearTrackColor: VesparaColors.surface,
        circularTrackColor: VesparaColors.surface,
      ),
    );
  }
  
  /// Build the text theme with Cinzel headers and Inter body
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // ═══════════════════════════════════════════════════════════════════════
      // DISPLAY STYLES - Large promotional text
      // ═══════════════════════════════════════════════════════════════════════
      displayLarge: GoogleFonts.cinzel(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: VesparaColors.primary,
        letterSpacing: 2,
      ),
      displayMedium: GoogleFonts.cinzel(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        color: VesparaColors.primary,
        letterSpacing: 1.8,
      ),
      displaySmall: GoogleFonts.cinzel(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: VesparaColors.primary,
        letterSpacing: 1.5,
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // HEADLINE STYLES - Section headers
      // ═══════════════════════════════════════════════════════════════════════
      headlineLarge: GoogleFonts.cinzel(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: VesparaColors.primary,
        letterSpacing: 1.5,
      ),
      headlineMedium: GoogleFonts.cinzel(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: VesparaColors.primary,
        letterSpacing: 1.2,
      ),
      headlineSmall: GoogleFonts.cinzel(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: VesparaColors.primary,
        letterSpacing: 1.2,
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // TITLE STYLES - Tile labels (Uppercase)
      // ═══════════════════════════════════════════════════════════════════════
      titleLarge: GoogleFonts.cinzel(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: VesparaColors.primary,
        letterSpacing: 1.5,
      ),
      titleMedium: GoogleFonts.cinzel(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: VesparaColors.primary,
        letterSpacing: 1.2,
      ),
      titleSmall: GoogleFonts.cinzel(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: VesparaColors.secondary,
        letterSpacing: 1.2,
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // BODY STYLES - Content text
      // ═══════════════════════════════════════════════════════════════════════
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: VesparaColors.primary,
        letterSpacing: 0.15,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: VesparaColors.secondary,
        letterSpacing: 0.1,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: VesparaColors.inactive,
        letterSpacing: 0.1,
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // LABEL STYLES - Buttons, chips, etc.
      // ═══════════════════════════════════════════════════════════════════════
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: VesparaColors.primary,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: VesparaColors.secondary,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: VesparaColors.inactive,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Extension for convenient access to Vespara text styles
extension VesparaTextStyles on TextTheme {
  /// Tile label style - uppercase, elegant
  TextStyle get tileLabel => GoogleFonts.cinzel(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: VesparaColors.primary,
    letterSpacing: 2,
  );
  
  /// Metric value style - large, bold numbers
  TextStyle get metricValue => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: VesparaColors.primary,
  );
  
  /// Subtitle style - muted
  TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: VesparaColors.secondary,
    letterSpacing: 0.5,
  );
}

/// Backward compatibility alias for legacy code using AppTheme
/// Maps old AppTheme.* references to new Vespara design system
class AppTheme {
  AppTheme._();
  
  // Colors
  static const Color backgroundDark = VesparaColors.background;
  static const Color surfaceDark = VesparaColors.surface;
  
  // Text Styles - Static versions for legacy code
  static TextStyle get displayLarge => GoogleFonts.cinzel(
    fontSize: 48,
    fontWeight: FontWeight.w600,
    color: VesparaColors.primary,
  );
  
  static TextStyle get headlineLarge => GoogleFonts.cinzel(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: VesparaColors.primary,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.cinzel(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: VesparaColors.primary,
  );
  
  static TextStyle get headlineSmall => GoogleFonts.cinzel(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VesparaColors.primary,
  );
  
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: VesparaColors.primary,
  );
  
  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VesparaColors.primary,
  );
  
  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: VesparaColors.primary,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: VesparaColors.primary,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: VesparaColors.primary,
  );
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: VesparaColors.primary,
  );
  
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: VesparaColors.primary,
  );
  
  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: VesparaColors.primary,
  );
  
  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: VesparaColors.primary,
  );
}
