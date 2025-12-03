import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Indigo/Purple Theme (from Calendar)
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF8B5CF6); // Purple
  static const Color primaryDark = Color(0xFF4F46E5);

  // Accent Colors
  static const Color accent = Color(0xFF8B5CF6); // Purple
  static const Color accentLight = Color(0xFFA78BFA);
  static const Color accentDark = Color(0xFF7C3AED);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color sidebarBackground = Color(0xFF5B4FA3); // Purple sidebar
  static const Color sidebarHover = Color(0xFF6D5CAE); // Lighter Purple Hover

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9E9E9E);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF6366F1); // Indigo

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFBDBDBD);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

