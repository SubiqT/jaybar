import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:process_run/shell.dart';
import '../models/space.dart';
import 'space_service.dart';
import 'app_icon_service.dart';

class YabaiSignalService implements SpaceService {
  static const _yabaiPaths = [
    '/opt/homebrew/bin/yabai',
    '/usr/local/bin/yabai',
    '/usr/bin/yabai'
  ];
  
  static YabaiSignalService? _instance;
  static YabaiSignalService get instance => _instance ??= YabaiSignalService._();
  
  YabaiSignalService._();
  
  String? _yabaiPath;
  ServerSocket? _server;
  static const _signalPort = 8080;
  bool _isStarted = false;
  
  List<Space>? _cachedSpaces;
  String? _cachedCurrentApp;
  Timer? _debounceTimer;
  bool _isQueryingSpaces = false;
  bool _isQueryingApp = false;
  
  @override
  Stream<List<Space>> get spaceStream => _spaceController.stream;
  final _spaceController = StreamController<List<Space>>.broadcast();
  
  Stream<String> get currentAppStream => _currentAppController.stream;
  final _currentAppController = StreamController<String>.broadcast();
  
  String? get currentApp => _cachedCurrentApp;
  
  // Public method to force space refresh
  Future<void> refreshSpaces() async {
    await _updateSpaces();
  }
  
  // Public method to force current app refresh
  Future<void> refreshCurrentApp() async {
    await _updateCurrentApp();
  }
  
  // Get current cached spaces
  List<Space>? get currentSpaces => _cachedSpaces;
  
  @override
  Future<void> start() async {
    if (_isStarted) return;
    
    _yabaiPath = await _findYabai();
    if (_yabaiPath == null) throw Exception('yabai not found in common paths');
    
    if (!await _checkNetcatAvailable()) {
      throw Exception('netcat (nc) not available - required for yabai signals');
    }
    
    // Load initial data first, before setting up signals
    await _initialSpaceLoad();
    await _initialAppLoad();
    
    await _setupSignalServer();
    await _registerSignals();
    
    _isStarted = true;
  }
  
  Future<bool> _checkNetcatAvailable() async {
    try {
      await Process.run('which', ['nc']);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _setupSignalServer() async {
    try {
      // Clean up any existing server first
      await _server?.close();
      
      _server = await ServerSocket.bind('localhost', _signalPort);
      
      _server!.listen((socket) {
        socket.cast<List<int>>().transform(utf8.decoder).listen((data) {
          _handleSignal(data.trim());
        }, onError: (e) {
          print('Signal socket error: $e');
          // Try to recover by restarting the server
          _recoverSignalServer();
        });
      }, onError: (e) {
        print('Signal server error: $e');
        _recoverSignalServer();
      });
    } catch (e) {
      print('Failed to start signal server: $e');
      // Continue without signal server - polling will still work
    }
  }
  
  Future<void> _recoverSignalServer() async {
    print('Attempting to recover signal server...');
    try {
      await _cleanupSignals();
      await Future.delayed(Duration(milliseconds: 500));
      await _setupSignalServer();
      await _registerSignals();
      print('Signal server recovered');
    } catch (e) {
      print('Failed to recover signal server: $e');
    }
  }
  
  Future<void> _registerSignals() async {
    // Clean up any existing signals first
    await _cleanupSignals();
    
    final signals = [
      'space_changed',
      'window_focused',
      'window_created',
      'window_destroyed',
      'display_changed'
    ];
    
    for (final signal in signals) {
      try {
        await Process.run(_yabaiPath!, ['-m', 'signal', '--add', 'event=$signal', 'label=jaybar_$signal', 'action=echo $signal | nc localhost $_signalPort']);
      } catch (e) {
        print('Failed to register signal $signal: $e');
      }
    }
  }
  
  Future<void> _initialSpaceLoad() async {
    await _updateSpaces();
  }
  
  Future<void> _initialAppLoad() async {
    await _updateCurrentApp();
  }
  
  void _handleSignal(String signal) {
    // Handle window_focused immediately without debounce
    if (signal == 'window_focused') {
      if (!_isQueryingApp) {
        _updateCurrentApp();
      }
      return;
    }
    
    // Debounce other signals
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 25), () {
      switch (signal) {
        case 'space_changed':
        case 'display_changed':
          if (!_isQueryingSpaces) {
            _updateSpaces();
          }
          break;
        case 'window_created':
        case 'window_destroyed':
          if (!_isQueryingSpaces) {
            _updateSpaces();
          }
          if (!_isQueryingApp) {
            _updateCurrentApp();
          }
          break;
      }
    });
  }
  
