import 'dart:async';

import 'package:accessibility_radar/features/radar/presentation/appt_resources.dart';
import 'package:accessibility_radar/features/radar/radar_scanner_tab.dart';
import 'package:flutter/material.dart';

class RadarHome extends StatelessWidget {
  const RadarHome({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accessibility Radar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Semantics & focus from the inspector; optional missing-label hints. '
                      'Hover rows for properties and device highlight.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'APPT accessibility resources (guidance reference)',
                child: PopupMenuButton<int>(
                  padding: EdgeInsets.zero,
                  tooltip: '',
                  icon: Icon(
                    Icons.menu_book_outlined,
                    size: 20,
                    color: scheme.primary,
                  ),
                  onSelected: (int i) {
                    if (i == 0) {
                      unawaited(
                        openAccessibilityHandbookUrl(Uri.parse(kApptOrg)),
                      );
                    } else if (i == 1) {
                      unawaited(
                        openAccessibilityHandbookUrl(
                          Uri.parse(kApptHandbookPdf),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => const [
                    PopupMenuItem<int>(value: 0, child: Text('appt.org')),
                    PopupMenuItem<int>(
                      value: 1,
                      child: Text('APPT Accessibility Handbook (PDF)'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Expanded(child: RadarScannerTab()),
        ],
      ),
    );
  }
}
