import 'dart:typed_data';
import 'package:flutter/services.dart';

class AppIconService {
  static const _channel = MethodChannel('jaybar/app_icon');
  
  static Future<Uint8List?> getFocusedAppIcon() async {
    try {
      final icon = await _channel.invokeMethod('getFocusedAppIcon')
          .timeout(const Duration(milliseconds: 500));
      return icon;
    } catch (e) {
      return null;
    }
  }
}
