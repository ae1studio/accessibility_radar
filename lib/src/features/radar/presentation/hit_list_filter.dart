/// What to show in the hit list: everything, inspector “found” rows only, hints, or semantic warnings.
enum HitListFilter {
  /// Semantics + focus primitives and WCAG hints.
  all,

  /// Rows from the tree that match semantics/focus heuristics (not hint suggestions).
  foundOnly,

  /// WCAG heuristic hints only.
  hintsOnly,

  /// Structural / best-practice semantic warnings only.
  warningsOnly,
}

extension HitListFilterUi on HitListFilter {
  String get shortLabel => switch (this) {
    HitListFilter.all => 'All',
    HitListFilter.foundOnly => 'Found',
    HitListFilter.hintsOnly => 'Hints',
    HitListFilter.warningsOnly => 'Warnings',
  };

  String get tooltip => switch (this) {
    HitListFilter.all =>
      'Show semantics/focus matches, WCAG hints, and semantic warnings',
    HitListFilter.foundOnly =>
      'Show only widgets matched as Semantics/focus primitives (exclude hint rows)',
    HitListFilter.hintsOnly => 'Show only WCAG-style heuristic hints',
    HitListFilter.warningsOnly =>
      'Show only rows with semantic structure warnings (nested MergeSemantics, etc.)',
  };
}
