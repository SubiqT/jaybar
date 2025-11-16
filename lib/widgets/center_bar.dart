import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/yabai_signal_service.dart';
import '../services/app_icon_service.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../theme/borders.dart';

class CenterBar extends StatefulWidget {
  const CenterBar({super.key});

  @override
  State<CenterBar> createState() => _CenterBarState();
}

class _CenterBarState extends State<CenterBar> {
  String _currentApp = 'Loading...';
  Uint8List? _appIcon;
  final _yabaiService = YabaiSignalService.instance;

  @override
  void initState() {
    super.initState();
    
    _yabaiService.currentAppStream.listen((appName) {
      if (mounted) {
        if (appName != _currentApp) {
          setState(() {
            _currentApp = appName;
            _appIcon = null; // Clear icon while loading
          });
          _updateAppIcon();
        }
      }
    });
    
    // Get current app immediately if available
    final currentApp = _yabaiService.currentApp;
    if (currentApp != null) {
      setState(() {
        _currentApp = currentApp;
      });
    }
    
    _updateAppIcon(); // Initial icon fetch
  }

  void _updateAppIcon() {
    AppIconService.getFocusedAppIcon().then((icon) {
      if (mounted) {
        setState(() {
          _appIcon = icon;
        });
      }
    }).catchError((error) {
      // Handle error silently
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Container(
        key: ValueKey(_currentApp),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPadding,
          vertical: 4
        ),
        decoration: BoxDecoration(
          color: AppColors.grey400.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppBorders.containerRadius),
          border: Border.all(color: AppColors.grey400.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_appIcon != null) ...[
              Image.memory(
                _appIcon!,
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _currentApp,
              style: AppTypography.systemInfo.copyWith(
                fontSize: 12,
                color: AppColors.foreground.withOpacity(0.7),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
