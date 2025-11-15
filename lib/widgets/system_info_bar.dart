import 'package:flutter/material.dart';
import '../services/system_info_service.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import '../theme/borders.dart';
import '../theme/typography.dart';

class SystemInfoBar extends StatefulWidget {
  @override
  _SystemInfoBarState createState() => _SystemInfoBarState();
}

class _SystemInfoBarState extends State<SystemInfoBar> {
  String _currentApp = '';
  String _currentTime = '';
  String _currentDate = '';
  
  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }
  
  void _initializeStreams() {
    // Update time every second
    SystemInfoService.timeUpdates.listen((dateTime) {
      if (mounted) {
        setState(() {
          _currentTime = SystemInfoService.getCurrentTime();
          _currentDate = SystemInfoService.getCurrentDate();
        });
      }
    });
    
    // Update current app every 5 seconds
    SystemInfoService.currentAppUpdates.listen((appName) {
      if (mounted) {
        setState(() {
          _currentApp = appName;
        });
      }
    });
    
    // Get initial values
    _updateInitialValues();
  }
  
  void _updateInitialValues() async {
    final app = await SystemInfoService.getCurrentApp();
    if (mounted) {
      setState(() {
        _currentApp = app;
        _currentTime = SystemInfoService.getCurrentTime();
        _currentDate = SystemInfoService.getCurrentDate();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current application
        if (_currentApp.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPadding, 
              vertical: 4
            ),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppBorders.containerRadius),
              border: Border.all(color: AppColors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apps,
                  size: 12,
                  color: AppColors.foreground.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _currentApp,
                  style: AppTypography.systemInfo,
                ),
              ],
            ),
          ),
        
        SizedBox(width: AppSpacing.itemSpacing),
        
        // Time and date
        Container(
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
              Icon(
                Icons.access_time,
                size: 12,
                color: AppColors.foreground.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currentTime,
                    style: AppTypography.systemInfo.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentDate,
                    style: AppTypography.systemInfo.copyWith(
                      fontSize: 9,
                      color: AppColors.foreground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
