import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'widgets/space_bar.dart';
import 'widgets/center_bar.dart';
import 'widgets/system_info_bar.dart';
import 'services/yabai_signal_service.dart';
import 'services/screen_service.dart';
import 'services/system_tray_service.dart';
import 'theme/app_colors.dart';
import 'theme/spacing.dart';
import 'theme/borders.dart';

const platform = MethodChannel('jaybar/window');

Future<void> handleCliCommand(List<String> args) async {
  final command = args[0];
  
  switch (command) {
    case '--start-service':
      await startService();
      break;
    case '--stop-service':
      await stopService();
      break;
    case '--restart-service':
      await restartService();
      break;
    case '--enable-service':
      await enableService();
      break;
    case '--disable-service':
      await disableService();
      break;
    case '--service':
      // Run as headless service
      await runAsService();
      break;
    case '--help':
    case '-h':
      printHelp();
      break;
    default:
      print('Unknown command: $command');
      printHelp();
  }
  
  exit(0);
}

void printHelp() {
  print('''
jaybar - A Flutter-powered status bar for yabai

Usage:
  jaybar                    Start the status bar GUI
  jaybar --start-service    Start the jaybar service
  jaybar --stop-service     Stop the jaybar service  
  jaybar --restart-service  Restart the jaybar service
  jaybar --enable-service   Enable the launch agent
  jaybar --disable-service  Disable the launch agent
  jaybar --help             Show this help message
''');
}

Future<void> startService() async {
  final homeDir = Platform.environment['HOME'];
  if (homeDir == null) {
    print('Error: HOME environment variable not found');
    exit(1);
  }
  
  final plistPath = '$homeDir/Library/LaunchAgents/com.jaybar.plist';
  
  if (!File(plistPath).existsSync()) {
    print('Service not enabled. Run: jaybar --enable-service');
    return;
  }
  
  final result = await Process.run('launchctl', ['load', plistPath]);
  if (result.exitCode == 0) {
    print('jaybar service started');
  } else {
    print('Failed to start service: ${result.stderr}');
  }
}

Future<void> stopService() async {
  final homeDir = Platform.environment['HOME'];
  if (homeDir == null) {
    print('Error: HOME environment variable not found');
    return;
  }
  
  final plistPath = '$homeDir/Library/LaunchAgents/com.jaybar.plist';
  
  final result = await Process.run('launchctl', ['unload', plistPath]);
  if (result.exitCode == 0) {
    print('jaybar service stopped');
  } else {
    print('Failed to stop service: ${result.stderr}');
  }
}

Future<void> restartService() async {
  print('Stopping jaybar service...');
  await stopService();
  await Future.delayed(Duration(milliseconds: 500));
  print('Starting jaybar service...');
  await startService();
}

Future<void> enableService() async {
  await installLaunchAgent();
}

Future<void> disableService() async {
  final homeDir = Platform.environment['HOME'];
  if (homeDir == null) {
    print('Error: HOME environment variable not found');
    return;
  }
  
  final plistPath = '$homeDir/Library/LaunchAgents/com.jaybar.plist';
  
  if (File(plistPath).existsSync()) {
    // Stop service first
    await Process.run('launchctl', ['unload', plistPath]);
    
    // Remove plist file
    await File(plistPath).delete();
    print('jaybar service disabled');
  } else {
    print('Service not enabled');
  }
}

Future<void> installLaunchAgent() async {
  final homeDir = Platform.environment['HOME'];
  if (homeDir == null) {
    print('HOME environment variable not found');
    return;
  }
  
  final launchAgentsDir = Directory('$homeDir/Library/LaunchAgents');
  final plistPath = '${launchAgentsDir.path}/com.jaybar.plist';
  
  if (File(plistPath).existsSync()) {
    print('Launch agent already enabled');
    return;
  }
  
  try {
    await launchAgentsDir.create(recursive: true);
    
    // Get current executable path
    final executablePath = Platform.resolvedExecutable;
    
    final plistContent = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.jaybar</string>
    <key>ProgramArguments</key>
    <array>
        <string>$executablePath</string>
        <string>--service</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>''';
    
    await File(plistPath).writeAsString(plistContent);
    
    final result = await Process.run('launchctl', ['load', plistPath]);
    if (result.exitCode == 0) {
      print('Launch agent enabled successfully');
    } else {
      print('Failed to load launch agent: ${result.stderr}');
    }
  } catch (e) {
    print('Failed to enable launch agent: $e');
  }
}

Future<void> runAsService() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  // Initialize system tray
  await SystemTrayService.instance.initialize();
  
  // Initialize yabai signal service
  try {
    await YabaiSignalService.instance.start();
  } catch (e) {
    print('Failed to start yabai signal service: $e');
  }
  
  // Configure window as always-on-top bar pinned to all workspaces
  await windowManager.waitUntilReadyToShow(null, () async {
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setVisibleOnAllWorkspaces(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setIgnoreMouseEvents(false);
    
    // Set window collection behavior to exclude from Mission Control
    try {
      await platform.invokeMethod('setWindowCollectionBehavior');
    } catch (e) {
      print('Failed to set window collection behavior: $e');
    }
    
    // Use dynamic screen sizing instead of hardcoded dimensions
    await ScreenService.positionBar();
    
    await windowManager.show();
  });
  
  runApp(const FastBarApp());
}

void main(List<String> args) async {
  // Handle CLI commands BEFORE any Flutter initialization
  if (args.isNotEmpty) {
    await handleCliCommand(args);
    return;
  }
  
  // Run GUI mode
  await runAsService();
}

class FastBarApp extends StatelessWidget {
  const FastBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastBar',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
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
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: ScreenService.barHeight,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.barPadding),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.90),
            borderRadius: BorderRadius.circular(AppBorders.barRadius),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  SpaceBar(),
                  const Spacer(),
                  SystemInfoBar(),
                ],
              ),
              Center(
                child: IgnorePointer(
                  child: CenterBar(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
