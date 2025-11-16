import 'dart:io';
import 'package:system_tray/system_tray.dart';
import 'yabai_signal_service.dart';

class SystemTrayService {
  static final SystemTrayService _instance = SystemTrayService._internal();
  static SystemTrayService get instance => _instance;
  SystemTrayService._internal();

  final SystemTray _systemTray = SystemTray();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _systemTray.initSystemTray(
        iconPath: _getIconPath(),
        toolTip: "jaybar - Status Bar",
      );

      final menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(label: 'jaybar', enabled: false),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Restart jaybar',
          onClicked: (menuItem) => _handleRestart(),
        ),
        MenuItemLabel(
          label: 'Quit jaybar',
          onClicked: (menuItem) => _handleQuit(),
        ),
      ]);

      await _systemTray.setContextMenu(menu);
      
      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          _systemTray.popUpContextMenu();
        }
      });
      
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize system tray: $e');
    }
  }

  String _getIconPath() {
    return Platform.isWindows ? 'assets/jaybar.ico' : 'assets/jaybar.png';
  }

  Future<void> _handleRestart() async {
    print('Restart requested from system tray');
    
    // Clean up services
    try {
      YabaiSignalService.instance.dispose();
    } catch (e) {
      print('Error stopping yabai service: $e');
    }
    
    try {
      await dispose();
    } catch (e) {
      print('Error disposing system tray: $e');
    }
    
    // Restart the process
    final executable = Platform.resolvedExecutable;
    final process = await Process.start(executable, []);
    process.exitCode.then((_) => exit(0));
  }

  Future<void> _handleQuit() async {
    print('Graceful shutdown requested from system tray');
    
    // Clean up services
    try {
      YabaiSignalService.instance.dispose();
    } catch (e) {
      print('Error stopping yabai service: $e');
    }
    
    try {
      await dispose();
    } catch (e) {
      print('Error disposing system tray: $e');
    }
    
    exit(0);
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _systemTray.destroy();
      _isInitialized = false;
    }
  }
}
