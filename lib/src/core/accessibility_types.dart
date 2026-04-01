class SemanticGapHint {
  const SemanticGapHint({
    required this.message,
    required this.wcagLevel,
    required this.criterionId,
    required this.criterionName,
  });

  final String message;
  final String wcagLevel;
  final String criterionId;
  final String criterionName;

  String get wcagFullLabel =>
      'WCAG 2.1 Level $wcagLevel: $criterionId $criterionName';
}

const String kAccessibilityHintSeparator = '\n\n***\n\n';

class SemanticWarning {
  const SemanticWarning({required this.shortLabel, required this.message});

  final String shortLabel;
  final String message;
}

const String kAccessibilityHintExampleSeparator = '\n\nExample:\n';

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

  final String? sourceFileUri;
  final int? sourceLine;
  final int? sourceColumn;

  final List<SemanticGapHint>? semanticGapHints;
  final List<SemanticWarning>? semanticWarnings;

  bool get isSemanticSuggestion =>
      semanticGapHints != null && semanticGapHints!.isNotEmpty;

  bool get hasSemanticWarnings =>
      semanticWarnings != null && semanticWarnings!.isNotEmpty;

  String? get semanticSuggestion {
    if (semanticGapHints == null || semanticGapHints!.isEmpty) return null;
    return semanticGapHints!
        .map((SemanticGapHint h) => h.message)
        .join(kAccessibilityHintSeparator);
  }

  String? get wcagLevel => semanticGapHints?.first.wcagLevel;

  String? get wcagCriterionId => semanticGapHints?.first.criterionId;

  String? get wcagCriterionName => semanticGapHints?.first.criterionName;

  bool get isInteresting =>
      hasSemanticsInterest ||
      hasFocusInterest ||
      isSemanticSuggestion ||
      hasSemanticWarnings;

  String? get wcagBadgeCompact {
    if (semanticGapHints == null || semanticGapHints!.isEmpty) return null;
    final SemanticGapHint first = semanticGapHints!.first;
    final String base = '${first.wcagLevel} · ${first.criterionId}';
    final int extra = semanticGapHints!.length - 1;
    if (extra <= 0) return base;
    return '$base (+$extra more)';
  }

  String? get wcagTooltipDetail {
    if (semanticGapHints == null || semanticGapHints!.isEmpty) return null;
    final StringBuffer buf = StringBuffer();
    for (final SemanticGapHint h in semanticGapHints!) {
      buf.writeln(
        'WCAG 2.1 Level ${h.wcagLevel}: ${h.criterionId} ${h.criterionName}.',
      );
    }
    buf.write('See the APPT handbook and WCAG 2.1 when fixing issues.');
    return buf.toString();
  }

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
  final String path = _shortenInspectorFileUri(fileUri);
  if (path.isEmpty) return null;
  final String col = column != null ? ':$column' : '';
  return '$path:$line$col';
}

String _shortenInspectorFileUri(String fileUri) {
  try {
    final Uri uri = Uri.parse(fileUri);
    if (uri.scheme == 'file' || uri.scheme.isEmpty) {
      final List<String> segments = uri.pathSegments;
      if (segments.isEmpty) return fileUri;
      final int libIdx = segments.indexOf('lib');
      if (libIdx >= 0 && libIdx < segments.length - 1) {
        return segments.sublist(libIdx).join('/');
      }
      if (segments.length >= 2) {
        return '${segments[segments.length - 2]}/${segments.last}';
      }
      return segments.last;
    }
    if (uri.scheme == 'package') {
      final String p = uri.path;
      return p.startsWith('/') ? p.substring(1) : p;
    }
  } catch (_) {}
  final List<String> parts = fileUri.split(RegExp(r'[/\\]'));
  return parts.isEmpty ? fileUri : parts.last;
}

