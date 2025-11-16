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
    
    // Get initial values
    _updateInitialValues();
  }
  
  void _updateInitialValues() async {
    if (mounted) {
      setState(() {
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentDate,
                    style: AppTypography.systemInfo.copyWith(
                      fontSize: 12,
                      color: AppColors.foreground.withOpacity(0.7),
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentTime,
                    style: AppTypography.systemInfo.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
