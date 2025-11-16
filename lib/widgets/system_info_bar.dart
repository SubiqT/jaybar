import 'package:flutter/material.dart';
import '../services/system_info_service.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import '../theme/borders.dart';
import '../theme/typography.dart';
import 'battery_widget.dart';
import 'volume_widget.dart';
import 'network_widget.dart';

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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Volume
        Container(
          height: 24,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
          child: VolumeWidget(),
        ),
        const SizedBox(width: 8),
        // Battery
        Container(
          height: 24,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
          child: BatteryWidget(),
        ),
        const SizedBox(width: 8),
        // Network
        NetworkWidget(),
        const SizedBox(width: 8),
        // Time and date
        Container(
          height: 24,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
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
        ),
      ],
    );
  }
}
