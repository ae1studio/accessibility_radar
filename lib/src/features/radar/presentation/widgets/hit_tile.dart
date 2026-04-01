import 'package:accessibility_radar/src/core/accessibility_types.dart';
import 'package:flutter/material.dart';

class HitTile extends StatelessWidget {
  const HitTile({
    super.key,
    required this.hit,
    required this.selected,
    required this.onHover,
  });

  final AccessibilityHit hit;
  final bool selected;
  final void Function(bool enter) onHover;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color accent;
    if (hit.hasSemanticWarnings) {
      accent = Color.lerp(scheme.error, scheme.tertiary, 0.4)!;
    } else if (hit.isSemanticSuggestion) {
      accent = scheme.tertiary;
    } else if (hit.hasSemanticsInterest && hit.hasFocusInterest) {
      accent = scheme.tertiary;
    } else if (hit.hasSemanticsInterest) {
      accent = scheme.primary;
    } else {
      accent = scheme.secondary;
    }

    return MouseRegion(
      onEnter: (_) => onHover(true),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : null,
        child: InkWell(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accent, width: 4)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  hit.hasSemanticWarnings
                      ? Icons.warning_amber_rounded
                      : hit.isSemanticSuggestion
                      ? Icons.lightbulb_outline
                      : hit.hasSemanticsInterest
                      ? Icons.accessibility_new
                      : Icons.keyboard,
                  size: 20,
                  color: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hitListTitle(hit),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (hit.hasSemanticWarnings &&
                          hit.semanticWarnings != null &&
                          hit.semanticWarnings!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final SemanticWarning w
                                in hit.semanticWarnings!)
                              Chip(
                                avatar: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: accent,
                                ),
                                label: Text(
                                  w.shortLabel,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ],
                      if (hit.isSemanticSuggestion &&
                          hit.semanticGapHints != null &&
                          hit.semanticGapHints!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Tooltip(
                          message: hit.wcagTooltipDetail ?? '',
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final SemanticGapHint h
                                  in hit.semanticGapHints!)
                                Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: [
                                      Chip(
                                        label: Text(
                                          h.wcagLevel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      Chip(
                                        label: Text(
                                          h.criterionId,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (hit.sourceLocationLabel != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          hit.sourceLocationLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontFamily: 'monospace',
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        hit.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: _hitTooltipMessage(hit),
                  child: const Icon(Icons.info_outline, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _hitListTitle(AccessibilityHit hit) {
  final bool w = hit.hasSemanticWarnings;
  final bool h = hit.isSemanticSuggestion;
  final bool tree = hit.hasSemanticsInterest || hit.hasFocusInterest;
  if (w && h) {
    if (tree) return 'Warning + hint + tree: ${hit.widgetRuntimeType}';
    return 'Warning + hint: ${hit.widgetRuntimeType}';
  }
  if (w) {
    if (tree) return 'Warning + tree: ${hit.widgetRuntimeType}';
    return 'Warning: ${hit.widgetRuntimeType}';
  }
  if (!h) return hit.widgetRuntimeType;
  if (tree) {
    return 'Hint + tree match: ${hit.widgetRuntimeType}';
  }
  return 'Hint: ${hit.widgetRuntimeType}';
}

String _hitTooltipMessage(AccessibilityHit hit) {
  final StringBuffer buf = StringBuffer();
  if (hit.sourceFileUri != null) {
    buf.writeln(hit.sourceFileUri);
    if (hit.sourceLine != null) {
      buf.writeln('Line: ${hit.sourceLine}');
    }
    buf.writeln();
  }
  if (hit.isSemanticSuggestion) {
    buf.writeln('Heuristic: missing semantics hint');
    if (hit.wcagTooltipDetail != null) {
      buf.writeln(hit.wcagTooltipDetail);
    }
    buf.writeln();
  }
  if (hit.hasSemanticWarnings) {
    buf.writeln('Semantic warnings:');
    for (final SemanticWarning w in hit.semanticWarnings!) {
      buf.writeln('• ${w.shortLabel}: ${w.message}');
    }
    buf.writeln();
  }
  buf.write('valueId: ${hit.valueId ?? "none"}');
  return buf.toString().trim();
}
