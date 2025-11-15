import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

class ScreenService {
  static const double barHeight = 32.0;
  
  /// Get the primary display size
  static Future<Size> getPrimaryScreenSize() async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      if (displays.isEmpty) {
        // Fallback to common resolution
        return const Size(1920, barHeight);
      }
      
      final primary = displays.first;
      return Size(primary.size.width, barHeight);
    } catch (e) {
      // Fallback on error
      return const Size(1920, barHeight);
    }
  }
  
  /// Position the bar at the top of the primary screen
  static Future<void> positionBar() async {
    try {
      final size = await getPrimaryScreenSize();
      await windowManager.setSize(size);
      await windowManager.setPosition(const Offset(0, 0));
    } catch (e) {
      // Fallback positioning
      await windowManager.setSize(const Size(1920, barHeight));
      await windowManager.setPosition(const Offset(0, 0));
    }
  }
  
  /// Get all displays for multi-monitor support
  static Future<List<Display>> getAllDisplays() async {
    try {
      return await screenRetriever.getAllDisplays();
    } catch (e) {
      return [];
    }
  }
  
  /// Listen for screen changes and reposition bar
  static Stream<void> get screenChanges {
    // Create a periodic check for screen changes
    // Note: screen_retriever doesn't have native change events
    return Stream.periodic(const Duration(seconds: 2));
  }
  
  /// Check if screen configuration has changed
  static Future<bool> hasScreenChanged(Size lastSize) async {
    final currentSize = await getPrimaryScreenSize();
    return currentSize != lastSize;
  }
}
