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
          });
          _updateAppIcon();
        }
      }
    });
    
    final currentApp = _yabaiService.currentApp;
    if (currentApp != null) {
      setState(() {
        _currentApp = currentApp;
      });
    }
    
    _updateAppIcon();
  }

  void _updateAppIcon() {
    // Check cache first
    final cachedIcon = AppIconService.getCachedIcon(_currentApp);
    if (cachedIcon != null) {
      setState(() {
        _appIcon = cachedIcon;
      });
      return;
    }
    
    // Clear icon while loading new one
    setState(() {
      _appIcon = null;
    });
    
    // Fetch new icon
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
        height: 24,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: _appIcon != null
                  ? Image.memory(_appIcon!, width: 16, height: 16)
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey400.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
            ),
            const SizedBox(width: 6),
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
