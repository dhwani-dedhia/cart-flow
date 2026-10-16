import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color primaryContainer = Color(0xFFEEF2FF); // Indigo 50

  // Secondary / Accent
  static const Color secondary = Color(0xFF0D9488); // Teal 600
  static const Color secondaryContainer = Color(0xFFCCFBF1); // Teal 100

  // Semantic
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Offline / Sync indicator
  static const Color offline = Color(0xFFEA580C); // Orange 600
  static const Color offlineContainer = Color(0xFFFFEDD5); // Orange 100
  static const Color synced = Color(0xFF059669); // Green 600

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFF1F5F9); // Slate 100
}
