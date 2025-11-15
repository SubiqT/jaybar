import 'package:flutter/material.dart';
import '../models/space.dart';
import '../services/space_service.dart';
import '../services/yabai_service.dart';
import '../services/mock_yabai_service.dart';
import '../services/performance_monitor.dart';
import '../services/screen_service.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import '../theme/borders.dart';
import '../theme/typography.dart';

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
            SizedBox(width: AppSpacing.itemSpacing),
            
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
                        child: Container(
                          width: AppSpacing.spaceSize,
                          height: AppSpacing.spaceSize,
                          margin: EdgeInsets.only(right: AppSpacing.spaceRightMargin),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: space.hasFocus ? Border.all(
                              color: AppColors.spaceFocused,
                              width: AppBorders.focusedBorderWidth,
                            ) : null,
                          ),
                          child: Center(
                            child: Container(
                              width: AppSpacing.spaceInnerSize,
                              height: AppSpacing.spaceInnerSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getInnerSpaceColor(space),
                                border: _getInnerSpaceBorder(space),
                              ),
                              child: Center(
                                child: Text(
                                  '${space.index}',
                                  style: AppTypography.spaceNumber.copyWith(
                                    color: _getTextColor(space),
                                  ),
                                ),
                              ),
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
  
  Color _getInnerSpaceColor(Space space) {
    if (space.hasFocus && !space.isOccupied) {
      // Focused empty space: transparent
      return AppColors.spaceEmpty;
    }
    if (space.hasFocus) {
      // Focused occupied space: gradient (using magenta as solid color)
      return AppColors.spaceFocused;
    }
    if (space.isOccupied) {
      // Occupied space: foreground color
      return AppColors.spaceOccupied;
    }
    // Empty space: transparent
    return AppColors.spaceEmpty;
  }
  
  Border? _getInnerSpaceBorder(Space space) {
    if (space.hasFocus && !space.isOccupied) {
      // Focused empty space: magenta border
      return Border.all(color: AppColors.spaceFocused, width: AppBorders.borderWidth);
    }
    if (!space.isOccupied) {
      // Empty space: foreground border
      return Border.all(color: AppColors.spaceBorder, width: AppBorders.borderWidth);
    }
    // Occupied spaces: no border
    return null;
  }
  
  Color _getTextColor(Space space) {
    if (space.hasFocus && !space.isOccupied) {
      // Focused empty space: magenta text
      return AppColors.spaceFocused;
    }
    if (!space.isOccupied) {
      // Empty space: foreground text
      return AppColors.foreground;
    }
    // Occupied spaces: background text (dark on light)
    return AppColors.background;
  }
}
