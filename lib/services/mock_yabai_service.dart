import 'dart:async';
import 'dart:math';
import '../models/space.dart';
import 'space_service.dart';

class MockYabaiService implements SpaceService {
  Timer? _pollTimer;
  
  // Caching and state management
  List<Space>? _cachedSpaces;
  String? _lastRawOutput;
  
  // Performance tracking
  final List<Duration> _pollLatencies = [];
  
  // Mock data
  int _focusedSpace = 1;
  final Set<int> _occupiedSpaces = {1, 3, 5};
  final Random _random = Random();
  
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
    _pollTimer = Timer.periodic(
      Duration(milliseconds: 50),
      (_) => _pollSpaces(),
    );
  }
  
  Future<void> _pollSpaces() async {
    final stopwatch = Stopwatch()..start();
    
    // Simulate occasional space changes
    if (_random.nextInt(100) < 5) { // 5% chance of change
      _focusedSpace = _random.nextInt(9) + 1;
    }
    if (_random.nextInt(100) < 3) { // 3% chance of occupation change
      final space = _random.nextInt(9) + 1;
      if (_occupiedSpaces.contains(space)) {
        _occupiedSpaces.remove(space);
      } else {
        _occupiedSpaces.add(space);
      }
    }
    
    // Generate mock spaces
    final spaces = List.generate(9, (i) => Space(
      index: i + 1,
      hasFocus: i + 1 == _focusedSpace,
      isOccupied: _occupiedSpaces.contains(i + 1),
    ));
    
    // Simulate raw output for caching comparison
    final rawOutput = spaces.map((s) => '${s.index}:${s.hasFocus}:${s.isOccupied}').join(',');
    
    // Only process if output changed (caching optimization)
    if (rawOutput != _lastRawOutput) {
      // Only emit if spaces actually changed (state change detection)
      if (!_spacesEqual(_cachedSpaces, spaces)) {
        _cachedSpaces = spaces;
        _spaceController.add(spaces);
      }
      _lastRawOutput = rawOutput;
    }
    
    // Add simulated latency (1-5ms)
    await Future.delayed(Duration(milliseconds: _random.nextInt(5) + 1));
    
    _pollLatencies.add(stopwatch.elapsed);
    
    // Keep only last 100 measurements
    if (_pollLatencies.length > 100) {
      _pollLatencies.removeAt(0);
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
    // Simulate space switching
    await Future.delayed(Duration(milliseconds: 10));
    _focusedSpace = index;
    _occupiedSpaces.add(index);
  }
  
  @override
  void dispose() {
    _pollTimer?.cancel();
    _spaceController.close();
    
    // Print performance stats
    if (_pollLatencies.isNotEmpty) {
      print('Mock Yabai Service Performance:');
      print('  Total polls: $pollCount');
      print('  Average poll latency: ${averagePollLatency.inMilliseconds}ms');
    }
  }
}
