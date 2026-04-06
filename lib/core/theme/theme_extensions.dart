import 'package:flutter/material.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color slotAvailable;
  final Color slotBooked;
  final Color slotSelected;
  final Color cardShadow;
  final Gradient premiumGradient;
  final double cardRadius;

  const AppThemeExtension({
    required this.slotAvailable,
    required this.slotBooked,
    required this.slotSelected,
    required this.cardShadow,
    required this.premiumGradient,
    required this.cardRadius,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? slotAvailable,
    Color? slotBooked,
    Color? slotSelected,
    Color? cardShadow,
    Gradient? premiumGradient,
    double? cardRadius,
  }) {
    return AppThemeExtension(
      slotAvailable: slotAvailable ?? this.slotAvailable,
      slotBooked: slotBooked ?? this.slotBooked,
      slotSelected: slotSelected ?? this.slotSelected,
      cardShadow: cardShadow ?? this.cardShadow,
      premiumGradient: premiumGradient ?? this.premiumGradient,
      cardRadius: cardRadius ?? this.cardRadius,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      slotAvailable: Color.lerp(slotAvailable, other.slotAvailable, t)!,
      slotBooked: Color.lerp(slotBooked, other.slotBooked, t)!,
      slotSelected: Color.lerp(slotSelected, other.slotSelected, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      premiumGradient: Gradient.lerp(premiumGradient, other.premiumGradient, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t),
    );
  }

  // Double lerp helper
  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  // Static instances for Light and Dark modes
  static const light = AppThemeExtension(
    slotAvailable: Color(0xFF10B981), // Emerald 500
    slotBooked: Color(0xFFEF4444), // Red 500
    slotSelected: Color(0xFF6366F1), // Indigo 500
    cardShadow: Color(0x1A000000), // 10% black
    premiumGradient: LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardRadius: 24.0,
  );

  static const dark = AppThemeExtension(
    slotAvailable: Color(0xFF34D399), // Emerald 400
    slotBooked: Color(0xFFF87171), // Red 400
    slotSelected: Color(0xFF818CF8), // Indigo 400
    cardShadow: Color(0x3F000000), // 25% black
    premiumGradient: LinearGradient(
      colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardRadius: 24.0,
  );
}
