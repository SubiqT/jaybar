import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:process_run/shell.dart';

class SystemInfoService {
  static final _shell = Shell(verbose: false);
  
  /// Get the current active application name
  static Future<String> getCurrentApp() async {
    try {
      final result = await _shell.run('yabai -m query --windows --window');
      if (result.isNotEmpty && result.first.stdout != null) {
        final json = result.first.stdout.toString().trim();
        if (json.isNotEmpty && json != 'null' && json != '{}') {
          final data = jsonDecode(json);
          final app = data['app']?.toString();
          if (app != null && app.isNotEmpty) {
            return app;
          }
        }
      }
    } catch (e) {
      // If yabai query fails, try getting all windows and find focused one
      try {
        final result = await _shell.run('yabai -m query --windows');
        if (result.isNotEmpty && result.first.stdout != null) {
          final json = result.first.stdout.toString().trim();
          final windows = jsonDecode(json) as List;
          for (final window in windows) {
            if (window['has-focus'] == true) {
              return window['app']?.toString() ?? 'Unknown';
            }
          }
        }
      } catch (e2) {
        print('Error getting current app: $e2');
      }
    }
    return 'Desktop';
  }
  
  /// Get current time formatted for display
  static String getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// Get current date formatted for display
  static String getCurrentDate() {
    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    final day = now.day;
    
    String getOrdinalSuffix(int day) {
      if (day >= 11 && day <= 13) return 'th';
      switch (day % 10) {
        case 1: return 'st';
        case 2: return 'nd';
        case 3: return 'rd';
        default: return 'th';
      }
    }
    
    return '$weekday $day${getOrdinalSuffix(day)} $month at';
  }
  
  /// Get basic system stats (simplified for now)
  static Future<Map<String, String>> getSystemStats() async {
    try {
      // Get memory usage
      final memResult = await _shell.run('vm_stat | head -4');
      final cpuResult = await _shell.run('top -l 1 -n 0 | grep "CPU usage"');
      
      // Parse basic info (simplified)
      return {
        'memory': 'Available', // Simplified for now
        'cpu': 'Normal', // Simplified for now
      };
    } catch (e) {
      return {
        'memory': 'Unknown',
        'cpu': 'Unknown',
      };
    }
  }
  
  /// Create a stream that updates every second for time display
  static Stream<DateTime> get timeUpdates {
    return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }
  
  /// Create a stream that updates every 100ms for current app
  static Stream<String> get currentAppUpdates {
    return Stream.periodic(const Duration(milliseconds: 100))
        .asyncMap((_) => getCurrentApp());
  }
}
