import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class LayoutModeWidget extends StatefulWidget {
  const LayoutModeWidget({super.key});

  @override
  State<LayoutModeWidget> createState() => _LayoutModeWidgetState();
}

class _LayoutModeWidgetState extends State<LayoutModeWidget> {
  String _layoutMode = 'bsp';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateLayoutMode();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateLayoutMode());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateLayoutMode() async {
    try {
      final result = await Process.run('yabai', ['-m', 'query', '--spaces', '--space']);
      if (result.exitCode == 0) {
        final data = jsonDecode(result.stdout);
        final newMode = data['type'] ?? 'bsp';
        if (mounted && newMode != _layoutMode) {
          setState(() => _layoutMode = newMode);
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      _layoutMode == 'stack' ? Icons.layers : Icons.grid_view,
      size: 16,
    );
  }
}
