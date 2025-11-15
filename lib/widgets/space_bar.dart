import 'package:flutter/material.dart';
import '../models/space.dart';
import '../services/space_service.dart';
import '../services/yabai_service.dart';
import '../services/mock_yabai_service.dart';
import '../services/performance_monitor.dart';
import '../services/screen_service.dart';

class SpaceBar extends StatefulWidget {
  @override
  _SpaceBarState createState() => _SpaceBarState();
}

class _SpaceBarState extends State<SpaceBar> with TickerProviderStateMixin {
  final _yabaiService = YabaiService();
  final _mockService = MockYabaiService();
  final _performanceMonitor = PerformanceMonitor();
  
  SpaceService? _activeService;
  bool _useMockService = false;
  int? _switchingToSpace;
  int? _hoveredSpace;
  String _displayInfo = '';
  late AnimationController _switchAnimationController;
  late Animation<double> _switchAnimation;
  
  @override
  void initState() {
    super.initState();
    _switchAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _switchAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _switchAnimationController, curve: Curves.easeInOut),
    );
    _initializeService();
    _getDisplayInfo();
  }
  
  Future<void> _initializeService() async {
    try {
      await _yabaiService.start();
      // If yabai works, use it
      setState(() {
        _useMockService = false;
        _activeService = _yabaiService;
      });
    } catch (e) {
      print('Yabai not available, using mock service: $e');
      await _mockService.start();
      setState(() {
        _useMockService = true;
        _activeService = _mockService;
      });
    }
  }
  
  Future<void> _getDisplayInfo() async {
    final size = await ScreenService.getPrimaryScreenSize();
    final displays = await ScreenService.getAllDisplays();
    if (mounted) {
      setState(() {
        _displayInfo = 'Screen: ${size.width.toInt()}x${size.height.toInt()} | Displays: ${displays.length}';
      });
    }
  }
  
  Future<void> _switchToSpace(int spaceIndex) async {
    setState(() {
      _switchingToSpace = spaceIndex;
    });
    
    _switchAnimationController.forward().then((_) {
      _switchAnimationController.reverse();
    });
    
    _performanceMonitor.startMeasurement();
    await _activeService!.switchToSpace(spaceIndex);
    
    // Clear switching state after a brief delay
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _switchingToSpace = null;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _yabaiService.dispose();
    _mockService.dispose();
    _switchAnimationController.dispose();
    _performanceMonitor.printStats();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_activeService == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      );
    }
    
    return StreamBuilder<List<Space>>(
      stream: _activeService!.spaceStream,
      builder: (context, snapshot) {
        _performanceMonitor.recordUpdate();
        
        if (!snapshot.hasData) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _useMockService ? 'Demo Mode' : 'Loading spaces...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          );
        }
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Service status indicator (small)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _useMockService ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            
            // Space indicators
            ...snapshot.data!.map((space) => 
              MouseRegion(
                onEnter: (_) => setState(() => _hoveredSpace = space.index),
                onExit: (_) => setState(() => _hoveredSpace = null),
                child: GestureDetector(
                  onTap: () => _switchToSpace(space.index),
                  child: AnimatedBuilder(
                    animation: _switchAnimation,
                    builder: (context, child) {
                      final isHovered = _hoveredSpace == space.index;
                      final isSwitching = _switchingToSpace == space.index;
                      final scale = isSwitching ? _switchAnimation.value : (isHovered ? 1.1 : 1.0);
                      
                      return Transform.scale(
                        scale: scale,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          margin: EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getSpaceColor(space, isHovered, isSwitching),
                            border: Border.all(
                              color: _getBorderColor(space, isHovered, isSwitching),
                              width: isSwitching ? 2 : (isHovered ? 1.5 : 1),
                            ),
                            boxShadow: isHovered || isSwitching ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ] : null,
                          ),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 150),
                              style: TextStyle(
                                fontSize: isHovered ? 11 : 10,
                                color: _getTextColor(space, isHovered, isSwitching),
                                fontWeight: FontWeight.bold,
                              ),
                              child: Text('${space.index}'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ).toList(),
          ],
        );
      },
    );
  }
  
  Color _getSpaceColor(Space space, bool isHovered, bool isSwitching) {
    if (isSwitching) return Colors.blue[300]!;
    if (space.hasFocus) return Colors.blue;
    if (isHovered) return space.isOccupied ? Colors.grey[500]! : Colors.grey[200]!;
    return space.isOccupied ? Colors.grey[400]! : Colors.transparent;
  }
  
  Color _getBorderColor(Space space, bool isHovered, bool isSwitching) {
    if (isSwitching) return Colors.blue[600]!;
    if (isHovered) return Colors.blue[400]!;
    return Colors.grey[600]!;
  }
  
  Color _getTextColor(Space space, bool isHovered, bool isSwitching) {
    if (isSwitching) return Colors.white;
    if (space.hasFocus) return Colors.white;
    if (isHovered) return Colors.black87;
    return Colors.black;
  }
}
