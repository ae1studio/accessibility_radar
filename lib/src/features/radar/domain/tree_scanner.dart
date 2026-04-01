/// WCAG 2.1 fields for a [SemanticGapHint].
class SemanticGapHint {
  const SemanticGapHint({
    required this.message,
    required this.wcagLevel,
    required this.criterionId,
    required this.criterionName,
  });

  /// Full suggestion text shown in the UI.
  final String message;

  /// Conformance level: `A`, `AA`, or `AAA` (WCAG 2.1).
  final String wcagLevel;

  /// Success criterion number, e.g. `1.1.1`.
  final String criterionId;

  /// Short criterion title, e.g. `Non-text Content`.
  final String criterionName;

  /// Tooltip / screen reader line.
  String get wcagFullLabel =>
      'WCAG 2.1 Level $wcagLevel: $criterionId $criterionName';
}

const String kAccessibilityHintSeparator = '\n\n***\n\n';

class SemanticWarning {
  const SemanticWarning({required this.shortLabel, required this.message});

  /// Short title for list chips / compact UI.
  final String shortLabel;

  /// Full explanation for the detail panel.
  final String message;
}

const String kAccessibilityHintExampleSeparator = '\n\nExample:\n';

/// Extra inspector text from [ext.flutter.inspector.getProperties]; the tree summary often omits `properties`.
const String kAccessibilityInspectorPropertyTextKey =
    'accessibilityRadar.inspectorPropertyText';

/// Walks getProperties JSON and appends descriptions into one string.
String flattenInspectorPropertyDescriptions(Object? raw) {
  final StringBuffer buf = StringBuffer();
  void walk(Object? node) {
    if (node is Map) {
      final Object? desc = node['description'];
      if (desc is String && desc.isNotEmpty) {
        buf.writeln(desc);
      }
      final Object? props = node['properties'];
      if (props is List) {
        for (final Object? p in props) {
          walk(p);
        }
      }
    } else if (node is List) {
      for (final Object? p in node) {
        walk(p);
      }
    }
  }
  if (raw is List) {
    for (final Object? p in raw) {
      walk(p);
    }
  } else {
    walk(raw);
  }
  return buf.toString().trimRight();
}

String accessibilityHeuristicInspectorText(
  Map<String, Object?> inspectorNode,
  String nodeDescription,
) {
  final Object? extra =
      inspectorNode[kAccessibilityInspectorPropertyTextKey];
  if (extra is! String || extra.isEmpty) {
    return nodeDescription;
  }
  return '$nodeDescription\n$extra';
}

({String prose, String? dartExample}) splitAccessibilityHintMessage(
  String text,
) {
  final i = text.indexOf(kAccessibilityHintExampleSeparator);
  if (i < 0) return (prose: text, dartExample: null);
  return (
    prose: text.substring(0, i),
    dartExample: text.substring(i + kAccessibilityHintExampleSeparator.length),
  );
}

/// One row in the scan results.
class AccessibilityHit {
  AccessibilityHit({
    required this.description,
    required this.widgetRuntimeType,
    required this.valueId,
    required this.hasSemanticsInterest,
    required this.hasFocusInterest,
    required this.depth,
    this.sourceFileUri,
    this.sourceLine,
    this.sourceColumn,
    this.semanticGapHints,
    this.semanticWarnings,
  }) : assert(
         semanticGapHints == null || semanticGapHints.isNotEmpty,
         'Use null instead of an empty hint list.',
       ),
       assert(
         semanticWarnings == null || semanticWarnings.isNotEmpty,
         'Use null instead of an empty warning list.',
       );

  final String description;
  final String widgetRuntimeType;
  final String? valueId;
  final bool hasSemanticsInterest;
  final bool hasFocusInterest;
  final int depth;

  /// Creation location: `file` URI + line (debug/profile when the VM sends it).
  final String? sourceFileUri;
  final int? sourceLine;
  final int? sourceColumn;

  /// Heuristic WCAG-style hints; multiple can share one row.
  final List<SemanticGapHint>? semanticGapHints;

  /// Structural warnings (MergeSemantics, ExcludeSemantics, etc.).
  final List<SemanticWarning>? semanticWarnings;

  /// Row has at least one hint.
  bool get isSemanticSuggestion =>
      semanticGapHints != null && semanticGapHints!.isNotEmpty;

  /// Row has at least one warning.
  bool get hasSemanticWarnings =>
      semanticWarnings != null && semanticWarnings!.isNotEmpty;

  /// All hint messages joined for tooltips / detail.
  String? get semanticSuggestion {
    if (semanticGapHints == null || semanticGapHints!.isEmpty) return null;
    return semanticGapHints!
        .map((h) => h.message)
        .join(kAccessibilityHintSeparator);
  }

  /// First hint’s WCAG level; full list in [semanticGapHints].
  String? get wcagLevel => semanticGapHints?.first.wcagLevel;

  /// First hint’s criterion id.
  String? get wcagCriterionId => semanticGapHints?.first.criterionId;

  /// First hint’s criterion title.
  String? get wcagCriterionName => semanticGapHints?.first.criterionName;

  bool get isInteresting =>
      hasSemanticsInterest ||
      hasFocusInterest ||
      isSemanticSuggestion ||
      hasSemanticWarnings;

  /// Compact chip text, e.g. `A · 1.1.1` or `A · 1.1.1 (+2 more)`.
  String? get wcagBadgeCompact {
    if (semanticGapHints == null || semanticGapHints!.isEmpty) return null;
    final first = semanticGapHints!.first;
    final base = '${first.wcagLevel} · ${first.criterionId}';
    final extra = semanticGapHints!.length - 1;
    if (extra <= 0) return base;
    return '$base (+$extra more)';
  }

  /// Long tooltip for the WCAG row.
  String? get wcagTooltipDetail {
    if (semanticGapHints == null || semanticGapHints!.isEmpty) return null;
    final buf = StringBuffer();
    for (final h in semanticGapHints!) {
      buf.writeln(
        'WCAG 2.1 Level ${h.wcagLevel}: ${h.criterionId} ${h.criterionName}.',
      );
    }
    buf.write('See the APPT handbook and WCAG 2.1 when fixing issues.');
    return buf.toString();
  }

