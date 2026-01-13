import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'color_matcher.dart';

class WallpaperService {
  static const platform = MethodChannel('jaybar/wallpaper');
  static Color? _cachedColor;
  static StreamController<Color>? _colorController;
  static bool _isMonitoring = false;
  
  static Stream<Color> get colorStream {
    _colorController ??= StreamController<Color>.broadcast();
    return _colorController!.stream;
  }
  
  static Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    platform.setMethodCallHandler(_handleMethodCall);
    await platform.invokeMethod('startWallpaperMonitoring');
  }
  
  static Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onWallpaperChanged') {
      final hexColor = call.arguments as String;
      final wallpaperColor = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
      final matchedColor = ColorMatcher.findClosestColor(wallpaperColor);
      
      if (_cachedColor != matchedColor) {
        _cachedColor = matchedColor;
        _colorController?.add(matchedColor);
      }
    }
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
    
    return const Color(0xFFc397d8);
  }
  
  static Color? get cachedColor => _cachedColor;
  
  static void dispose() {
    _colorController?.close();
    _colorController = null;
    _isMonitoring = false;
  }
}
