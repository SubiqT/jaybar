import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/space.dart';
import 'space_service.dart';
import 'process_pool.dart';

class YabaiService implements SpaceService {
  Timer? _pollTimer;
  
  // Caching and state management
  List<Space>? _cachedSpaces;
  String? _lastRawOutput;
  
  @override
  Stream<List<Space>> get spaceStream => _spaceController.stream;
  final _spaceController = StreamController<List<Space>>.broadcast();
  
  @override
  Future<void> start() async {
    _pollTimer = Timer.periodic(
      Duration(milliseconds: 50),
      (_) => _pollSpaces(),
    );
  }
  
  Future<void> _pollSpaces() async {
    try {
      final result = await ProcessPool.instance.runYabaiCommand(['-m', 'query', '--spaces']);
      if (result?.exitCode != 0 || result?.stdout.isEmpty == true) return;
      
      final rawOutput = result!.stdout.trim();
      
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
  
  @override
  Future<void> switchToSpace(int index) async {
    try {
      await ProcessPool.instance.runYabaiCommand(['-m', 'space', '--focus', index.toString()]);
    } catch (e) {
      print('Error switching to space $index: $e');
    }
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    ProcessPool.instance.killAllProcesses();
    _spaceController.close();
  }
}
