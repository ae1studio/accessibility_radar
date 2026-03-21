import 'package:accessibility_radar/src/features/radar_shell/presentation/radar_home.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DevToolsExtension(child: RadarHome()));
}
