import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NetworkWidget extends StatefulWidget {
  const NetworkWidget({super.key});

  @override
  State<NetworkWidget> createState() => _NetworkWidgetState();
}

class _NetworkWidgetState extends State<NetworkWidget> {
  bool _isConnected = false;
  String _connectionType = '';
  String _networkName = '';
  bool _showName = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateNetworkStatus();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _updateNetworkStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateNetworkStatus() async {
    try {
      // Check if Wi-Fi is connected using system_profiler
      final wifiResult = await Process.run('system_profiler', ['SPAirPortDataType']);
      final wifiOutput = wifiResult.stdout.toString();
      
      if (wifiOutput.contains('Current Network Information:')) {
        // Extract network name from Wi-Fi output
        final lines = wifiOutput.split('\n');
        String networkName = '';
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains('Current Network Information:')) {
            // Look for the network name in the following lines
            for (int j = i + 1; j < lines.length && j < i + 10; j++) {
              if (lines[j].trim().isEmpty) break;
              final line = lines[j].trim();
              if (!line.contains(':') && line.isNotEmpty) {
                networkName = line;
                break;
              }
            }
            break;
          }
        }
        
        if (mounted) {
          setState(() {
            _isConnected = true;
            _connectionType = 'wifi';
            _networkName = networkName.isNotEmpty ? networkName : 'Wi-Fi';
          });
        }
      } else {
        // Check for any active network connection
        final routeResult = await Process.run('route', ['get', 'default']);
        if (routeResult.exitCode == 0) {
          if (mounted) {
            setState(() {
              _isConnected = true;
              _connectionType = 'ethernet';
              _networkName = 'Ethernet';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _connectionType = '';
              _networkName = '';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _connectionType = '';
          _networkName = '';
        });
      }
    }
  }

  IconData _getNetworkIcon() {
    if (!_isConnected) return Icons.wifi_off;
    if (_connectionType == 'wifi') return Icons.wifi;
    if (_connectionType == 'ethernet') return Icons.lan;
    return Icons.signal_wifi_4_bar;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (mounted) {
          setState(() => _showName = !_showName);
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _getNetworkIcon(),
              size: 14,
              color: _isConnected ? null : Colors.red,
            ),
            if (_showName && _networkName.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                _networkName,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
