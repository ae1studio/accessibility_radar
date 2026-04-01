const String kAccessibilityInspectorPropertyTextKey =
    'accessibilityRadar.inspectorPropertyText';

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

String formatPropertiesForTooltip(List<Object?>? properties) {
  if (properties == null || properties.isEmpty) {
    return 'No extra properties returned (try a debug/profile build).';
  }
  final StringBuffer buf = StringBuffer();
  for (final Object? p in properties) {
    if (p is Map) {
      final String name = p['name'] as String? ?? '';
      final String desc = p['description'] as String? ?? '';
      if (name.isNotEmpty) {
        buf.writeln('$name: $desc');
      } else if (desc.isNotEmpty) {
        buf.writeln(desc);
      }
    }
  }
  final String s = buf.toString().trim();
  return s.isEmpty ? '(empty property list)' : s;
}

