import 'package:flutter/material.dart';
import 'dart:io';
import '../theme/app_colors.dart';

class CaffeinateWidget extends StatefulWidget {
  @override
  _CaffeinateWidgetState createState() => _CaffeinateWidgetState();
}

class _CaffeinateWidgetState extends State<CaffeinateWidget> {
  bool _isActive = false;
  Process? _caffeinateProcess;

  @override
  void dispose() {
    _stopCaffeinate();
    super.dispose();
  }

  Future<void> _toggleCaffeinate() async {
    if (_isActive) {
      await _stopCaffeinate();
    } else {
      await _startCaffeinate();
    }
  }

  Future<void> _startCaffeinate() async {
    try {
      _caffeinateProcess = await Process.start('caffeinate', ['-d']);
      setState(() {
        _isActive = true;
      });
    } catch (e) {
      print('Error starting caffeinate: $e');
    }
  }

  Future<void> _stopCaffeinate() async {
    if (_caffeinateProcess != null) {
      _caffeinateProcess!.kill();
      _caffeinateProcess = null;
      setState(() {
        _isActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCaffeinate,
      child: Container(
        width: 20,
        height: 20,
        child: Icon(
          Icons.coffee,
          size: 14,
          color: _isActive ? AppColors.brightGreen : AppColors.foreground.withOpacity(0.6),
        ),
      ),
    );
  }
}
