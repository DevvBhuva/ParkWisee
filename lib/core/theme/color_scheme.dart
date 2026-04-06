import 'package:flutter/material.dart';

class AppColorScheme {
  // Light Palette - Indigo/Slate
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6366F1), // Indigo 500
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE0E7FF), // Indigo 100
    onPrimaryContainer: Color(0xFF3730A3), // Indigo 800
    secondary: Color(0xFF10B981), // Emerald 500
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD1FAE5), // Emerald 100
    onSecondaryContainer: Color(0xFF065F46), // Emerald 800
    tertiary: Color(0xFFF59E0B), // Amber 500
    onTertiary: Colors.white,
    error: Color(0xFFEF4444), // Red 500
    onError: Colors.white,
    surface: Color(0xFFF8FAFC), // Slate 50 (Background)
    onSurface: Color(0xFF0F172A), // Slate 900
    surfaceContainer: Colors.white, // Elevated surfaces/cards
    surfaceContainerHighest: Color(0xFFF1F5F9), // Slate 100 (for secondary containers)
    onSurfaceVariant: Color(0xFF64748B), // Slate 500
    outline: Color(0xFFE2E8F0), // Slate 200 (Subtle borders)
    outlineVariant: Color(0xFFCBD5E1), // Slate 300
    shadow: Color(0x0F000000), // Subtle shadow
  );

  // Dark Palette - Clean Material Dark
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF818CF8), // Indigo 400
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF312E81), // Indigo 900
    onPrimaryContainer: Color(0xFFE0E7FF), // Indigo 100
    secondary: Color(0xFF34D399), // Emerald 400
    onSecondary: Color(0xFF064E3B), // Emerald 950
    secondaryContainer: Color(0xFF065F46), // Emerald 800
    onSecondaryContainer: Color(0xFFD1FAE5), // Emerald 100
    tertiary: Color(0xFFFBBF24), // Amber 400
    onTertiary: Color(0xFF78350F), // Amber 950
    error: Color(0xFFF87171), // Red 400
    onError: Color(0xFF7F1D1D), // Red 950
    surface: Color(0xFF121212), // Material Dark Background
    onSurface: Color(0xFFF8FAFC), // Slate 50
    surfaceContainer: Color(0xFF1E1E1E), // Elevated surfaces/cards
    surfaceContainerHighest: Color(0xFF2C2C2C), // Higher elevation surfaces
    onSurfaceVariant: Color(0xFF94A3B8), // Slate 400
    outline: Color(0x1AFFFFFF), // Subtle 10% white border for dark depth
    outlineVariant: Color(0x33FFFFFF), // 20% white border
    shadow: Color(0x3F000000), // Deeper shadow for dark mode
  );
}