  /// Short label for lists, e.g. `lib/main.dart:42` or `package:my_app/foo.dart:10`.
  String? get sourceLocationLabel {
    if (sourceFileUri == null || sourceLine == null) return null;
    return formatCreationLocationLabel(
      sourceFileUri!,
      sourceLine!,
      column: sourceColumn,
    );
  }
}

String? formatCreationLocationLabel(String fileUri, int line, {int? column}) {
  final path = _shortenInspectorFileUri(fileUri);
  if (path.isEmpty) return null;
  final col = column != null ? ':$column' : '';
  return '$path:$line$col';
}

String _shortenInspectorFileUri(String fileUri) {
  try {
    final uri = Uri.parse(fileUri);
    if (uri.scheme == 'file' || uri.scheme.isEmpty) {
      final segments = uri.pathSegments;
      if (segments.isEmpty) return fileUri;
      final libIdx = segments.indexOf('lib');
      if (libIdx >= 0 && libIdx < segments.length - 1) {
        return segments.sublist(libIdx).join('/');
      }
      if (segments.length >= 2) {
        return '${segments[segments.length - 2]}/${segments.last}';
      }
      return segments.last;
    }
    if (uri.scheme == 'package') {
      final p = uri.path;
      return p.startsWith('/') ? p.substring(1) : p;
    }
  } catch (_) {}
  final parts = fileUri.split(RegExp(r'[/\\]'));
  return parts.isEmpty ? fileUri : parts.last;
}

/// Scans `getRootWidgetTree` JSON: semantics, focus, optional heuristic rows.
List<AccessibilityHit> scanInspectorTree(
  Map<String, Object?>? root, {
  bool includeSemanticGapHints = true,
  bool includeSemanticWarnings = true,
  bool filterToLocalProject = false,
}) {
  if (root == null) return const [];
  final out = <AccessibilityHit>[];
  void visit(
    Map<String, Object?> node,
    int depth, {
    required int excludeSemanticsDepth,
    required String? parentWidgetType,
    required int mergeSemanticsAncestorCount,
  }) {
    final desc = node['description'] as String? ?? '';
    final type = node['widgetRuntimeType'] as String? ?? '';
    final valueId = node['valueId'] as String?;
    final loc = _parseCreationLocation(node['creationLocation']);
    final createdByLocalProject = node['createdByLocalProject'] == true;
    final sourceFileUri = loc?.$1;

    final inExcludedSubtree = excludeSemanticsDepth > 0;
    var childExcludeDepth = excludeSemanticsDepth;
    if (_isExcludeSemanticsWidget(type, desc)) {
      childExcludeDepth++;
    }

    final sem = _semanticsMatch(type, desc);
    final focus = _focusMatch(type, desc);

    final includeNode =
        !filterToLocalProject ||
        createdByLocalProject ||
        !_isClearlyExternalInspectorSource(sourceFileUri);

    final hints = includeSemanticGapHints && !inExcludedSubtree && includeNode
        ? _collectSemanticGapHints(
            inspectorNode: node,
            type: type,
            description: desc,
            parentWidgetType: parentWidgetType,
            sourceLocationLabel: loc != null
                ? formatCreationLocationLabel(loc.$1, loc.$2, column: loc.$3)
                : null,
          )
        : <SemanticGapHint>[];

    final warnings =
        includeSemanticWarnings && !inExcludedSubtree && includeNode
        ? _collectSemanticWarnings(
            inspectorNode: node,
            type: type,
            description: desc,
            mergeSemanticsAncestorCount: mergeSemanticsAncestorCount,
            parentWidgetType: parentWidgetType,
          )
        : <SemanticWarning>[];

    final isMerge = _isMergeSemanticsWidgetType(type);
    final mergeForChildren = mergeSemanticsAncestorCount + (isMerge ? 1 : 0);

    final gestureDetectorExcludeSemanticsFound =
        includeNode &&
        !inExcludedSubtree &&
        _isPlainGestureDetectorType(type) &&
        _effectiveExcludeFromSemanticsForGestureDetector(node, type, desc);

    if ((sem || focus) && includeNode) {
      out.add(
        AccessibilityHit(
          description: desc,
          widgetRuntimeType: type,
          valueId: valueId,
          hasSemanticsInterest: sem,
          hasFocusInterest: focus,
          depth: depth,
          sourceFileUri: loc?.$1,
          sourceLine: loc?.$2,
          sourceColumn: loc?.$3,
          semanticGapHints: hints.isNotEmpty ? hints : null,
          semanticWarnings: warnings.isNotEmpty ? warnings : null,
        ),
      );
    } else if (hints.isNotEmpty) {
      out.add(
        AccessibilityHit(
          description: desc,
          widgetRuntimeType: type,
          valueId: valueId,
          hasSemanticsInterest: false,
          hasFocusInterest: false,
          depth: depth,
          sourceFileUri: loc?.$1,
          sourceLine: loc?.$2,
          sourceColumn: loc?.$3,
          semanticGapHints: hints,
          semanticWarnings: warnings.isNotEmpty ? warnings : null,
        ),
      );
    } else if (gestureDetectorExcludeSemanticsFound) {
      out.add(
        AccessibilityHit(
          description: desc,
          widgetRuntimeType: type,
          valueId: valueId,
          hasSemanticsInterest: true,
          hasFocusInterest: false,
          depth: depth,
          sourceFileUri: loc?.$1,
          sourceLine: loc?.$2,
          sourceColumn: loc?.$3,
          semanticGapHints: null,
          semanticWarnings: warnings.isNotEmpty ? warnings : null,
        ),
      );
    } else if (warnings.isNotEmpty && includeNode) {
      out.add(
        AccessibilityHit(
          description: desc,
          widgetRuntimeType: type,
          valueId: valueId,
          hasSemanticsInterest: false,
          hasFocusInterest: false,
          depth: depth,
          sourceFileUri: loc?.$1,
          sourceLine: loc?.$2,
          sourceColumn: loc?.$3,
          semanticGapHints: null,
          semanticWarnings: warnings,
        ),
      );
    }

    final children = node['children'];
    if (children is List) {
      for (final c in children) {
        if (c is Map<String, Object?>) {
          visit(
            c,
            depth + 1,
            excludeSemanticsDepth: childExcludeDepth,
            parentWidgetType: type,
            mergeSemanticsAncestorCount: mergeForChildren,
          );
        } else if (c is Map) {
          visit(
            Map<String, Object?>.from(c),
            depth + 1,
            excludeSemanticsDepth: childExcludeDepth,
            parentWidgetType: type,
            mergeSemanticsAncestorCount: mergeForChildren,
          );
        }
      }
    }
  }

  visit(
    root,
    0,
    excludeSemanticsDepth: 0,
    parentWidgetType: null,
    mergeSemanticsAncestorCount: 0,
  );
  return out;
}

