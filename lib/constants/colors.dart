// colors.dart - Create this file to centralize GrandLine color constants

import 'package:flutter/material.dart';

class GrandLineColors {
  // Primary GrandLine Colors
  static const Color primaryGold = Color(0xFFD4AF37);      // Rich Gold
  static const Color brightGold = Color(0xFFFFD700);       // Bright Gold
  static const Color darkGold = Color(0xFFB8860B);         // Dark Goldenrod
  static const Color lightGold = Color(0xFFDAA520);        // Goldenrod

  // Background Colors
  static const Color background = Color(0xFF0A0A0B);       // Deep black
  static const Color surface = Color(0xFF1A1A1D);          // Dark gray
  static const Color card = Color(0xFF232327);             // Lighter dark gray

  // Text Colors
  static const Color textPrimary = Color(0xFFE8E8E8);      // Light gray text
  static const Color textSecondary = Color(0xFF9E9E9E);    // Muted text

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGold, brightGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background, surface, background],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      card,
      surface,
    ],
  );

  // Helper methods for opacity variations
  static Color primaryWithOpacity(double opacity) => primaryGold.withOpacity(opacity);
  static Color brightGoldWithOpacity(double opacity) => brightGold.withOpacity(opacity);
  static Color textPrimaryWithOpacity(double opacity) => textPrimary.withOpacity(opacity);
  static Color textSecondaryWithOpacity(double opacity) => textSecondary.withOpacity(opacity);

  // Box Shadow definitions
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primaryGold.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
}

// Extension for quick color access
extension GrandLineColorExtension on BuildContext {
  GrandLineColors get colors => GrandLineColors();
}

/*
USAGE EXAMPLES:

// In any screen, replace old orange colors with new gold colors:

OLD CODE:
const Color(0xFFFF6B35)

NEW CODE:
GrandLineColors.primaryGold

// For gradients:
Container(
  decoration: BoxDecoration(
    gradient: GrandLineColors.primaryGradient,
  ),
)

// For shadows:
Container(
  decoration: BoxDecoration(
    boxShadow: GrandLineColors.primaryShadow,
  ),
)

// Global replacements needed across all screens:
// 1. Color(0xFFFF6B35) → GrandLineColors.primaryGold
// 2. Color(0xFFFF8E53) → GrandLineColors.brightGold
// 3. Icons.auto_stories_rounded → Icons.explore_rounded (compass)
// 4. 'Grand Line' → 'GrandLine'
// 5. Update all progress indicators, buttons, and accent elements

// Key screens to update:
// ✅ main.dart (done)
// ✅ home_screen.dart (done)
// ✅ login_screen.dart (done)
// ✅ register_screen.dart (done)
// - profile_screen.dart
// - series_list_screen.dart
// - comics_list_screen.dart
// - favorites_screen.dart
// - image_reader_screen.dart
*/