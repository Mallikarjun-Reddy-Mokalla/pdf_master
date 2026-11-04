import 'package:flutter/material.dart';

/// App color palette adhering to professional blue, clean white and subtle gray scheme.
class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF1E56A0); // Professional deep blue
  static const Color primaryLight = Color(0xFFE8F1FC);
  static const Color primaryDark = Color(0xFF0F366A);
  static const Color accent = Color(0xFF007BFF);
  static const Color secondary = Color(0xFF2C3E50);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Colors.white;
  static const Color cardBorder = Color(0xFFE5E9F0);

  // Neutral Colors
  static const Color textPrimary = Color(0xFF1A2130);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFEDF2F7);

  // Functional Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Accent Badges & Tool categories
  static const Color orangeBadge = Color(0xFFFF7A00);
  static const Color purpleBadge = Color(0xFF8B5CF6);
  static const Color tealBadge = Color(0xFF14B8A6);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E56A0), Color(0xFF007BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient proGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