/// "App only" filter: treat SDK / pub-cache paths as external when `createdByLocalProject` is missing.
bool _isClearlyExternalInspectorSource(String? fileUri) {
  if (fileUri == null || fileUri.isEmpty) return false;
  final lower = fileUri.toLowerCase();
  if (lower.contains('/.pub-cache/')) return true;
  if (lower.contains('/flutter/packages/flutter/')) return true;
  if (lower.startsWith('package:flutter/')) return true;
  return false;
}

bool _isExcludeSemanticsWidget(String type, String description) {
  return type.contains('ExcludeSemantics') ||
      description.contains('ExcludeSemantics');
}

/// True if [description] (or merged property text) contains `excludeFromSemantics: true`.
bool _inspectorDescriptionShowsExcludeFromSemanticsTrue(String description) {
  if (RegExp(
    r'excludeFromSemantics\s*[:=]\s*true\b',
    caseSensitive: false,
  ).hasMatch(description)) {
    return true;
  }
  final compact = description.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  return compact.contains('excludefromsemantics:true');
}

bool _isPlainGestureDetectorType(String type) {
  if (type.contains('RawGestureDetector')) return false;
  return type == 'GestureDetector' || type.startsWith('GestureDetector');
}

/// True if this gesture target is excluded from semantics.
///
/// [GestureDetector] often omits `excludeFromSemantics` on its summary line; check merged properties
/// and any [RawGestureDetector] child.
bool _effectiveExcludeFromSemanticsForGestureDetector(
  Map<String, Object?> node,
  String type,
  String description,
) {
  final String heuristicText = accessibilityHeuristicInspectorText(
    node,
    description,
  );
  if (_inspectorDescriptionShowsExcludeFromSemanticsTrue(heuristicText)) {
    return true;
  }
  if (type.contains('RawGestureDetector')) {
    return false;
  }
  if (!type.contains('GestureDetector')) {
    return false;
  }
  final children = node['children'];
  if (children is! List) return false;
  for (final c in children) {
    final child = c is Map<String, Object?>
        ? c
        : (c is Map ? Map<String, Object?>.from(c) : null);
    if (child == null) continue;
    final ct = child['widgetRuntimeType'] as String? ?? '';
    final cd = child['description'] as String? ?? '';
    final childHeuristicText = accessibilityHeuristicInspectorText(child, cd);
    if (ct.contains('RawGestureDetector') &&
        _inspectorDescriptionShowsExcludeFromSemanticsTrue(childHeuristicText)) {
      return true;
    }
  }
  return false;
}

String _hintDartExample(String dartSnippet) =>
    '$kAccessibilityHintExampleSeparator${dartSnippet.trimRight()}\n';

