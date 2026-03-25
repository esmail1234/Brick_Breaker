import 'package:flutter/material.dart';

/// Neon dark-mode color palette for Brick Breaker.
class ColorConstants {
  ColorConstants._();

  // Backgrounds
  static const Color background = Color(0xFF050514);
  static const Color backgroundLight = Color(0xFF0D0D2B);

  // Ball
  static const Color ballCore = Colors.white;
  static const Color ballGlow = Color(0xFF00FFFF);

  // Paddle
  static const Color paddleStart = Color(0xFF4FC3F7);
  static const Color paddleEnd = Color(0xFF9C27B0);
  static const Color paddleGlow = Color(0xFF2979FF);

  // Shield
  static const Color shieldColor = Color(0xFF69F0AE);

  // Brick tiers (index 0 = durability 1, index 3 = durability 4)
  static const List<Color> brickColors = [
    Color(0xFF00E5FF), // tier 1 – cyan
    Color(0xFF69F0AE), // tier 2 – green
    Color(0xFFFFD740), // tier 3 – amber
    Color(0xFFFF5252), // tier 4 – red
  ];

  static const List<Color> brickGlowColors = [
    Color(0xFF00B8C8),
    Color(0xFF3DB870),
    Color(0xFFBB9B2D),
    Color(0xFFBB3838),
  ];

  // Power-up types
  static const Color puExpand = Color(0xFF76FF03);
  static const Color puShrink = Color(0xFFFF6E40);
  static const Color puSlow = Color(0xFF40C4FF);
  static const Color puMultiBall = Color(0xFFE040FB);
  static const Color puShield = Color(0xFFFFD740);

  // HUD / UI
  static const Color hudText = Color(0xFFE0E0FF);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonPink = Color(0xFFE91E8C);
  static const Color neonBlue = Color(0xFF448AFF);
  static const Color heartColor = Color(0xFFFF5252);
}
