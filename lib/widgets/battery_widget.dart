import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class BatteryWidget extends StatefulWidget {
  const BatteryWidget({super.key});

  @override
  State<BatteryWidget> createState() => _BatteryWidgetState();
}

class _BatteryWidgetState extends State<BatteryWidget> {
  int _batteryLevel = 0;
  bool _isCharging = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateBattery();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateBattery());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateBattery() async {
    try {
      final result = await Process.run('pmset', ['-g', 'batt']);
      final output = result.stdout.toString();
      final match = RegExp(r'(\d+)%').firstMatch(output);
      final chargingMatch = output.contains('AC Power');
      
      if (match != null) {
        setState(() {
          _batteryLevel = int.parse(match.group(1)!);
          _isCharging = chargingMatch;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  IconData _getBatteryIcon() {
    if (_isCharging) return Icons.battery_charging_full;
    
    if (_batteryLevel >= 90) return Icons.battery_full;
    if (_batteryLevel >= 60) return Icons.battery_5_bar;
    if (_batteryLevel >= 50) return Icons.battery_4_bar;
    if (_batteryLevel >= 30) return Icons.battery_3_bar;
    if (_batteryLevel >= 20) return Icons.battery_2_bar;
    if (_batteryLevel >= 10) return Icons.battery_1_bar;
    return Icons.battery_0_bar;
  }

  Color? _getBatteryColor() {
    if (_batteryLevel < 20) return Colors.red;
    if (_batteryLevel < 50) return Colors.yellow;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBatteryColor();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getBatteryIcon(),
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$_batteryLevel%',
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
