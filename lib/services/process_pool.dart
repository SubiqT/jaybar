import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ProcessPool {
  static ProcessPool? _instance;
  static ProcessPool get instance => _instance ??= ProcessPool._();
  
  ProcessPool._();
  
  final Map<String, Process> _activeProcesses = {};
  final Set<String> _runningCommands = {};
  int _processCounter = 0;
  
  static const int maxConcurrentProcesses = 8;
  
  Future<ProcessResult?> runYabaiCommand(List<String> args, {Duration timeout = const Duration(seconds: 1)}) async {
    final commandKey = args.join(' ');
    
    // Prevent duplicate concurrent commands
    if (_runningCommands.contains(commandKey)) {
      return null;
    }
    
    // Limit concurrent processes
    if (_activeProcesses.length >= maxConcurrentProcesses) {
      return null;
    }
    
    _runningCommands.add(commandKey);
    final processId = 'yabai_${_processCounter++}';
    
    try {
      final yabaiPath = await _findYabai();
      if (yabaiPath == null) return null;
      
      final process = await Process.start(yabaiPath, args);
      _activeProcesses[processId] = process;
      
      final completer = Completer<ProcessResult>();
      
      // Set up timeout
      Timer? timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          process.kill(ProcessSignal.sigterm);
          completer.complete(ProcessResult(process.pid, -1, '', 'Timeout'));
        }
      });
      
      // Collect output
      final stdoutBuffer = <int>[];
      final stderrBuffer = <int>[];
      
      process.stdout.listen(
        stdoutBuffer.addAll,
        onDone: () => _checkCompletion(completer, process, stdoutBuffer, stderrBuffer, timeoutTimer),
        onError: (e) => _handleError(completer, process, e, timeoutTimer),
      );
      
      process.stderr.listen(
        stderrBuffer.addAll,
        onDone: () => _checkCompletion(completer, process, stdoutBuffer, stderrBuffer, timeoutTimer),
        onError: (e) => _handleError(completer, process, e, timeoutTimer),
      );
      
      process.exitCode.then((exitCode) {
        if (!completer.isCompleted) {
          timeoutTimer?.cancel();
          final result = ProcessResult(
            process.pid,
            exitCode,
            utf8.decode(stdoutBuffer),
            utf8.decode(stderrBuffer),
          );
          completer.complete(result);
        }
      });
      
      return await completer.future;
      
    } catch (e) {
      return ProcessResult(-1, -1, '', e.toString());
    } finally {
      _activeProcesses.remove(processId);
      _runningCommands.remove(commandKey);
    }
  }
  
  void _checkCompletion(Completer<ProcessResult> completer, Process process, 
                       List<int> stdout, List<int> stderr, Timer? timer) {
    // This will be called when both stdout and stderr are done
    // The actual completion is handled by exitCode listener
  }
  
  void _handleError(Completer<ProcessResult> completer, Process process, 
                   dynamic error, Timer? timer) {
    if (!completer.isCompleted) {
      timer?.cancel();
      process.kill(ProcessSignal.sigterm);
      completer.complete(ProcessResult(process.pid, -1, '', error.toString()));
    }
  }
  
  Future<String?> _findYabai() async {
    const paths = [
      '/opt/homebrew/bin/yabai',
      '/usr/local/bin/yabai',
      '/usr/bin/yabai'
    ];
    
    for (final path in paths) {
      if (await File(path).exists()) return path;
    }
    return null;
  }
  
  void killAllProcesses() {
    for (final process in _activeProcesses.values) {
      try {
        process.kill(ProcessSignal.sigterm);
      } catch (e) {
        // Ignore errors
      }
    }
    _activeProcesses.clear();
    _runningCommands.clear();
  }
  
  int get activeProcessCount => _activeProcesses.length;
}