List<SemanticGapHint> _collectSemanticGapHints({
  required Map<String, Object?> inspectorNode,
  required String type,
  required String description,
  required String? parentWidgetType,
  required String? sourceLocationLabel,
}) {
  if (_immediateParentSuppliesSemantics(parentWidgetType)) {
    return const [];
  }
  if (_effectiveExcludeFromSemanticsForGestureDetector(
    inspectorNode,
    type,
    description,
  )) {
    return const [];
  }

  final String heuristicText =
      accessibilityHeuristicInspectorText(inspectorNode, description);

  final where = sourceLocationLabel != null
      ? 'Where: $sourceLocationLabel. Widget type: $type.\n\n'
      : 'Where: this widget’s build method (no creation location from the VM; use a debug or profile build).\n\n';

  void appendUnique(List<SemanticGapHint> out, SemanticGapHint hint) {
    if (out.any((h) => h.criterionId == hint.criterionId)) return;
    out.add(hint);
  }

  final out = <SemanticGapHint>[];

  if (_isImageLikeWidget(type) &&
      _imageInspectorLacksSemanticLabel(description)) {
    appendUnique(
      out,
      SemanticGapHint(
        message:
            '${where}This Image does not show a non-empty semanticLabel in the inspector string '
            '(the VM often omits it when unset; it is usually null). '
            'Set semanticLabel on Image, or wrap with Semantics(label: …, image: true, child: …), '
            'or excludeFromSemantics: true if purely decorative. Hover Properties to confirm.'
            '${_hintDartExample("Image.asset(\n"
            "  'assets/logo.png',\n"
            "  semanticLabel: 'Company logo', // spoken name for screen readers\n"
            ");\n"
            '\n'
            '// Decorative image only (no spoken name):\n'
            '// Image.asset(..., excludeFromSemantics: true)\n'
            '\n'
            '// Or wrap:\n'
            '// Semantics(label: "Logo", image: true, child: Image.network(url))')}',
        wcagLevel: 'A',
        criterionId: '1.1.1',
        criterionName: 'Non-text Content',
      ),
    );
  }

  if (_richTextGenericLinkPurpose(type, description)) {
    appendUnique(
      out,
      SemanticGapHint(
        message:
            '${where}This rich text includes a tappable span with very generic link text (e.g. “click here”, “read more”). '
            'Prefer descriptive link text (or an explicit Semantics label) so the purpose is clear out of context. '
            'See also 2.4.4 (A) for in-context link purpose.'
            '${_hintDartExample('Text.rich(\n'
            '  TextSpan(\n'
            '    children: [\n'
            '      const TextSpan(text: "Read our "),\n'
            '      TextSpan(\n'
            '        text: "privacy policy",\n'
            '        style: TextStyle(color: Theme.of(context).colorScheme.primary),\n'
            '        recognizer: TapGestureRecognizer()..onTap = openPrivacy,\n'
            '      ),\n'
            '    ],\n'
            '  ),\n'
            ')\n'
            '\n'
            '// Or wrap the tappable region:\n'
            '// Semantics(label: "Open privacy policy", link: true, child: GestureDetector(...))')}',
        wcagLevel: 'AAA',
        criterionId: '2.4.9',
        criterionName: 'Link Purpose (Link Only)',
      ),
    );
  }

  if (_textLooksLikeHeadingWithoutHeaderSemantics(type, description)) {
    appendUnique(
      out,
      SemanticGapHint(
        message:
            '${where}This Text is styled like a prominent heading (large + bold) but the inspector line does not show '
            'heading-related Semantics (e.g. Semantics(header: true) or an appropriate role on web). '
            'Consider marking headings so assistive tech can navigate by structure.'
            '${_hintDartExample('Semantics(\n'
            '  header: true,\n'
            '  child: Text(\n'
            "    'Section title',\n"
            '    style: Theme.of(context).textTheme.headlineSmall,\n'
            '  ),\n'
            ')')}',
        wcagLevel: 'AA',
        criterionId: '2.4.6',
        criterionName: 'Headings and Labels',
      ),
    );
  }

  if (_focusIndicatorLikelyHidden(type, description)) {
    appendUnique(
      out,
      SemanticGapHint(
        message:
            '${where}This control shows a transparent or fully transparent `focusColor` (or equivalent) in the inspector summary. '
            'Keyboard users need a visible focus indicator; restore a non-transparent focus/highlight color or use theme focus styles.'
            '${_hintDartExample('InkWell(\n'
            '  focusColor: Theme.of(context).focusColor,\n'
            '  // or: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),\n'
            '  onTap: () {},\n'
            '  child: const Padding(...),\n'
            ')\n'
            '\n'
            '// Theme-wide (Material 3):\n'
            '// ThemeData(focusColor: ..., or use component themes for ButtonStyle)')}',
        wcagLevel: 'AA',
        criterionId: '2.4.7',
        criterionName: 'Focus Visible',
      ),
    );
  }

  if (_touchTargetLikelyTooSmall(type, description, inspectorNode)) {
    appendUnique(
      out,
      SemanticGapHint(
        message:
            '${where}This interactive widget’s inspector summary suggests a very small hit target '
            '(e.g. tight SizedBox or small IconButton constraints). '
            'Aim for at least ~44×44 logical pixels for primary targets (WCAG 2.1 AAA 2.5.5); '
            'increase padding or minimum size and retest with touch and pointer.'
            '${_hintDartExample('ConstrainedBox(\n'
            '  constraints: const BoxConstraints(\n'
            '    minWidth: 48,\n'
            '    minHeight: 48,\n'
            '  ),\n'
            '  child: GestureDetector(onTap: () {}, child: icon),\n'
            ')\n'
            '\n'
            '// IconButton already enforces a minimum tap target; avoid shrinking with tight SizedBox.\n'
            '// IconButton(iconSize: 24, constraints: BoxConstraints(minWidth: 48, minHeight: 48), ...)')}',
        wcagLevel: 'AAA',
        criterionId: '2.5.5',
        criterionName: 'Target Size',
      ),
    );
  }

  if (_isBareGestureDetector(type, description, inspectorNode)) {
    appendUnique(
      out,
      SemanticGapHint(
        message:
            '${where}This GestureDetector may be a custom tap/drag target without a clear spoken name. '
            'Flutter’s inspector usually does not list onTap/onPan in the tree line. Check Properties. '
            'Prefer IconButton, TextButton, or InkWell where possible, or wrap with '
            'Semantics(button: true, label: …, child: …). '
            'For keyboard users, also provide a focusable/actionable wrapper (e.g. FocusableActionDetector + Shortcuts/Actions).'
            '${_hintDartExample('Semantics(\n'
            '  button: true,\n'
            "  label: 'Open menu',\n"
            '  child: GestureDetector(\n'
            '    onTap: () {},\n'
            '    child: const Icon(Icons.menu),\n'
            '  ),\n'
            ')\n'
            '\n'
            '// Often simpler: IconButton(tooltip: "Menu", onPressed: () {})\n'
            '// Keyboard: wrap with FocusableActionDetector + Shortcuts/Actions if needed.')}',
        wcagLevel: 'A',
        criterionId: '4.1.2',
        criterionName: 'Name, Role, Value (related: 2.1.1 Keyboard)',
      ),
    );
  }

  if (_textFieldLikelyNeedsAccessibleLabel(type, heuristicText)) {
    appendUnique(
      out,
      SemanticGapHint(
        message:
            '${where}This TextField appears to rely on hintText without a persistent label. '
            'Prefer InputDecoration(labelText: …) (or an explicit Semantics label) so screen readers '
            'and form navigation have a stable accessible name.'
            '${_hintDartExample('TextField(\n'
            '  decoration: InputDecoration(\n'
            "    labelText: 'Email address',\n"
            "    hintText: 'you@example.com',\n"
            '  ),\n'
            ')\n'
            '\n'
            '// Or TextFormField + InputDecoration(labelText: ...)')}',
        wcagLevel: 'A',
        criterionId: '3.3.2',
        criterionName: 'Labels or Instructions',
      ),
    );
  }

  if (_dropdownLikelyNeedsVisibleLabel(type, heuristicText)) {
    appendUnique(
      out,
      SemanticGapHint(
        message:
            '${where}This dropdown appears to use a hint without a persistent visible label. '
            'Prefer InputDecoration(labelText: …) on DropdownButtonFormField, or a visible Text label '
            'associated with DropdownButton via Semantics, so the control keeps its name in context.'
            '${_hintDartExample('DropdownButtonFormField<String>(\n'
            '  decoration: const InputDecoration(\n'
            "    labelText: 'Country',\n"
            '  ),\n'
            '  items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),\n'
            '  onChanged: (v) {},\n'
            ')\n'
            '\n'
            '// Plain DropdownButton: pair with a visible Text label + Semantics above, or use FormField.')}',
        wcagLevel: 'A',
        criterionId: '3.3.2',
        criterionName: 'Labels or Instructions',
      ),
    );
  }

  if (_sliderLikelyMissingValueLabel(type, description)) {
    appendUnique(
      out,
      SemanticGapHint(
        message:
            '${where}This Slider does not show a `label` in the inspector summary. '
            'Provide `label:` (value readout while adjusting) and ensure screen readers get the current value '
            '(Semantics or Slider properties) per platform guidance.'
            '${_hintDartExample('Slider(\n'
            '  value: volume,\n'
            '  min: 0,\n'
            '  max: 100,\n'
            "  label: '\${volume.round()}%', // announced while dragging\n"
            '  onChanged: (v) => setState(() => volume = v),\n'
            "  semanticFormatterCallback: (v) => '\${v.round()} percent',\n"
            ')')}',
        wcagLevel: 'A',
        criterionId: '4.1.2',
        criterionName: 'Name, Role, Value',
      ),
    );
  }

  if (_controlLikelyMissingAccessibleName(type, heuristicText)) {
    appendUnique(
      out,
      SemanticGapHint(
        message:
            '${where}This Material or Cupertino input control appears to rely on an icon-only or placeholder-only presentation and the inspector summary shows no tooltip, label, or semantic label. '
            'Controls such as IconButton, FloatingActionButton, CupertinoButton, Switch, Checkbox, Radio, and their Cupertino equivalents should expose a clear accessible name via tooltip, semanticLabel, labelText, or an enclosing Semantics/ListTile widget.'
            '${_hintDartExample('IconButton(\n'
            '  icon: const Icon(Icons.menu),\n'
            '  tooltip: \'Open navigation menu\',\n'
            '  onPressed: openMenu,\n'
            ')\n'
            '\n'
            '// Or wrap a CupertinoButton or Switch:\n'
            '// Semantics(label: \'Close dialog\', button: true, child: CupertinoButton(...))\n'
            '// Semantics(label: \'Enable notifications\', toggled: isOn, child: Switch(...))')}',
        wcagLevel: 'A',
        criterionId: '4.1.2',
        criterionName: 'Name, Role, Value',
      ),
    );
  }

  return out;
}

