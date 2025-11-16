import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VolumeWidget extends StatefulWidget {
  const VolumeWidget({super.key});

  @override
  State<VolumeWidget> createState() => _VolumeWidgetState();
}

class _VolumeWidgetState extends State<VolumeWidget> {
  int _volumeLevel = 0;
  bool _isMuted = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateVolume();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateVolume());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateVolume() async {
    try {
      final result = await Process.run('osascript', [
        '-e',
        'output volume of (get volume settings)'
      ]);
      
      if (result.exitCode == 0) {
        final volumeStr = result.stdout.toString().trim();
        final volume = int.tryParse(volumeStr) ?? 0;
        
        final muteResult = await Process.run('osascript', [
          '-e',
          'output muted of (get volume settings)'
        ]);
        
        final isMuted = muteResult.stdout.toString().trim() == 'true';
        
        setState(() {
          _volumeLevel = volume;
          _isMuted = isMuted;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  IconData _getVolumeIcon() {
    if (_isMuted || _volumeLevel == 0) return Icons.volume_off;
    if (_volumeLevel < 30) return Icons.volume_down;
    if (_volumeLevel < 70) return Icons.volume_up;
    return Icons.volume_up;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          _getVolumeIcon(),
          size: 14,
          color: _isMuted ? AppColors.red : AppColors.foreground,
        ),
        const SizedBox(width: 4),
        Text(
          _isMuted ? 'Muted' : '$_volumeLevel%',
          style: TextStyle(
            fontSize: 12,
            color: _isMuted ? Colors.red : null,
          ),
        ),
      ],
    );
  }
}
