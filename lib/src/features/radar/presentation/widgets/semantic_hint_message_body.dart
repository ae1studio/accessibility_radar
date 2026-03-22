import 'package:accessibility_radar/src/features/radar/domain/tree_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';

class SemanticHintMessageBody extends StatelessWidget {
  const SemanticHintMessageBody({super.key, required this.fullText});

  final String fullText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color onTert = scheme.onTertiaryContainer;
    final TextStyle? proseStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: onTert, height: 1.35);
    final List<String> chunks = fullText.split(kAccessibilityHintSeparator);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < chunks.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 8),
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 8),
          ],
          _SemanticHintChunk(chunk: chunks[i], proseStyle: proseStyle),
        ],
      ],
    );
  }
}

class _SemanticHintChunk extends StatelessWidget {
  const _SemanticHintChunk({required this.chunk, required this.proseStyle});

  final String chunk;
  final TextStyle? proseStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ({String prose, String? dartExample}) parts =
        splitAccessibilityHintMessage(chunk);
    if (parts.dartExample == null) {
      return SelectableText(parts.prose, style: proseStyle);
    }
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Map<String, TextStyle> hlTheme = isDark
        ? atomOneDarkTheme
        : atomOneLightTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(parts.prose, style: proseStyle),
        const SizedBox(height: 8),
        Text(
          'Example',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onTertiaryContainer.withValues(alpha: 0.95),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.55),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectionArea(
              child: HighlightView(
                parts.dartExample!,
                language: 'dart',
                theme: hlTheme,
                textStyle: const TextStyle(fontSize: 12.5, height: 1.45),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
