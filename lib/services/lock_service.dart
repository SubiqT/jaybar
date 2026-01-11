import 'dart:io';

class LockService {
  static const String _lockFileName = '.jaybar.lock';
  static late final String _lockFilePath;
  static File? _lockFile;

  static void initialize() {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    _lockFilePath = '$homeDir/$_lockFileName';
  }

  static bool tryAcquireLock() {
    initialize();
    _lockFile = File(_lockFilePath);
    
    if (_lockFile!.existsSync()) {
      final pidStr = _lockFile!.readAsStringSync().trim();
      if (_isProcessRunning(pidStr)) {
        return false; // Another instance is running
      }
      // Stale lock file, remove it
      _lockFile!.deleteSync();
    }
    
    // Create lock file with current PID
    _lockFile!.writeAsStringSync(pid.toString());
    return true;
  }

  static void releaseLock() {
    if (_lockFile?.existsSync() == true) {
      _lockFile!.deleteSync();
    }
  }

  static bool _isProcessRunning(String pidStr) {
    try {
      final pid = int.parse(pidStr);
      final result = Process.runSync('kill', ['-0', pid.toString()]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
