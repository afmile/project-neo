/// Project Neo - High-Tech Minimalista Theme
///
/// A solid, OLED-friendly dark theme inspired by Discord and Telegram.
/// Supports dynamic community accent colors.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Core color palette - High-Tech Minimalista
class NeoColors {
  NeoColors._();
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BASE COLORS (OLED Optimized)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Pure black background (OLED)
  static const Color background = Color(0xFF000000);
  
  /// Slightly lifted surface
  static const Color surface = Color(0xFF0D0D0D);
  
  /// Lighter surface for elevated elements
  static const Color surfaceLight = Color(0xFF1A1A1A);
  
  /// Card/Bento cell background
  static const Color card = Color(0xFF141414);
  
  /// Elevated elements
  static const Color elevated = Color(0xFF1A1A1A);
  
  /// Thin borders (0.5-1px)
  static const Color border = Color(0xFF1F1F1F);
  
  /// Input field background
  static const Color inputFill = Color(0xFF0A0A0A);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Primary text - white high legibility
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Secondary text - gray
  static const Color textSecondary = Color(0xFFA0A0A0);
  
  /// Tertiary/muted text
  static const Color textTertiary = Color(0xFF666666);
  
  /// Disabled text
  static const Color textDisabled = Color(0xFF404040);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT ACCENT (Discord-like blue)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Default accent color
  static const Color accent = Color(0xFF5865F2);
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Success - green
  static const Color success = Color(0xFF3BA55C);
  
  /// Warning - yellow
  static const Color warning = Color(0xFFFAA61A);
  
  /// Error - red
  static const Color error = Color(0xFFED4245);
  
  /// Info - blue
  static const Color info = Color(0xFF5865F2);
  
  /// Online/Active status
  static const Color online = Color(0xFF3BA55C);
  
  /// Streaming status
  static const Color streaming = Color(0xFF593695);
}

/// Spacing constants
class NeoSpacing {
  NeoSpacing._();
  
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  
  /// Card border radius
  static const double cardRadius = 12;
  
  /// Button border radius
  static const double buttonRadius = 8;
  
  /// Input border radius
  static const double inputRadius = 8;
  
  /// Small elements radius
  static const double smallRadius = 6;
  
  /// Border width
  static const double borderWidth = 0.5;
}

/// High-Tech Minimalista Text Styles using Inter font
class NeoTextStyles {
  NeoTextStyles._();
  
  static TextStyle get _baseStyle => GoogleFonts.poppins(
    color: NeoColors.textPrimary,
  );
  
  // Display
  static TextStyle get displayLarge => _baseStyle.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1.2,
  );
  
  static TextStyle get displayMedium => _baseStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static TextStyle get displaySmall => _baseStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  // Headlines
  static TextStyle get headlineLarge => _baseStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle get headlineMedium => _baseStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle get headlineSmall => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Body
  static TextStyle get bodyLarge => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: NeoColors.textSecondary,
    height: 1.5,
  );
  
  static TextStyle get bodySmall => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: NeoColors.textTertiary,
    height: 1.5,
  );
  
  // Labels
  static TextStyle get labelLarge => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  
  static TextStyle get labelMedium => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: NeoColors.textSecondary,
    letterSpacing: 0.3,
  );
  
  static TextStyle get labelSmall => _baseStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: NeoColors.textTertiary,
    letterSpacing: 0.3,
  );
  
  // Button
  static TextStyle get button => _baseStyle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}

/// Main theme builder with dynamic accent support
class NeoTheme {
  NeoTheme._();
  
  /// Build dark theme with optional custom accent color
  static ThemeData darkTheme({Color accentColor = NeoColors.accent}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NeoColors.background,
      
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: NeoColors.surface,
        error: NeoColors.error,
        onPrimary: NeoColors.textPrimary,
        onSecondary: NeoColors.textPrimary,
        onSurface: NeoColors.textPrimary,
        onError: NeoColors.textPrimary,
      ),
      
      textTheme: TextTheme(
        displayLarge: NeoTextStyles.displayLarge,
        displayMedium: NeoTextStyles.displayMedium,
        displaySmall: NeoTextStyles.displaySmall,
        headlineLarge: NeoTextStyles.headlineLarge,
        headlineMedium: NeoTextStyles.headlineMedium,
        headlineSmall: NeoTextStyles.headlineSmall,
        bodyLarge: NeoTextStyles.bodyLarge,
        bodyMedium: NeoTextStyles.bodyMedium,
        bodySmall: NeoTextStyles.bodySmall,
        labelLarge: NeoTextStyles.labelLarge,
        labelMedium: NeoTextStyles.labelMedium,
        labelSmall: NeoTextStyles.labelSmall,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: NeoColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: NeoTextStyles.headlineMedium,
        iconTheme: const IconThemeData(color: NeoColors.textPrimary),
      ),
      
      cardTheme: CardThemeData(
        color: NeoColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoSpacing.cardRadius),
          side: const BorderSide(
            color: NeoColors.border,
            width: NeoSpacing.borderWidth,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeoColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoSpacing.inputRadius),
          borderSide: const BorderSide(color: NeoColors.border, width: NeoSpacing.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoSpacing.inputRadius),
          borderSide: const BorderSide(color: NeoColors.border, width: NeoSpacing.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoSpacing.inputRadius),
          borderSide: BorderSide(color: accentColor, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeoSpacing.inputRadius),
          borderSide: const BorderSide(color: NeoColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NeoSpacing.md,
          vertical: 14,
        ),
        hintStyle: NeoTextStyles.bodyMedium.copyWith(
          color: NeoColors.textTertiary,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: NeoColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: NeoSpacing.lg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoSpacing.buttonRadius),
          ),
          textStyle: NeoTextStyles.button,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NeoColors.textPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: NeoSpacing.lg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeoSpacing.buttonRadius),
          ),
          side: const BorderSide(color: NeoColors.border, width: NeoSpacing.borderWidth),
          textStyle: NeoTextStyles.button,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: NeoTextStyles.button,
        ),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: NeoColors.surface,
        selectedItemColor: NeoColors.textPrimary,
        unselectedItemColor: NeoColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NeoColors.card,
        contentTextStyle: NeoTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoSpacing.smallRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: NeoColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoSpacing.cardRadius),
          side: const BorderSide(color: NeoColors.border, width: NeoSpacing.borderWidth),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: NeoColors.border,
        thickness: NeoSpacing.borderWidth,
      ),
      
      // Page transitions for hierarchical navigation
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(), // Material 3 style - zoom from center
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(), // Native iOS slide
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: NeoColors.border,
      ),
    );
  }
}
