import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:process_run/shell.dart';
import '../models/space.dart';
import 'space_service.dart';

class YabaiService implements SpaceService {
  static const _yabaiPaths = [
    '/opt/homebrew/bin/yabai',
    '/usr/local/bin/yabai',
    '/usr/bin/yabai'
  ];
  
  String? _yabaiPath;
  Timer? _pollTimer;
  final _shell = Shell();
  
  // Caching and state management
  List<Space>? _cachedSpaces;
  String? _lastRawOutput;
  
  // Performance tracking
  final List<Duration> _pollLatencies = [];
  
  @override
  Stream<List<Space>> get spaceStream => _spaceController.stream;
  final _spaceController = StreamController<List<Space>>.broadcast();
  
  // Performance getters
  @override
  Duration get averagePollLatency {
    if (_pollLatencies.isEmpty) return Duration.zero;
    final total = _pollLatencies.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: total ~/ _pollLatencies.length);
  }
  
  @override
  int get pollCount => _pollLatencies.length;
  
  @override
  Future<void> start() async {
    _yabaiPath = await _findYabai();
    if (_yabaiPath == null) throw Exception('yabai not found in common paths');
    
    _pollTimer = Timer.periodic(
      Duration(milliseconds: 50),
      (_) => _pollSpaces(),
    );
  }
  
  Future<void> _pollSpaces() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await _shell.run('$_yabaiPath -m query --spaces');
      final rawOutput = result.outText.trim();
      
      // Only process if output changed
      if (rawOutput != _lastRawOutput) {
        final spaces = (jsonDecode(rawOutput) as List)
            .map((json) => Space.fromJson(json))
            .toList();
        
        // Only emit if spaces actually changed
        if (!_spacesEqual(_cachedSpaces, spaces)) {
          _cachedSpaces = spaces;
          _spaceController.add(spaces);
        }
        
        _lastRawOutput = rawOutput;
      }
      
      _pollLatencies.add(stopwatch.elapsed);
      
      // Keep only last 100 measurements
      if (_pollLatencies.length > 100) {
        _pollLatencies.removeAt(0);
      }
      
    } catch (e) {
      print('Error polling spaces: $e');
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
        await _shell.run('$_yabaiPath -m space --focus $index');
      } catch (e) {
        print('Error switching to space $index: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _spaceController.close();
    
    // Print performance stats
    if (_pollLatencies.isNotEmpty) {
      print('Yabai Service Performance:');
      print('  Total polls: $pollCount');
      print('  Average poll latency: ${averagePollLatency.inMilliseconds}ms');
    }
  }
}
