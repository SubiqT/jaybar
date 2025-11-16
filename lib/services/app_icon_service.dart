import 'dart:typed_data';
import 'package:flutter/services.dart';

class AppIconService {
  static const _channel = MethodChannel('jaybar/app_icon');
  static final Map<String, Uint8List> _iconCache = {};
  
  static Future<Uint8List?> getFocusedAppIcon() async {
    try {
      final result = await _channel.invokeMethod('getFocusedAppIcon')
          .timeout(const Duration(milliseconds: 500));
      
      if (result is Map) {
        final appName = result['appName'] as String?;
        final iconData = result['icon'] as Uint8List?;
        
        if (appName != null && iconData != null) {
          _iconCache[appName] = iconData;
          return iconData;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  static Uint8List? getCachedIcon(String appName) {
    return _iconCache[appName];
  }
}
