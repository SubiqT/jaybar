import 'package:flutter/material.dart';
import 'dart:async';
import '../models/space.dart';
import '../services/space_service.dart';
import '../services/yabai_signal_service.dart';
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
  final _yabaiService = YabaiSignalService.instance;
  
  int? _switchingToSpace;
  int? _hoveredSpace;
  String _displayInfo = '';
  late AnimationController _switchAnimationController;
  late Animation<double> _switchAnimation;
  List<Space>? _initialSpaces;
  
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
    _loadInitialSpaces();
    _getDisplayInfo();
    
    // Fallback timer to force refresh if still loading after 2 seconds
    Timer(Duration(seconds: 2), () {
      if (mounted && _initialSpaces == null) {
        _loadInitialSpaces();
      }
    });
  }
  
  Future<void> _loadInitialSpaces() async {
    // Force an immediate space query to populate the UI
    await _yabaiService.refreshSpaces();
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
    
    await _yabaiService.switchToSpace(spaceIndex);
    
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
    _switchAnimationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Space>>(
      stream: _yabaiService.spaceStream,
      initialData: _yabaiService.currentSpaces,
      builder: (context, snapshot) {
        final spaces = snapshot.data ?? _yabaiService.currentSpaces;
        
        if (spaces == null || spaces.isEmpty) {
          if (_initialSpaces == null) {
            _loadInitialSpaces();
          }
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
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
                  'Loading spaces...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }
        
        _initialSpaces = spaces;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildGroupedSpaces(spaces),
        );
      },
    );
  }
  
  List<Widget> _buildGroupedSpaces(List<Space> spaces) {
    List<Widget> widgets = [];
    
    for (int i = 0; i < spaces.length; i++) {
      final space = spaces[i];
      
      widgets.add(MouseRegion(
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
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Transform.scale(
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
                ),
              );
            },
          ),
        ),
      ));
      
      // Add separator after every 3rd space (but not after the last space)
      if ((i + 1) % 3 == 0 && i < spaces.length - 1) {
        widgets.add(Container(
          width: 1,
          height: 12,
          margin: EdgeInsets.symmetric(horizontal: 8),
          color: Colors.white24,
        ));
      }
    }
    
    return widgets;
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
