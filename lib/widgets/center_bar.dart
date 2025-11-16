import 'package:flutter/material.dart';
import '../services/yabai_signal_service.dart';
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
  String _currentApp = '';
  final _yabaiService = YabaiSignalService.instance;

  @override
  void initState() {
    super.initState();
    _yabaiService.currentAppStream.listen((appName) {
      if (mounted) {
        setState(() {
          _currentApp = appName;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _currentApp.isNotEmpty
        ? Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPadding,
              vertical: 4
            ),
            decoration: BoxDecoration(
              color: AppColors.grey400.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppBorders.containerRadius),
              border: Border.all(color: AppColors.grey400.withOpacity(0.3)),
            ),
            child: Text(
              _currentApp,
              style: AppTypography.systemInfo.copyWith(
                fontSize: 12,
                color: AppColors.foreground.withOpacity(0.7),
                height: 1.0,
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