List<SemanticWarning> _collectSemanticWarnings({
  required Map<String, Object?> inspectorNode,
  required String type,
  required String description,
  required int mergeSemanticsAncestorCount,
  required String? parentWidgetType,
}) {
  final out = <SemanticWarning>[];

  void addUnique(SemanticWarning w) {
    if (out.any((x) => x.shortLabel == w.shortLabel)) return;
    out.add(w);
  }

  if (_isMergeSemanticsWidgetType(type) && mergeSemanticsAncestorCount > 0) {
    addUnique(
      const SemanticWarning(
        shortLabel: 'Nested MergeSemantics',
        message:
            'This MergeSemantics sits inside another MergeSemantics. Nesting is rarely needed and can make merged semantics harder to reason about. Prefer a single MergeSemantics or restructure the subtree.',
      ),
    );
  }

  if (_isGenericSemanticsWidgetType(type) &&
      _immediateChildIsGenericSemantics(inspectorNode)) {
    addUnique(
      const SemanticWarning(
        shortLabel: 'Nested Semantics',
        message:
            'The direct child is another Semantics widget. That is often redundant; consider one Semantics/MergeSemantics scope or an explicit merge strategy unless you intentionally split roles.',
      ),
    );
  }

  if (_isGenericSemanticsWidgetType(type) &&
      _semanticsButtonLacksAccessibleLabel(description)) {
    addUnique(
      const SemanticWarning(
        shortLabel: 'Button without label',
        message:
            'Semantics marks this node as a button, but the inspector line shows no usable label or tooltip. Screen readers need a name, so set label / Semantics(label: ...) / tooltip as appropriate.',
      ),
    );
  }

  if (_isExcludeSemanticsWidget(type, description) &&
      _firstChildLooksInteractive(inspectorNode)) {
    addUnique(
      const SemanticWarning(
        shortLabel: 'ExcludeSemantics + interactive child',
        message:
            'ExcludeSemantics removes this subtree from the semantics tree. If the first child is interactive (button, InkWell, etc.), assistive tech may not reach it. Reserve ExcludeSemantics for purely decorative content.',
      ),
    );
  }

  if (_shouldSuggestMergeSemanticsForLayout(
    inspectorNode: inspectorNode,
    type: type,
    mergeSemanticsAncestorCount: mergeSemanticsAncestorCount,
    parentWidgetType: parentWidgetType,
  )) {
    addUnique(
      const SemanticWarning(
        shortLabel: 'Consider MergeSemantics',
        message:
            'Flutter’s MergeSemantics merges descendant semantics into one node so screen readers announce a Row/Column/Flex/Wrap as a single unit instead of stepping through each child (e.g. Icon + Text). '
            'Use it when several children contribute to one meaning: wrap the layout as MergeSemantics(child: Row(...)). '
            'You can skip this if a parent Semantics already provides one label for the group, or if each child must stay a separate semantic target.',
      ),
    );
  }

  return out;
}

bool _shouldSuggestMergeSemanticsForLayout({
  required Map<String, Object?> inspectorNode,
  required String type,
  required int mergeSemanticsAncestorCount,
  required String? parentWidgetType,
}) {
  if (mergeSemanticsAncestorCount > 0) {
    return false;
  }
  if (_immediateParentSuppliesSemantics(parentWidgetType)) {
    return false;
  }
  if (!_isRowColumnFlexOrWrapLayoutType(type)) {
    return false;
  }
  return _countMergeSemanticsCandidateChildren(inspectorNode) >= 2;
}

