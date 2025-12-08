/// App Colors
/// 
/// Defines the color palette for the application.
/// Based on a modern enterprise design system.

import 'package:flutter/material.dart';

/// Application Color Palette
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF2563EB);       // Blue 600
  static const Color primaryLight = Color(0xFF60A5FA);  // Blue 400
  static const Color primaryDark = Color(0xFF1D4ED8);   // Blue 700

  // Secondary Colors
  static const Color secondary = Color(0xFF7C3AED);     // Violet 600
  static const Color secondaryLight = Color(0xFFA78BFA); // Violet 400

  // Accent Colors
  static const Color accent = Color(0xFF06B6D4);        // Cyan 500
  static const Color success = Color(0xFF22C55E);       // Green 500
  static const Color warning = Color(0xFFF59E0B);       // Amber 500
  static const Color error = Color(0xFFEF4444);         // Red 500
  static const Color info = Color(0xFF3B82F6);          // Blue 500

  // Neutral Colors - Light Mode
  static const Color background = Color(0xFFF8FAFC);    // Slate 50
  static const Color surface = Color(0xFFFFFFFF);       // White
  static const Color border = Color(0xFFE2E8F0);        // Slate 200
  static const Color textPrimary = Color(0xFF0F172A);   // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8);      // Slate 400

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

  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
