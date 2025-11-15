class PerformanceMonitor {
  final List<Duration> _latencies = [];
  Stopwatch? _stopwatch;
  
  void startMeasurement() {
    _stopwatch = Stopwatch()..start();
  }
  
  void recordUpdate() {
    if (_stopwatch != null) {
      _latencies.add(_stopwatch!.elapsed);
      _stopwatch = null;
    }
  }
  
  Duration get averageLatency {
    if (_latencies.isEmpty) return Duration.zero;
    final total = _latencies.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: total ~/ _latencies.length);
  }
  
  Duration get maxLatency => _latencies.isEmpty 
      ? Duration.zero 
      : _latencies.reduce((a, b) => a > b ? a : b);
      
  int get measurementCount => _latencies.length;
  
  void reset() {
    _latencies.clear();
    _stopwatch = null;
  }
  
  void printStats() {
    // Performance stats available but not logged
  }
}
