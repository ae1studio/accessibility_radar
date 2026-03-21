import 'package:accessibility_radar_example/none.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accessibility Radar example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DemoHome(),
      routes: {
        NoAccessibilityDemoPage.routeName: (_) =>
            const NoAccessibilityDemoPage(),
      },
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp): _IncrementIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _IncrementIntent: CallbackAction<_IncrementIntent>(
            onInvoke: (_) {
              setState(() => _count++);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Semantics(
                header: true,
                child: const Text('Radar example'),
              ),
            ),
            body: MergeSemantics(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Use DevTools → Accessibility Radar → Scan widget tree.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    label: 'Open screen with no explicit accessibility widgets',
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(NoAccessibilityDemoPage.routeName),
                      child: const Text('Open “no accessibility widgets” page'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label:
                        'Counter shows how many times you pressed the button',
                    child: Text('Count: $_count'),
                  ),
                  const SizedBox(height: 16),
                  FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    button: true,
                    label: 'Increment counter',
                    child: FilledButton(
                      onPressed: () => setState(() => _count++),
                      child: const Text('Increment'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ExcludeSemantics(
                    child: Text(
                      'Decorative note: this line is excluded from semantics on purpose.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncrementIntent extends Intent {
  const _IncrementIntent();
}