bool _isRowColumnFlexOrWrapLayoutType(String type) {
  if (type == 'Row' || type.startsWith('Row<') || type.startsWith('Row(')) {
    return true;
  }
  if (type == 'Column' ||
      type.startsWith('Column<') ||
      type.startsWith('Column(')) {
    return true;
  }
  if (type == 'Flex' || type.startsWith('Flex<') || type.startsWith('Flex(')) {
    return true;
  }
  if (type == 'Wrap' || type.startsWith('Wrap<') || type.startsWith('Wrap(')) {
    return true;
  }
  return false;
}

int _countMergeSemanticsCandidateChildren(Map<String, Object?> node) {
  final children = node['children'];
  if (children is! List) {
    return 0;
  }
  var n = 0;
  for (final c in children) {
    final map = c is Map<String, Object?>
        ? c
        : (c is Map ? Map<String, Object?>.from(c) : null);
    if (map == null) {
      continue;
    }
    final ct = map['widgetRuntimeType'] as String? ?? '';
    if (_isMergeSemanticsCandidateChildType(ct)) {
      n++;
    }
  }
  return n;
}

bool _isMergeSemanticsCandidateChildType(String type) {
  if (type == 'Text' || type.startsWith('Text<') || type.startsWith('Text(')) {
    return true;
  }
  if (type.contains('RichText')) {
    return true;
  }
  if (type == 'Icon' || type.startsWith('Icon<') || type.startsWith('Icon(')) {
    return true;
  }
  if (type == 'Image' || type.startsWith('Image(')) {
    return true;
  }
  if (type.contains('IconButton')) {
    return true;
  }
  return false;
}

bool _isMergeSemanticsWidgetType(String type) {
  return type.contains('MergeSemantics');
}

bool _isGenericSemanticsWidgetType(String type) {
  return type == 'Semantics' || type.startsWith('Semantics(');
}

Map<String, Object?>? _firstChildMap(Map<String, Object?> node) {
  final children = node['children'];
  if (children is! List || children.isEmpty) return null;
  final first = children.first;
  if (first is Map<String, Object?>) return first;
  if (first is Map) return Map<String, Object?>.from(first);
  return null;
}

bool _immediateChildIsGenericSemantics(Map<String, Object?> node) {
  final child = _firstChildMap(node);
  if (child == null) return false;
  final ct = child['widgetRuntimeType'] as String? ?? '';
  return ct == 'Semantics' || ct.startsWith('Semantics(');
}

bool _semanticsButtonLacksAccessibleLabel(String description) {
  if (!RegExp(
    r'\bbutton\s*:\s*true\b',
    caseSensitive: false,
  ).hasMatch(description)) {
    return false;
  }
  final labelMatch = RegExp(
    r'\blabel\s*:\s*',
    caseSensitive: false,
  ).firstMatch(description);
  if (labelMatch != null) {
    final rest = description.substring(labelMatch.end);
    final token = _firstPropertyValueToken(rest);
    if (token != null &&
        token != 'null' &&
        token != '""' &&
        token != "''" &&
        token.isNotEmpty) {
      return false;
    }
  }
  final tipMatch = RegExp(
    r'\btooltip\s*:\s*',
    caseSensitive: false,
  ).firstMatch(description);
  if (tipMatch != null) {
    final rest = description.substring(tipMatch.end);
    final token = _firstPropertyValueToken(rest);
    if (token != null &&
        token != 'null' &&
        token != '""' &&
        token != "''" &&
        token.isNotEmpty) {
      return false;
    }
  }
  return true;
}

String? _firstPropertyValueToken(String afterColon) {
  final t = afterColon.trimLeft();
  if (t.isEmpty) return null;
  if (t.startsWith('null')) return 'null';
  if (t.startsWith('""')) return '""';
  if (t.startsWith("''")) return "''";
  if (t.startsWith('"')) {
    final end = t.indexOf('"', 1);
    if (end > 0) return t.substring(0, end + 1);
  }
  if (t.startsWith("'")) {
    final end = t.indexOf("'", 1);
    if (end > 0) return t.substring(0, end + 1);
  }
  final buf = StringBuffer();
  var depth = 0;
  for (var i = 0; i < t.length; i++) {
    final ch = t[i];
    if (ch == '(' || ch == '[' || ch == '{') {
      depth++;
    } else if (ch == ')' || ch == ']' || ch == '}') {
      depth = depth > 0 ? depth - 1 : 0;
    } else if (ch == ',' && depth == 0) {
      break;
    }
    buf.write(ch);
  }
  final s = buf.toString().trim();
  return s.isEmpty ? null : s;
}

bool _firstChildLooksInteractive(Map<String, Object?> node) {
  final child = _firstChildMap(node);
  if (child == null) return false;
  final ct = child['widgetRuntimeType'] as String? ?? '';
  final cd = child['description'] as String? ?? '';
  const interactiveTypes = <String>[
    'InkWell',
    'InkResponse',
    'GestureDetector',
    'ElevatedButton',
    'FilledButton',
    'TextButton',
    'OutlinedButton',
    'IconButton',
    'CupertinoButton',
    'FloatingActionButton',
    'Switch',
    'Checkbox',
    'Radio',
    'Slider',
    'TextField',
    'MenuItemButton',
    'SubmenuButton',
  ];
  if (interactiveTypes.any(ct.contains)) {
    return true;
  }
  final lower = cd.toLowerCase();
  return lower.contains('ontap') || lower.contains('onpressed');
}

bool _immediateParentSuppliesSemantics(String? parentType) {
  if (parentType == null) return false;
  if (parentType.contains('Semantics') &&
      !parentType.contains('ExcludeSemantics')) {
    return true;
  }
  const materialButtons = <String>[
    'IconButton',
    'TextButton',
    'ElevatedButton',
    'FilledButton',
    'OutlinedButton',
    'IconButtonTheme',
    'MenuItemButton',
    'SubmenuButton',
    'CupertinoButton',
    'FloatingActionButton',
    'InkWell',
    'ListTile',
    'SwitchListTile',
    'CheckboxListTile',
    'RadioListTile',
    'ExpansionTile',
    // MergeSemantics has no label; still visit children.
  ];
  return materialButtons.any(parentType.contains);
}