  Future<void> _updateSpaces() async {
    if (_isQueryingSpaces) return;
    _isQueryingSpaces = true;
    
    try {
      final result = await Process.run(_yabaiPath!, ['-m', 'query', '--spaces']).timeout(Duration(seconds: 2));
      if (result.exitCode == 0) {
        final spaces = (jsonDecode(result.stdout.toString().trim()) as List)
            .map((json) => Space.fromJson(json))
            .toList();
        
        if (_cachedSpaces == null || !_spacesEqual(_cachedSpaces, spaces)) {
          _cachedSpaces = spaces;
          _spaceController.add(spaces);
          
          // Proactively cache icons for all open apps
          _cacheOpenAppIcons();
        }
      }
    } catch (e) {
      print('Error updating spaces: $e');
    } finally {
      _isQueryingSpaces = false;
    }
  }
  
  Future<void> _cacheOpenAppIcons() async {
    try {
      final result = await Process.run(_yabaiPath!, ['-m', 'query', '--windows'])
          .timeout(Duration(milliseconds: 500));
      
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final windows = jsonDecode(result.stdout.toString().trim()) as List;
        final appNames = windows
            .map((window) => window['app']?.toString())
            .where((app) => app != null && app.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();
        

      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  Future<void> _updateCurrentApp() async {
    if (_isQueryingApp) {
      return;
    }
    _isQueryingApp = true;
    
    try {
      final result = await Process.run(_yabaiPath!, ['-m', 'query', '--windows'])
          .timeout(Duration(milliseconds: 500));
      
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty && result.stdout.toString().trim() != 'null') {
        final windows = jsonDecode(result.stdout.toString().trim()) as List;
        final focusedWindow = windows.firstWhere(
          (window) => window['has-focus'] == true,
          orElse: () => null,
        );
        
        final app = focusedWindow?['app']?.toString() ?? 'Desktop';
        
        if (app != _cachedCurrentApp || _cachedCurrentApp == null) {
          _cachedCurrentApp = app;
          _currentAppController.add(app);
        }
      }
    } catch (e) {
      if (_cachedCurrentApp != 'Desktop') {
        _cachedCurrentApp = 'Desktop';
        _currentAppController.add('Desktop');
      }
    } finally {
      _isQueryingApp = false;
    }
  }
  
  bool _spacesEqual(List<Space>? a, List<Space>? b) {
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i].index != b[i].index || 
          a[i].hasFocus != b[i].hasFocus || 
          a[i].isOccupied != b[i].isOccupied) {
        return false;
      }
    }
    return true;
  }
  
  Future<String?> _findYabai() async {
    for (final path in _yabaiPaths) {
      if (await File(path).exists()) return path;
    }
    return null;
  }
  
  @override
  Future<void> switchToSpace(int index) async {
    if (_yabaiPath != null) {
      try {
        await Process.run(_yabaiPath!, ['-m', 'space', '--focus', index.toString()]);
      } catch (e) {
        print('Error switching to space $index: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _cleanupSignals();
    _server?.close();
    _spaceController.close();
    _currentAppController.close();
    _isStarted = false;
    _instance = null;
  }
  
  Future<void> _cleanupSignals() async {
    final signals = [
      'space_changed',
      'window_focused', 
      'window_created',
      'window_destroyed',
      'display_changed'
    ];
    
    for (final signal in signals) {
      try {
        await Process.run(_yabaiPath!, ['-m', 'signal', '--remove', 'jaybar_$signal']);
      } catch (e) {
        // Ignore errors - signal might not exist
      }
    }
  }
}
