import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors from PRD
  static const Color incomeColor = Color(0xFF10B981); // Emerald green
  static const Color expenseColor = Color(0xFFEF4444); // Coral red
  static const Color primaryBackground = Colors.white;
  static const Color secondaryBackground = Color(0xFFF9FAFB);
  static const Color primaryText = Color(0xFF1F2937); // Gray 800
  static const Color secondaryText = Color(0xFF6B7280); // Gray 500

  // Additional colors
  static const Color accentColor = Color(0xFF3B82F6); // Blue
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color successColor = Color(0xFF10B981); // Same as income
  static const Color errorColor = Color(0xFFEF4444); // Same as expense

  // Card and container styling
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double inputBorderRadius = 8.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Typography
  static const String fontFamilyTitles = 'Inter';
  static const String fontFamilyContent = 'SF Pro';

  static TextStyle get titleLarge => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryText,
    fontFamily: fontFamilyTitles,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryText,
    fontFamily: fontFamilyTitles,
  );

  static TextStyle get titleSmall => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: primaryText,
    fontFamily: fontFamilyTitles,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: primaryText,
    fontFamily: fontFamilyContent,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryText,
    fontFamily: fontFamilyContent,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: secondaryText,
    fontFamily: fontFamilyContent,
  );

  static TextStyle get labelLarge => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryText,
    fontFamily: fontFamilyContent,
  );

  static TextStyle get labelMedium => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: secondaryText,
    fontFamily: fontFamilyContent,
  );

  // Card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: primaryBackground,
    borderRadius: BorderRadius.circular(cardBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Button styling
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );

  static ButtonStyle get incomeButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: incomeColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );

  static ButtonStyle get expenseButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: expenseColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );

  // Input decoration
  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: secondaryBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputBorderRadius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputBorderRadius),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputBorderRadius),
      borderSide: const BorderSide(color: accentColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  // App theme
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentColor,
      primary: accentColor,
      secondary: incomeColor,
      error: errorColor,
      surface: primaryBackground,
    ),
    scaffoldBackgroundColor: secondaryBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: titleMedium,
      iconTheme: const IconThemeData(color: primaryText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputBorderRadius),
      ),
      filled: true,
      fillColor: secondaryBackground,
    ),
    textTheme: TextTheme(
      headlineLarge: titleLarge,
      headlineMedium: titleMedium,
      headlineSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
    ),
  );

  // Aliases used by some views
  static const Color primaryColor = accentColor;
  static const Color secondaryColor = incomeColor;
  static const Color textPrimary = primaryText;
  static const Color textSecondary = secondaryText;
}
