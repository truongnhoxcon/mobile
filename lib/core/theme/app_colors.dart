/// App Colors
/// 
/// Color palette based on DACN Mobile design (purple/pink gradient theme)

import 'package:flutter/material.dart';

/// Application Color Palette
class AppColors {
  AppColors._();

  // Primary Colors (Purple from Web SysAdmin Theme - Modern Violet)
  static const Color primary = Color(0xFF7C3AED);        // Violet 600
  static const Color primaryLight = Color(0xFF8B5CF6);   // Violet 500
  static const Color primaryDark = Color(0xFF6D28D9);    // Violet 700
  
  // Secondary Colors (Pink gradient end)
  static const Color secondary = Color(0xFFD7BDE2);      // Light pink/lavender
  static const Color secondaryLight = Color(0xFFE8DAEF); // Very light pink

  // Accent Colors
  static const Color accent = Color(0xFFFF9500);         // Orange for check-in button
  static const Color accentLight = Color(0xFFFFB347);    // Light orange
  static const Color accentGradientEnd = Color(0xFFFFD700); // Yellow/Gold

  // Status Colors
  static const Color success = Color(0xFF27AE60);        // Green
  static const Color warning = Color(0xFFF39C12);        // Orange/Amber
  static const Color error = Color(0xFFE74C3C);          // Red
  static const Color info = Color(0xFF3498DB);           // Blue

  // Chart/Stats Colors
  static const Color chartBlue = Color(0xFF5DADE2);      // Light blue for charts
  static const Color chartBlueDark = Color(0xFF2980B9);  // Dark blue for charts
  static const Color statGreen = Color(0xFF2ECC71);      // Stat badge green
  static const Color statOrange = Color(0xFFF39C12);     // Stat badge orange  
  static const Color statRed = Color(0xFFE74C3C);        // Stat badge red
  static const Color statPurple = Color(0xFF8B5CF6);     // Stat badge purple

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);     // Light gray background
  static const Color backgroundDark = Color(0xFF1A1A2E); // Dark mode background
  static const Color surface = Color(0xFFFFFFFF);        // White surface
  static const Color cardBackground = Color(0xFFFFFFFF); // White cards

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);    // Dark blue-gray
  static const Color textSecondary = Color(0xFF7F8C8D);  // Medium gray
  static const Color textHint = Color(0xFFBDC3C7);       // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // White text

  // Border Colors
  static const Color border = Color(0xFFE5E8EB);         // Light border
  static const Color borderLight = Color(0xFFF0F3F5);    // Very light border

  // Neutral Colors - Dark Mode
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B);    // Slate 800
  static const Color darkBorder = Color(0xFF334155);     // Slate 700
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400

  // Status Colors for Issues/Tasks
  static const Color statusTodo = Color(0xFF94A3B8);     // Gray
  static const Color statusInProgress = Color(0xFF3B82F6); // Blue
  static const Color statusDone = Color(0xFF22C55E);     // Green
  static const Color statusBlocked = Color(0xFFEF4444);  // Red

  // Priority Colors
  static const Color priorityLow = Color(0xFF22C55E);    // Green
  static const Color priorityMedium = Color(0xFFF59E0B); // Amber
  static const Color priorityHigh = Color(0xFFF97316);   // Orange
  static const Color priorityCritical = Color(0xFFEF4444); // Red

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)], // Violet 600 -> Violet 400
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFC4B5FD)], // Violet 600 -> Violet 300
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient checkOutGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chartGradient = LinearGradient(
    colors: [chartBlue, chartBlueDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
