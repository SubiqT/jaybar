import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class NetworkWidget extends StatefulWidget {
  const NetworkWidget({super.key});

  @override
  State<NetworkWidget> createState() => _NetworkWidgetState();
}

class _NetworkWidgetState extends State<NetworkWidget> {
  bool _isConnected = false;
  String _connectionType = '';
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
        setState(() {
          _isConnected = true;
          _connectionType = 'wifi';
        });
      } else {
        // Check for any active network connection
        final routeResult = await Process.run('route', ['get', 'default']);
        if (routeResult.exitCode == 0) {
          setState(() {
            _isConnected = true;
            _connectionType = 'ethernet';
          });
        } else {
          setState(() {
            _isConnected = false;
            _connectionType = '';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionType = '';
      });
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getNetworkIcon(),
          size: 14,
          color: _isConnected ? null : Colors.red,
        ),
      ],
    );
  }
}
