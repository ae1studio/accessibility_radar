import 'package:accessibility_radar/src/core/accessibility_types.dart';
import 'package:flutter/material.dart';

class WcagHintHeader extends StatelessWidget {
  const WcagHintHeader({super.key, required this.hints});

  final List<SemanticGapHint> hints;

  @override
  Widget build(BuildContext context) {
    if (hints.isEmpty) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final Color onTert = scheme.onTertiaryContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < hints.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Tooltip(
            message:
                '${hints[i].wcagFullLabel}. See the APPT handbook and WCAG 2.1 for fixes.',
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (i == 0)
                  Chip(
                    avatar: Icon(Icons.gavel, size: 16, color: onTert),
                    label: Text(
                      'WCAG 2.1',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: onTert,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: scheme.tertiary.withValues(alpha: 0.35),
                    side: BorderSide(
                      color: scheme.onTertiaryContainer.withValues(alpha: 0.5),
                    ),
                  ),
                Chip(
                  label: Text(
                    'Level ${hints[i].wcagLevel}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: onTert,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  backgroundColor: scheme.primary.withValues(alpha: 0.35),
                  side: BorderSide(
                    color: scheme.onTertiaryContainer.withValues(alpha: 0.5),
                  ),
                ),
                Chip(
                  label: Text(
                    '${hints[i].criterionId}: ${hints[i].criterionName}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: onTert),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  backgroundColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  side: BorderSide(
                    color: scheme.onTertiaryContainer.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