bool _isImageLikeWidget(String type) {
  switch (type) {
    case 'Image':
    case 'RawImage':
      return true;
    default:
      if (type.contains('FadeInImage')) return true;
      return false;
  }
}

/// True when the summary shows no non-empty `semanticLabel`.
///
/// Null labels are often left out of the string; that still counts as needing review unless a quoted label appears.
bool _imageInspectorLacksSemanticLabel(String description) {
  if (description.contains('excludeFromSemantics: true')) {
    return false;
  }
  return !_hasNonEmptySemanticLabelInDescription(description);
}

bool _hasNonEmptySemanticLabelInDescription(String description) {
  final dq = RegExp(
    r'semanticLabel:\s*"([^"]*)"',
    caseSensitive: false,
  ).firstMatch(description);
  if (dq != null && (dq.group(1)?.trim().isNotEmpty ?? false)) {
    return true;
  }
  final sq = RegExp(
    r"semanticLabel:\s*'([^']*)'",
    caseSensitive: false,
  ).firstMatch(description);
  return sq != null && (sq.group(1)?.trim().isNotEmpty ?? false);
}

bool _isBareGestureDetector(
  String type,
  String description,
  Map<String, Object?> inspectorNode,
) {
  if (!type.contains('GestureDetector')) return false;
  if (type.contains('RawGestureDetector')) return false;
  final d = description;
  if (_effectiveExcludeFromSemanticsForGestureDetector(
    inspectorNode,
    type,
    d,
  )) {
    return false;
  }
  if (d.contains('behavior: HitTestBehavior.deferToChild') ||
      d.toLowerCase().contains('hittestbehavior.defertochild')) {
    return false;
  }
  return _gestureDetectorLikelyNeedsSemanticsName(description);
}

bool _gestureDetectorLikelyNeedsSemanticsName(String description) {
  final lower = description.toLowerCase();

  if (_hasDragLikeCallbacks(lower) && !_hasTapLikeCallbacks(lower)) {
    return false;
  }

  if (_hasTapLikeCallbacks(lower)) {
    return true;
  }

  final minimal =
      lower.trim() == 'gesturedetector' ||
      (lower.startsWith('gesturedetector(') && !_hasDragLikeCallbacks(lower));
  return minimal;
}

bool _hasTapLikeCallbacks(String lower) {
  const tokens = <String>[
    'ontap',
    'onlongpress',
    'ondoubletap',
    'onsecondarytap',
    'ontertiarytap',
    'onforcepress',
  ];
  return tokens.any(lower.contains);
}

bool _hasDragLikeCallbacks(String lower) {
  const tokens = <String>[
    'onpan',
    'onhorizontaldrag',
    'onverticaldrag',
    'onscale',
  ];
  return tokens.any(lower.contains);
}

bool _textFieldInspectorShowsLabel(String lower, String description) {
  if (RegExp(r'labeltext\s*:\s*null\b', caseSensitive: false).hasMatch(lower)) {
    return false;
  }
  if (RegExp(r'labeltext\s*:', caseSensitive: false).hasMatch(lower)) {
    return true;
  }
  if (RegExp(
    r'label\s*:\s*(const\s+)?(Text|RichText)\s*\(',
    caseSensitive: false,
  ).hasMatch(description)) {
    return true;
  }
  return false;
}

bool _textFieldLikelyNeedsAccessibleLabel(String type, String description) {
  if (!type.contains('TextField') && !type.contains('EditableText')) {
    return false;
  }
  final lower = description.toLowerCase();
  if (lower.contains('excludefromsemantics: true')) {
    return false;
  }
  if (_textFieldInspectorShowsLabel(lower, description)) {
    return false;
  }
  return lower.contains('hinttext:');
}

bool _dropdownLikelyNeedsVisibleLabel(String type, String description) {
  if (!type.contains('DropdownButton')) return false;
  final lower = description.toLowerCase();
  if (lower.contains('excludefromsemantics: true')) return false;
  if (lower.contains('labeltext:')) return false;
  return true;
}

bool _sliderLikelyMissingValueLabel(String type, String description) {
  if (!type.contains('Slider')) return false;
  final lower = description.toLowerCase();
  if (lower.contains('excludefromsemantics: true')) return false;
  if (lower.contains('label: null')) return true;
  if (!lower.contains('label:')) return true;
  if (RegExp(r'label:\s*"[^"]+"').hasMatch(description)) return false;
  if (RegExp(r"label:\s*'[^']+'").hasMatch(description)) return false;
  return true;
}

bool _controlLikelyMissingAccessibleName(String type, String description) {
  const controlTypes = <String>[
    'IconButton',
    'FloatingActionButton',
    'CupertinoButton',
    'Switch',
    'Checkbox',
    'Radio',
    'CupertinoSwitch',
    'CupertinoCheckbox',
    'CupertinoRadio',
    'CupertinoSlider',
    'CupertinoTextField',
  ];
  if (!controlTypes.any(type.contains)) {
    return false;
  }
  final lower = description.toLowerCase();
  if (lower.contains('excludefromsemantics: true')) {
    return false;
  }
  if (lower.contains('tooltip:')) {
    return false;
  }
  if (_hasNonEmptySemanticLabelInDescription(description)) {
    return false;
  }
  if (_hasNonEmptyTextChildInDescription(description)) {
    return false;
  }
  return true;
}

bool _hasNonEmptyTextChildInDescription(String description) {
  final RegExp pattern = RegExp(
    "Text\\s*\\(\\s*(['\\\"])([^'\\\"]+)\\1",
    caseSensitive: false,
  );
  final RegExpMatch? textMatch = pattern.firstMatch(description);
  if (textMatch == null) {
    return false;
  }
  final String value = (textMatch.group(2) ?? '').trim();
  return value.isNotEmpty;
}

/// WCAG 2.1 AAA 2.4.9 — generic link text in [RichText] / [Text] spans.
bool _richTextGenericLinkPurpose(String type, String description) {
  final lower = description.toLowerCase();
  final hasRecognizer =
      lower.contains('tapgesturerecognizer') ||
      lower.contains('longpressgesturerecognizer');
  if (!hasRecognizer) return false;
  final isRich = type.contains('RichText') || type == 'Text';
  if (!isRich) return false;

  const genericPhrases = <String>[
    'click here',
    'tap here',
    'read more',
    'learn more',
    'see more',
  ];
  for (final g in genericPhrases) {
    if (lower.contains(g)) return true;
  }
  if (lower.contains("text: 'here'") || lower.contains('text: "here"')) {
    return true;
  }
  return false;
}

