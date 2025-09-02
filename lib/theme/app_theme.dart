import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color palette
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color deepGreen = Color(0xFF2E7D32);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF2E2E2E);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color cardLight = Color(0xFFFAFAFA);
  static const Color cardDark = Color(0xFF424242);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightGreen, darkGreen, deepGreen],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF81C784),
      Color(0xFF388E3C),
      Color(0xFF2E7D32),
    ],
  );

  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light(useMaterial3: true);
    return baseTheme.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF388E3C),
        brightness: Brightness.light,
      ),
      // You can add more customizations here
    );
  }

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    return baseTheme.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF81C784),
        brightness: Brightness.dark,
      ),
      // You can add more customizations here
    );
  }

  // Helper methods for gradients
  static BoxDecoration get primaryGradientDecoration => const BoxDecoration(
    gradient: primaryGradient,
  );

  static BoxDecoration get backgroundGradientDecoration => const BoxDecoration(
    gradient: backgroundGradient,
  );

  static BoxDecoration cardGradientDecoration(bool isDarkMode) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDarkMode
          ? [cardDark, Colors.grey[700]!]
          : [white, lightGray],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
