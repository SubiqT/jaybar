import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  
  // Caching and state management
  List<Space>? _cachedSpaces;
  String? _lastRawOutput;
  
  @override
  Stream<List<Space>> get spaceStream => _spaceController.stream;
  final _spaceController = StreamController<List<Space>>.broadcast();
  
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
    try {
      final result = await Process.run(_yabaiPath!, ['-m', 'query', '--spaces']);
      if (result.exitCode != 0) return;
      
      final rawOutput = result.stdout.toString().trim();
      
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
        await Process.run(_yabaiPath!, ['-m', 'space', '--focus', index.toString()]);
      } catch (e) {
        print('Error switching to space $index: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _spaceController.close();
  }
}
