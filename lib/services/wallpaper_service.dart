import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'color_matcher.dart';

class WallpaperService {
  static const platform = MethodChannel('jaybar/wallpaper');
  static Color? _cachedColor;
  static String? _lastWallpaperPath;
  static StreamController<Color>? _colorController;
  
  static Stream<Color> get colorStream {
    _colorController ??= StreamController<Color>.broadcast();
    return _colorController!.stream;
  }
  
  static Future<Color> getDominantColor() async {
    try {
      final result = await platform.invokeMethod('getWallpaperDominantColor');
      if (result != null) {
        final wallpaperColor = Color(int.parse(result.toString().replaceFirst('#', '0xFF')));
        final matchedColor = ColorMatcher.findClosestColor(wallpaperColor);
        
        if (_cachedColor != matchedColor) {
          _cachedColor = matchedColor;
          _colorController?.add(matchedColor);
        }
        return matchedColor;
      }
    } catch (e) {
      print('Failed to get wallpaper color: $e');
    }
    
    // Fallback to default
    return const Color(0xFFc397d8); // brightMagenta
  }
  
  static Color? get cachedColor => _cachedColor;
  
  static void dispose() {
    _colorController?.close();
    _colorController = null;
  }
}
