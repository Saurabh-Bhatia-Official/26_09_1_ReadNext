import 'package:flutter/material.dart';

enum AppThemeMode {
  corporate,
  dark,
  light,
  sepia,
  system,
}

class AppTheme {
  // Corporate Executive Theme (Default)
  static ThemeData get corporateTheme {
    const primarySeed = Color(0xFF1E40AF); // Enterprise Royal Blue
    const primaryColor = Color(0xFF2563EB); // Corporate Cobalt
    const surfaceColor = Color(0xFF0F172A); // Executive Slate / Navy Surface
    const canvasBg = Color(0xFF090E17); // Corporate Midnight Slate Canvas
    const cardBg = Color(0xFF131F37); // Refined Slate Navy Card
    const borderColor = Color(0xFF1E2E4A); // Corporate Navy Border
    const mutedTextColor = Color(0xFF94A3B8); // Slate 400
    const lightTextColor = Color(0xFFF8FAFC); // Slate 50

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeed,
        brightness: Brightness.dark,
        surface: surfaceColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: const Color(0xFF0284C7),
        onSecondary: Colors.white,
        surfaceContainer: cardBg,
        surfaceContainerHigh: const Color(0xFF192845),
        surfaceContainerHighest: const Color(0xFF1F3255),
        outline: borderColor,
        outlineVariant: const Color(0xFF17243B),
      ),
      scaffoldBackgroundColor: canvasBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: lightTextColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: Color(0xFFCBD5E1)),
        titleTextStyle: TextStyle(
          color: lightTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFF0F172A),
        selectedIconTheme: IconThemeData(color: Color(0xFF60A5FA)),
        unselectedIconTheme: IconThemeData(color: Color(0xFF94A3B8)),
        selectedLabelTextStyle: TextStyle(
          color: Color(0xFF93C5FD),
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
        ),
        indicatorColor: Color(0xFF1E3A8A),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF93C5FD),
          side: const BorderSide(color: Color(0xFF2B4268)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B1324),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: Border.all(color: const Color(0xFF334155)),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightTextColor, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: lightTextColor, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: lightTextColor, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: lightTextColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: lightTextColor, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: lightTextColor, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: lightTextColor, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: lightTextColor, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: lightTextColor, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Color(0xFFE2E8F0)),
        bodyMedium: TextStyle(color: Color(0xFFCBD5E1)),
        bodySmall: TextStyle(color: mutedTextColor),
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    const primaryColor = Color(0xFF0D47A1);
    const surfaceColor = Color(0xFFF8FAFC);
    const canvasBg = Color(0xFFE2E8F0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: canvasBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    const primaryColor = Color(0xFF60A5FA);
    const surfaceColor = Color(0xFF1E293B);
    const canvasBg = Color(0xFF0F172A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: canvasBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF475569),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // Sepia / Eye-Care Theme
  static ThemeData get sepiaTheme {
    const primaryColor = Color(0xFF8B5E3C);
    const surfaceColor = Color(0xFFF5EBE1);
    const canvasBg = Color(0xFFEADBCE);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: canvasBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5EBE1),
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: Color(0xFF4A3728)),
        titleTextStyle: TextStyle(
          color: Color(0xFF38291F),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFF5EBE1),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFDCC8B3)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFDCC8B3),
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF4A3728),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: Color(0xFFF5EBE1), fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
