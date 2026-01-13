import 'package:flutter/material.dart';
import 'dart:math';

class ColorMatcher {
  static final List<Color> _appPalette = [
    const Color(0xFFcc6566), // red
    const Color(0xFFd54e53), // brightRed
    const Color(0xFFb6bd68), // green
    const Color(0xFFb9ca4b), // brightGreen
    const Color(0xFFf0c674), // yellow
    const Color(0xFF82a2be), // blue
    const Color(0xFF7aa6da), // brightBlue
    const Color(0xFFb294bb), // magenta
    const Color(0xFFc397d8), // brightMagenta
    const Color(0xFF8abeb7), // cyan
    const Color(0xFF70c0b1), // brightCyan
  ];
  
  static Color findClosestColor(Color targetColor) {
    Color closestColor = _appPalette.first;
    double minDistance = double.infinity;
    
    for (final color in _appPalette) {
      final distance = _colorDistance(targetColor, color);
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }
    
    return closestColor;
  }
  
  static double _colorDistance(Color c1, Color c2) {
    // Convert to HSV for better perceptual distance
    final hsv1 = HSVColor.fromColor(c1);
    final hsv2 = HSVColor.fromColor(c2);
    
    // Weight hue difference more heavily for better color matching
    final hueDiff = (hsv1.hue - hsv2.hue).abs();
    final satDiff = (hsv1.saturation - hsv2.saturation).abs();
    final valDiff = (hsv1.value - hsv2.value).abs();
    
    // Normalize hue difference (0-180 scale)
    final normalizedHueDiff = hueDiff > 180 ? 360 - hueDiff : hueDiff;
    
    return normalizedHueDiff * 2 + satDiff * 100 + valDiff * 100;
  }
}
