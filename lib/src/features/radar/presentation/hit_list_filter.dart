/// Which rows the hit list shows.
enum HitListFilter {
  /// Semantics, focus, hints, and warnings.
  all,

  /// Semantics/focus hits only (no hint rows).
  foundOnly,

  /// WCAG-style hints only.
  hintsOnly,

  /// Structural warnings only.
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
    HitListFilter.all => 'Semantics, focus, hints, and warnings',
    HitListFilter.foundOnly => 'Semantics and focus matches only',
    HitListFilter.hintsOnly => 'WCAG-style hints only',
    HitListFilter.warningsOnly => 'Structure warnings only (e.g. MergeSemantics)',
  };
}
