import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:window_manager/window_manager.dart';
import 'widgets/space_bar.dart';
import 'widgets/system_info_bar.dart';
import 'services/yabai_service.dart';
import 'services/screen_service.dart';
import 'theme/app_colors.dart';
import 'theme/spacing.dart';
import 'theme/borders.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  // Configure window as always-on-top bar pinned to all workspaces
  await windowManager.waitUntilReadyToShow(null, () async {
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setVisibleOnAllWorkspaces(true);
    
    // Use dynamic screen sizing instead of hardcoded dimensions
    await ScreenService.positionBar();
    
    await windowManager.show();
  });
  
  runApp(const FastBarApp());
}

class FastBarApp extends StatelessWidget {
  const FastBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastBar',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const FastBarWindow(),
    );
  }
}

class FastBarWindow extends StatefulWidget {
  const FastBarWindow({super.key});

  @override
  State<FastBarWindow> createState() => _FastBarWindowState();
}

class _FastBarWindowState extends State<FastBarWindow> {
  Size? _currentScreenSize;
  
  @override
  void initState() {
    super.initState();
    _initializeScreenMonitoring();
  }
  
  void _initializeScreenMonitoring() async {
    // Get initial screen size
    _currentScreenSize = await ScreenService.getPrimaryScreenSize();
    
    // Monitor for screen changes
    ScreenService.screenChanges.listen((_) async {
      final newSize = await ScreenService.getPrimaryScreenSize();
      if (_currentScreenSize != null && newSize != _currentScreenSize) {
        _currentScreenSize = newSize;
        await ScreenService.positionBar();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorders.barRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: ScreenService.barHeight,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.barPadding),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
            child: Row(
              children: [
                SpaceBar(),
                const Spacer(),
                SystemInfoBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