/// WCAG 2.1 AA 2.4.6 — large bold [Text] without header semantics in the summary.
bool _textLooksLikeHeadingWithoutHeaderSemantics(
  String type,
  String description,
) {
  if (type != 'Text') return false;
  final lower = description.toLowerCase();
  if (lower.contains('excludefromsemantics: true')) return false;
  if (lower.contains('header: true') || lower.contains('semanticsrole:')) {
    return false;
  }
  if (lower.contains('tapgesturerecognizer') || lower.contains('rich:')) {
    return false;
  }

  final hasBold =
      lower.contains('fontweight.bold') ||
      lower.contains('w700') ||
      lower.contains('w800') ||
      lower.contains('w900');
  final sizeMatch = RegExp(
    r'fontsize:\s*(\d+\.?\d*)',
    caseSensitive: false,
  ).firstMatch(description);
  final sz = sizeMatch != null
      ? double.tryParse(sizeMatch.group(1) ?? '')
      : null;
  final large = sz != null && sz >= 20.0;
  return hasBold && large;
}

/// WCAG 2.1 AA 2.4.7 — focus ring hidden (transparent focusColor).
bool _focusIndicatorLikelyHidden(String type, String description) {
  const interactive = <String>[
    'InkWell',
    'InkResponse',
    'IconButton',
    'TextButton',
    'ElevatedButton',
    'OutlinedButton',
    'FilledButton',
  ];
  if (!interactive.any(type.contains)) return false;
  final lower = description.toLowerCase();
  if (!lower.contains('focuscolor:')) return false;
  if (lower.contains('colors.transparent')) return true;
  if (lower.contains('color(alpha: 0)')) return true;
  if (lower.contains('0x00000000')) return true;
  return false;
}

/// WCAG 2.1 AAA 2.5.5 — very small hit target in the summary.
bool _touchTargetLikelyTooSmall(
  String type,
  String description,
  Map<String, Object?> inspectorNode,
) {
  if (!type.contains('GestureDetector') &&
      !type.contains('InkWell') &&
      !type.contains('InkResponse') &&
      !type.contains('IconButton')) {
    return false;
  }
  if (type.contains('GestureDetector') &&
      _effectiveExcludeFromSemanticsForGestureDetector(
        inspectorNode,
        type,
        description,
      )) {
    return false;
  }
  final d = description;
  final square = RegExp(
    r'SizedBox\.square\(\s*(\d+\.?\d*)\s*\)',
    caseSensitive: false,
  ).firstMatch(d);
  if (square != null) {
    final v = double.tryParse(square.group(1) ?? '');
    if (v != null && v < 44) return true;
  }
  final wMatch = RegExp(
    r'width:\s*(\d+\.?\d*)',
    caseSensitive: false,
  ).firstMatch(d);
  final hMatch = RegExp(
    r'height:\s*(\d+\.?\d*)',
    caseSensitive: false,
  ).firstMatch(d);
  if (wMatch != null && hMatch != null) {
    final w = double.tryParse(wMatch.group(1) ?? '');
    final h = double.tryParse(hMatch.group(1) ?? '');
    if (w != null && h != null && w < 44 && h < 44) return true;
  }
  if (type.contains('IconButton')) {
    final minW = RegExp(
      r'minWidth:\s*(\d+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(d);
    final minH = RegExp(
      r'minHeight:\s*(\d+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(d);
    if (minW != null && minH != null) {
      final a = double.tryParse(minW.group(1) ?? '');
      final b = double.tryParse(minH.group(1) ?? '');
      if (a != null && b != null && a < 44 && b < 44) return true;
    }
  }
  return false;
}

(String, int, int?)? _parseCreationLocation(Object? raw) {
  if (raw == null) return null;
  final Map<String, Object?>? map = switch (raw) {
    final Map<String, Object?> m => m,
    final Map m => Map<String, Object?>.from(
      m.map((k, v) => MapEntry(k.toString(), v as Object?)),
    ),
    _ => null,
  };
  if (map == null) return null;
  final file = map['file'] as String?;
  final lineVal = map['line'];
  final colVal = map['column'];
  final line = lineVal is int
      ? lineVal
      : (lineVal is num ? lineVal.toInt() : null);
  final column = colVal is int
      ? colVal
      : (colVal is num ? colVal.toInt() : null);
  if (file == null || line == null) return null;
  return (file, line, column);
}

bool _semanticsMatch(String type, String description) {
  const keys = [
    'Semantics',
    'MergeSemantics',
    'ExcludeSemantics',
    'IndexedSemantics',
    'BlockSemantics',
    'SemanticsDebugger',
    'RenderSemanticsAnnotations',
    'SemanticsGestureDelegate',
  ];
  return keys.any((k) => type.contains(k) || description.contains(k));
}

bool _focusMatch(String type, String description) {
  const keys = [
    'Focus',
    'FocusScope',
    'FocusTraversal',
    'FocusableActionDetector',
    'Shortcuts',
    'Actions',
    'KeyboardListener',
    'CallbackShortcuts',
    'FocusManager',
  ];
  return keys.any((k) => type.contains(k) || description.contains(k));
}

String formatPropertiesForTooltip(List<Object?>? properties) {
  if (properties == null || properties.isEmpty) {
    return 'No extra properties returned (try a debug/profile build).';
  }
  final buf = StringBuffer();
  for (final p in properties) {
    if (p is Map) {
      final name = p['name'] as String? ?? '';
      final desc = p['description'] as String? ?? '';
      if (name.isNotEmpty) {
        buf.writeln('$name: $desc');
      } else if (desc.isNotEmpty) {
        buf.writeln(desc);
      }
    }
  }
  final s = buf.toString().trim();
  return s.isEmpty ? '(empty property list)' : s;
}
