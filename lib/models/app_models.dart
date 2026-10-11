import 'dart:typed_data';

import 'package:flutter/material.dart';

enum MoodQuadrant { red, blue, green, yellow }

extension MoodData on MoodQuadrant {
  Color get color {
    switch (this) {
      case MoodQuadrant.red:
        return const Color(0xFFE53935);
      case MoodQuadrant.blue:
        return const Color(0xFF1976D2);
      case MoodQuadrant.green:
        return const Color(0xFF43A047);
      case MoodQuadrant.yellow:
        return const Color(0xFFFFB300);
    }
  }

  String get label {
    switch (this) {
      case MoodQuadrant.red:
        return 'High Energy · Unpleasant';
      case MoodQuadrant.blue:
        return 'Low Energy · Unpleasant';
      case MoodQuadrant.green:
        return 'Low Energy · Pleasant';
      case MoodQuadrant.yellow:
        return 'High Energy · Pleasant';
    }
  }
}

class AppInfo {
  final String appName;
  final String packageName;
  final Uint8List? icon;

  /// Total foreground time over the ranking window (ms). 0 = unused.
  final int foregroundMs;

  AppInfo({
    required this.appName,
    required this.packageName,
    this.icon,
    this.foregroundMs = 0,
  });

  bool get hasRecentUsage => foregroundMs > 0;

  AppInfo copyWithUsage(int ms) => AppInfo(
        appName: appName,
        packageName: packageName,
        icon: icon,
        foregroundMs: ms,
      );
}
