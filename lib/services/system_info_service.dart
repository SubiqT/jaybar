import 'dart:async';
import 'dart:io';
import 'package:process_run/shell.dart';

class SystemInfoService {
  static final _shell = Shell(verbose: false);
  
  /// Get the current active application name
  static Future<String> getCurrentApp() async {
    try {
      final result = await _shell.run('''
        osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true'
      ''');
      
      if (result.isNotEmpty && result.first.stdout != null) {
        return result.first.stdout.toString().trim();
      }
    } catch (e) {
      // Fallback if AppleScript fails
    }
    return 'Unknown';
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
    
    return '$weekday $month $day';
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
  
  /// Create a stream that updates every 5 seconds for current app
  static Stream<String> get currentAppUpdates {
    return Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => getCurrentApp());
  }
}
