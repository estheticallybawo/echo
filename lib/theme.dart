import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class EchoColors {
  
  static const Color surface = Color(0xFFF8FBFF); // Very soft blue-white
  static const Color surfaceSecondary = Color(0xFFF0F7FF); // Light blue tint
  static const Color surfaceTertiary = Color(0xFFE8F1FF); // Slightly more blue
  
  
  static const Color textPrimary = Color(0xFF1A2332); // Dark navy
  static const Color textSecondary = Color(0xFF4A5F7F); // Medium blue-grey
  static const Color textTertiary = Color(0xFF8A9FB3); // Light blue-grey
  
  
  static const Color primary = Color(0xFF0891B2); // Professional teal
  static const Color primaryLight = Color(0xFF06B6D4); // Lighter teal
  static const Color primaryDark = Color(0xFF0D7377); // Darker teal
  
  
  static const Color secondary = Color(0xFF8B5CF6); // Soft purple
  static const Color secondaryLight = Color(0xFFA78BFA); // Lighter purple
  
  
  static const Color success = Color(0xFF10B981); // Soft emerald
  static const Color warning = Color(0xFFF59E0B); // Soft amber
  static const Color neutral = Color(0xFF6B7280); // Soft grey-blue
  
  
  static const Color switchOn = Color(0xFF00A3C4); // Bright Cyan
  static const Color switchOff = Color(0xFF334155); // Slate Gray
  
  
  static const Color glassLight = Color(0x0FFFFFFF);
}


class EchoTypography {
  
  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    height: 1.2,
  );
  
  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    height: 1.3,
  );
  
  
  static TextStyle headingLarge = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.4,
  );
  
  static TextStyle headingMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.5,
  );
  
  
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.1,
  );
  
  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.05,
  );
  
  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.03,
  );
  
  
  static TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: 1.3,
  );
  
  static TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.2,
  );
}

/// Echo Theme Data - Light Mode
ThemeData buildEchoTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: EchoColors.surface,
    
    // Primary brand color
    primaryColor: EchoColors.primary,
    
    // App Bar - Minimal, clean light
    appBarTheme: AppBarTheme(
      backgroundColor: EchoColors.surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: EchoTypography.headingLarge.copyWith(
        color: EchoColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: EchoColors.primary),
    ),
    
    // Cards - Rounded with soft glass effect
    cardTheme: CardThemeData(
      color: EchoColors.surfaceSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Input Decoration - Clean, minimal, light
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: EchoColors.surfaceSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(
          color: Color(0xFF00A3C4),
          width: 1.5,
        ),
      ),
      hintStyle: EchoTypography.bodyMedium.copyWith(
        color: EchoColors.textTertiary,
      ),
      labelStyle: EchoTypography.bodyMedium.copyWith(
        color: EchoColors.textSecondary,
      ),
    ),
    
    // Button Styles - Cyan primary
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: EchoColors.primary,
        foregroundColor: EchoColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: EchoTypography.labelLarge.copyWith(
          color: EchoColors.surface,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: EchoColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: EchoTypography.labelLarge,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: EchoColors.primary,
        side: const BorderSide(color: EchoColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: EchoTypography.labelLarge,
      ),
    ),
    
    // Text Theme - Light mode text colors
    textTheme: TextTheme(
      displayLarge: EchoTypography.displayLarge.copyWith(
        color: EchoColors.textPrimary,
      ),
      displayMedium: EchoTypography.displayMedium.copyWith(
        color: EchoColors.textPrimary,
      ),
      headlineSmall: EchoTypography.headingLarge.copyWith(
        color: EchoColors.textPrimary,
      ),
      titleLarge: EchoTypography.headingMedium.copyWith(
        color: EchoColors.textPrimary,
      ),
      bodyLarge: EchoTypography.bodyLarge.copyWith(
        color: EchoColors.textPrimary,
      ),
      bodyMedium: EchoTypography.bodyMedium.copyWith(
        color: EchoColors.textSecondary,
      ),
      bodySmall: EchoTypography.bodySmall.copyWith(
        color: EchoColors.textTertiary,
      ),
      labelLarge: EchoTypography.labelLarge.copyWith(
        color: EchoColors.surface,
      ),
    ),
    
    // Bottom Navigation - Minimal icons
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: EchoColors.surfaceSecondary,
      selectedItemColor: EchoColors.primary,
      unselectedItemColor: EchoColors.textTertiary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    
    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: EchoColors.primary,
      foregroundColor: EchoColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

/// Holographic Gradient for mesh backgrounds
LinearGradient buildHolographicGradient({
  double angle = 45,
}) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: const [
      Color(0x0A00D4FF), // Cyan - very subtle
      Color(0x056B5BFF), // Purple - minimal
      Color(0x0A00D4FF), // Back to cyan
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// Glassmorphism Container
BoxDecoration buildGlassmorphism({
  Color baseColor = EchoColors.surfaceSecondary,
  double blur = 10,
  double opacity = 0.1,
}) {
  return BoxDecoration(
    color: baseColor.withOpacity(0.5),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: EchoColors.textPrimary.withOpacity(0.08),
      width: 1,
    ),
    // Note: BackdropFilter needs to be applied separately in parent widget
  );
}
