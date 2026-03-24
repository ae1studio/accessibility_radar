
import 'package:flutter/material.dart';

/// Intentionally plain: no [Semantics], [MergeSemantics], [ExcludeSemantics], or focus groups; good for demo scans.
class NoAccessibilityDemoPage extends StatefulWidget {
  const NoAccessibilityDemoPage({super.key});

  static const String routeName = '/no-accessibility-demo';

  @override
  State<NoAccessibilityDemoPage> createState() =>
      _NoAccessibilityDemoPageState();
}

class _NoAccessibilityDemoPageState extends State<NoAccessibilityDemoPage> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('No accessibility extras'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'This screen uses plain widgets only—no Semantics, focus groups, '
            'or shortcuts. Scan here to see recommendations.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _taps++),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tap target',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.star),
            ],
          ),
          const SizedBox(height: 8),
          Text('Taps: $_taps'),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              hintText: 'No label, hint only',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Image.network(
            'https://flutter.dev/images/flutter-logo-sharing.png',
            height: 48,
            errorBuilder: (_, _, _) => const Text('(image failed to load)'),
          ),
        ],
      ),
    );
  }
}
